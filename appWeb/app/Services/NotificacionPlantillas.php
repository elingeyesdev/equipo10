<?php

namespace App\Services;

/**
 * Plantillas de mensaje para notificaciones de estado final.
 * Genera titulo y cuerpo dinamicos segun el tipo de resultado del reporte.
 */
class NotificacionPlantillas
{
    /**
     * Resultado POSITIVO: el caso fue resuelto exitosamente.
     * Se usa cuando el reporte pasa a estado "resuelto".
     */
    public static function positivo(string $tituloReporte, string $nombreCreador = ''): array
    {
        $cuerpo = "El caso \"{$tituloReporte}\" ha sido resuelto exitosamente.";
        if (!empty($nombreCreador)) {
            $cuerpo .= " {$nombreCreador} confirmo el hallazgo.";
        }
        $cuerpo .= " Gracias por tu colaboracion como voluntario.";

        return [
            'titulo' => 'Caso Resuelto',
            'cuerpo' => $cuerpo,
            'tipo' => 'resultado_positivo',
        ];
    }

    /**
     * Resultado SUSPENSION (pausado): la busqueda fue suspendida temporalmente.
     * Se usa cuando el reporte pasa a estado "pausado".
     */
    public static function suspension(string $tituloReporte, string $justificacion = ''): array
    {
        $cuerpo = "La busqueda del caso \"{$tituloReporte}\" fue suspendida temporalmente.";
        if (!empty($justificacion)) {
            $cuerpo .= " Motivo: {$justificacion}";
        }

        return [
            'titulo' => 'Busqueda Suspendida',
            'cuerpo' => $cuerpo,
            'tipo' => 'resultado_suspension',
        ];
    }

    /**
     * Resultado REAPERTURA: un caso pausado fue reactivado.
     * Se usa cuando el reporte vuelve a estado "activo" desde "pausado".
     */
    public static function reapertura(string $tituloReporte): array
    {
        return [
            'titulo' => 'Busqueda Reactivada',
            'cuerpo' => "El caso \"{$tituloReporte}\" ha sido reactivado. La busqueda continua, mantente atento.",
            'tipo' => 'resultado_reapertura',
        ];
    }

    /**
     * Notificacion de EXPANSION: el area de busqueda se expandio.
     */
    public static function expansion(string $tituloReporte, int $nivel): array
    {
        return [
            'titulo' => 'Area de Busqueda Ampliada',
            'cuerpo' => "El caso \"{$tituloReporte}\" ha expandido su zona de busqueda al nivel {$nivel}. Nuevos voluntarios pueden unirse.",
            'tipo' => 'expansion_reporte',
        ];
    }

    /**
     * Notificacion de NUEVO REPORTE en la zona del voluntario.
     */
    public static function nuevoReporte(string $tituloReporte, string $categoria = ''): array
    {
        $cuerpo = "Nuevo caso reportado: \"{$tituloReporte}\"";
        if (!empty($categoria)) {
            $cuerpo .= " (Categoria: {$categoria})";
        }
        $cuerpo .= ". Tu ayuda puede ser clave.";

        return [
            'titulo' => 'Nuevo Caso en tu Zona',
            'cuerpo' => $cuerpo,
            'tipo' => 'nuevo_reporte_zona',
        ];
    }

    /**
     * Mensaje de BROADCAST del creador del reporte a sus voluntarios.
     */
    public static function broadcast(string $tituloReporte, string $mensaje): array
    {
        return [
            'titulo' => "Mensaje del caso: {$tituloReporte}",
            'cuerpo' => $mensaje,
            'tipo' => 'broadcast_voluntarios',
        ];
    }
}
