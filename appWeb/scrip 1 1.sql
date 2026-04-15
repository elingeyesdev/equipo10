
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS usuarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    telefono VARCHAR(20),
    avatar_url TEXT,
    puntos_ayuda INTEGER DEFAULT 0,
    fecha_registro TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    activo BOOLEAN DEFAULT TRUE,
    ubicacion_actual_lat DECIMAL(10,8),
    ubicacion_actual_lng DECIMAL(11,8),
    rol VARCHAR(20) DEFAULT 'cliente' CHECK (rol IN ('cliente', 'moderador', 'admin')),
    contrasena TEXT NOT NULL DEFAULT ''::text,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


CREATE TABLE IF NOT EXISTS configuracion_notificaciones_usuario (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL UNIQUE REFERENCES usuarios(id) ON DELETE CASCADE,
    push_activo BOOLEAN DEFAULT TRUE,
    email_activo BOOLEAN DEFAULT TRUE,
    sms_activo BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS cuadrantes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    codigo VARCHAR(20) UNIQUE NOT NULL,
    fila VARCHAR(5) NOT NULL,
    columna INTEGER NOT NULL,
    nombre VARCHAR(100),
    lat_min DECIMAL(10, 8) NOT NULL,
    lat_max DECIMAL(10, 8) NOT NULL,
    lng_min DECIMAL(11, 8) NOT NULL,
    lng_max DECIMAL(11, 8) NOT NULL,
    centro_lat DECIMAL(10,8),
    centro_lng DECIMAL(11,8),
    ciudad VARCHAR(100) NOT NULL,
    zona VARCHAR(100),
    activo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(fila, columna)
);

CREATE TABLE IF NOT EXISTS cuadrante_barrios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cuadrante_id UUID NOT NULL REFERENCES cuadrantes(id) ON DELETE CASCADE,
    nombre_barrio VARCHAR(200) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(cuadrante_id, nombre_barrio)
);


CREATE TABLE IF NOT EXISTS categorias (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre VARCHAR(100) NOT NULL UNIQUE,
    icono VARCHAR(50),
    color VARCHAR(7),
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

INSERT INTO categorias (nombre, icono, color, descripcion) VALUES
('Personas', 'person', '#FF6B6B', 'Personas perdidas o desaparecidas'),
('Mascotas', 'pets', '#4ECDC4', 'Perros, gatos y otras mascotas'),
('Documentos', 'description', '#45B7D1', 'Identificaciones, pasaportes, licencias'),
('Electrónicos', 'smartphone', '#96CEB4', 'Teléfonos, laptops, tablets, etc.'),
('Vehículos', 'directions_car', '#FFEAA7', 'Autos, motos, bicicletas'),
('Ropa/Accesorios', 'checkroom', '#DDA0DD', 'Ropa, bolsas, joyas, etc.'),
('Llaves', 'vpn_key', '#F39C12', 'Llaves de casa, auto, oficina'),
('Otros', 'category', '#95A5A6', 'Otros objetos no categorizados')
ON CONFLICT (nombre) DO NOTHING;


CREATE TABLE IF NOT EXISTS reportes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    categoria_id UUID NOT NULL REFERENCES categorias(id),
    cuadrante_id UUID NOT NULL REFERENCES cuadrantes(id),
    tipo_reporte VARCHAR(20) NOT NULL CHECK (tipo_reporte IN ('perdido', 'encontrado')),
    titulo VARCHAR(200) NOT NULL,
    descripcion TEXT NOT NULL,
    ubicacion_exacta_lat DECIMAL(10,8),
    ubicacion_exacta_lng DECIMAL(11,8),
    direccion_referencia TEXT,
    fecha_perdida TIMESTAMP WITH TIME ZONE,
    fecha_reporte TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    estado VARCHAR(20) DEFAULT 'activo' CHECK (estado IN ('activo', 'resuelto', 'inactivo', 'spam')),
    prioridad VARCHAR(20) DEFAULT 'normal' CHECK (prioridad IN ('baja', 'normal', 'alta', 'urgente')),
    nivel_expansion INTEGER DEFAULT 1,
    max_expansion INTEGER DEFAULT 3,
    proxima_expansion TIMESTAMP WITH TIME ZONE,
    contacto_publico BOOLEAN DEFAULT TRUE,
    telefono_contacto VARCHAR(20),
    email_contacto VARCHAR(255),
    recompensa DECIMAL(10,2),
    vistas INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


CREATE TABLE IF NOT EXISTS reporte_caracteristicas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporte_id UUID NOT NULL REFERENCES reportes(id) ON DELETE CASCADE,
    clave VARCHAR(100) NOT NULL,
    valor TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(reporte_id, clave)
);


CREATE TABLE IF NOT EXISTS reporte_imagenes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporte_id UUID NOT NULL REFERENCES reportes(id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    orden INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- NUEVA TABLA: reporte_videos (1FN)
CREATE TABLE IF NOT EXISTS reporte_videos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporte_id UUID NOT NULL REFERENCES reportes(id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    orden INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


CREATE TABLE IF NOT EXISTS respuestas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporte_id UUID NOT NULL REFERENCES reportes(id) ON DELETE CASCADE,
    usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    tipo_respuesta VARCHAR(20) NOT NULL CHECK (tipo_respuesta IN ('avistamiento', 'encontrado', 'informacion', 'pregunta')),
    mensaje TEXT NOT NULL,
    ubicacion_lat DECIMAL(10,8),
    ubicacion_lng DECIMAL(11,8),
    direccion_referencia TEXT,
    verificada BOOLEAN DEFAULT FALSE,
    util BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS respuesta_imagenes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    respuesta_id UUID NOT NULL REFERENCES respuestas(id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    orden INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


CREATE TABLE IF NOT EXISTS respuesta_videos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    respuesta_id UUID NOT NULL REFERENCES respuestas(id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    orden INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


CREATE TABLE IF NOT EXISTS grupos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cuadrante_id UUID NOT NULL REFERENCES cuadrantes(id),
    nombre VARCHAR(200) NOT NULL,
    descripcion TEXT,
    imagen_url TEXT,
    publico BOOLEAN DEFAULT TRUE,
    requiere_aprobacion BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS grupo_miembros (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    grupo_id UUID NOT NULL REFERENCES grupos(id) ON DELETE CASCADE,
    usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    rol VARCHAR(20) DEFAULT 'miembro' CHECK (rol IN ('miembro', 'moderador', 'admin')),
    notificaciones_activas BOOLEAN DEFAULT TRUE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(grupo_id, usuario_id)
);


CREATE TABLE IF NOT EXISTS expansiones_reporte (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporte_id UUID NOT NULL REFERENCES reportes(id) ON DELETE CASCADE,
    cuadrante_expandido_id UUID NOT NULL,
    nivel INTEGER NOT NULL,
    fecha_expansion TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(reporte_id, cuadrante_expandido_id),
    -- Nota: cuadrante_original_id se elimina porque es redundante con reportes.cuadrante_id
    -- cuadrante_expandido_id no tiene FK para evitar complejidad innecesaria
    CONSTRAINT check_cuadrante_expandido CHECK (cuadrante_expandido_id IS NOT NULL)
);


CREATE TABLE IF NOT EXISTS notificaciones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    tipo VARCHAR(50) NOT NULL,
    titulo VARCHAR(200) NOT NULL,
    mensaje TEXT NOT NULL,
    leida BOOLEAN DEFAULT FALSE,
    enviada_push BOOLEAN DEFAULT FALSE,
    enviada_email BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


CREATE TABLE IF NOT EXISTS notificacion_datos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    notificacion_id UUID NOT NULL REFERENCES notificaciones(id) ON DELETE CASCADE,
    clave VARCHAR(100) NOT NULL,
    valor TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(notificacion_id, clave)
);


CREATE TABLE IF NOT EXISTS configuracion_sistema (
    clave VARCHAR(100) PRIMARY KEY,
    valor TEXT NOT NULL,
    descripcion TEXT,
    tipo VARCHAR(20) DEFAULT 'string' CHECK (tipo IN ('string', 'number', 'boolean', 'json')),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

INSERT INTO configuracion_sistema (clave, valor, descripcion, tipo) VALUES
('tiempo_expansion_horas', '0.083', 'Horas antes de expandir a cuadrantes adyacentes', 'number'),
('max_nivel_expansion', '3', 'Máximo nivel de expansión permitido', 'number'),
('radio_cuadrante_km', '2', 'Radio en kilómetros de cada cuadrante', 'number')
ON CONFLICT (clave) DO NOTHING;



CREATE INDEX idx_reporte_caracteristicas_reporte ON reporte_caracteristicas(reporte_id);
CREATE INDEX idx_reporte_imagenes_reporte ON reporte_imagenes(reporte_id);
CREATE INDEX idx_reporte_videos_reporte ON reporte_videos(reporte_id);
CREATE INDEX idx_respuesta_imagenes_respuesta ON respuesta_imagenes(respuesta_id);
CREATE INDEX idx_respuesta_videos_respuesta ON respuesta_videos(respuesta_id);
CREATE INDEX idx_cuadrante_barrios_cuadrante ON cuadrante_barrios(cuadrante_id);
CREATE INDEX idx_notificacion_datos_notificacion ON notificacion_datos(notificacion_id);
CREATE INDEX idx_respuestas_reporte ON respuestas(reporte_id);
CREATE INDEX idx_expansiones_reporte ON expansiones_reporte(reporte_id);
