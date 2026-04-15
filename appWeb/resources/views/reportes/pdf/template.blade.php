<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>{{ $title }}</title>
    <style>
        body { font-family: sans-serif; }
        h1 { color: #333; border-bottom: 2px solid #ddd; padding-bottom: 10px; }
        .footer { position: fixed; bottom: 0; width: 100%; text-align: center; font-size: 12px; color: #999; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h1>{{ $title }}</h1>
    <p>Fecha de generación: {{ date('Y-m-d H:i:s') }}</p>

    <div class="content">
        <p>Este es un reporte generado automáticamente por el sistema "Amigate".</p>
        
        
        <p>Los datos detallados se encuentran adjuntos o visualizados en la plataforma web.</p>
    </div>

    <div class="footer">
        &copy; {{ date('Y') }} Amigate - Sistema de Objetos Perdidos
    </div>
</body>
</html>
