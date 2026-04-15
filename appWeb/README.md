# 🔍 Amigate - Sistema de Reportes de Objetos Perdidos

[![Laravel](https://img.shields.io/badge/Laravel-12.x-red.svg)](https://laravel.com)
[![PHP](https://img.shields.io/badge/PHP-8.2+-blue.svg)](https://www.php.net)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue.svg)](https://www.postgresql.org)
[![PostGIS](https://img.shields.io/badge/PostGIS-3.4-green.svg)](https://postgis.net)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://www.docker.com)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**Amigate** es una plataforma web desarrollada en Laravel que permite a los usuarios reportar objetos perdidos o encontrados, facilitando la conexión entre personas que han perdido algo y quienes lo han encontrado. El sistema utiliza tecnología geoespacial avanzada con PostGIS para organizar reportes por cuadrantes geográficos y grupos de usuarios, con un sistema inteligente de expansión automática de reportes.

## 📋 Tabla de Contenidos

- [Características](#-características)
- [Tecnologías Utilizadas](#-tecnologías-utilizadas)
- [Requisitos Previos](#-requisitos-previos)
- [Instalación](#-instalación)
  - [Instalación con Docker (Recomendado)](#instalación-con-docker-recomendado)
  - [Instalación Manual](#instalación-manual)
- [Configuración](#-configuración)
- [Uso](#-uso)
- [Interfaz Web](#-interfaz-web)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [API Endpoints](#-api-endpoints)
- [Base de Datos](#-base-de-datos)
- [Testing](#-testing)
- [Despliegue](#-despliegue)
- [Contribución](#-contribución)
- [Licencia](#-licencia)

## ✨ Características

### 🔐 Autenticación y Usuarios
- ✅ Sistema de registro e inicio de sesión con Laravel Sanctum
- ✅ Gestión completa de perfiles de usuario
- ✅ Sistema de puntos de ayuda para incentivar la colaboración
- ✅ Configuración personalizada de notificaciones por usuario
- ✅ Sistema de roles y permisos con Spatie (Cliente, Moderador, Admin)
- ✅ Gestión de ubicación actual del usuario en tiempo real

### 📍 Sistema Geoespacial Avanzado
- ✅ **Cuadrantes Geográficos**: División del territorio en cuadrantes para organización eficiente
- ✅ **Detección Automática**: Identificación automática del cuadrante según ubicación GPS
- ✅ **Cuadrantes Cercanos**: Búsqueda de hasta 25 cuadrantes próximos a una ubicación
- ✅ **Cuadrantes Adyacentes**: Obtención de los 8 cuadrantes vecinos (norte, sur, este, oeste, diagonales)
- ✅ **Integración PostGIS**: Cálculos geoespaciales avanzados y consultas optimizadas
- ✅ **Barrios por Cuadrante**: Asociación de barrios específicos a cada cuadrante

### 👥 Sistema de Grupos Inteligente
- ✅ Creación y gestión de grupos de usuarios
- ✅ **Unión Automática**: Los usuarios se unen automáticamente a grupos según su ubicación
- ✅ **Cambio Automático**: El sistema detecta cuando un usuario se desplaza y lo cambia de grupo automáticamente
- ✅ Gestión de miembros de grupo con roles (admin, miembro)
- ✅ Notificaciones activas por grupo
- ✅ Búsqueda de grupos por múltiples cuadrantes

### 📝 Sistema de Reportes Completo
- ✅ Creación de reportes de objetos **perdidos** o **encontrados**
- ✅ Categorización de reportes (mascotas, documentos, electrónicos, etc.)
- ✅ Subida múltiple de imágenes y videos
- ✅ Características detalladas de los objetos (color, tamaño, marca, etc.)
- ✅ Sistema de recompensas monetarias
- ✅ **Expansión Automática Inteligente**: Los reportes se expanden automáticamente a cuadrantes adyacentes después de un tiempo configurado
- ✅ Control de niveles de expansión (hasta 3 niveles por defecto)
- ✅ Marcado de reportes como resueltos
- ✅ Sistema de prioridades (baja, normal, alta, urgente)
- ✅ Contador de vistas
- ✅ Fechas de pérdida y reporte

### 💬 Sistema de Respuestas
- ✅ Los usuarios pueden responder a reportes indicando si encontraron el objeto
- ✅ Sistema de validación (marcar respuestas como correctas o erróneas)
- ✅ Gestión de imágenes y videos en respuestas
- ✅ Filtrado de respuestas tipo "encontrado"
- ✅ Eliminación de respuestas

### 🔔 Sistema de Notificaciones
- ✅ Sistema completo de notificaciones en tiempo real
- ✅ Notificaciones no leídas con contador
- ✅ Configuración personalizada por usuario
- ✅ Notificaciones automáticas por expansión de reportes
- ✅ Marcar todas como leídas
- ✅ Eliminación individual o masiva

### 🎨 Panel de Administración Web
- ✅ Dashboard administrativo completo con estadísticas en tiempo real
- ✅ Gestión completa de usuarios, reportes, cuadrantes y grupos
- ✅ Interfaz web responsive con Tailwind CSS
- ✅ Sistema de autenticación web (login/registro)
- ✅ Exportación de reportes a PDF y Excel
- ✅ Estadísticas y reportes detallados
- ✅ Gestión de roles y permisos desde la interfaz
- ✅ Configuración del sistema desde el panel
- ✅ Visualización de notificaciones y respuestas

### 🚀 Características Técnicas
- ✅ API RESTful completa y documentada
- ✅ Autenticación con tokens (Sanctum)
- ✅ Validación de datos robusta
- ✅ Manejo de errores centralizado
- ✅ Logging detallado
- ✅ Optimización de consultas con índices geoespaciales
- ✅ Soporte para UUIDs en todas las tablas
- ✅ Timestamps con timezone

## 🛠️ Tecnologías Utilizadas

### Backend
- **Laravel 12.x** - Framework PHP moderno y robusto
- **PHP 8.2+** - Lenguaje de programación
- **PostgreSQL 16** - Base de datos relacional de alto rendimiento
- **PostGIS 3.4** - Extensión geoespacial para PostgreSQL
- **Laravel Sanctum** - Autenticación API con tokens
- **Spatie Laravel Permission** - Gestión avanzada de roles y permisos
- **Laravel DomPDF** - Generación de PDFs para reportes
- **Doctrine DBAL** - Abstracción de base de datos

### Frontend
- **Vite 7.x** - Build tool y bundler ultra-rápido
- **Tailwind CSS 4.0** - Framework CSS utility-first
- **Axios** - Cliente HTTP para peticiones API
- **Blade Templates** - Motor de plantillas de Laravel
- **JavaScript ES6+** - Lenguaje de programación

### DevOps y Herramientas
- **Docker** - Contenedorización de la aplicación
- **Docker Compose** - Orquestación de contenedores
- **Nginx** - Servidor web de alto rendimiento
- **PHP-FPM** - Procesador PHP para Nginx
- **Composer** - Gestor de dependencias PHP
- **NPM** - Gestor de paquetes Node.js

### APIs Externas (Opcionales)
- **OpenWeather API** - Datos meteorológicos
- **FIRMS API** - Información de incendios forestales

## 📦 Requisitos Previos

### Para Instalación con Docker (Recomendado)
- **Docker** 20.10 o superior
- **Docker Compose** 2.0 o superior
- **Git** para clonar el repositorio

### Para Instalación Manual
- **PHP** 8.2 o superior con las siguientes extensiones:
  - `pdo_pgsql`
  - `zip`
  - `mbstring`
  - `xml`
  - `gd` o `imagick`
  - `curl`
  - `fileinfo`
- **Composer** 2.0 o superior
- **PostgreSQL** 16+ con extensión **PostGIS 3.4+**
- **Node.js** 18+ y **npm**
- **Nginx** o **Apache** con mod_rewrite habilitado

## 🚀 Instalación

### Instalación con Docker (Recomendado)

Esta es la forma más rápida y sencilla de poner en marcha el proyecto.

#### 1. Clonar el repositorio

```bash
git clone https://github.com/tu-usuario/amigate-web-app.git
cd amigate-web-app
```

#### 2. Configurar variables de entorno

```bash
cp .env.example .env
```

Edita el archivo `.env` y configura las siguientes variables:

```env
# Base de datos
DB_CONNECTION=pgsql
DB_HOST=db
DB_PORT=5432
DB_DATABASE=amigate
DB_USERNAME=postgres
DB_PASSWORD=admin

# Aplicación
APP_NAME=Amigate
APP_ENV=local
APP_DEBUG=true
APP_URL=http://localhost:8080

# APIs Externas (opcionales)
OPENWEATHER_API_KEY=tu_api_key
FIRMS_API_KEY=tu_api_key

# Sanctum
SANCTUM_STATEFUL_DOMAINS=localhost:8080
```

#### 3. Construir y levantar los contenedores

```bash
docker-compose up -d --build
```

Este comando:
- Construye las imágenes Docker necesarias
- Levanta los contenedores (Laravel, Nginx, PostgreSQL)
- Ejecuta automáticamente las migraciones y seeders
- Configura los permisos necesarios

#### 4. Acceder a la aplicación

- **Aplicación web**: http://localhost:8080
- **Base de datos PostgreSQL**: localhost:5434
  - Usuario: `postgres`
  - Contraseña: `admin`
  - Base de datos: `amigate`

#### 5. Verificar la instalación

```bash
# Ver logs de los contenedores
docker-compose logs -f

# Verificar que los contenedores estén corriendo
docker-compose ps

# Acceder al contenedor de Laravel
docker-compose exec laravel bash
```

### Instalación Manual

Si prefieres instalar sin Docker, sigue estos pasos:

#### 1. Clonar el repositorio

```bash
git clone https://github.com/tu-usuario/amigate-web-app.git
cd amigate-web-app
```

#### 2. Instalar dependencias de PHP

```bash
composer install
```

#### 3. Instalar dependencias de Node.js

```bash
npm install
```

#### 4. Configurar el archivo .env

```bash
cp .env.example .env
php artisan key:generate
```

Edita el archivo `.env` con tus credenciales de base de datos y configuración.

#### 5. Configurar PostgreSQL con PostGIS

```sql
-- Conectarse a PostgreSQL
psql -U postgres

-- Crear base de datos
CREATE DATABASE amigate;

-- Conectarse a la base de datos
\c amigate

-- Habilitar extensión PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;
```

#### 6. Ejecutar migraciones y seeders

```bash
php artisan migrate
php artisan db:seed
```

#### 7. Crear enlace simbólico de storage

```bash
php artisan storage:link
```

#### 8. Compilar assets

```bash
# Para desarrollo
npm run dev

# Para producción
npm run build
```

#### 9. Configurar permisos

```bash
chmod -R 775 storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache
```

#### 10. Iniciar el servidor de desarrollo

```bash
php artisan serve
```

La aplicación estará disponible en: http://localhost:8000

## ⚙️ Configuración

### Variables de Entorno Importantes

```env
# ============================================
# CONFIGURACIÓN DE LA APLICACIÓN
# ============================================
APP_NAME=Amigate
APP_ENV=local
APP_KEY=base64:...  # Generado automáticamente con php artisan key:generate
APP_DEBUG=true
APP_URL=http://localhost:8080

# ============================================
# BASE DE DATOS
# ============================================
DB_CONNECTION=pgsql
DB_HOST=127.0.0.1  # o 'db' si usas Docker
DB_PORT=5432
DB_DATABASE=amigate
DB_USERNAME=postgres
DB_PASSWORD=tu_password_segura

# ============================================
# APIS EXTERNAS (Opcionales)
# ============================================
OPENWEATHER_API_KEY=tu_api_key_aqui
FIRMS_API_KEY=tu_api_key_aqui

# ============================================
# LARAVEL SANCTUM
# ============================================
SANCTUM_STATEFUL_DOMAINS=localhost:8080,localhost:8000

# ============================================
# CACHE Y SESIONES
# ============================================
CACHE_DRIVER=file
SESSION_DRIVER=file
SESSION_LIFETIME=120

# ============================================
# COLAS (Opcional, para producción)
# ============================================
QUEUE_CONNECTION=sync  # o 'database', 'redis', etc.
```

### Configuración de PostGIS

Asegúrate de que PostgreSQL tenga la extensión PostGIS habilitada. Si usas Docker, esto se hace automáticamente. Para instalación manual:

```sql
-- Conectarse a la base de datos
\c amigate

-- Verificar que PostGIS esté instalado
SELECT PostGIS_version();

-- Si no está instalado:
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;
```

### Configuración de Expansión Automática

El sistema permite configurar el tiempo y niveles de expansión de reportes. Estos valores se almacenan en la tabla `configuracion_sistema`:

- `tiempo_expansion_horas`: Horas antes de expandir (default: 24)
- `tiempo_expansion_minutos`: Minutos adicionales (default: 0)
- `max_nivel_expansion`: Nivel máximo de expansión (default: 2)

Puedes modificar estos valores desde el panel de administración o directamente en la base de datos.

## 📖 Uso

### Scripts Disponibles

#### Composer Scripts

```bash
# Configuración inicial completa (instala dependencias, migra BD, compila assets)
composer setup

# Desarrollo completo (servidor, queue, logs, vite en paralelo)
composer dev

# Ejecutar tests
composer test
```

#### NPM Scripts

```bash
# Desarrollo con hot reload (Vite)
npm run dev

# Compilar para producción
npm run build
```

#### Artisan Commands

```bash
# Limpiar cachés
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan optimize:clear  # Limpia todos los cachés

# Optimizar aplicación
php artisan optimize
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Crear enlace simbólico de storage
php artisan storage:link

# Verificar expansiones automáticas (ejecutar periódicamente)
php artisan tinker
>>> App\Services\ExpansionService::verificarYExpandirReportes();
```

### Uso de la API

#### Autenticación

La API utiliza Laravel Sanctum para autenticación. Primero necesitas registrarte o iniciar sesión:

```bash
# Registro
POST /api/auth/register
{
  "nombre": "Juan Pérez",
  "email": "juan@example.com",
  "telefono": "+1234567890",
  "contrasena": "password123",
  "ubicacion_actual_lat": 40.7128,
  "ubicacion_actual_lng": -74.0060
}

# Login
POST /api/auth/login
{
  "email": "juan@example.com",
  "contrasena": "password123"
}
```

El login devuelve un token que debes incluir en las siguientes peticiones:

```
Authorization: Bearer {token}
```

#### Ejemplo: Crear un Reporte

```bash
POST /api/reportes
Authorization: Bearer {token}
Content-Type: multipart/form-data

{
  "categoria_id": "uuid-de-categoria",
  "tipo_reporte": "perdido",
  "titulo": "Perro perdido en el parque",
  "descripcion": "Perro labrador amarillo, collar rojo",
  "ubicacion_exacta_lat": 40.7128,
  "ubicacion_exacta_lng": -74.0060,
  "direccion_referencia": "Parque Central, cerca del lago",
  "fecha_perdida": "2024-01-15 10:00:00",
  "recompensa": 100.00,
  "imagenes[]": [archivo1.jpg, archivo2.jpg]
}
```

### Colección de Postman

Se incluye una colección completa de Postman (`Amigate_Postman_Collection.json`) con todos los endpoints documentados. Importa esta colección en Postman para facilitar las pruebas de la API.

## 🌐 Interfaz Web

Amigate incluye una interfaz web completa para administración y gestión del sistema. La interfaz está construida con Blade Templates y Tailwind CSS, proporcionando una experiencia de usuario moderna y responsive.

### Autenticación Web

- **Login**: `/login` - Inicio de sesión para usuarios registrados
- **Registro**: `/register` - Registro de nuevos usuarios
- **Logout**: Cierre de sesión seguro

### Dashboard

- **Ruta**: `/dashboard`
- **Acceso**: Requiere autenticación
- **Funcionalidades**:
  - Estadísticas generales (total reportes, usuarios, reportes activos/resueltos)
  - Reportes por tipo (perdidos/encontrados)
  - Reportes por prioridad (baja, normal, alta, urgente)
  - Reportes del día
  - Zona crítica (cuadrante con más reportes activos)
  - Últimos 10 reportes
  - Nuevos usuarios (últimos 5)
  - Categorías más populares

### Gestión de Usuarios

- **Ruta base**: `/usuarios`
- **Acceso**: Requiere autenticación
- **Rutas disponibles**:
  - `GET /usuarios` - Listar todos los usuarios
  - `GET /usuarios/create` - Formulario de creación
  - `POST /usuarios` - Crear nuevo usuario
  - `GET /usuarios/{id}` - Ver detalles del usuario
  - `GET /usuarios/{id}/edit` - Formulario de edición
  - `PUT /usuarios/{id}` - Actualizar usuario
  - `DELETE /usuarios/{id}` - Eliminar usuario

### Gestión de Reportes

- **Ruta base**: `/reportes`
- **Acceso**: Requiere rol `administrador`, `editor` o permisos `crear reportes`/`editar reportes`
- **Rutas disponibles**:
  - `GET /reportes` - Listar reportes (con filtros de búsqueda, estado, tipo)
  - `GET /reportes/create` - Formulario de creación
  - `POST /reportes` - Crear nuevo reporte
  - `GET /reportes/{id}` - Ver detalles del reporte
  - `GET /reportes/{id}/edit` - Formulario de edición
  - `PUT /reportes/{id}` - Actualizar reporte
  - `DELETE /reportes/{id}` - Eliminar reporte

### Reportes Estadísticos

- **Ruta base**: `/reportes-estadisticos`
- **Acceso**: Requiere rol `administrador` o `editor`
- **Rutas disponibles**:
  - `GET /reportes-estadisticos` - Dashboard de estadísticas
  - `GET /reportes-estadisticos/eficacia` - Eficacia por cuadrante
  - `GET /reportes-estadisticos/usuarios` - Top usuarios colaboradores
  - `GET /reportes-estadisticos/tendencias` - Tendencias temporales
  - `GET /reportes-estadisticos/exportar/pdf/{reporte}` - Exportar a PDF
  - `GET /reportes-estadisticos/exportar/excel/{reporte}` - Exportar a Excel

### Gestión de Categorías

- **Ruta base**: `/categorias`
- **Acceso**: Requiere rol `administrador`, `editor` o permisos `crear categorias`/`editar categorias`
- **Rutas disponibles**:
  - `GET /categorias` - Listar categorías
  - `GET /categorias/create` - Formulario de creación
  - `POST /categorias` - Crear categoría
  - `GET /categorias/{id}` - Ver categoría
  - `GET /categorias/{id}/edit` - Formulario de edición
  - `PUT /categorias/{id}` - Actualizar categoría
  - `DELETE /categorias/{id}` - Eliminar categoría

### Gestión de Cuadrantes

- **Ruta base**: `/cuadrantes`
- **Acceso**: Requiere rol `administrador` o `editor`
- **Rutas disponibles**:
  - `GET /cuadrantes` - Listar y gestionar cuadrantes
  - `POST /cuadrantes` - Crear nuevo cuadrante

### Gestión de Grupos

- **Ruta base**: `/grupos`
- **Acceso**: Requiere autenticación
- **Rutas disponibles**:
  - `GET /grupos` - Listar grupos
  - `GET /grupos/{id}` - Ver detalles del grupo
  - `POST /grupos` - Crear grupo
  - `POST /grupos/{id}/join` - Unirse a un grupo
  - `POST /grupos/{id}/leave` - Salir de un grupo

### Gestión de Respuestas

- **Ruta base**: `/respuestas`
- **Acceso**: Requiere autenticación
- **Rutas disponibles**:
  - `GET /respuestas` - Listar todas las respuestas (con relaciones a reportes y usuarios)

### Gestión de Notificaciones

- **Ruta base**: `/notificaciones`
- **Acceso**: Requiere autenticación
- **Rutas disponibles**:
  - `GET /notificaciones` - Listar notificaciones (paginadas, 50 por página)

### Configuración del Sistema

- **Ruta base**: `/configuracion`
- **Acceso**: Requiere rol `administrador`
- **Rutas disponibles**:
  - `GET /configuracion` - Ver configuración actual
  - `GET /configuracion/editar` - Formulario de edición
  - `PUT /configuracion` - Actualizar configuración
  - Permite configurar tiempos de expansión, niveles máximos, etc.

### Gestión de Roles y Permisos

- **Ruta base**: `/users/roles`
- **Acceso**: Requiere rol `administrador`
- **Rutas disponibles**:
  - `GET /users/roles` - Listar usuarios y sus roles
  - `GET /users/roles/{id}/edit` - Editar roles de usuario
  - `PUT /users/roles/{id}` - Actualizar roles
  - `POST /users/roles/{id}/assign` - Asignar rol a usuario
  - `DELETE /users/roles/{id}/remove` - Remover rol de usuario

### Características de la Interfaz Web

- ✅ **Diseño Responsive**: Adaptable a dispositivos móviles, tablets y desktop
- ✅ **Tailwind CSS**: Framework CSS moderno para estilos consistentes
- ✅ **Blade Templates**: Motor de plantillas de Laravel
- ✅ **Autenticación Segura**: Sistema de login/registro con validación
- ✅ **Control de Acceso**: Middleware de roles y permisos
- ✅ **Búsqueda y Filtros**: Búsqueda avanzada en listados
- ✅ **Paginación**: Listados paginados para mejor rendimiento
- ✅ **Exportación**: Exportación de datos a PDF y Excel
- ✅ **Dashboard Interactivo**: Estadísticas en tiempo real
- ✅ **Gestión Completa**: CRUD completo para todas las entidades

### Roles y Permisos en la Web

El sistema utiliza Spatie Laravel Permission para gestionar roles y permisos:

- **Administrador**: Acceso completo a todas las funcionalidades
- **Editor**: Puede crear y editar reportes y categorías
- **Cliente**: Acceso básico para ver y crear reportes

Los permisos específicos incluyen:
- `crear reportes`
- `editar reportes`
- `crear categorias`
- `editar categorias`

## 📁 Estructura del Proyecto

```
amigate-web-app/
├── app/
│   ├── Console/
│   │   └── Commands/          # Comandos Artisan personalizados
│   ├── Exports/
│   │   └── ReporteExport.php  # Exportadores (PDF, Excel)
│   ├── Http/
│   │   ├── Controllers/
│   │   │   ├── Api/           # Controladores de la API REST
│   │   │   │   ├── AuthController.php
│   │   │   │   ├── CategoriaController.php
│   │   │   │   ├── CuadranteController.php
│   │   │   │   ├── GrupoController.php
│   │   │   │   ├── NotificacionController.php
│   │   │   │   ├── ReporteController.php
│   │   │   │   └── RespuestaController.php
│   │   │   ├── Web/           # Controladores para vistas web
│   │   │   │   ├── DashboardController.php
│   │   │   │   ├── UsuarioWebController.php
│   │   │   │   ├── ReporteWebController.php
│   │   │   │   ├── CategoriaWebController.php
│   │   │   │   ├── CuadranteWebController.php
│   │   │   │   ├── ConfiguracionWebController.php
│   │   │   │   └── UserRoleController.php
│   │   │   ├── Auth/          # Controladores de autenticación
│   │   │   │   ├── LoginController.php
│   │   │   │   └── RegisterController.php
│   │   │   └── ReporteEstadisticoController.php
│   │   └── Middleware/        # Middleware personalizado
│   ├── Listeners/
│   │   └── ModifySpatieQueriesListener.php
│   ├── Models/                # Modelos Eloquent
│   │   ├── Usuario.php
│   │   ├── Reporte.php
│   │   ├── Respuesta.php
│   │   ├── Cuadrante.php
│   │   ├── Grupo.php
│   │   ├── Categoria.php
│   │   ├── Notificacion.php
│   │   └── ...
│   ├── Providers/
│   │   ├── AppServiceProvider.php
│   │   └── PermissionServiceProvider.php
│   ├── Services/
│   │   └── ExpansionService.php  # Servicio de expansión automática
│   └── Traits/
│       └── ConvertsIdToStringForSpatie.php
├── bootstrap/
│   ├── app.php
│   └── cache/                 # Caché de bootstrap
├── config/                     # Archivos de configuración
│   ├── app.php
│   ├── database.php
│   ├── permission.php
│   └── ...
├── database/
│   ├── factories/             # Factories para testing
│   ├── migrations/            # Migraciones de base de datos
│   └── seeders/               # Seeders de datos iniciales
│       ├── DatabaseSeeder.php
│       ├── AdminUserSeeder.php
│       └── RolePermissionSeeder.php
├── public/                     # Punto de entrada público
│   ├── index.php
│   └── storage/               # Enlace simbólico a storage/app/public
├── resources/
│   ├── css/
│   │   └── app.css            # Estilos CSS
│   ├── js/
│   │   ├── app.js
│   │   └── bootstrap.js
│   └── views/                 # Vistas Blade
│       ├── layouts/
│       │   └── app.blade.php  # Layout principal
│       ├── auth/              # Vistas de autenticación
│       │   ├── login.blade.php
│       │   └── register.blade.php
│       ├── dashboard.blade.php
│       ├── usuarios/          # Gestión de usuarios
│       ├── reportes/          # Gestión de reportes
│       ├── categorias/        # Gestión de categorías
│       ├── cuadrantes/        # Gestión de cuadrantes
│       ├── grupos/            # Gestión de grupos
│       ├── respuestas/        # Gestión de respuestas
│       ├── notificaciones/    # Gestión de notificaciones
│       ├── configuracion/     # Configuración del sistema
│       └── users/             # Gestión de roles
├── routes/
│   ├── api.php                # Rutas de la API
│   └── web.php                # Rutas web
├── storage/
│   ├── app/
│   │   ├── private/           # Archivos privados
│   │   └── public/            # Archivos públicos (imágenes, videos)
│   ├── framework/             # Caché de framework
│   └── logs/                  # Logs de la aplicación
├── tests/                     # Tests automatizados
│   ├── Feature/
│   └── Unit/
├── docker-compose.yml         # Configuración Docker Compose
├── Dockerfile                 # Imagen Docker de Laravel
├── entrypoint.sh              # Script de inicialización Docker
├── nginx.conf                 # Configuración Nginx
├── composer.json              # Dependencias PHP
├── package.json               # Dependencias Node.js
├── vite.config.js             # Configuración Vite
└── README.md                  # Este archivo
```

## 🔌 API Endpoints

### Autenticación

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `POST` | `/api/auth/register` | Registro de nuevo usuario |
| `POST` | `/api/auth/login` | Inicio de sesión |
| `GET` | `/api/auth/perfil/{usuarioId}` | Obtener perfil de usuario |
| `PUT` | `/api/auth/perfil/{usuarioId}` | Actualizar perfil |
| `PUT` | `/api/auth/ubicacion/{usuarioId}` | Actualizar ubicación del usuario |
| `PUT` | `/api/auth/notificaciones/{usuarioId}` | Actualizar configuración de notificaciones |

### Categorías

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/categorias` | Listar todas las categorías |
| `GET` | `/api/categorias/{id}` | Obtener categoría específica |

### Cuadrantes

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/cuadrantes` | Listar todos los cuadrantes |
| `GET` | `/api/cuadrantes/{id}` | Obtener cuadrante específico |
| `POST` | `/api/cuadrantes` | Crear nuevo cuadrante |
| `POST` | `/api/cuadrantes/detectar` | Detectar cuadrante por ubicación GPS |
| `POST` | `/api/cuadrantes/cercanos` | Obtener 25 cuadrantes cercanos a una ubicación |
| `GET` | `/api/cuadrantes/{cuadranteId}/adyacentes` | Obtener 8 cuadrantes adyacentes |
| `POST` | `/api/cuadrantes/{cuadranteId}/barrios` | Agregar barrio a cuadrante |

### Grupos

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/grupos` | Listar todos los grupos |
| `GET` | `/api/grupos/{id}` | Obtener grupo específico |
| `POST` | `/api/grupos` | Crear nuevo grupo |
| `GET` | `/api/grupos/usuario/{usuarioId}` | Obtener grupos del usuario |
| `GET` | `/api/grupos/{grupoId}/miembros` | Obtener miembros de un grupo |
| `POST` | `/api/grupos/unir-automatico` | Unir usuario a grupo automáticamente |
| `POST` | `/api/grupos/verificar-cambio-grupo` | Verificar y cambiar grupo según ubicación |
| `POST` | `/api/grupos/por-cuadrantes` | Obtener grupos por múltiples cuadrantes |
| `POST` | `/api/grupos/salir` | Salir de un grupo |

### Reportes

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/reportes/{id}` | Obtener reporte específico |
| `POST` | `/api/reportes` | Crear nuevo reporte |
| `GET` | `/api/reportes/usuario/{usuarioId}` | Obtener reportes del usuario |
| `GET` | `/api/reportes/grupo/{grupoId}` | Obtener reportes de un grupo |
| `POST` | `/api/reportes/{reporteId}/expandir` | Expandir reporte manualmente |
| `POST` | `/api/reportes/{reporteId}/expandir-inmediato` | Expandir reporte inmediatamente (testing) |
| `PUT` | `/api/reportes/{reporteId}/resuelto` | Marcar reporte como resuelto |
| `POST` | `/api/reportes/verificar-expansiones` | Verificar y ejecutar expansiones automáticas |

### Respuestas

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/respuestas/{id}` | Obtener respuesta específica |
| `POST` | `/api/respuestas` | Crear nueva respuesta |
| `GET` | `/api/respuestas/reporte/{reporteId}` | Obtener todas las respuestas de un reporte |
| `GET` | `/api/respuestas/reporte/{reporteId}/encontrado` | Obtener solo respuestas tipo "encontrado" |
| `PUT` | `/api/respuestas/{respuestaId}/bien` | Marcar respuesta como correcta |
| `PUT` | `/api/respuestas/{respuestaId}/erroneo` | Marcar respuesta como errónea |
| `DELETE` | `/api/respuestas/{id}` | Eliminar respuesta |

### Notificaciones

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/notificaciones/usuario/{usuarioId}` | Obtener todas las notificaciones del usuario |
| `GET` | `/api/notificaciones/usuario/{usuarioId}/no-leidas` | Obtener notificaciones no leídas |
| `PUT` | `/api/notificaciones/{notificacionId}/leida` | Marcar notificación como leída |
| `PUT` | `/api/notificaciones/usuario/{usuarioId}/marcar-todas-leidas` | Marcar todas como leídas |
| `DELETE` | `/api/notificaciones/{notificacionId}` | Eliminar notificación |
| `DELETE` | `/api/notificaciones/usuario/{usuarioId}/eliminar-todas` | Eliminar todas las notificaciones |

### Utilidades

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/ping` | Verificar estado de la API |

> 📦 **Colección de Postman**: Se incluye `Amigate_Postman_Collection.json` con todos los endpoints documentados y ejemplos de peticiones para facilitar las pruebas.

## 🗄️ Base de Datos

### Modelos Principales

- **Usuario** - Usuarios del sistema con autenticación y roles
- **Reporte** - Reportes de objetos perdidos/encontrados
- **Respuesta** - Respuestas de usuarios a reportes
- **Cuadrante** - Cuadrantes geográficos del territorio
- **CuadranteBarrio** - Barrios asociados a cuadrantes
- **Grupo** - Grupos de usuarios por ubicación
- **GrupoMiembro** - Relación muchos-a-muchos usuarios-grupos
- **Categoria** - Categorías de reportes
- **Notificacion** - Notificaciones del sistema
- **NotificacionDato** - Datos adicionales de notificaciones
- **ExpansionReporte** - Historial de expansiones de reportes
- **ConfiguracionSistema** - Configuración global del sistema
- **ConfiguracionNotificacionesUsuario** - Configuración de notificaciones por usuario

### Características de la Base de Datos

- ✅ **UUIDs** como identificadores primarios en todas las tablas
- ✅ **PostGIS** para datos geoespaciales (puntos, polígonos, cálculos de distancia)
- ✅ **Timestamps con timezone** (timestampsTz) para fechas precisas
- ✅ **Índices optimizados** para consultas geoespaciales y búsquedas
- ✅ **Constraints** para integridad referencial
- ✅ **Soft deletes** en tablas críticas (opcional)
- ✅ **Relaciones Eloquent** bien definidas

### Esquema de Relaciones

```
Usuario
  ├── hasMany Reporte
  ├── hasMany Respuesta
  ├── belongsToMany Grupo (a través de GrupoMiembro)
  ├── hasMany Notificacion
  └── hasOne ConfiguracionNotificacionesUsuario

Reporte
  ├── belongsTo Usuario
  ├── belongsTo Categoria
  ├── belongsTo Cuadrante
  ├── hasMany Respuesta
  ├── hasMany ExpansionReporte
  ├── hasMany ReporteImagen
  ├── hasMany ReporteVideo
  └── hasMany ReporteCaracteristica

Cuadrante
  ├── hasMany Reporte
  ├── hasMany CuadranteBarrio
  └── hasMany ExpansionReporte (como cuadrante_expandido_id)

Grupo
  ├── belongsToMany Usuario (a través de GrupoMiembro)
  └── hasMany GrupoMiembro
```

## 🧪 Testing

El proyecto incluye tests automatizados con PHPUnit:

```bash
# Ejecutar todos los tests
php artisan test

# Ejecutar tests con cobertura de código
php artisan test --coverage

# Ejecutar tests específicos
php artisan test --filter NombreDelTest

# Ejecutar solo tests de Feature
php artisan test --testsuite=Feature

# Ejecutar solo tests Unit
php artisan test --testsuite=Unit
```

### Estructura de Tests

```
tests/
├── Feature/          # Tests de integración (API, controladores)
│   └── ExampleTest.php
└── Unit/             # Tests unitarios (modelos, servicios)
    └── ExampleTest.php
```

## 🚢 Despliegue

### Producción con Docker

1. **Configurar variables de entorno de producción**

```bash
APP_ENV=production
APP_DEBUG=false
APP_URL=https://tu-dominio.com
```

2. **Construir imágenes optimizadas**

```bash
docker-compose -f docker-compose.prod.yml build --no-cache
```

3. **Levantar servicios**

```bash
docker-compose -f docker-compose.prod.yml up -d
```

### Consideraciones de Producción

- ✅ Configurar **HTTPS** con certificados SSL válidos
- ✅ Usar variables de entorno seguras (nunca commitear `.env`)
- ✅ Configurar **backups automáticos** de la base de datos
- ✅ Configurar **colas de trabajos** (queues) para tareas asíncronas
- ✅ Optimizar assets: `npm run build`
- ✅ Optimizar Laravel: `php artisan optimize`
- ✅ Configurar **rate limiting** en la API
- ✅ Habilitar **caché** de configuración, rutas y vistas
- ✅ Configurar **monitoreo** y logging centralizado
- ✅ Usar **CDN** para assets estáticos
- ✅ Configurar **caché de consultas** (Redis/Memcached)

### Comandos de Optimización

```bash
# Optimizar para producción
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan optimize

# Compilar assets
npm run build

# Limpiar cachés de desarrollo
php artisan optimize:clear
```

## 🤝 Contribución

Las contribuciones son bienvenidas. Por favor sigue estos pasos:

1. **Fork** el proyecto
2. Crea una **rama** para tu feature (`git checkout -b feature/AmazingFeature`)
3. **Commit** tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. **Push** a la rama (`git push origin feature/AmazingFeature`)
5. Abre un **Pull Request**

### Estándares de Código

- ✅ Seguir las **convenciones de Laravel** (PSR-12)
- ✅ Escribir **tests** para nuevas funcionalidades
- ✅ **Documentar** código complejo con comentarios
- ✅ Usar **Laravel Pint** o PHP CS Fixer para formateo
- ✅ Mantener **coherencia** en el estilo de código
- ✅ Actualizar **documentación** cuando sea necesario

### Proceso de Revisión

- Los PRs serán revisados por el equipo
- Se pueden solicitar cambios antes de mergear
- Los tests deben pasar antes de mergear
- El código debe seguir los estándares del proyecto

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## 👥 Autores

- **Tu Nombre** - *Desarrollo inicial* - [TuGitHub](https://github.com/tu-usuario)

## 🙏 Agradecimientos

- **Laravel Framework** - Por el excelente framework PHP
- **Comunidad de Laravel** - Por el apoyo y recursos
- **Spatie** - Por el paquete de permisos
- **PostGIS Team** - Por la extensión geoespacial
- Todos los **contribuidores** de las librerías utilizadas

## 📞 Soporte

Si tienes preguntas o necesitas ayuda:

- 📧 Abre un [Issue](https://github.com/tu-usuario/amigate-web-app/issues) en GitHub
- 📖 Revisa la [documentación de la API](#-api-endpoints)
- 💬 Contacta al equipo de desarrollo

## 🔗 Enlaces Útiles

- [Documentación de Laravel](https://laravel.com/docs)
- [Documentación de PostGIS](https://postgis.net/documentation/)
- [Documentación de Spatie Permissions](https://spatie.be/docs/laravel-permission)
- [Documentación de Laravel Sanctum](https://laravel.com/docs/sanctum)

---

⭐ **Si este proyecto te resulta útil, ¡no olvides darle una estrella en GitHub!**

---

**Desarrollado con ❤️ usando Laravel y PostGIS**
