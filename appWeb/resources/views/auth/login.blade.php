<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>Iniciar sesión - Echoes</title>

    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">

    <style>
        :root {
            --primary:      #3F7AC5;
            --dark-base:    #353F4C;
            --dark-dark:    #2B333D;
            --accent:       #E9C978;
            --accent-dark:  #E5C062;
            --bg-light:     #F8F8F8;
            --bg-dark:      #DFDFDF;
            --danger:       #EF4444;
            --success:      #16A34A;
        }

        * { box-sizing: border-box; margin: 0; padding: 0; }

        body {
            background-color: var(--dark-base);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            color: var(--dark-dark);
        }

        .login-container {
            max-width: 420px;
            width: 100%;
            padding: 20px;
        }

        .login-card {
            background: white;
            border-radius: 16px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.25);
            overflow: hidden;
        }

        .login-header {
            background-color: var(--dark-dark);
            color: white;
            padding: 36px 30px;
            text-align: center;
        }

        .login-header h1 {
            font-size: 1.6rem;
            font-weight: 700;
            margin-bottom: 4px;
            letter-spacing: 0.5px;
        }

        .login-header p {
            font-size: 0.875rem;
            opacity: 0.75;
            margin: 0;
        }

        .login-header img.logo {
            width: 120px;
            height: auto;
            object-fit: contain;
            margin-bottom: 12px;
        }

        .input-group-icon {
            position: relative;
        }

        /* Solo el ícono izquierdo (hijo directo) */
        .input-group-icon > .bi {
            position: absolute;
            left: 12px;
            top: 50%;
            transform: translateY(-50%);
            color: #9ca3af;
            font-size: 1rem;
            pointer-events: none;
            z-index: 5;
        }

        .input-group-icon .form-control {
            padding-left: 38px;
        }

        .input-group-icon .form-control.has-toggle {
            padding-right: 44px;
        }

        .input-group-icon .toggle-password {
            position: absolute;
            right: 0;
            top: 0;
            height: 100%;
            width: 44px;
            background: none;
            border: none;
            padding: 0;
            color: #9ca3af;
            cursor: pointer;
            font-size: 1.1rem;
            z-index: 10;
            display: flex;
            align-items: center;
            justify-content: center;
            border-radius: 0 8px 8px 0;
        }

        .input-group-icon .toggle-password:hover {
            color: var(--primary);
        }

        .login-body {
            padding: 36px 30px;
        }

        .form-label {
            font-weight: 600;
            font-size: 0.875rem;
            color: var(--dark-dark);
            margin-bottom: 6px;
        }

        .form-control {
            border: 1.5px solid var(--bg-dark);
            border-radius: 8px;
            padding: 10px 14px;
            font-size: 0.95rem;
            color: var(--dark-dark);
            background-color: white;
            transition: border-color 0.2s;
        }

        .form-control:focus {
            border-color: var(--primary);
            box-shadow: 0 0 0 3px rgba(63, 122, 197, 0.15);
            outline: none;
        }

        .form-control.is-invalid {
            border-color: var(--danger);
        }

        .form-control.is-invalid:focus {
            box-shadow: 0 0 0 3px rgba(239, 68, 68, 0.15);
        }

        .invalid-feedback {
            color: var(--danger);
            font-size: 0.8rem;
            margin-top: 4px;
        }

        .form-check-input:checked {
            background-color: var(--primary);
            border-color: var(--primary);
        }

        .form-check-input:focus {
            box-shadow: 0 0 0 3px rgba(63, 122, 197, 0.15);
            border-color: var(--primary);
        }

        .btn-login {
            width: 100%;
            padding: 11px;
            background-color: var(--primary);
            border: none;
            border-radius: 8px;
            color: white;
            font-weight: 600;
            font-size: 0.95rem;
            cursor: pointer;
            transition: background-color 0.2s;
        }

        .btn-login:hover {
            background-color: #355f9a;
        }

        .btn-login:focus {
            outline: none;
            box-shadow: 0 0 0 3px rgba(63, 122, 197, 0.35);
        }

        .divider {
            border-top: 1px solid var(--bg-dark);
            margin: 24px 0 16px;
        }

        .footer-link {
            text-align: center;
            font-size: 0.875rem;
            color: #6b7280;
        }

        .footer-link a {
            color: var(--primary);
            text-decoration: none;
            font-weight: 600;
        }

        .footer-link a:hover {
            text-decoration: underline;
        }

        .alert {
            border-radius: 8px;
            border: none;
            padding: 12px 16px;
            font-size: 0.875rem;
            margin-bottom: 20px;
        }

        .alert-success {
            background-color: rgba(22, 163, 74, 0.1);
            color: var(--success);
        }

        .alert-danger {
            background-color: rgba(239, 68, 68, 0.1);
            color: var(--danger);
        }

        .copyright {
            text-align: center;
            margin-top: 20px;
            font-size: 0.8rem;
            color: rgba(255, 255, 255, 0.5);
        }
    </style>
</head>
<body>
    <div class="login-container">
        <div class="login-card">

            <div class="login-header">
                <img src="/images/logoapp.png" alt="Echoes" class="logo">
                <h1>Echoes</h1>
                <p>Inicia sesión para continuar</p>
            </div>

            <div class="login-body">
                @if(session('success'))
                    <div class="alert alert-success" role="alert">
                        {{ session('success') }}
                        <button type="button" class="btn-close float-end" data-bs-dismiss="alert"></button>
                    </div>
                @endif

                @if($errors->any())
                    <div class="alert alert-danger" role="alert">
                        @foreach($errors->all() as $error)
                            {{ $error }}
                        @endforeach
                        <button type="button" class="btn-close float-end" data-bs-dismiss="alert"></button>
                    </div>
                @endif

                <form method="POST" action="{{ route('login') }}">
                    @csrf

                    <div class="mb-3">
                        <label for="email" class="form-label">Correo electrónico</label>
                        <div class="input-group-icon">
                            <i class="bi bi-envelope"></i>
                            <input
                                type="email"
                                class="form-control @error('email') is-invalid @enderror"
                                id="email"
                                name="email"
                                value="{{ old('email') }}"
                                placeholder="tu@email.com"
                                required
                                autofocus
                            >
                        </div>
                        @error('email')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                    </div>

                    <div class="mb-3">
                        <label for="password" class="form-label">Contraseña</label>
                        <div class="input-group-icon">
                            <i class="bi bi-lock"></i>
                            <input
                                type="password"
                                class="form-control has-toggle @error('password') is-invalid @enderror"
                                id="password"
                                name="password"
                                placeholder="••••••••"
                                required
                            >
                            <button type="button" class="toggle-password" onclick="togglePassword('password', this)">
                                <i class="bi bi-eye"></i>
                            </button>
                        </div>
                        @error('password')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                    </div>

                    <div class="mb-4">
                        <div class="form-check">
                            <input class="form-check-input" type="checkbox" id="remember" name="remember" value="1">
                            <label class="form-check-label" for="remember" style="font-size: 0.875rem;">
                                Recordarme
                            </label>
                        </div>
                    </div>

                    <button type="submit" class="btn-login">Iniciar sesión</button>
                </form>

                <div class="divider"></div>
                <p class="footer-link">
                    ¿No tienes una cuenta?
                    <a href="{{ route('register') }}">Regístrate aquí</a>
                </p>
            </div>
        </div>

        <p class="copyright">&copy; {{ date('Y') }} Echoes. Todos los derechos reservados.</p>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        function togglePassword(id, btn) {
            var input = document.getElementById(id);
            var icon = btn.querySelector('i');
            if (input.type === 'password') {
                input.type = 'text';
                icon.classList.replace('bi-eye', 'bi-eye-slash');
            } else {
                input.type = 'password';
                icon.classList.replace('bi-eye-slash', 'bi-eye');
            }
        }
    </script>
</body>
</html>
