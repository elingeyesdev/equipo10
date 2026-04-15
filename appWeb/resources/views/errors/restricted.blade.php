<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Acceso Restringido - Amigate</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600;800&display=swap" rel="stylesheet">
    <style>
        body { font-family: 'Outfit', sans-serif; }
    </style>
</head>
<body class="bg-gray-100 flex items-center justify-center min-h-screen p-4">

    <div class="bg-white rounded-2xl shadow-xl p-8 max-w-md w-full text-center">
        <div class="mb-6">
            <div class="mx-auto w-20 h-20 bg-red-100 rounded-full flex items-center justify-center mb-4">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-10 w-10 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                </svg>
            </div>
            <h1 class="text-3xl font-bold text-gray-800 mb-2">Acceso Restringido</h1>
            <p class="text-gray-600">
                Esta es una zona exclusiva para usuarios con privilegios elevados.
            </p>
        </div>

        <div class="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-8 text-sm text-blue-800">
            Tu cuenta tiene el rol de <strong>Usuario</strong>. <br>
            Necesitas ser <strong>Editor</strong> o <strong>Administrador</strong> para acceder al panel.
        </div>

        <form method="POST" action="{{ route('logout') }}">
            @csrf
            <button type="submit" class="w-full bg-gray-900 hover:bg-black text-white font-bold py-3 px-6 rounded-xl transition duration-300 shadow-lg transform hover:scale-[1.02]">
                Cerrar Sesión
            </button>
        </form>
    </div>

</body>
</html>
