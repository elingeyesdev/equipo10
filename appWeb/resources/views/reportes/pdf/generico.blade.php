<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>{{ $title }}</title>
    <style>
        body { font-family: sans-serif; font-size: 12px; color: #333; }
        .header { text-align: center; margin-bottom: 30px; border-bottom: 2px solid #2563eb; padding-bottom: 10px; }
        .header h1 { color: #2563eb; margin: 0; font-size: 24px; text-transform: uppercase; }
        .meta { color: #666; font-style: italic; margin-top: 5px; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 10px; text-align: left; }
        th { background-color: #f8f9fa; color: #1f2937; font-weight: bold; text-transform: uppercase; font-size: 10px; }
        tr:nth-child(even) { background-color: #f9fafb; }
        .footer { position: fixed; bottom: 0; width: 100%; text-align: center; font-size: 10px; color: #9ca3af; border-top: 1px solid #ddd; padding-top: 10px; }
        .logo { position: absolute; top: 0; left: 0; font-weight: bold; color: #2563eb; font-size: 18px; }
    </style>
</head>
<body>
    <div class="logo">Amigate</div>
    
    <div class="header">
        <h1>{{ $title }}</h1>
        <div class="meta">{{ $meta }}</div>
        <div class="meta">Generado el: {{ date('d/m/Y H:i') }}</div>
    </div>

    <table>
        <thead>
            <tr>
                @foreach($columns as $col)
                    <th>{{ $col }}</th>
                @endforeach
            </tr>
        </thead>
        <tbody>
            @foreach($datos as $d)
                <tr>
                    @foreach($keys as $key)
                        <td>
                            
                            @if(is_array($d))
                                {{ $d[$key] }}
                            @elseif(is_object($d))
                                {{ $d->$key }}
                            @else
                                -
                            @endif
                        </td>
                    @endforeach
                </tr>
            @endforeach
        </tbody>
    </table>

    <div class="footer">
        Este documento es un reporte oficial del sistema Amigate.
    </div>
</body>
</html>
