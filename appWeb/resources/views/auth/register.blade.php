<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>Registro - Echoes</title>

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
            padding: 20px 0;
        }

        .register-container {
            max-width: 460px;
            width: 100%;
            padding: 20px;
        }

        .register-card {
            background: white;
            border-radius: 16px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.25);
            overflow: hidden;
        }

        .register-header {
            background-color: var(--dark-dark);
            color: white;
            padding: 36px 30px;
            text-align: center;
        }

        .register-header h1 {
            font-size: 1.6rem;
            font-weight: 700;
            margin-bottom: 4px;
            letter-spacing: 0.5px;
        }

        .register-header p {
            font-size: 0.875rem;
            opacity: 0.75;
            margin: 0;
        }

        .register-header img.logo {
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

        .register-body {
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

        .btn-register {
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

        .btn-register:hover {
            background-color: #355f9a;
        }

        .btn-register:focus {
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

        .hint {
            font-size: 0.8rem;
            color: #6b7280;
            margin-top: 4px;
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
    <div class="register-container">
        <div class="register-card">

            <div class="register-header">
                <img src="/images/logoapp.png" alt="Echoes" class="logo">
                <h1>Echoes</h1>
                <p>Crea tu cuenta para comenzar</p>
            </div>

            <div class="register-body">
                @if(session('success'))
                    <div class="alert alert-success" role="alert">
                        {{ session('success') }}
                        <button type="button" class="btn-close float-end" data-bs-dismiss="alert"></button>
                    </div>
                @endif

                @if($errors->any())
                    <div class="alert alert-danger" role="alert">
                        <ul class="mb-0 ps-3">
                            @foreach($errors->all() as $error)
                                <li>{{ $error }}</li>
                            @endforeach
                        </ul>
                        <button type="button" class="btn-close float-end" data-bs-dismiss="alert"></button>
                    </div>
                @endif

                <form method="POST" action="{{ route('register') }}">
                    @csrf

                    <div class="mb-3">
                        <label for="name" class="form-label">Nombre completo</label>
                        <div class="input-group-icon">
                            <i class="bi bi-person"></i>
                            <input
                                type="text"
                                class="form-control @error('name') is-invalid @enderror"
                                id="name"
                                name="name"
                                value="{{ old('name') }}"
                                placeholder="Tu nombre completo"
                                required
                                autofocus
                            >
                        </div>
                        @error('name')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                    </div>

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
                                placeholder="Mínimo 6 caracteres"
                                required
                            >
                            <button type="button" class="toggle-password" onclick="togglePassword('password', this)">
                                <i class="bi bi-eye"></i>
                            </button>
                        </div>
                        @error('password')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                        <p class="hint">La contraseña debe tener al menos 6 caracteres</p>
                    </div>

                    <div class="mb-4">
                        <label for="password_confirmation" class="form-label">Confirmar contraseña</label>
                        <div class="input-group-icon">
                            <i class="bi bi-lock-fill"></i>
                            <input
                                type="password"
                                class="form-control has-toggle"
                                id="password_confirmation"
                                name="password_confirmation"
                                placeholder="Repite tu contraseña"
                                required
                            >
                            <button type="button" class="toggle-password" onclick="togglePassword('password_confirmation', this)">
                                <i class="bi bi-eye"></i>
                            </button>
                        </div>
                    </div>

                    <button type="submit" class="btn-register">Crear cuenta</button>
                </form>

                <div class="divider"></div>
                <p class="footer-link">
                    ¿Ya tienes una cuenta?
                    <a href="{{ route('login') }}">Inicia sesión aquí</a>
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
