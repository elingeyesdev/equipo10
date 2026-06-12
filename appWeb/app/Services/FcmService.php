<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;

class FcmService
{
    private string $projectId;
    private string $clientEmail;
    private string $privateKey;

    public function __construct()
    {
        $this->projectId   = config('services.firebase.project_id', '');
        $this->clientEmail = config('services.firebase.client_email', '');
        // Las variables de entorno almacenan \n como literal — convertir a saltos reales
        $this->privateKey  = str_replace('\\n', "\n", config('services.firebase.private_key', ''));
    }

    /**
     * Obtener access token de Google OAuth2 usando las credenciales del service account.
     * Se cachea por 55 minutos (el token dura 60 min).
     */
    private function getAccessToken(): ?string
    {
        return Cache::remember('fcm_access_token', 3300, function () {
            try {
                $now = time();

                // Header JWT
                $header = $this->base64UrlEncode(json_encode([
                    'alg' => 'RS256',
                    'typ' => 'JWT',
                ]));

                // Payload JWT
                $payload = $this->base64UrlEncode(json_encode([
                    'iss' => $this->clientEmail,
                    'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
                    'aud' => 'https://oauth2.googleapis.com/token',
                    'iat' => $now,
                    'exp' => $now + 3600,
                ]));

                // Firmar con la clave privada
                $dataToSign = "$header.$payload";
                $privateKey = openssl_pkey_get_private($this->privateKey);

                if (!$privateKey) {
                    Log::channel('fcm')->error('[FcmService] Clave privada de Firebase invalida');
                    return null;
                }

                openssl_sign($dataToSign, $signature, $privateKey, OPENSSL_ALGO_SHA256);
                $jwt = $dataToSign . '.' . $this->base64UrlEncode($signature);

                // Intercambiar JWT por access token
                $response = Http::asForm()->post('https://oauth2.googleapis.com/token', [
                    'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                    'assertion' => $jwt,
                ]);

                if ($response->successful()) {
                    Log::channel('fcm')->info('[FcmService] Access token obtenido correctamente');
                    return $response->json('access_token');
                }

                Log::channel('fcm')->error('[FcmService] Error al obtener access token: ' . $response->body());
                return null;
            } catch (\Exception $e) {
                Log::channel('fcm')->error('[FcmService] Excepcion al obtener access token: ' . $e->getMessage());
                return null;
            }
        });
    }

    /**
     * Enviar notificacion push a UN token FCM.
     */
    public function enviarAToken(string $token, string $titulo, string $cuerpo, array $datos = []): bool
    {
        $accessToken = $this->getAccessToken();

        if (!$accessToken) {
            Log::channel('fcm')->error('[FcmService] No se pudo obtener access token, notificacion no enviada');
            return false;
        }

        try {
            $message = [
                'message' => [
                    'token' => $token,
                    'notification' => [
                        'title' => $titulo,
                        'body' => $cuerpo,
                    ],
                ],
            ];

            if (!empty($datos)) {
                // FCM data values deben ser strings
                $message['message']['data'] = array_map('strval', $datos);
            }

            $url = "https://fcm.googleapis.com/v1/projects/{$this->projectId}/messages:send";

            $response = Http::withToken($accessToken)
                ->post($url, $message);

            if ($response->successful()) {
                Log::channel('fcm')->info("[FcmService] Notificacion enviada a token: " . substr($token, 0, 20) . '...');
                return true;
            }

            Log::channel('fcm')->warning('[FcmService] Error al enviar notificacion: ' . $response->body());
            return false;
        } catch (\Exception $e) {
            Log::channel('fcm')->error('[FcmService] Excepcion al enviar notificacion: ' . $e->getMessage());
            return false;
        }
    }

    /**
     * Enviar notificacion push MASIVA a multiples tokens FCM.
     * Retorna un array con el resultado de cada envio.
     */
    public function enviarMasivo(array $tokens, string $titulo, string $cuerpo, array $datos = []): array
    {
        $resultados = [
            'enviados' => 0,
            'fallidos' => 0,
            'tokens_invalidos' => [],
        ];

        foreach ($tokens as $token) {
            if (empty($token)) {
                $resultados['fallidos']++;
                continue;
            }

            $exito = $this->enviarAToken($token, $titulo, $cuerpo, $datos);

            if ($exito) {
                $resultados['enviados']++;
            } else {
                $resultados['fallidos']++;
                $resultados['tokens_invalidos'][] = $token;
            }
        }

        Log::channel('fcm')->info("[FcmService] Envio masivo completado: {$resultados['enviados']} enviados, {$resultados['fallidos']} fallidos", [
            'titulo' => $titulo,
            'datos' => $datos,
            'invalidos' => $resultados['tokens_invalidos']
        ]);

        return $resultados;
    }

    /**
     * Verificar si el servicio FCM esta configurado correctamente.
     */
    public function estaConfigurado(): bool
    {
        return !empty($this->projectId)
            && !empty($this->clientEmail)
            && !empty($this->privateKey);
    }

    /**
     * Codificacion Base64 URL-safe (requerida para JWT).
     */
    private function base64UrlEncode(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }
}
