<?php
$data = [
    'usuario_id' => '019dcb54-b88a-7127-9017-15cc823ec1fd',
    'categoria_id' => '4c067a7b-0237-4582-99ee-12020e0ec2aa',
    'tipo_reporte' => 'perdido',
    'titulo' => 'Perri test',
    'descripcion' => 'Un test',
    'ubicacion_exacta_lat' => -17.7816,
    'ubicacion_exacta_lng' => -63.1826,
    'contacto_publico' => true
];

$options = [
    'http' => [
        'header'  => "Content-type: application/json\r\nAccept: application/json\r\n",
        'method'  => 'POST',
        'content' => json_encode($data),
        'ignore_errors' => true // to get response body even on 500 error
    ]
];
$context  = stream_context_create($options);
$result = file_get_contents('http://nginx/api/reportes', false, $context);
echo "RESPONSE FROM API:\n";
echo $result . "\n";
