--
-- PostgreSQL database dump
--

\restrict xRrAsbLI0rSN2hzi5D24Z7AM6UpdelBKLJhyekeJnefhDBZXvLCN7ja0YEnnBri

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO postgres;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS '';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: cache; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cache (
    key character varying(255) NOT NULL,
    value text NOT NULL,
    expiration integer NOT NULL
);


ALTER TABLE public.cache OWNER TO postgres;

--
-- Name: cache_locks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cache_locks (
    key character varying(255) NOT NULL,
    owner character varying(255) NOT NULL,
    expiration integer NOT NULL
);


ALTER TABLE public.cache_locks OWNER TO postgres;

--
-- Name: categorias; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categorias (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nombre character varying(100) NOT NULL,
    icono character varying(50),
    color character varying(7),
    descripcion text,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp(0) with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.categorias OWNER TO postgres;

--
-- Name: configuracion_notificaciones_usuario; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.configuracion_notificaciones_usuario (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    push_activo boolean DEFAULT true NOT NULL,
    email_activo boolean DEFAULT true NOT NULL,
    sms_activo boolean DEFAULT false NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE public.configuracion_notificaciones_usuario OWNER TO postgres;

--
-- Name: configuracion_sistema; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.configuracion_sistema (
    clave character varying(100) NOT NULL,
    valor text NOT NULL,
    descripcion text,
    tipo character varying(20) DEFAULT 'string'::character varying NOT NULL,
    updated_at timestamp(0) with time zone DEFAULT now() NOT NULL,
    CONSTRAINT check_tipo CHECK (((tipo)::text = ANY ((ARRAY['string'::character varying, 'number'::character varying, 'boolean'::character varying, 'json'::character varying])::text[])))
);


ALTER TABLE public.configuracion_sistema OWNER TO postgres;

--
-- Name: cuadrante_barrios; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cuadrante_barrios (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    cuadrante_id uuid NOT NULL,
    nombre_barrio character varying(200) NOT NULL,
    created_at timestamp(0) with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.cuadrante_barrios OWNER TO postgres;

--
-- Name: cuadrantes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cuadrantes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    codigo character varying(20) NOT NULL,
    fila character varying(5) NOT NULL,
    columna integer NOT NULL,
    nombre character varying(100),
    lat_min numeric(10,8) NOT NULL,
    lat_max numeric(10,8) NOT NULL,
    lng_min numeric(11,8) NOT NULL,
    lng_max numeric(11,8) NOT NULL,
    centro_lat numeric(10,8),
    centro_lng numeric(11,8),
    ciudad character varying(100) NOT NULL,
    zona character varying(100),
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp(0) with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.cuadrantes OWNER TO postgres;

--
-- Name: expansiones_reporte; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.expansiones_reporte (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    reporte_id uuid NOT NULL,
    cuadrante_expandido_id uuid NOT NULL,
    nivel integer NOT NULL,
    fecha_expansion timestamp(0) with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.expansiones_reporte OWNER TO postgres;

--
-- Name: failed_jobs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.failed_jobs (
    id bigint NOT NULL,
    uuid character varying(255) NOT NULL,
    connection text NOT NULL,
    queue text NOT NULL,
    payload text NOT NULL,
    exception text NOT NULL,
    failed_at timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.failed_jobs OWNER TO postgres;

--
-- Name: failed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.failed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.failed_jobs_id_seq OWNER TO postgres;

--
-- Name: failed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.failed_jobs_id_seq OWNED BY public.failed_jobs.id;


--
-- Name: grupo_miembros; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.grupo_miembros (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    grupo_id uuid NOT NULL,
    usuario_id uuid NOT NULL,
    rol character varying(20) DEFAULT 'miembro'::character varying NOT NULL,
    notificaciones_activas boolean DEFAULT true NOT NULL,
    joined_at timestamp(0) with time zone DEFAULT now() NOT NULL,
    CONSTRAINT check_rol CHECK (((rol)::text = ANY ((ARRAY['miembro'::character varying, 'moderador'::character varying, 'admin'::character varying])::text[])))
);


ALTER TABLE public.grupo_miembros OWNER TO postgres;

--
-- Name: grupos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.grupos (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    cuadrante_id uuid NOT NULL,
    nombre character varying(200) NOT NULL,
    descripcion text,
    imagen_url text,
    publico boolean DEFAULT true NOT NULL,
    requiere_aprobacion boolean DEFAULT false NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone
);


ALTER TABLE public.grupos OWNER TO postgres;

--
-- Name: job_batches; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.job_batches (
    id character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    total_jobs integer NOT NULL,
    pending_jobs integer NOT NULL,
    failed_jobs integer NOT NULL,
    failed_job_ids text NOT NULL,
    options text,
    cancelled_at integer,
    created_at integer NOT NULL,
    finished_at integer
);


ALTER TABLE public.job_batches OWNER TO postgres;

--
-- Name: jobs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.jobs (
    id bigint NOT NULL,
    queue character varying(255) NOT NULL,
    payload text NOT NULL,
    attempts smallint NOT NULL,
    reserved_at integer,
    available_at integer NOT NULL,
    created_at integer NOT NULL
);


ALTER TABLE public.jobs OWNER TO postgres;

--
-- Name: jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.jobs_id_seq OWNER TO postgres;

--
-- Name: jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.jobs_id_seq OWNED BY public.jobs.id;


--
-- Name: migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.migrations (
    id integer NOT NULL,
    migration character varying(255) NOT NULL,
    batch integer NOT NULL
);


ALTER TABLE public.migrations OWNER TO postgres;

--
-- Name: migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.migrations_id_seq OWNER TO postgres;

--
-- Name: migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.migrations_id_seq OWNED BY public.migrations.id;


--
-- Name: model_has_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.model_has_permissions (
    permission_id bigint NOT NULL,
    model_type character varying(255) NOT NULL,
    model_id character varying(255) NOT NULL
);


ALTER TABLE public.model_has_permissions OWNER TO postgres;

--
-- Name: model_has_roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.model_has_roles (
    role_id bigint NOT NULL,
    model_type character varying(255) NOT NULL,
    model_id character varying(255) NOT NULL
);


ALTER TABLE public.model_has_roles OWNER TO postgres;

--
-- Name: notificacion_datos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notificacion_datos (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    notificacion_id uuid NOT NULL,
    clave character varying(100) NOT NULL,
    valor text NOT NULL,
    created_at timestamp(0) with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.notificacion_datos OWNER TO postgres;

--
-- Name: notificaciones; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notificaciones (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    tipo character varying(50) NOT NULL,
    titulo character varying(200) NOT NULL,
    mensaje text NOT NULL,
    leida boolean DEFAULT false NOT NULL,
    enviada_push boolean DEFAULT false NOT NULL,
    enviada_email boolean DEFAULT false NOT NULL,
    created_at timestamp(0) with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.notificaciones OWNER TO postgres;

--
-- Name: password_reset_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.password_reset_tokens (
    email character varying(255) NOT NULL,
    token character varying(255) NOT NULL,
    created_at timestamp(0) without time zone
);


ALTER TABLE public.password_reset_tokens OWNER TO postgres;

--
-- Name: permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.permissions (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    guard_name character varying(255) NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.permissions OWNER TO postgres;

--
-- Name: permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.permissions_id_seq OWNER TO postgres;

--
-- Name: permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.permissions_id_seq OWNED BY public.permissions.id;


--
-- Name: reporte_caracteristicas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reporte_caracteristicas (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    reporte_id uuid NOT NULL,
    clave character varying(100) NOT NULL,
    valor text NOT NULL,
    created_at timestamp(0) with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.reporte_caracteristicas OWNER TO postgres;

--
-- Name: reporte_imagenes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reporte_imagenes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    reporte_id uuid NOT NULL,
    url text NOT NULL,
    orden integer DEFAULT 0 NOT NULL,
    created_at timestamp(0) with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.reporte_imagenes OWNER TO postgres;

--
-- Name: reporte_videos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reporte_videos (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    reporte_id uuid NOT NULL,
    url text NOT NULL,
    orden integer DEFAULT 0 NOT NULL,
    created_at timestamp(0) with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.reporte_videos OWNER TO postgres;

--
-- Name: reportes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reportes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    categoria_id uuid NOT NULL,
    cuadrante_id uuid NOT NULL,
    tipo_reporte character varying(20) NOT NULL,
    titulo character varying(200) NOT NULL,
    descripcion text NOT NULL,
    ubicacion_exacta_lat numeric(10,8),
    ubicacion_exacta_lng numeric(11,8),
    direccion_referencia text,
    fecha_perdida timestamp(0) with time zone,
    fecha_reporte timestamp(0) with time zone DEFAULT now() NOT NULL,
    estado character varying(20) DEFAULT 'activo'::character varying NOT NULL,
    prioridad character varying(20) DEFAULT 'normal'::character varying NOT NULL,
    nivel_expansion integer DEFAULT 1 NOT NULL,
    max_expansion integer DEFAULT 3 NOT NULL,
    proxima_expansion timestamp(0) with time zone,
    contacto_publico boolean DEFAULT true NOT NULL,
    telefono_contacto character varying(20),
    email_contacto character varying(255),
    recompensa numeric(10,2),
    vistas integer DEFAULT 0 NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT check_estado CHECK (((estado)::text = ANY ((ARRAY['activo'::character varying, 'resuelto'::character varying, 'inactivo'::character varying, 'spam'::character varying])::text[]))),
    CONSTRAINT check_prioridad CHECK (((prioridad)::text = ANY ((ARRAY['baja'::character varying, 'normal'::character varying, 'alta'::character varying, 'urgente'::character varying])::text[]))),
    CONSTRAINT check_tipo_reporte CHECK (((tipo_reporte)::text = ANY ((ARRAY['perdido'::character varying, 'encontrado'::character varying])::text[])))
);


ALTER TABLE public.reportes OWNER TO postgres;

--
-- Name: respuesta_imagenes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.respuesta_imagenes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    respuesta_id uuid NOT NULL,
    url text NOT NULL,
    orden integer DEFAULT 0 NOT NULL,
    created_at timestamp(0) with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.respuesta_imagenes OWNER TO postgres;

--
-- Name: respuesta_videos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.respuesta_videos (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    respuesta_id uuid NOT NULL,
    url text NOT NULL,
    orden integer DEFAULT 0 NOT NULL,
    created_at timestamp(0) with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.respuesta_videos OWNER TO postgres;

--
-- Name: respuestas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.respuestas (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    reporte_id uuid NOT NULL,
    usuario_id uuid NOT NULL,
    tipo_respuesta character varying(20) NOT NULL,
    mensaje text NOT NULL,
    ubicacion_lat numeric(10,8),
    ubicacion_lng numeric(11,8),
    direccion_referencia text,
    verificada boolean DEFAULT false NOT NULL,
    util boolean,
    created_at timestamp(0) with time zone DEFAULT now() NOT NULL,
    CONSTRAINT check_tipo_respuesta CHECK (((tipo_respuesta)::text = ANY ((ARRAY['avistamiento'::character varying, 'encontrado'::character varying, 'informacion'::character varying, 'pregunta'::character varying])::text[])))
);


ALTER TABLE public.respuestas OWNER TO postgres;

--
-- Name: role_has_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.role_has_permissions (
    permission_id bigint NOT NULL,
    role_id bigint NOT NULL
);


ALTER TABLE public.role_has_permissions OWNER TO postgres;

--
-- Name: roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    guard_name character varying(255) NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.roles OWNER TO postgres;

--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.roles_id_seq OWNER TO postgres;

--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sessions (
    id character varying(255) NOT NULL,
    user_id bigint,
    ip_address character varying(45),
    user_agent text,
    payload text NOT NULL,
    last_activity integer NOT NULL
);


ALTER TABLE public.sessions OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    email_verified_at timestamp(0) without time zone,
    password character varying(255) NOT NULL,
    remember_token character varying(100),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: usuarios; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.usuarios (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nombre character varying(100) NOT NULL,
    email character varying(255) NOT NULL,
    telefono character varying(20),
    avatar_url text,
    puntos_ayuda integer DEFAULT 0 NOT NULL,
    fecha_registro timestamp(0) with time zone DEFAULT now() NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    ubicacion_actual_lat numeric(10,8),
    ubicacion_actual_lng numeric(11,8),
    rol character varying(20) DEFAULT 'cliente'::character varying NOT NULL,
    contrasena text DEFAULT ''::text NOT NULL,
    created_at timestamp(0) with time zone,
    updated_at timestamp(0) with time zone,
    CONSTRAINT check_rol CHECK (((rol)::text = ANY ((ARRAY['cliente'::character varying, 'moderador'::character varying, 'admin'::character varying])::text[])))
);


ALTER TABLE public.usuarios OWNER TO postgres;

--
-- Name: failed_jobs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.failed_jobs ALTER COLUMN id SET DEFAULT nextval('public.failed_jobs_id_seq'::regclass);


--
-- Name: jobs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jobs ALTER COLUMN id SET DEFAULT nextval('public.jobs_id_seq'::regclass);


--
-- Name: migrations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.migrations ALTER COLUMN id SET DEFAULT nextval('public.migrations_id_seq'::regclass);


--
-- Name: permissions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permissions ALTER COLUMN id SET DEFAULT nextval('public.permissions_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: cache; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cache (key, value, expiration) FROM stdin;
\.


--
-- Data for Name: cache_locks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cache_locks (key, owner, expiration) FROM stdin;
\.


--
-- Data for Name: categorias; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.categorias (id, nombre, icono, color, descripcion, activo, created_at) FROM stdin;
6002c2e2-6a0e-4370-9c11-42c10edf15ef	Personas	person	#FF6B6B	Personas perdidas o desaparecidas	t	2025-12-13 21:53:23-04
ea31ca99-64ca-4ff6-996d-6b431c289018	Mascotas	pets	#4ECDC4	Perros, gatos y otras mascotas	t	2025-12-13 21:53:23-04
2123b794-d024-4f9d-9169-4f5794e380da	Documentos	description	#45B7D1	Identificaciones, pasaportes, licencias	t	2025-12-13 21:53:23-04
d67582ae-b982-454d-a55b-df43873fa7d9	Electrónicos	smartphone	#96CEB4	Teléfonos, laptops, tablets, etc.	t	2025-12-13 21:53:23-04
129497e4-b602-47b4-9b90-a15cd3e1f440	Vehículos	directions_car	#FFEAA7	Autos, motos, bicicletas	t	2025-12-13 21:53:23-04
71c1c42d-f3f0-4225-941a-046765941691	Ropa/Accesorios	checkroom	#DDA0DD	Ropa, bolsas, joyas, etc.	t	2025-12-13 21:53:23-04
ffefcfd5-0fb9-4e3f-933f-026c71069f11	Llaves	vpn_key	#F39C12	Llaves de casa, auto, oficina	t	2025-12-13 21:53:23-04
bd7be892-a767-4ef1-b89f-dbd7a00df01a	Otros	category	#95A5A6	Otros objetos no categorizados	t	2025-12-13 21:53:23-04
\.


--
-- Data for Name: configuracion_notificaciones_usuario; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.configuracion_notificaciones_usuario (id, usuario_id, push_activo, email_activo, sms_activo, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: configuracion_sistema; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.configuracion_sistema (clave, valor, descripcion, tipo, updated_at) FROM stdin;
tiempo_expansion_horas	0.083	Horas antes de expandir a cuadrantes adyacentes	number	2025-12-13 21:53:24-04
max_nivel_expansion	3	Máximo nivel de expansión permitido	number	2025-12-13 21:53:24-04
radio_cuadrante_km	2	Radio en kilómetros de cada cuadrante	number	2025-12-13 21:53:24-04
\.


--
-- Data for Name: cuadrante_barrios; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cuadrante_barrios (id, cuadrante_id, nombre_barrio, created_at) FROM stdin;
019b1b00-9d85-7256-ba93-22ee19555b73	019b1b00-9857-73c4-953e-b4fb25064c7b	Sur A1	2025-12-14 03:56:23-04
019b1b00-9fd6-71e3-b97c-a1ccdf3f8974	019b1b00-9857-73c4-953e-b4fb25064c7b	Villa A1	2025-12-14 03:56:24-04
019b1b00-a1c4-70df-b841-d4dad26d9373	019b1b00-9857-73c4-953e-b4fb25064c7b	Los Pozos A1	2025-12-14 03:56:24-04
019b1b00-a8a7-73ae-bb06-d3b960991ba2	019b1b00-a6aa-705b-8142-3cca0af4e82c	Los Pozos A2	2025-12-14 03:56:26-04
019b1b00-aaf8-7311-9bfc-a41f5a7a3f5f	019b1b00-a6aa-705b-8142-3cca0af4e82c	Oeste A2	2025-12-14 03:56:27-04
019b1b00-b33b-72ff-8556-cad959811904	019b1b00-b16a-706d-87e5-79fca6695fb6	Equipetrol A3	2025-12-14 03:56:29-04
019b1b00-b589-7366-afc2-b36122089cf7	019b1b00-b16a-706d-87e5-79fca6695fb6	Oeste A3	2025-12-14 03:56:29-04
019b1b00-bb6d-70aa-8fee-4e1d445455be	019b1b00-b939-7209-8855-194cca25a5c5	Centro A4	2025-12-14 03:56:31-04
019b1b00-bd46-72d8-bd9e-d9eb0f554e18	019b1b00-b939-7209-8855-194cca25a5c5	Equipetrol A4	2025-12-14 03:56:31-04
019b1b00-bf1b-72cd-b1a9-aeaab085ffae	019b1b00-b939-7209-8855-194cca25a5c5	Los Pozos A4	2025-12-14 03:56:32-04
019b1b00-c17c-738c-a445-b1cc5d4b923e	019b1b00-b939-7209-8855-194cca25a5c5	Este A4	2025-12-14 03:56:33-04
019b1b00-ca4e-7004-a48d-0f8c9f4a70dc	019b1b00-c7e6-70b9-88d9-705531f22ad7	Palmasola A5	2025-12-14 03:56:35-04
019b1b00-cc44-73f9-b087-5e2b0f1b42ed	019b1b00-c7e6-70b9-88d9-705531f22ad7	Sur A5	2025-12-14 03:56:35-04
019b1b00-cea6-71ae-9f58-7d9908d228ec	019b1b00-c7e6-70b9-88d9-705531f22ad7	Oeste A5	2025-12-14 03:56:36-04
019b1b00-d4bc-71da-bdbe-0330c00ced98	019b1b00-d262-71ad-84d0-0c0ce3feb1ed	Centro A6	2025-12-14 03:56:37-04
019b1b00-d692-720b-a5b3-07ff10c728f0	019b1b00-d262-71ad-84d0-0c0ce3feb1ed	Cristo Redentor A6	2025-12-14 03:56:38-04
019b1b00-d871-73c1-8c6e-0bf99a098b17	019b1b00-d262-71ad-84d0-0c0ce3feb1ed	Urbanización A6	2025-12-14 03:56:38-04
019b1b00-de8d-73fa-babd-a5acda190566	019b1b00-dcb3-7092-a87d-b169a9cfb4d7	Satélite Norte A7	2025-12-14 03:56:40-04
019b1b00-e0d8-734e-a22a-e8482ecc22b2	019b1b00-dcb3-7092-a87d-b169a9cfb4d7	Este A7	2025-12-14 03:56:41-04
019b1b00-e71a-708f-b398-04c052c1e8eb	019b1b00-e4bf-7111-b308-ad3f370ef625	Centro A8	2025-12-14 03:56:42-04
019b1b00-e8f9-73b6-a17d-41dc9a827d43	019b1b00-e4bf-7111-b308-ad3f370ef625	Plan 3000 A8	2025-12-14 03:56:43-04
019b1b00-ef60-7179-ac99-5ad10eee3f1d	019b1b00-ed27-7041-b0eb-5190ce4d7a4d	Plan 3000 A9	2025-12-14 03:56:44-04
019b1b00-f137-7028-8826-31b5b145b29b	019b1b00-ed27-7041-b0eb-5190ce4d7a4d	Cristo Redentor A9	2025-12-14 03:56:45-04
019b1b00-f315-71de-a14a-1c9c7a0f9d82	019b1b00-ed27-7041-b0eb-5190ce4d7a4d	Norte A9	2025-12-14 03:56:45-04
019b1b00-f99d-71a2-b5ea-73e5e670c89b	019b1b00-f751-72c6-b3e0-30172deceae6	Satélite Norte A10	2025-12-14 03:56:47-04
019b1b00-fb6b-7028-86c3-c7703d4e7bac	019b1b00-f751-72c6-b3e0-30172deceae6	Los Pozos A10	2025-12-14 03:56:47-04
019b1b00-fd42-7015-bef5-d721e7624c8b	019b1b00-f751-72c6-b3e0-30172deceae6	Palmasola A10	2025-12-14 03:56:48-04
019b1b00-ff96-714c-b599-815b73362cb1	019b1b00-f751-72c6-b3e0-30172deceae6	Sur A10	2025-12-14 03:56:48-04
019b1b01-017d-729f-a8fe-37e44fbfe224	019b1b00-f751-72c6-b3e0-30172deceae6	Equipetrol A10	2025-12-14 03:56:49-04
019b1b01-0777-731f-bb14-b2e30f0d8450	019b1b01-057f-7280-88f4-30881489c569	Urbanización A11	2025-12-14 03:56:50-04
019b1b01-09e4-710a-a0b2-0b504aef88b5	019b1b01-057f-7280-88f4-30881489c569	Las Palmas A11	2025-12-14 03:56:51-04
019b1b01-1010-70d5-b5da-8a049a59e9de	019b1b01-0e27-71bc-bcd1-09162be77279	Plan 3000 A12	2025-12-14 03:56:53-04
019b1b01-1814-7123-837c-94f815377e57	019b1b01-1638-739d-947e-f1c95c6fb5c5	Plan 3000 A13	2025-12-14 03:56:55-04
019b1b01-1a3d-700c-9027-142597907606	019b1b01-1638-739d-947e-f1c95c6fb5c5	Urbanización A13	2025-12-14 03:56:55-04
019b1b01-1c11-7308-a5f2-7fff40cab376	019b1b01-1638-739d-947e-f1c95c6fb5c5	Urbarí A13	2025-12-14 03:56:56-04
019b1b01-2224-716f-9715-7cf97fbcb27a	019b1b01-2033-70af-947a-7131287a0a2f	Este A14	2025-12-14 03:56:57-04
019b1b01-23f7-7245-9e01-4822c5dcde27	019b1b01-2033-70af-947a-7131287a0a2f	Las Palmas A14	2025-12-14 03:56:58-04
019b1b01-261b-737e-a538-3ad867e54a96	019b1b01-2033-70af-947a-7131287a0a2f	Centro A14	2025-12-14 03:56:58-04
019b1b01-29c1-7286-b272-902f6d1581db	019b1b01-2033-70af-947a-7131287a0a2f	Cristo Redentor A14	2025-12-14 03:56:59-04
019b1b01-3073-72f7-8054-59c8efc7fbe1	019b1b01-2e21-732d-b525-5df98e2991fb	Este B1	2025-12-14 03:57:01-04
019b1b01-325b-716b-879e-ff78320637e4	019b1b01-2e21-732d-b525-5df98e2991fb	Oeste B1	2025-12-14 03:57:01-04
019b1b01-3440-7237-b5ac-bc1504738661	019b1b01-2e21-732d-b525-5df98e2991fb	Las Palmas B1	2025-12-14 03:57:02-04
019b1b01-3a49-7230-b9e2-19bbd89e76f8	019b1b01-3867-7188-9ae8-e17343566ead	Oeste B2	2025-12-14 03:57:03-04
019b1b01-3ca3-7391-8b08-e519d8b51438	019b1b01-3867-7188-9ae8-e17343566ead	Las Palmas B2	2025-12-14 03:57:04-04
019b1b01-3e90-734d-ad28-3d387ee56c28	019b1b01-3867-7188-9ae8-e17343566ead	Villa B2	2025-12-14 03:57:05-04
019b1b01-40cc-7031-b3f2-bfb069d88079	019b1b01-3867-7188-9ae8-e17343566ead	Equipetrol B2	2025-12-14 03:57:05-04
019b1b01-42b0-71e2-8a1c-3ce74a411bf0	019b1b01-3867-7188-9ae8-e17343566ead	Los Pozos B2	2025-12-14 03:57:06-04
019b1b01-48e5-731c-b057-1845a7581a94	019b1b01-46f7-72bd-b5f9-37fac7ece605	Urbanización B3	2025-12-14 03:57:07-04
019b1b01-4b12-71a2-a6b3-bcd04a2c820a	019b1b01-46f7-72bd-b5f9-37fac7ece605	Plan 3000 B3	2025-12-14 03:57:08-04
019b1b01-4cf0-7058-a47f-2a5813e33677	019b1b01-46f7-72bd-b5f9-37fac7ece605	Oeste B3	2025-12-14 03:57:08-04
019b1b01-54a7-7337-870c-c7dcc9f7130e	019b1b01-52b2-7076-bdbb-c36f0f6a6db4	Plan 3000 B4	2025-12-14 03:57:10-04
019b1b01-56fc-729d-9090-35408ff2c047	019b1b01-52b2-7076-bdbb-c36f0f6a6db4	Centro B4	2025-12-14 03:57:11-04
019b1b01-58d6-70f7-87eb-7b0943ca9cbc	019b1b01-52b2-7076-bdbb-c36f0f6a6db4	Satélite Norte B4	2025-12-14 03:57:11-04
019b1b01-5aa4-73a0-bbf1-979a202c0c66	019b1b01-52b2-7076-bdbb-c36f0f6a6db4	Equipetrol B4	2025-12-14 03:57:12-04
019b1b01-5ce4-73d0-a0ae-2b01c06c70df	019b1b01-52b2-7076-bdbb-c36f0f6a6db4	Las Palmas B4	2025-12-14 03:57:12-04
019b1b01-62be-705b-887d-c16adefc9a80	019b1b01-6088-714a-9914-2845c26a18c5	Cristo Redentor B5	2025-12-14 03:57:14-04
019b1b01-6487-732d-b8bd-faf06a687488	019b1b01-6088-714a-9914-2845c26a18c5	Centro B5	2025-12-14 03:57:14-04
019b1b01-6a68-709a-a130-5bc7bf7fda9e	019b1b01-6886-70e1-b422-0f1c1f2976d8	Urbanización B6	2025-12-14 03:57:16-04
019b1b01-6cc3-72bc-93ff-be04dbe8ffa4	019b1b01-6886-70e1-b422-0f1c1f2976d8	Los Pozos B6	2025-12-14 03:57:16-04
019b1b01-6e9b-7185-9399-b4a9e3942ca4	019b1b01-6886-70e1-b422-0f1c1f2976d8	Equipetrol B6	2025-12-14 03:57:17-04
019b1b01-7067-71ca-9290-36e07035fd3f	019b1b01-6886-70e1-b422-0f1c1f2976d8	Urbarí B6	2025-12-14 03:57:17-04
019b1b01-766c-7381-a14e-5b5abd57382b	019b1b01-7473-722c-9b60-fc717b1f031f	Centro B7	2025-12-14 03:57:19-04
019b1b01-78b1-7269-a7f0-c0008f07cb55	019b1b01-7473-722c-9b60-fc717b1f031f	Urbanización B7	2025-12-14 03:57:19-04
019b1b01-7aa1-720f-88e6-9dd6c9bf32f7	019b1b01-7473-722c-9b60-fc717b1f031f	Equipetrol B7	2025-12-14 03:57:20-04
019b1b01-7c75-7358-b0cb-5d1004560b0c	019b1b01-7473-722c-9b60-fc717b1f031f	Este B7	2025-12-14 03:57:20-04
019b1b01-82d2-72d2-b067-ff079719fbb9	019b1b01-8091-730e-80d4-e3909fc53ff9	Equipetrol B8	2025-12-14 03:57:22-04
019b1b01-84a3-70ea-9f70-867a0a2e2b43	019b1b01-8091-730e-80d4-e3909fc53ff9	Hamacas B8	2025-12-14 03:57:22-04
019b1b01-8688-732b-99c6-bbcfd5aa2327	019b1b01-8091-730e-80d4-e3909fc53ff9	Oeste B8	2025-12-14 03:57:23-04
019b1b01-8ec5-73d2-b06b-9e7296392904	019b1b01-8c69-7105-a356-cdf8bde5d0c3	Urbanización B9	2025-12-14 03:57:25-04
019b1b01-90a5-7204-9a59-2ce5508376b6	019b1b01-8c69-7105-a356-cdf8bde5d0c3	Las Palmas B9	2025-12-14 03:57:26-04
019b1b01-9301-7065-93b3-fa1ecc642ec8	019b1b01-8c69-7105-a356-cdf8bde5d0c3	Sur B9	2025-12-14 03:57:26-04
019b1b01-9750-73dd-8e40-c609b2746398	019b1b01-8c69-7105-a356-cdf8bde5d0c3	Plan 3000 B9	2025-12-14 03:57:27-04
019b1b01-9d62-7294-bfd7-26b7146a4954	019b1b01-9b18-70b9-a84f-c0a7f1346478	Este B10	2025-12-14 03:57:29-04
019b1b01-9f4a-7282-8079-d207214a7d55	019b1b01-9b18-70b9-a84f-c0a7f1346478	Norte B10	2025-12-14 03:57:29-04
019b1b01-a12f-70bb-9359-45ecdd9741e8	019b1b01-9b18-70b9-a84f-c0a7f1346478	Centro B10	2025-12-14 03:57:30-04
019b1b01-a7ae-704e-b7c0-440f9c126426	019b1b01-a554-72c9-bff3-fb18488b9997	Norte B11	2025-12-14 03:57:31-04
019b1b01-a98d-713b-9192-bb718ed80cc7	019b1b01-a554-72c9-bff3-fb18488b9997	Equipetrol B11	2025-12-14 03:57:32-04
019b1b01-affc-72fd-a289-516476bda678	019b1b01-adab-713c-8ed8-ef3bdaf014ae	Hamacas B12	2025-12-14 03:57:34-04
019b1b01-b1ff-72c9-97ff-4dac3a75113e	019b1b01-adab-713c-8ed8-ef3bdaf014ae	Urbarí B12	2025-12-14 03:57:34-04
019b1b01-b47e-7066-8621-e9d09fde6636	019b1b01-adab-713c-8ed8-ef3bdaf014ae	Equipetrol B12	2025-12-14 03:57:35-04
019b1b01-b673-73af-8a61-f166317deec2	019b1b01-adab-713c-8ed8-ef3bdaf014ae	Satélite Norte B12	2025-12-14 03:57:35-04
019b1b01-bcf7-7304-97ea-e091ecef77a2	019b1b01-babf-70a0-bf41-728e9604929f	Hamacas B13	2025-12-14 03:57:37-04
019b1b01-bed9-7127-abc5-e21027b44485	019b1b01-babf-70a0-bf41-728e9604929f	Plan 3000 B13	2025-12-14 03:57:37-04
019b1b01-c0b7-707e-9512-9eb54fcebccb	019b1b01-babf-70a0-bf41-728e9604929f	Oeste B13	2025-12-14 03:57:38-04
019b1b01-c2f0-73dd-a75f-c811c607303f	019b1b01-babf-70a0-bf41-728e9604929f	Equipetrol B13	2025-12-14 03:57:38-04
019b1b01-c913-724f-b2a9-eb60af064ab1	019b1b01-c6c5-7395-b99c-b7ca7c2f992a	Urbarí B14	2025-12-14 03:57:40-04
019b1b01-cb07-7240-8d18-a50714e13a8e	019b1b01-c6c5-7395-b99c-b7ca7c2f992a	Este B14	2025-12-14 03:57:40-04
019b1b01-cd6b-70d7-9045-d1c30c9d92b2	019b1b01-c6c5-7395-b99c-b7ca7c2f992a	Las Palmas B14	2025-12-14 03:57:41-04
019b1b01-cf40-7084-bb1f-3fd18395746c	019b1b01-c6c5-7395-b99c-b7ca7c2f992a	Cristo Redentor B14	2025-12-14 03:57:42-04
019b1b01-d5d1-714f-96b3-4c038cda5649	019b1b01-d382-7140-9329-54b105e6ef00	Plan 3000 C1	2025-12-14 03:57:43-04
019b1b01-d7b8-720a-9069-4e5f8228bf34	019b1b01-d382-7140-9329-54b105e6ef00	Norte C1	2025-12-14 03:57:44-04
019b1b01-d997-73f1-8ca4-79dc2739f03e	019b1b01-d382-7140-9329-54b105e6ef00	Oeste C1	2025-12-14 03:57:44-04
019b1b01-dbef-7118-a76a-0b26e9d8960d	019b1b01-d382-7140-9329-54b105e6ef00	Sur C1	2025-12-14 03:57:45-04
019b1b01-e1d8-728c-afe9-6f565cddea4c	019b1b01-dfa0-7325-95df-f0dc6d01dfd4	Este C2	2025-12-14 03:57:46-04
019b1b01-e3ae-718a-bc7e-935f75726421	019b1b01-dfa0-7325-95df-f0dc6d01dfd4	Norte C2	2025-12-14 03:57:47-04
019b1b01-e9b5-7175-a0c6-284b731bf241	019b1b01-e7d6-71d7-9812-dd307461585f	Oeste C3	2025-12-14 03:57:48-04
019b1b01-eb8f-700f-b53f-b214868f37b4	019b1b01-e7d6-71d7-9812-dd307461585f	Satélite Norte C3	2025-12-14 03:57:49-04
019b1b01-f1e4-70fd-b38c-7bdb87e1c5a3	019b1b01-efa9-73bf-940e-4a3240fbc80b	Este C4	2025-12-14 03:57:50-04
019b1b01-f3bd-713b-9d42-8233e0d4a715	019b1b01-efa9-73bf-940e-4a3240fbc80b	Los Pozos C4	2025-12-14 03:57:51-04
019b1b01-f5b2-7374-86e6-a1a2fc220ae9	019b1b01-efa9-73bf-940e-4a3240fbc80b	Palmasola C4	2025-12-14 03:57:51-04
019b1b01-fcab-70c0-b6a8-1263c3d7ac84	019b1b01-fa4e-73a5-9c6b-a9995f059279	Urbanización C5	2025-12-14 03:57:53-04
019b1b01-fea0-73bb-a2e2-c8ae68e67009	019b1b01-fa4e-73a5-9c6b-a9995f059279	Satélite Norte C5	2025-12-14 03:57:54-04
019b1b02-02b2-7184-84fd-046cf017b73f	019b1b01-fa4e-73a5-9c6b-a9995f059279	Centro C5	2025-12-14 03:57:55-04
019b1b02-048d-73ab-aec8-9d190538d38e	019b1b01-fa4e-73a5-9c6b-a9995f059279	Este C5	2025-12-14 03:57:55-04
019b1b02-0a8d-732a-ba45-03fa62f6d780	019b1b02-089d-72e2-8b55-cd3e13565924	Las Palmas C6	2025-12-14 03:57:57-04
019b1b02-0ccf-71ad-b809-7b28b8f6b470	019b1b02-089d-72e2-8b55-cd3e13565924	Palmasola C6	2025-12-14 03:57:57-04
019b1b02-0ec2-7365-aaec-72bf8731c2e2	019b1b02-089d-72e2-8b55-cd3e13565924	Cristo Redentor C6	2025-12-14 03:57:58-04
019b1b02-1097-723f-a335-96c9f3d30cfd	019b1b02-089d-72e2-8b55-cd3e13565924	Villa C6	2025-12-14 03:57:58-04
019b1b02-1665-7133-ac0d-97081a71ea7f	019b1b02-1487-721c-a35a-06b2c069ffea	Equipetrol C7	2025-12-14 03:58:00-04
019b1b02-1843-7225-b189-9d1e5a506169	019b1b02-1487-721c-a35a-06b2c069ffea	Norte C7	2025-12-14 03:58:00-04
019b1b02-1a84-728b-aeb7-e7def2d4463d	019b1b02-1487-721c-a35a-06b2c069ffea	Urbanización C7	2025-12-14 03:58:01-04
019b1b02-1c85-73c9-8ffa-165fd4f649a5	019b1b02-1487-721c-a35a-06b2c069ffea	Satélite Norte C7	2025-12-14 03:58:01-04
019b1b02-2270-73c1-a365-a3e12d2bc17b	019b1b02-2096-719a-87be-1f95727fa3f4	Villa C8	2025-12-14 03:58:03-04
019b1b02-244d-7219-afe9-5943fe93f356	019b1b02-2096-719a-87be-1f95727fa3f4	Los Pozos C8	2025-12-14 03:58:03-04
019b1b02-267f-71ab-b90d-b157ce43b19e	019b1b02-2096-719a-87be-1f95727fa3f4	Cristo Redentor C8	2025-12-14 03:58:04-04
019b1b02-2850-724a-808d-e8171981802a	019b1b02-2096-719a-87be-1f95727fa3f4	Este C8	2025-12-14 03:58:04-04
019b1b02-2e6f-71e8-8b28-93fe65ca8aab	019b1b02-2c98-71a1-b044-6e6d6619c18f	Equipetrol C9	2025-12-14 03:58:06-04
019b1b02-3629-73da-8e51-7fd06280b732	019b1b02-3437-718b-b15b-9bb0d66d3959	Los Pozos C10	2025-12-14 03:58:08-04
019b1b02-3a28-733a-82f1-cbdc25a086e7	019b1b02-3437-718b-b15b-9bb0d66d3959	Villa C10	2025-12-14 03:58:09-04
019b1b02-402a-7118-8cba-523976c895be	019b1b02-3e56-7183-af6c-810c087bea77	Este C11	2025-12-14 03:58:10-04
019b1b02-4218-739a-91c9-11f15a089345	019b1b02-3e56-7183-af6c-810c087bea77	Sur C11	2025-12-14 03:58:11-04
019b1b02-4477-737d-8d0c-a27dfc73c1ce	019b1b02-3e56-7183-af6c-810c087bea77	Los Pozos C11	2025-12-14 03:58:12-04
019b1b02-4891-70ee-a562-7e6b7d2e5dd9	019b1b02-3e56-7183-af6c-810c087bea77	Cristo Redentor C11	2025-12-14 03:58:13-04
019b1b02-4ea4-734e-800d-bd04374b761b	019b1b02-4c5b-7386-a42e-b7a654c437cb	Hamacas C12	2025-12-14 03:58:14-04
019b1b02-5087-712e-9543-e01815ec5d8c	019b1b02-4c5b-7386-a42e-b7a654c437cb	Equipetrol C12	2025-12-14 03:58:15-04
019b1b02-567a-7286-a979-816f20f88b4f	019b1b02-54a4-7129-b945-2f0f91ef3ac4	Villa C13	2025-12-14 03:58:16-04
019b1b02-58b9-714d-b878-05b71a50b98a	019b1b02-54a4-7129-b945-2f0f91ef3ac4	Norte C13	2025-12-14 03:58:17-04
019b1b02-5a83-713d-9097-7a9e51145768	019b1b02-54a4-7129-b945-2f0f91ef3ac4	Centro C13	2025-12-14 03:58:17-04
019b1b02-62cf-7276-9e15-43bddb7c1424	019b1b02-6087-723a-b4d6-1bceceb78e7a	Satélite Norte C14	2025-12-14 03:58:19-04
019b1b02-64ab-7208-bcb0-90051f7890b7	019b1b02-6087-723a-b4d6-1bceceb78e7a	Los Pozos C14	2025-12-14 03:58:20-04
019b1b02-6697-7349-b7f4-a31721c29d0a	019b1b02-6087-723a-b4d6-1bceceb78e7a	Palmasola C14	2025-12-14 03:58:20-04
019b1b02-68e4-70d9-ad3e-90f1b431e6db	019b1b02-6087-723a-b4d6-1bceceb78e7a	Equipetrol C14	2025-12-14 03:58:21-04
019b1b02-709f-7012-9c5c-cbf0e85b93d4	019b1b02-6ec7-71e9-b3c6-37a189794ef5	Sur D1	2025-12-14 03:58:23-04
019b1b02-7285-7263-8368-20a3a3f01c1a	019b1b02-6ec7-71e9-b3c6-37a189794ef5	Hamacas D1	2025-12-14 03:58:23-04
019b1b02-76a8-7012-bccb-356cc3f47682	019b1b02-6ec7-71e9-b3c6-37a189794ef5	Palmasola D1	2025-12-14 03:58:24-04
019b1b02-7d11-73bc-a9c7-a2c87be07d44	019b1b02-7ad0-73d1-a4ba-41d13fb59b81	Palmasola D2	2025-12-14 03:58:26-04
019b1b02-7ee3-7313-8b1b-1a7218bad590	019b1b02-7ad0-73d1-a4ba-41d13fb59b81	Cristo Redentor D2	2025-12-14 03:58:27-04
019b1b02-80c0-707c-84f6-9965933175f6	019b1b02-7ad0-73d1-a4ba-41d13fb59b81	Oeste D2	2025-12-14 03:58:27-04
019b1b02-86d1-7321-9a69-7f292a714370	019b1b02-84f7-70fa-89ba-38671bf623c8	Urbarí D3	2025-12-14 03:58:29-04
019b1b02-8936-701f-b440-40e7bda66736	019b1b02-84f7-70fa-89ba-38671bf623c8	Este D3	2025-12-14 03:58:29-04
019b1b02-8f56-7320-ac48-f01c27bf7d96	019b1b02-8d79-7300-836a-a9ecea7bd834	Oeste D4	2025-12-14 03:58:31-04
019b1b02-9369-715d-a6e4-90ad530d0fd0	019b1b02-8d79-7300-836a-a9ecea7bd834	Centro D4	2025-12-14 03:58:32-04
019b1b02-9c02-70ff-9f5c-dfc549c341cd	019b1b02-99c0-7087-89c9-2cb704681f8c	Urbanización D5	2025-12-14 03:58:34-04
019b1b02-a40e-72ae-b492-6f9fb7695a6c	019b1b02-a222-72e3-88dd-c0864f7a8599	Cristo Redentor D6	2025-12-14 03:58:36-04
019b1b02-a65c-713d-b190-cfd014a0a62b	019b1b02-a222-72e3-88dd-c0864f7a8599	Urbarí D6	2025-12-14 03:58:37-04
019b1b02-a839-735a-bf08-7122016160ea	019b1b02-a222-72e3-88dd-c0864f7a8599	Sur D6	2025-12-14 03:58:37-04
019b1b02-aa15-73e8-84a5-aef4e3fd0546	019b1b02-a222-72e3-88dd-c0864f7a8599	Satélite Norte D6	2025-12-14 03:58:38-04
019b1b02-b015-7033-b4f0-4deb3cabfe43	019b1b02-ae2b-73b0-b239-c4be7d32653a	Las Palmas D7	2025-12-14 03:58:39-04
019b1b02-b257-724c-8971-fbf48b266f53	019b1b02-ae2b-73b0-b239-c4be7d32653a	Villa D7	2025-12-14 03:58:40-04
019b1b02-b60e-7202-8c54-9c5405bbb7dc	019b1b02-ae2b-73b0-b239-c4be7d32653a	Oeste D7	2025-12-14 03:58:41-04
019b1b02-bc85-706c-a02f-5f19530054c5	019b1b02-ba42-73ce-bd98-debe8d7ed4ac	Este D8	2025-12-14 03:58:42-04
019b1b02-be68-717f-9873-0092729bda6d	019b1b02-ba42-73ce-bd98-debe8d7ed4ac	Sur D8	2025-12-14 03:58:43-04
019b1b02-c048-7388-a66b-8dde93237262	019b1b02-ba42-73ce-bd98-debe8d7ed4ac	Urbanización D8	2025-12-14 03:58:43-04
019b1b02-c675-72b7-a013-c7554c17d55d	019b1b02-c48c-729d-bafc-4021c1564694	Urbanización D9	2025-12-14 03:58:45-04
019b1b02-c8ab-72a5-8e63-f01573d5bfbc	019b1b02-c48c-729d-bafc-4021c1564694	Centro D9	2025-12-14 03:58:45-04
019b1b02-ca9a-72c7-a2e1-f95a522c6ef7	019b1b02-c48c-729d-bafc-4021c1564694	Las Palmas D9	2025-12-14 03:58:46-04
019b1b02-d0ab-7333-8b98-04becb609285	019b1b02-ced5-7098-a830-8693997fcfbf	Los Pozos D10	2025-12-14 03:58:47-04
019b1b02-d276-7368-bd29-23e37fa694ea	019b1b02-ced5-7098-a830-8693997fcfbf	Sur D10	2025-12-14 03:58:48-04
019b1b02-dabf-7273-94c4-0e6e2cf2eab6	019b1b02-d872-70b7-9448-f7df890eebe5	Satélite Norte D11	2025-12-14 03:58:50-04
019b1b02-dca7-722b-97af-24df52956142	019b1b02-d872-70b7-9448-f7df890eebe5	Plan 3000 D11	2025-12-14 03:58:51-04
019b1b02-defa-73fb-b111-2b27f43269d8	019b1b02-d872-70b7-9448-f7df890eebe5	Oeste D11	2025-12-14 03:58:51-04
019b1b02-e50a-72b8-9e4b-9c30350b1218	019b1b02-e328-71dc-8286-da6a3f279a90	Hamacas D12	2025-12-14 03:58:53-04
019b1b02-e700-715d-886c-66428bea44fb	019b1b02-e328-71dc-8286-da6a3f279a90	Centro D12	2025-12-14 03:58:53-04
019b1b02-e959-7235-aca5-d933dbbe9ff0	019b1b02-e328-71dc-8286-da6a3f279a90	Urbanización D12	2025-12-14 03:58:54-04
019b1b02-eb43-71d9-be9b-4b7fcf9c5867	019b1b02-e328-71dc-8286-da6a3f279a90	Satélite Norte D12	2025-12-14 03:58:54-04
019b1b02-f13b-72e6-b3b6-604022ed4a03	019b1b02-ef56-73d4-a8b0-47445839e2c5	Urbarí D13	2025-12-14 03:58:56-04
019b1b02-f36f-7389-8719-3b4354083689	019b1b02-ef56-73d4-a8b0-47445839e2c5	Equipetrol D13	2025-12-14 03:58:56-04
019b1b02-f54d-72b8-a6ff-966e1bbff639	019b1b02-ef56-73d4-a8b0-47445839e2c5	Urbanización D13	2025-12-14 03:58:57-04
019b1b02-fdeb-72cb-a5d9-b244c8eb0c84	019b1b02-fb8d-7006-aba0-ece4433b1bfa	Urbanización D14	2025-12-14 03:58:59-04
019b1b02-ffce-7385-b0d1-72e9f2c6ead3	019b1b02-fb8d-7006-aba0-ece4433b1bfa	Cristo Redentor D14	2025-12-14 03:59:00-04
019b1b03-082c-7004-b33c-bd39e7df0ef3	019b1b03-064e-733b-850b-41c873d82eb6	Norte E1	2025-12-14 03:59:02-04
019b1b03-0a2b-71b7-afb5-a83553b82943	019b1b03-064e-733b-850b-41c873d82eb6	Cristo Redentor E1	2025-12-14 03:59:02-04
019b1b03-0c7f-72db-9840-6e962a3d59c3	019b1b03-064e-733b-850b-41c873d82eb6	Centro E1	2025-12-14 03:59:03-04
019b1b03-0e6f-70c2-a89d-6e7131e37059	019b1b03-064e-733b-850b-41c873d82eb6	Este E1	2025-12-14 03:59:03-04
019b1b03-16b2-7264-897f-971515210440	019b1b03-1453-7277-95fd-0e0f8fedf0f4	Las Palmas E2	2025-12-14 03:59:05-04
019b1b03-1887-706f-91e5-f11f14d492bc	019b1b03-1453-7277-95fd-0e0f8fedf0f4	Oeste E2	2025-12-14 03:59:06-04
019b1b03-1ac8-726a-8209-3a00a999f2f1	019b1b03-1453-7277-95fd-0e0f8fedf0f4	Palmasola E2	2025-12-14 03:59:06-04
019b1b03-1ca5-72be-8245-215913755d51	019b1b03-1453-7277-95fd-0e0f8fedf0f4	Villa E2	2025-12-14 03:59:07-04
019b1b03-1e80-725c-a23b-52dd99daa0ff	019b1b03-1453-7277-95fd-0e0f8fedf0f4	Plan 3000 E2	2025-12-14 03:59:07-04
019b1b03-24f2-7395-8f88-1997d7c65b54	019b1b03-22a7-72f4-b78b-022e3c1430bf	Urbarí E3	2025-12-14 03:59:09-04
019b1b03-26dc-7287-9180-9dc50cb49ef8	019b1b03-22a7-72f4-b78b-022e3c1430bf	Equipetrol E3	2025-12-14 03:59:10-04
019b1b03-2928-700b-a1d9-44f5ac0079cd	019b1b03-22a7-72f4-b78b-022e3c1430bf	Sur E3	2025-12-14 03:59:10-04
019b1b03-2b0d-717d-acc1-7b82dd3aab7a	019b1b03-22a7-72f4-b78b-022e3c1430bf	Norte E3	2025-12-14 03:59:11-04
019b1b03-3359-721a-9daf-671c44d452d1	019b1b03-311d-7047-a48d-5d833ce6f19c	Cristo Redentor E4	2025-12-14 03:59:13-04
019b1b03-352b-706c-b910-7715b863be2b	019b1b03-311d-7047-a48d-5d833ce6f19c	Urbarí E4	2025-12-14 03:59:13-04
019b1b03-3706-73c0-83d1-5b33ea61d78b	019b1b03-311d-7047-a48d-5d833ce6f19c	Equipetrol E4	2025-12-14 03:59:14-04
019b1b03-3d97-739a-9ecc-e2e9a0a2af7a	019b1b03-3b40-73bc-8ec5-3d69c80687aa	Urbarí E5	2025-12-14 03:59:15-04
019b1b03-3f7c-70c5-8b64-15d287602408	019b1b03-3b40-73bc-8ec5-3d69c80687aa	Villa E5	2025-12-14 03:59:16-04
019b1b03-41ce-7327-a8c4-e14e3fa93dec	019b1b03-3b40-73bc-8ec5-3d69c80687aa	Oeste E5	2025-12-14 03:59:16-04
019b1b03-47bb-70a8-8ea8-ce0119fc0c20	019b1b03-457c-70cd-8738-e538630c9fe1	Oeste E6	2025-12-14 03:59:18-04
019b1b03-4994-7001-815c-9d9c83c8a5d2	019b1b03-457c-70cd-8738-e538630c9fe1	Hamacas E6	2025-12-14 03:59:18-04
019b1b03-4b90-73cb-8aa2-cab80313070b	019b1b03-457c-70cd-8738-e538630c9fe1	Villa E6	2025-12-14 03:59:19-04
019b1b03-4ded-7363-9046-998fa845b40f	019b1b03-457c-70cd-8738-e538630c9fe1	Plan 3000 E6	2025-12-14 03:59:20-04
019b1b03-5623-70de-99e3-d5f7b67fc346	019b1b03-5411-7062-85d6-be858b564b4d	Plan 3000 E7	2025-12-14 03:59:22-04
019b1b03-5885-7202-85dd-de391bd89795	019b1b03-5411-7062-85d6-be858b564b4d	Equipetrol E7	2025-12-14 03:59:22-04
019b1b03-5a6d-715e-bcd7-e481ccd90a6a	019b1b03-5411-7062-85d6-be858b564b4d	Urbarí E7	2025-12-14 03:59:23-04
019b1b03-5cb0-70c5-8ee9-c2ecae4c5387	019b1b03-5411-7062-85d6-be858b564b4d	Villa E7	2025-12-14 03:59:23-04
019b1b03-62c0-7001-aef9-f361b76304c5	019b1b03-606b-7024-8a0d-6ef4eac39ba0	Palmasola E8	2025-12-14 03:59:25-04
019b1b03-649d-7346-9472-20f888156d96	019b1b03-606b-7024-8a0d-6ef4eac39ba0	Cristo Redentor E8	2025-12-14 03:59:25-04
019b1b03-6688-71a5-906d-10abd19ab141	019b1b03-606b-7024-8a0d-6ef4eac39ba0	Equipetrol E8	2025-12-14 03:59:26-04
019b1b03-6d5d-7225-aec7-addb36567b93	019b1b03-6aef-71ab-903d-b972fcf133fb	Oeste E9	2025-12-14 03:59:28-04
019b1b03-6f3b-7213-84a3-a35bfa1310d6	019b1b03-6aef-71ab-903d-b972fcf133fb	Centro E9	2025-12-14 03:59:28-04
019b1b03-7181-7221-ac11-a8e343acf37d	019b1b03-6aef-71ab-903d-b972fcf133fb	Palmasola E9	2025-12-14 03:59:29-04
019b1b03-738d-723d-b794-14b442896c02	019b1b03-6aef-71ab-903d-b972fcf133fb	Este E9	2025-12-14 03:59:29-04
019b1b03-75f9-73bf-8d2f-cd54adc798be	019b1b03-6aef-71ab-903d-b972fcf133fb	Sur E9	2025-12-14 03:59:30-04
019b1b03-7c11-725f-8f62-87dbae8f9fb4	019b1b03-7a35-7363-a960-71dad55030f6	Hamacas E10	2025-12-14 03:59:31-04
019b1b03-7df2-728c-ad58-77f223ab5f85	019b1b03-7a35-7363-a960-71dad55030f6	Equipetrol E10	2025-12-14 03:59:32-04
019b1b03-8032-7169-9d27-dea42779669f	019b1b03-7a35-7363-a960-71dad55030f6	Villa E10	2025-12-14 03:59:32-04
019b1b03-8217-7020-a242-1de956b3564e	019b1b03-7a35-7363-a960-71dad55030f6	Oeste E10	2025-12-14 03:59:33-04
019b1b03-8821-72f5-9cec-c7564d28dac9	019b1b03-864a-720d-af51-c2e142d83192	Norte E11	2025-12-14 03:59:34-04
019b1b03-8a8e-70ff-835e-fa43e694e4f7	019b1b03-864a-720d-af51-c2e142d83192	Este E11	2025-12-14 03:59:35-04
019b1b03-8c7d-7149-beb9-22524dc41b1a	019b1b03-864a-720d-af51-c2e142d83192	Oeste E11	2025-12-14 03:59:36-04
019b1b03-8e85-7196-863b-617b005610ce	019b1b03-864a-720d-af51-c2e142d83192	Sur E11	2025-12-14 03:59:36-04
019b1b03-9515-70b0-a905-7c1c82e7623e	019b1b03-92d4-70ca-a674-fa7e7d312fcb	Equipetrol E12	2025-12-14 03:59:38-04
019b1b03-96f9-7268-bd01-b5dc0298d83a	019b1b03-92d4-70ca-a674-fa7e7d312fcb	Los Pozos E12	2025-12-14 03:59:38-04
019b1b03-98dd-73f1-9e5b-07cfae0d8fca	019b1b03-92d4-70ca-a674-fa7e7d312fcb	Norte E12	2025-12-14 03:59:39-04
019b1b03-9fbc-71c9-9f3f-3ccacccfbee5	019b1b03-9d6e-7103-a700-066291349bae	Oeste E13	2025-12-14 03:59:40-04
019b1b03-a7d0-73e9-9476-df7e995a9a7e	019b1b03-a5e4-7160-b485-df05686f7cc0	Urbarí E14	2025-12-14 03:59:43-04
019b1b03-aa1d-729f-8802-439ec661eba7	019b1b03-a5e4-7160-b485-df05686f7cc0	Los Pozos E14	2025-12-14 03:59:43-04
019b1b03-ac02-7073-8e88-068ce2d0a246	019b1b03-a5e4-7160-b485-df05686f7cc0	Centro E14	2025-12-14 03:59:44-04
019b1b03-ae59-71cb-b6de-ba2d5340d7b6	019b1b03-a5e4-7160-b485-df05686f7cc0	Plan 3000 E14	2025-12-14 03:59:44-04
019b1b03-b45c-7096-8191-841ab882b3a4	019b1b03-b271-708f-9d1e-11022509f1a7	Urbarí F1	2025-12-14 03:59:46-04
019b1b03-b638-715c-bc8d-0b30be0f80a3	019b1b03-b271-708f-9d1e-11022509f1a7	Cristo Redentor F1	2025-12-14 03:59:46-04
019b1b03-b8a5-73ad-8ecc-55bb87599b4a	019b1b03-b271-708f-9d1e-11022509f1a7	Norte F1	2025-12-14 03:59:47-04
019b1b03-bc68-731b-96bd-e8cd8b31b6ef	019b1b03-b271-708f-9d1e-11022509f1a7	Las Palmas F1	2025-12-14 03:59:48-04
019b1b03-c30b-72c9-b64b-f84f5798f47f	019b1b03-c0b4-702e-8df4-ec87472ccb32	Urbanización F2	2025-12-14 03:59:50-04
019b1b03-c4e9-7298-b315-856e9944c573	019b1b03-c0b4-702e-8df4-ec87472ccb32	Palmasola F2	2025-12-14 03:59:50-04
019b1b03-c6cb-73e0-b5e0-6e6b6f1ced35	019b1b03-c0b4-702e-8df4-ec87472ccb32	Las Palmas F2	2025-12-14 03:59:50-04
019b1b03-c90c-739f-8908-31e6c34d5989	019b1b03-c0b4-702e-8df4-ec87472ccb32	Plan 3000 F2	2025-12-14 03:59:51-04
019b1b03-caf0-72de-b2af-57042c9b34ec	019b1b03-c0b4-702e-8df4-ec87472ccb32	Oeste F2	2025-12-14 03:59:52-04
019b1b03-d10d-716a-9612-ba78b8262031	019b1b03-cf19-7258-91b6-e0d18649a584	Urbanización F3	2025-12-14 03:59:53-04
019b1b03-d2de-711d-86e0-6d5a1173fd52	019b1b03-cf19-7258-91b6-e0d18649a584	Hamacas F3	2025-12-14 03:59:54-04
019b1b03-d702-72e1-8fa0-a5bf66251101	019b1b03-cf19-7258-91b6-e0d18649a584	Satélite Norte F3	2025-12-14 03:59:55-04
019b1b03-dd4c-724a-8d92-22375c841a42	019b1b03-db17-70b0-80b4-6dcbe4ad7985	Satélite Norte F4	2025-12-14 03:59:56-04
019b1b03-e174-71a3-856d-785c165a53a4	019b1b03-db17-70b0-80b4-6dcbe4ad7985	Este F4	2025-12-14 03:59:57-04
019b1b03-e788-7390-8ee2-958f614c66b3	019b1b03-e590-72f7-a6e9-189cc2820985	Urbarí F5	2025-12-14 03:59:59-04
019b1b03-e9d5-72e4-8bbc-4504d39708e6	019b1b03-e590-72f7-a6e9-189cc2820985	Norte F5	2025-12-14 03:59:59-04
019b1b03-ebc2-705d-93ff-2017d2d7038d	019b1b03-e590-72f7-a6e9-189cc2820985	Los Pozos F5	2025-12-14 04:00:00-04
019b1b03-ee19-7337-8fbc-ad697e74ce5b	019b1b03-e590-72f7-a6e9-189cc2820985	Las Palmas F5	2025-12-14 04:00:01-04
019b1b03-f419-7131-ba90-3807811df3e8	019b1b03-f1d8-7298-8a7d-0d43022c3b16	Las Palmas F6	2025-12-14 04:00:02-04
019b1b03-f60b-73e5-9a3e-34ad151a8ae3	019b1b03-f1d8-7298-8a7d-0d43022c3b16	Sur F6	2025-12-14 04:00:03-04
019b1b03-f849-7351-9d38-0f687bffa99b	019b1b03-f1d8-7298-8a7d-0d43022c3b16	Satélite Norte F6	2025-12-14 04:00:03-04
019b1b04-0010-7223-91dc-6b9ed213cece	019b1b03-fe27-71b7-a22b-e058a57dc398	Satélite Norte F7	2025-12-14 04:00:05-04
019b1b04-01e2-7156-9ea6-ccb359835754	019b1b03-fe27-71b7-a22b-e058a57dc398	Urbarí F7	2025-12-14 04:00:06-04
019b1b04-083c-70f3-871f-8b4f4bca0f63	019b1b04-05f5-7178-9d36-dd2caa7a081d	Palmasola F8	2025-12-14 04:00:07-04
019b1b04-0a2c-7338-898b-e5cca43c80b4	019b1b04-05f5-7178-9d36-dd2caa7a081d	Urbarí F8	2025-12-14 04:00:08-04
019b1b04-1018-70b3-a966-f96802449187	019b1b04-0e32-73cc-aba8-319497bae801	Urbarí F9	2025-12-14 04:00:09-04
019b1b04-11fa-7007-b045-a1222a69d754	019b1b04-0e32-73cc-aba8-319497bae801	Los Pozos F9	2025-12-14 04:00:10-04
019b1b04-18d6-7387-a02f-93311a088b15	019b1b04-162b-71ad-9117-189c0df75323	Cristo Redentor F10	2025-12-14 04:00:11-04
019b1b04-1b0a-7208-8e38-3e3a342527aa	019b1b04-162b-71ad-9117-189c0df75323	Equipetrol F10	2025-12-14 04:00:12-04
019b1b04-1eb0-7388-8804-706b1c24381d	019b1b04-162b-71ad-9117-189c0df75323	Este F10	2025-12-14 04:00:13-04
019b1b04-2100-73f3-b709-15b6c733862d	019b1b04-162b-71ad-9117-189c0df75323	Satélite Norte F10	2025-12-14 04:00:14-04
019b1b04-26ff-735d-8362-8e50a7eb9ae6	019b1b04-24a1-70a8-8455-e15c7d04d8c8	Norte F11	2025-12-14 04:00:15-04
019b1b04-28e2-733a-988c-c858b777717e	019b1b04-24a1-70a8-8455-e15c7d04d8c8	Hamacas F11	2025-12-14 04:00:16-04
019b1b04-2f46-73e6-8302-976a9333d22e	019b1b04-2d0c-72ae-bbea-b04947d481f3	Centro F12	2025-12-14 04:00:17-04
019b1b04-3133-73d2-b103-31e0f732d58a	019b1b04-2d0c-72ae-bbea-b04947d481f3	Villa F12	2025-12-14 04:00:18-04
019b1b04-3305-71aa-8bf1-16c11dcb4a44	019b1b04-2d0c-72ae-bbea-b04947d481f3	Las Palmas F12	2025-12-14 04:00:18-04
019b1b04-3538-7375-851d-238b7daff98f	019b1b04-2d0c-72ae-bbea-b04947d481f3	Cristo Redentor F12	2025-12-14 04:00:19-04
019b1b04-370c-7110-8e4e-a2a52bccc62b	019b1b04-2d0c-72ae-bbea-b04947d481f3	Norte F12	2025-12-14 04:00:19-04
019b1b04-3cf8-7076-85e3-f382095f662a	019b1b04-3b1e-73f7-9b18-1d55ad45ca47	Las Palmas F13	2025-12-14 04:00:21-04
019b1b04-3ecd-71f2-93ee-8d89c24e4891	019b1b04-3b1e-73f7-9b18-1d55ad45ca47	Urbarí F13	2025-12-14 04:00:21-04
019b1b04-452a-702e-bf84-207224002215	019b1b04-42e2-73f2-8612-e55507c4f3ba	Equipetrol F14	2025-12-14 04:00:23-04
019b1b04-46f8-72dd-850d-69bfea97e87c	019b1b04-42e2-73f2-8612-e55507c4f3ba	Palmasola F14	2025-12-14 04:00:23-04
019b1b04-48e2-71a3-a8d7-f58d09abfbe7	019b1b04-42e2-73f2-8612-e55507c4f3ba	Oeste F14	2025-12-14 04:00:24-04
019b1b04-4b2d-7000-b656-8b561318aa34	019b1b04-42e2-73f2-8612-e55507c4f3ba	Norte F14	2025-12-14 04:00:24-04
019b1b04-513e-736f-acde-86a2536588da	019b1b04-4f69-73f7-b455-274d469a1dbe	Urbarí G1	2025-12-14 04:00:26-04
019b1b04-5573-7223-9d1d-e132a542ae40	019b1b04-4f69-73f7-b455-274d469a1dbe	Satélite Norte G1	2025-12-14 04:00:27-04
019b1b04-574e-7061-b5bd-7b0813e6bcf6	019b1b04-4f69-73f7-b455-274d469a1dbe	Norte G1	2025-12-14 04:00:27-04
019b1b04-5927-71a5-a687-5c47dd2368c1	019b1b04-4f69-73f7-b455-274d469a1dbe	Cristo Redentor G1	2025-12-14 04:00:28-04
019b1b04-5f23-7103-8c1e-40606492535f	019b1b04-5d3e-733a-a177-2bc78f422970	Urbarí G2	2025-12-14 04:00:29-04
019b1b04-616a-731a-9081-275b8e893b5f	019b1b04-5d3e-733a-a177-2bc78f422970	Plan 3000 G2	2025-12-14 04:00:30-04
019b1b04-6361-73f3-85c0-4c37cd834d48	019b1b04-5d3e-733a-a177-2bc78f422970	Este G2	2025-12-14 04:00:31-04
019b1b04-65ab-70dd-bb56-63c21e9a13df	019b1b04-5d3e-733a-a177-2bc78f422970	Cristo Redentor G2	2025-12-14 04:00:31-04
019b1b04-6bad-715d-a438-ab6988e0b301	019b1b04-6969-71ee-85ca-10b94d9a5c4c	Las Palmas G3	2025-12-14 04:00:33-04
019b1b04-6d92-7037-ae5e-f9da12fcbced	019b1b04-6969-71ee-85ca-10b94d9a5c4c	Hamacas G3	2025-12-14 04:00:33-04
019b1b04-73a0-7068-a268-6d989019f022	019b1b04-71b5-720a-9fee-4b87397918dd	Centro G4	2025-12-14 04:00:35-04
019b1b04-75ea-73e4-9542-bf8636612f5d	019b1b04-71b5-720a-9fee-4b87397918dd	Sur G4	2025-12-14 04:00:35-04
019b1b04-77c7-7058-bd6e-b8fb907e54ba	019b1b04-71b5-720a-9fee-4b87397918dd	Palmasola G4	2025-12-14 04:00:36-04
019b1b04-7a1b-71b2-94d3-2b1dae438523	019b1b04-71b5-720a-9fee-4b87397918dd	Satélite Norte G4	2025-12-14 04:00:36-04
019b1b04-7c0c-725b-a5c7-2ed5560a8c79	019b1b04-71b5-720a-9fee-4b87397918dd	Este G4	2025-12-14 04:00:37-04
019b1b04-8270-71c3-983e-f27f79254b6f	019b1b04-8037-71f5-a2c4-0e43a29942c1	Hamacas G5	2025-12-14 04:00:39-04
019b1b04-846b-70bb-a2a2-08ee25beba60	019b1b04-8037-71f5-a2c4-0e43a29942c1	Centro G5	2025-12-14 04:00:39-04
019b1b04-88ac-73fa-96b9-f627b8a303dd	019b1b04-8037-71f5-a2c4-0e43a29942c1	Urbarí G5	2025-12-14 04:00:40-04
019b1b04-8ae2-710c-aabd-1f42b779a44c	019b1b04-8037-71f5-a2c4-0e43a29942c1	Equipetrol G5	2025-12-14 04:00:41-04
019b1b04-911a-71cb-83bf-486518ff4b10	019b1b04-8f13-725e-83d3-bbda0dd5ff9d	Palmasola G6	2025-12-14 04:00:42-04
019b1b04-9356-70e6-93af-cee41616394d	019b1b04-8f13-725e-83d3-bbda0dd5ff9d	Equipetrol G6	2025-12-14 04:00:43-04
019b1b04-9535-7236-b244-5cb36300ea81	019b1b04-8f13-725e-83d3-bbda0dd5ff9d	Satélite Norte G6	2025-12-14 04:00:43-04
019b1b04-970f-71cc-bc86-1f59593db4b5	019b1b04-8f13-725e-83d3-bbda0dd5ff9d	Urbarí G6	2025-12-14 04:00:44-04
019b1b04-994a-7376-9cd4-7a6259d61799	019b1b04-8f13-725e-83d3-bbda0dd5ff9d	Las Palmas G6	2025-12-14 04:00:44-04
019b1b04-9fa5-7141-af72-ec1db44c95c7	019b1b04-9d69-7219-8474-939c8da540ab	Las Palmas G7	2025-12-14 04:00:46-04
019b1b04-a207-71ce-83a2-861c5bd3d04d	019b1b04-9d69-7219-8474-939c8da540ab	Los Pozos G7	2025-12-14 04:00:47-04
019b1b04-a3f3-7232-bd2a-58b97cf404e3	019b1b04-9d69-7219-8474-939c8da540ab	Cristo Redentor G7	2025-12-14 04:00:47-04
019b1b04-a61a-71e5-a967-bd141001160e	019b1b04-9d69-7219-8474-939c8da540ab	Oeste G7	2025-12-14 04:00:48-04
019b1b04-a7f1-7332-a163-792e19d10843	019b1b04-9d69-7219-8474-939c8da540ab	Palmasola G7	2025-12-14 04:00:48-04
019b1b04-adce-72ba-ace2-b0222ae14c4e	019b1b04-abed-7030-9acd-b357f019d8f2	Satélite Norte G8	2025-12-14 04:00:50-04
019b1b04-afbc-735a-a8ef-c470d42cef7d	019b1b04-abed-7030-9acd-b357f019d8f2	Este G8	2025-12-14 04:00:50-04
019b1b04-b836-7144-bad5-385e42595fff	019b1b04-b5de-70fe-9cec-b5600a6027cf	Cristo Redentor G9	2025-12-14 04:00:52-04
019b1b04-ba17-7114-9070-90c08be6c858	019b1b04-b5de-70fe-9cec-b5600a6027cf	Hamacas G9	2025-12-14 04:00:53-04
019b1b04-bc05-729e-a39d-4e1fe334ec4b	019b1b04-b5de-70fe-9cec-b5600a6027cf	Las Palmas G9	2025-12-14 04:00:53-04
019b1b04-be38-7132-be73-a07e893429ca	019b1b04-b5de-70fe-9cec-b5600a6027cf	Urbanización G9	2025-12-14 04:00:54-04
019b1b04-c01c-7106-8a1b-b578d7f9dd1b	019b1b04-b5de-70fe-9cec-b5600a6027cf	Equipetrol G9	2025-12-14 04:00:54-04
019b1b04-c629-706f-ae9a-8b12e6b7ac7e	019b1b04-c446-735f-b54f-a00b683f3188	Centro G10	2025-12-14 04:00:56-04
019b1b04-c812-73b8-aeed-9403ea0346f3	019b1b04-c446-735f-b54f-a00b683f3188	Sur G10	2025-12-14 04:00:56-04
019b1b04-cc50-73d1-b057-33769c1320bc	019b1b04-c446-735f-b54f-a00b683f3188	Las Palmas G10	2025-12-14 04:00:57-04
019b1b04-ce92-73dd-a45e-ce7ac3dc2519	019b1b04-c446-735f-b54f-a00b683f3188	Norte G10	2025-12-14 04:00:58-04
019b1b04-d4a5-7369-816b-670162b63377	019b1b04-d24f-7063-8705-be62894962db	Palmasola G11	2025-12-14 04:01:00-04
019b1b04-d67e-70b2-a4e9-3ed93f939a23	019b1b04-d24f-7063-8705-be62894962db	Cristo Redentor G11	2025-12-14 04:01:00-04
019b1b04-dd21-7270-b549-786e9905a56c	019b1b04-dac1-709e-a90c-2b7b857767c1	Cristo Redentor G12	2025-12-14 04:01:02-04
019b1b04-df18-73ff-a26a-2d0c57b7de80	019b1b04-dac1-709e-a90c-2b7b857767c1	Palmasola G12	2025-12-14 04:01:02-04
019b1b04-e15d-7251-9800-b2a5603002a7	019b1b04-dac1-709e-a90c-2b7b857767c1	Norte G12	2025-12-14 04:01:03-04
019b1b04-e333-7169-87b6-fb3da4f04c34	019b1b04-dac1-709e-a90c-2b7b857767c1	Equipetrol G12	2025-12-14 04:01:03-04
019b1b04-e913-73ca-8a53-0fa8f3780bcd	019b1b04-e73c-72b1-b3fb-9085c88e37de	Cristo Redentor G13	2025-12-14 04:01:05-04
019b1b04-eb05-704c-9972-d6e350c308a1	019b1b04-e73c-72b1-b3fb-9085c88e37de	Este G13	2025-12-14 04:01:05-04
019b1b04-f132-7077-9f47-a5e07bcb8185	019b1b04-ef2d-7199-b4cf-92b368d6424e	Hamacas G14	2025-12-14 04:01:07-04
019b1b04-f3d9-7071-b085-f0edf4ab4c67	019b1b04-ef2d-7199-b4cf-92b368d6424e	Palmasola G14	2025-12-14 04:01:08-04
019b1b04-f61b-70fb-913d-965ad2caf426	019b1b04-ef2d-7199-b4cf-92b368d6424e	Cristo Redentor G14	2025-12-14 04:01:08-04
019b1b04-f7f5-7370-ad60-fbbef43f96fc	019b1b04-ef2d-7199-b4cf-92b368d6424e	Villa G14	2025-12-14 04:01:09-04
019b1b04-fe1a-706f-b120-3195359be434	019b1b04-fc3c-739c-af75-4fa9e4d5f5a1	Los Pozos H1	2025-12-14 04:01:10-04
019b1b05-006f-73fe-8d37-2c9bd512cf0c	019b1b04-fc3c-739c-af75-4fa9e4d5f5a1	Equipetrol H1	2025-12-14 04:01:11-04
019b1b05-0434-736e-be08-914597da706d	019b1b04-fc3c-739c-af75-4fa9e4d5f5a1	Palmasola H1	2025-12-14 04:01:12-04
019b1b05-0a1a-705d-8a17-4fc7b670fdc2	019b1b05-084b-73a1-b8df-4e3c0a9aed7b	Hamacas H2	2025-12-14 04:01:13-04
019b1b05-0c49-725f-ac73-9a83c941a9bf	019b1b05-084b-73a1-b8df-4e3c0a9aed7b	Sur H2	2025-12-14 04:01:14-04
019b1b05-0ff8-7147-af92-dca83f54acdd	019b1b05-084b-73a1-b8df-4e3c0a9aed7b	Norte H2	2025-12-14 04:01:15-04
019b1b05-1257-72a5-854d-a24cc528b848	019b1b05-084b-73a1-b8df-4e3c0a9aed7b	Los Pozos H2	2025-12-14 04:01:15-04
019b1b05-186f-73be-b51c-938e1eea7d6d	019b1b05-1698-7373-9447-5c262e4fb07b	Equipetrol H3	2025-12-14 04:01:17-04
019b1b05-1aa3-7278-8e52-e9dbc30ce421	019b1b05-1698-7373-9447-5c262e4fb07b	Sur H3	2025-12-14 04:01:17-04
019b1b05-2077-7235-ba30-ecbbec46d26c	019b1b05-1e4d-73d3-a47d-99202f27dad6	Cristo Redentor H4	2025-12-14 04:01:19-04
019b1b05-225b-72bc-84cc-4295d75a5277	019b1b05-1e4d-73d3-a47d-99202f27dad6	Equipetrol H4	2025-12-14 04:01:19-04
019b1b05-2431-70e1-8bc8-cb4e5eb4aaa6	019b1b05-1e4d-73d3-a47d-99202f27dad6	Hamacas H4	2025-12-14 04:01:20-04
019b1b05-2a0c-718b-9db5-fa27be47b5d1	019b1b05-2835-73c5-88b3-3d70af34802f	Los Pozos H5	2025-12-14 04:01:21-04
019b1b05-2c3e-7368-8f3e-618d758395c6	019b1b05-2835-73c5-88b3-3d70af34802f	Plan 3000 H5	2025-12-14 04:01:22-04
019b1b05-2e2d-7140-82fe-1c963e195ac4	019b1b05-2835-73c5-88b3-3d70af34802f	Satélite Norte H5	2025-12-14 04:01:22-04
019b1b05-3074-711c-ae61-53dd5df0814d	019b1b05-2835-73c5-88b3-3d70af34802f	Oeste H5	2025-12-14 04:01:23-04
019b1b05-366d-72da-add2-e8d3d21c99c2	019b1b05-3430-7265-b028-1673a7f6484d	Hamacas H6	2025-12-14 04:01:25-04
019b1b05-383f-72c1-8eb6-ceb7f7854128	019b1b05-3430-7265-b028-1673a7f6484d	Norte H6	2025-12-14 04:01:25-04
019b1b05-3a13-72cc-98cf-a9807f9c25cf	019b1b05-3430-7265-b028-1673a7f6484d	Urbanización H6	2025-12-14 04:01:26-04
019b1b05-3c63-7059-a4d3-5f203166a247	019b1b05-3430-7265-b028-1673a7f6484d	Cristo Redentor H6	2025-12-14 04:01:26-04
019b1b05-444e-7156-b618-d23cc38406ce	019b1b05-427e-7187-b847-299a1d2ead23	Norte H7	2025-12-14 04:01:28-04
019b1b05-462b-7210-a21b-6b3aae05edf6	019b1b05-427e-7187-b847-299a1d2ead23	Urbanización H7	2025-12-14 04:01:29-04
019b1b05-4881-70ad-b838-9f4e61fcd003	019b1b05-427e-7187-b847-299a1d2ead23	Hamacas H7	2025-12-14 04:01:29-04
019b1b05-4a73-7106-a277-a1662943652d	019b1b05-427e-7187-b847-299a1d2ead23	Palmasola H7	2025-12-14 04:01:30-04
019b1b05-50df-71be-b2b7-f1ffd7be24f4	019b1b05-4e93-73fd-8e15-2e1c3461d981	Cristo Redentor H8	2025-12-14 04:01:31-04
019b1b05-52b6-7145-80c3-984d3a4306ce	019b1b05-4e93-73fd-8e15-2e1c3461d981	Palmasola H8	2025-12-14 04:01:32-04
019b1b05-5895-7382-be16-e2cf7f63250d	019b1b05-56b8-702d-bd58-ee9e6b1cbe94	Centro H9	2025-12-14 04:01:33-04
019b1b05-5ad3-738f-b61f-dfea9ff0e141	019b1b05-56b8-702d-bd58-ee9e6b1cbe94	Oeste H9	2025-12-14 04:01:34-04
019b1b05-62ac-7242-888f-96e4d117ff9a	019b1b05-60e0-72a8-81bb-34663dce944e	Las Palmas H10	2025-12-14 04:01:36-04
019b1b05-6491-73be-b89e-8a605ffa61d0	019b1b05-60e0-72a8-81bb-34663dce944e	Este H10	2025-12-14 04:01:36-04
019b1b05-66d3-7058-8848-ac11840911ee	019b1b05-60e0-72a8-81bb-34663dce944e	Palmasola H10	2025-12-14 04:01:37-04
019b1b05-6ceb-7043-8c0f-4e3b1dd604ed	019b1b05-6b08-737b-8ab6-4c427cf7cedb	Urbarí H11	2025-12-14 04:01:39-04
019b1b05-6eb0-73f0-af94-f79eccdc3b05	019b1b05-6b08-737b-8ab6-4c427cf7cedb	Cristo Redentor H11	2025-12-14 04:01:39-04
019b1b05-751a-7343-a661-cf48f713fab3	019b1b05-72e9-7015-82af-9e6ad8a0555f	Villa H12	2025-12-14 04:01:41-04
019b1b05-7708-73b2-aa7e-af07d2def4ad	019b1b05-72e9-7015-82af-9e6ad8a0555f	Hamacas H12	2025-12-14 04:01:41-04
019b1b05-78e1-7247-bee9-fbefe1111658	019b1b05-72e9-7015-82af-9e6ad8a0555f	Centro H12	2025-12-14 04:01:42-04
019b1b05-7f45-7288-8a05-aabf76f496f9	019b1b05-7d10-7221-9984-19f2609210d2	Equipetrol H13	2025-12-14 04:01:43-04
019b1b05-8121-721a-859d-308e6418c894	019b1b05-7d10-7221-9984-19f2609210d2	Centro H13	2025-12-14 04:01:44-04
019b1b05-8311-727a-ae1e-ee15827983d5	019b1b05-7d10-7221-9984-19f2609210d2	Oeste H13	2025-12-14 04:01:44-04
019b1b05-89bf-7370-94b0-ba0d409e6dd1	019b1b05-8776-722b-80d2-7ddda939c8af	Villa H14	2025-12-14 04:01:46-04
019b1b05-8b8f-71e3-83cf-c4ea18366d61	019b1b05-8776-722b-80d2-7ddda939c8af	Cristo Redentor H14	2025-12-14 04:01:46-04
019b1b05-8d6f-7386-b503-78833cddad2a	019b1b05-8776-722b-80d2-7ddda939c8af	Urbanización H14	2025-12-14 04:01:47-04
019b1b05-8fd7-71fb-8d77-769a57c7a264	019b1b05-8776-722b-80d2-7ddda939c8af	Sur H14	2025-12-14 04:01:47-04
019b1b05-9620-710d-a623-3971fc234d67	019b1b05-9424-71e6-a941-67523195d2de	Este I1	2025-12-14 04:01:49-04
019b1b05-9869-705c-bc90-304820276680	019b1b05-9424-71e6-a941-67523195d2de	Urbanización I1	2025-12-14 04:01:50-04
019b1b05-9cbb-7067-a52f-018ad247828c	019b1b05-9424-71e6-a941-67523195d2de	Oeste I1	2025-12-14 04:01:51-04
019b1b05-9ed2-719e-9cd6-baaa1d29cf4f	019b1b05-9424-71e6-a941-67523195d2de	Norte I1	2025-12-14 04:01:51-04
019b1b05-a5a2-739f-9cea-9a2d848dcf61	019b1b05-a347-7088-8b20-84fb3e2d1de9	Norte I2	2025-12-14 04:01:53-04
019b1b05-a79f-71f5-8bf7-b636afb41339	019b1b05-a347-7088-8b20-84fb3e2d1de9	Este I2	2025-12-14 04:01:54-04
019b1b05-aa19-7000-94b6-ea7cc20ba445	019b1b05-a347-7088-8b20-84fb3e2d1de9	Urbarí I2	2025-12-14 04:01:54-04
019b1b05-ac1d-704f-94d9-4f56d3627eed	019b1b05-a347-7088-8b20-84fb3e2d1de9	Palmasola I2	2025-12-14 04:01:55-04
019b1b05-aea6-70d5-96d5-0e894b7bf711	019b1b05-a347-7088-8b20-84fb3e2d1de9	Equipetrol I2	2025-12-14 04:01:55-04
019b1b05-b4eb-71e8-b780-e05afd8e4f84	019b1b05-b2f6-7208-8806-f482ce8fd562	Villa I3	2025-12-14 04:01:57-04
019b1b05-b73c-71b6-8911-9b90f7e7859f	019b1b05-b2f6-7208-8806-f482ce8fd562	Centro I3	2025-12-14 04:01:58-04
019b1b05-b924-73f9-a875-d37dd1e9bbd1	019b1b05-b2f6-7208-8806-f482ce8fd562	Los Pozos I3	2025-12-14 04:01:58-04
019b1b05-bd57-7180-8e92-18094559a629	019b1b05-b2f6-7208-8806-f482ce8fd562	Equipetrol I3	2025-12-14 04:01:59-04
019b1b05-c372-72df-814f-9bfcc6ddffa0	019b1b05-c131-7161-bef2-f1793758fbca	Satélite Norte I4	2025-12-14 04:02:01-04
019b1b05-c561-738d-944b-217334d0b92c	019b1b05-c131-7161-bef2-f1793758fbca	Hamacas I4	2025-12-14 04:02:01-04
019b1b05-cb7f-7070-877c-e9eba32181e3	019b1b05-c98d-730c-a3b7-13361675e18e	Cristo Redentor I5	2025-12-14 04:02:03-04
019b1b05-cfd3-71b4-b5f8-90acc1d4686a	019b1b05-c98d-730c-a3b7-13361675e18e	Plan 3000 I5	2025-12-14 04:02:04-04
019b1b05-d210-7278-a4ff-cd0b43272469	019b1b05-c98d-730c-a3b7-13361675e18e	Oeste I5	2025-12-14 04:02:04-04
019b1b05-d851-70a0-85ea-6a1afdb47e3e	019b1b05-d667-70cd-8c6b-ce43bfa1c940	Oeste I6	2025-12-14 04:02:06-04
019b1b05-da9e-71e7-bafa-dd46b863c336	019b1b05-d667-70cd-8c6b-ce43bfa1c940	Centro I6	2025-12-14 04:02:07-04
019b1b05-dc8c-73be-a7bb-b36f006252ab	019b1b05-d667-70cd-8c6b-ce43bfa1c940	Las Palmas I6	2025-12-14 04:02:07-04
019b1b05-de8e-71ff-a8ec-07dd8ce9c28f	019b1b05-d667-70cd-8c6b-ce43bfa1c940	Los Pozos I6	2025-12-14 04:02:08-04
019b1b05-e4a1-7201-b760-dab2f524e36c	019b1b05-e2b2-70c5-8625-c023829a6753	Palmasola I7	2025-12-14 04:02:09-04
019b1b05-e700-72ba-9d98-8a233e702078	019b1b05-e2b2-70c5-8625-c023829a6753	Sur I7	2025-12-14 04:02:10-04
019b1b05-ead5-7097-8c63-8fdb516bd98f	019b1b05-e2b2-70c5-8625-c023829a6753	Urbarí I7	2025-12-14 04:02:11-04
019b1b05-f1c3-7261-b462-accb7efa16de	019b1b05-ef3f-7142-a4ec-95aabc937147	Centro I8	2025-12-14 04:02:13-04
019b1b05-f3c6-7132-a90f-40d90aa780ab	019b1b05-ef3f-7142-a4ec-95aabc937147	Equipetrol I8	2025-12-14 04:02:13-04
019b1b05-fc61-717f-8a64-f89ab297a0fd	019b1b05-fa84-73cc-8e60-05030a991a26	Palmasola I9	2025-12-14 04:02:15-04
019b1b05-fec6-725d-80a5-d5e552d9c951	019b1b05-fa84-73cc-8e60-05030a991a26	Hamacas I9	2025-12-14 04:02:16-04
019b1b06-00bc-720a-bcf6-e6b5a670f584	019b1b05-fa84-73cc-8e60-05030a991a26	Urbanización I9	2025-12-14 04:02:16-04
019b1b06-0754-7069-a443-d5fa75f25009	019b1b06-0505-7192-9854-e9987577741e	Cristo Redentor I10	2025-12-14 04:02:18-04
019b1b06-0b15-7050-bd3b-34e743d1b4d9	019b1b06-0505-7192-9854-e9987577741e	Centro I10	2025-12-14 04:02:19-04
019b1b06-1132-72af-bd62-c4fbbfeb28e6	019b1b06-0f4d-70d0-afe2-a09189793751	Villa I11	2025-12-14 04:02:21-04
019b1b06-138d-7177-9b7b-c57868e50cb0	019b1b06-0f4d-70d0-afe2-a09189793751	Sur I11	2025-12-14 04:02:21-04
019b1b06-17c9-733c-95ef-831ac2508e09	019b1b06-0f4d-70d0-afe2-a09189793751	Hamacas I11	2025-12-14 04:02:22-04
019b1b06-19a0-7329-9fac-3b0dfc152853	019b1b06-0f4d-70d0-afe2-a09189793751	Centro I11	2025-12-14 04:02:23-04
019b1b06-1fa6-73ff-b2a0-ff5f296cca8c	019b1b06-1dcb-7290-a39f-4661ce8a0cb8	Equipetrol I12	2025-12-14 04:02:24-04
019b1b06-218c-70c8-a07b-84c7ad632731	019b1b06-1dcb-7290-a39f-4661ce8a0cb8	Satélite Norte I12	2025-12-14 04:02:25-04
019b1b06-23ed-73bd-accb-dbf64f72bffc	019b1b06-1dcb-7290-a39f-4661ce8a0cb8	Norte I12	2025-12-14 04:02:25-04
019b1b06-29d9-73f1-abad-edb6e1f29edf	019b1b06-2791-7062-ad29-ce1e6a0c891d	Norte I13	2025-12-14 04:02:27-04
019b1b06-2bcc-73bb-8b92-e1065d67f0dc	019b1b06-2791-7062-ad29-ce1e6a0c891d	Centro I13	2025-12-14 04:02:27-04
019b1b06-31f2-70a0-bbf6-a195a5af61cd	019b1b06-3005-7210-8845-9a346e15492d	Sur I14	2025-12-14 04:02:29-04
019b1b06-3468-7105-bd8c-8694d6d32839	019b1b06-3005-7210-8845-9a346e15492d	Las Palmas I14	2025-12-14 04:02:30-04
019b1b06-3653-71c9-a4b6-7caf85b60021	019b1b06-3005-7210-8845-9a346e15492d	Hamacas I14	2025-12-14 04:02:30-04
019b1b06-3873-7068-9b1a-c6b1789888fb	019b1b06-3005-7210-8845-9a346e15492d	Urbanización I14	2025-12-14 04:02:31-04
019b1b06-3a6c-7303-89f0-65a771de55f5	019b1b06-3005-7210-8845-9a346e15492d	Equipetrol I14	2025-12-14 04:02:31-04
019b1b06-407f-7349-894e-5126ac04b15b	019b1b06-3e8e-719e-8779-8ac6b995da23	Oeste J1	2025-12-14 04:02:33-04
019b1b06-42ef-7271-a97d-6d739f5cd438	019b1b06-3e8e-719e-8779-8ac6b995da23	Urbanización J1	2025-12-14 04:02:33-04
019b1b06-44c8-721a-9f90-91f7323cafdf	019b1b06-3e8e-719e-8779-8ac6b995da23	Este J1	2025-12-14 04:02:34-04
019b1b06-4711-726b-97f1-671ec427db1e	019b1b06-3e8e-719e-8779-8ac6b995da23	Norte J1	2025-12-14 04:02:34-04
019b1b06-48f1-7394-89e5-71fc47167f24	019b1b06-3e8e-719e-8779-8ac6b995da23	Palmasola J1	2025-12-14 04:02:35-04
019b1b06-4f98-7262-a997-cd5a519adf4a	019b1b06-4d37-73c8-b750-b1d0f9e54a90	Villa J2	2025-12-14 04:02:37-04
019b1b06-517d-71b5-a681-971326e6245b	019b1b06-4d37-73c8-b750-b1d0f9e54a90	Cristo Redentor J2	2025-12-14 04:02:37-04
019b1b06-579b-71c3-aafb-0f23b811d038	019b1b06-55b8-71e4-9a6b-43f2c4c6b84f	Las Palmas J3	2025-12-14 04:02:39-04
019b1b06-59c5-718c-b8cb-ef742a67f9b5	019b1b06-55b8-71e4-9a6b-43f2c4c6b84f	Equipetrol J3	2025-12-14 04:02:39-04
019b1b06-5fdd-7250-ac69-f1347209ad01	019b1b06-5d8a-73c8-ace3-11998b0a3a0b	Hamacas J4	2025-12-14 04:02:41-04
019b1b06-61ba-70ab-a789-304c5940926b	019b1b06-5d8a-73c8-ace3-11998b0a3a0b	Palmasola J4	2025-12-14 04:02:41-04
019b1b06-639a-7114-847e-788af358bf95	019b1b06-5d8a-73c8-ace3-11998b0a3a0b	Este J4	2025-12-14 04:02:42-04
019b1b06-65e9-71c8-a19b-0dfc7c27a400	019b1b06-5d8a-73c8-ace3-11998b0a3a0b	Equipetrol J4	2025-12-14 04:02:42-04
019b1b06-6dcd-71a5-90ee-7392a9321b28	019b1b06-6bea-70a0-bbec-74c3a605a188	Norte J5	2025-12-14 04:02:44-04
019b1b06-701f-7012-81ef-8e591323957a	019b1b06-6bea-70a0-bbec-74c3a605a188	Villa J5	2025-12-14 04:02:45-04
019b1b06-7200-7378-afa3-ab756e551aed	019b1b06-6bea-70a0-bbec-74c3a605a188	Plan 3000 J5	2025-12-14 04:02:45-04
019b1b06-7819-7258-a3fd-7614c5851a17	019b1b06-7624-73d8-bc4c-5aac69c3122a	Villa J6	2025-12-14 04:02:47-04
019b1b06-7a6e-730e-9d1b-3552ef703be3	019b1b06-7624-73d8-bc4c-5aac69c3122a	Centro J6	2025-12-14 04:02:48-04
019b1b06-7e92-722a-be7d-1c508b8c412e	019b1b06-7624-73d8-bc4c-5aac69c3122a	Satélite Norte J6	2025-12-14 04:02:49-04
019b1b06-8498-7391-887e-ea1392281b36	019b1b06-8259-708d-9368-590c022bbc08	Este J7	2025-12-14 04:02:50-04
019b1b06-867a-7103-8972-a9faddba7e2a	019b1b06-8259-708d-9368-590c022bbc08	Palmasola J7	2025-12-14 04:02:51-04
019b1b06-886a-73c9-be8b-e93db7f73892	019b1b06-8259-708d-9368-590c022bbc08	Oeste J7	2025-12-14 04:02:51-04
019b1b06-8ab2-7385-8502-4dc4d34fde46	019b1b06-8259-708d-9368-590c022bbc08	Sur J7	2025-12-14 04:02:52-04
019b1b06-8c8a-72c8-95bc-ecee4ff309e3	019b1b06-8259-708d-9368-590c022bbc08	Los Pozos J7	2025-12-14 04:02:52-04
019b1b06-9294-705d-9b31-f2df6bb38773	019b1b06-90ac-71ba-af56-9b0237bf030c	Centro J8	2025-12-14 04:02:54-04
019b1b06-94de-73ca-9eb2-6c8280de2462	019b1b06-90ac-71ba-af56-9b0237bf030c	Urbanización J8	2025-12-14 04:02:54-04
019b1b06-9704-715f-a70e-2d4e34b55f04	019b1b06-90ac-71ba-af56-9b0237bf030c	Cristo Redentor J8	2025-12-14 04:02:55-04
019b1b06-98e8-7000-a475-829fa7e18447	019b1b06-90ac-71ba-af56-9b0237bf030c	Oeste J8	2025-12-14 04:02:55-04
019b1b06-9eef-71b0-9a3d-378117a7906a	019b1b06-9d0f-70c5-81b0-3c3bf2286e36	Palmasola J9	2025-12-14 04:02:57-04
019b1b06-a0cb-71c3-a31f-cf04cab25208	019b1b06-9d0f-70c5-81b0-3c3bf2286e36	Sur J9	2025-12-14 04:02:57-04
019b1b06-a309-738e-beab-48d8bdf6d12e	019b1b06-9d0f-70c5-81b0-3c3bf2286e36	Urbarí J9	2025-12-14 04:02:58-04
019b1b06-a923-714a-ac75-8c3544cbce3a	019b1b06-a6c8-7124-8f16-db232fa6ab80	Equipetrol J10	2025-12-14 04:03:00-04
019b1b06-ab05-73b1-bbda-200d55838f17	019b1b06-a6c8-7124-8f16-db232fa6ab80	Los Pozos J10	2025-12-14 04:03:00-04
019b1b06-ad69-7212-8457-1716e6155eff	019b1b06-a6c8-7124-8f16-db232fa6ab80	Villa J10	2025-12-14 04:03:01-04
019b1b06-b34b-7270-8158-d96959eb1e81	019b1b06-b164-70bf-a417-a0122e5c951f	Urbanización J11	2025-12-14 04:03:02-04
019b1b06-b52f-73e5-8645-74b3fd8838f0	019b1b06-b164-70bf-a417-a0122e5c951f	Las Palmas J11	2025-12-14 04:03:03-04
019b1b06-b789-72af-ae1e-de5fbd14377d	019b1b06-b164-70bf-a417-a0122e5c951f	Norte J11	2025-12-14 04:03:03-04
019b1b06-b966-720d-92a1-5a9b64351d7d	019b1b06-b164-70bf-a417-a0122e5c951f	Villa J11	2025-12-14 04:03:04-04
019b1b06-bb58-706d-b611-65f2647f5ed8	019b1b06-b164-70bf-a417-a0122e5c951f	Satélite Norte J11	2025-12-14 04:03:04-04
019b1b06-c153-715b-9960-7f1c15ced140	019b1b06-bf60-72b2-a664-a63df1963b5e	Norte J12	2025-12-14 04:03:06-04
019b1b06-c37e-713c-bd65-730caf6cdf38	019b1b06-bf60-72b2-a664-a63df1963b5e	Urbanización J12	2025-12-14 04:03:06-04
019b1b06-c97a-733e-ae64-6cc764e2971c	019b1b06-c741-7118-b644-21ff68053554	Las Palmas J13	2025-12-14 04:03:08-04
019b1b06-cb59-71e8-950f-b8454dae14a5	019b1b06-c741-7118-b644-21ff68053554	Plan 3000 J13	2025-12-14 04:03:08-04
019b1b06-cd9c-71a1-a207-eca8fc895676	019b1b06-c741-7118-b644-21ff68053554	Los Pozos J13	2025-12-14 04:03:09-04
019b1b06-d572-7382-a6fa-3c85dedb1597	019b1b06-d38c-7124-80fe-85ce8c43272a	Equipetrol J14	2025-12-14 04:03:11-04
019b1b06-d749-7084-89f0-2bc6b5a1279a	019b1b06-d38c-7124-80fe-85ce8c43272a	Los Pozos J14	2025-12-14 04:03:11-04
019b1b06-d987-717a-a08c-4f4afebb1c9f	019b1b06-d38c-7124-80fe-85ce8c43272a	Este J14	2025-12-14 04:03:12-04
019b1b06-db66-731d-92d0-fdec627486cb	019b1b06-d38c-7124-80fe-85ce8c43272a	Cristo Redentor J14	2025-12-14 04:03:12-04
019b1b06-dd4a-73f3-a695-b824c2fbd900	019b1b06-d38c-7124-80fe-85ce8c43272a	Hamacas J14	2025-12-14 04:03:13-04
019b1b06-e344-70c0-a964-fbf9e51e07fa	019b1b06-e172-7010-9610-29899d48df98	Norte K1	2025-12-14 04:03:14-04
019b1b06-e565-7037-9a78-3c78fffb78e9	019b1b06-e172-7010-9610-29899d48df98	Equipetrol K1	2025-12-14 04:03:15-04
019b1b06-e739-720f-9591-e5ef82825a02	019b1b06-e172-7010-9610-29899d48df98	Las Palmas K1	2025-12-14 04:03:15-04
019b1b06-e928-71a2-8780-a22189712aa2	019b1b06-e172-7010-9610-29899d48df98	Los Pozos K1	2025-12-14 04:03:16-04
019b1b06-efa9-710c-9e04-bb89f602a6f4	019b1b06-ed57-7192-b84c-d58cd6730caf	Villa K2	2025-12-14 04:03:18-04
019b1b06-f34f-7057-bee9-12304e02e844	019b1b06-ed57-7192-b84c-d58cd6730caf	Satélite Norte K2	2025-12-14 04:03:18-04
019b1b06-f5a6-7139-a5ae-e87590e0899a	019b1b06-ed57-7192-b84c-d58cd6730caf	Urbanización K2	2025-12-14 04:03:19-04
019b1b06-fbc8-73b1-9232-45c61db04551	019b1b06-f9d7-736d-94f3-034c142e832f	Sur K3	2025-12-14 04:03:21-04
019b1b06-ffee-713c-8cf9-a025675de46a	019b1b06-f9d7-736d-94f3-034c142e832f	Norte K3	2025-12-14 04:03:22-04
019b1b07-0612-7203-8de0-400fb61d671e	019b1b07-0428-7081-9326-d596bd1c842c	Los Pozos K4	2025-12-14 04:03:23-04
019b1b07-0847-710f-8926-f6bea054e6ab	019b1b07-0428-7081-9326-d596bd1c842c	Urbarí K4	2025-12-14 04:03:24-04
019b1b07-0a2b-73be-a446-1def3fc8f7f9	019b1b07-0428-7081-9326-d596bd1c842c	Norte K4	2025-12-14 04:03:24-04
019b1b07-0c05-7008-a464-22fd666304ce	019b1b07-0428-7081-9326-d596bd1c842c	Las Palmas K4	2025-12-14 04:03:25-04
019b1b07-0e4f-7173-9660-bc3c96066315	019b1b07-0428-7081-9326-d596bd1c842c	Equipetrol K4	2025-12-14 04:03:25-04
019b1b07-1450-7116-9287-e1d0b7adc7fd	019b1b07-1214-73b9-a753-50f118f50722	Oeste K5	2025-12-14 04:03:27-04
019b1b07-1623-713a-af39-3722e2ceb277	019b1b07-1214-73b9-a753-50f118f50722	Urbarí K5	2025-12-14 04:03:27-04
019b1b07-180f-7161-990a-af7c39ba576b	019b1b07-1214-73b9-a753-50f118f50722	Sur K5	2025-12-14 04:03:28-04
019b1b07-2081-70d8-b6c9-a8940255de25	019b1b07-1e25-71a6-b701-d0bd2cbd7e1d	Las Palmas K6	2025-12-14 04:03:30-04
019b1b07-2268-7285-98f2-1d183ad3810c	019b1b07-1e25-71a6-b701-d0bd2cbd7e1d	Villa K6	2025-12-14 04:03:31-04
019b1b07-24b1-7374-99d7-dc6c47aef5fe	019b1b07-1e25-71a6-b701-d0bd2cbd7e1d	Sur K6	2025-12-14 04:03:31-04
019b1b07-26a2-732b-abff-3f270e39c4c3	019b1b07-1e25-71a6-b701-d0bd2cbd7e1d	Palmasola K6	2025-12-14 04:03:32-04
019b1b07-28fe-7154-90c8-c8b189c7325b	019b1b07-1e25-71a6-b701-d0bd2cbd7e1d	Plan 3000 K6	2025-12-14 04:03:32-04
019b1b07-2efc-7109-813c-1fe80ec58629	019b1b07-2cbd-71bf-a5a1-292b7c656f19	Urbarí K7	2025-12-14 04:03:34-04
019b1b07-329b-70af-8d3c-605bd275eef1	019b1b07-2cbd-71bf-a5a1-292b7c656f19	Plan 3000 K7	2025-12-14 04:03:35-04
019b1b07-34d3-710c-9b89-5e2e19924e0a	019b1b07-2cbd-71bf-a5a1-292b7c656f19	Villa K7	2025-12-14 04:03:35-04
019b1b07-36a9-727b-a65e-9bd49ac25f4c	019b1b07-2cbd-71bf-a5a1-292b7c656f19	Palmasola K7	2025-12-14 04:03:36-04
019b1b07-3ca8-7029-893b-75b8092a060e	019b1b07-3ace-7117-9bcf-490f6410cfed	Palmasola K8	2025-12-14 04:03:37-04
019b1b07-3eed-72d5-9e85-c52ccf27ff29	019b1b07-3ace-7117-9bcf-490f6410cfed	Hamacas K8	2025-12-14 04:03:38-04
019b1b07-40c0-7335-bc40-b7298e324bf6	019b1b07-3ace-7117-9bcf-490f6410cfed	Los Pozos K8	2025-12-14 04:03:38-04
019b1b07-46dc-7179-b0bf-097f0bb20bc8	019b1b07-44f9-7199-ac4f-4fd239445e70	Cristo Redentor K9	2025-12-14 04:03:40-04
019b1b07-4f2f-73c5-ad47-7f4e339a22d6	019b1b07-4cee-70c6-a1ba-225a76fc7cfd	Urbanización K10	2025-12-14 04:03:42-04
019b1b07-5110-730b-8e07-3da91c88cca8	019b1b07-4cee-70c6-a1ba-225a76fc7cfd	Norte K10	2025-12-14 04:03:42-04
019b1b07-52ea-72d7-9fee-06ac2cd043e5	019b1b07-4cee-70c6-a1ba-225a76fc7cfd	Oeste K10	2025-12-14 04:03:43-04
019b1b07-570c-70f7-aae3-3b5e9bf29f79	019b1b07-4cee-70c6-a1ba-225a76fc7cfd	Plan 3000 K10	2025-12-14 04:03:44-04
019b1b07-5d1c-72f6-8410-e3011cfb6c0f	019b1b07-5b40-708c-bc97-dad916399c87	Centro K11	2025-12-14 04:03:46-04
019b1b07-5f6f-73ef-8f89-92b25fac853c	019b1b07-5b40-708c-bc97-dad916399c87	Este K11	2025-12-14 04:03:46-04
019b1b07-6159-7198-adb7-51d5a14832ce	019b1b07-5b40-708c-bc97-dad916399c87	Plan 3000 K11	2025-12-14 04:03:47-04
019b1b07-67f9-73e8-a7d5-e9d44be17fdb	019b1b07-65ac-720f-8025-25cea0e703e5	Villa K12	2025-12-14 04:03:48-04
019b1b07-69e2-7091-a318-9e96659aa9d5	019b1b07-65ac-720f-8025-25cea0e703e5	Cristo Redentor K12	2025-12-14 04:03:49-04
019b1b07-703e-7149-ae0b-de3e7863277a	019b1b07-6e61-70f3-bebc-d6195f5229b1	Hamacas K13	2025-12-14 04:03:50-04
019b1b07-7294-7130-82ed-ce218bd48dbc	019b1b07-6e61-70f3-bebc-d6195f5229b1	Equipetrol K13	2025-12-14 04:03:51-04
019b1b07-78b6-719e-ba5b-808dc080b747	019b1b07-76c1-731e-a5d5-447fb8f79ba6	Los Pozos K14	2025-12-14 04:03:53-04
019b1b07-7b00-7381-9a6a-6172e8464a24	019b1b07-76c1-731e-a5d5-447fb8f79ba6	Sur K14	2025-12-14 04:03:53-04
019b1b07-7eca-726c-8c4e-4cfaad07c3ed	019b1b07-76c1-731e-a5d5-447fb8f79ba6	Palmasola K14	2025-12-14 04:03:54-04
019b1b07-8711-7033-96ee-4c2992ae3398	019b1b07-853e-708c-bfee-447d882dc7c5	Centro L1	2025-12-14 04:03:56-04
019b1b07-88ff-7052-b801-bc438b095491	019b1b07-853e-708c-bfee-447d882dc7c5	Plan 3000 L1	2025-12-14 04:03:57-04
019b1b07-8b47-7144-ba45-dfe6033ccd91	019b1b07-853e-708c-bfee-447d882dc7c5	Norte L1	2025-12-14 04:03:57-04
019b1b07-8d14-71ee-a151-ea905663e30b	019b1b07-853e-708c-bfee-447d882dc7c5	Villa L1	2025-12-14 04:03:58-04
019b1b07-8ef9-73bd-82dd-d0ab4b6fea72	019b1b07-853e-708c-bfee-447d882dc7c5	Este L1	2025-12-14 04:03:58-04
019b1b07-95bf-70ee-8b61-fdf963a32d92	019b1b07-931f-70e3-80bb-0e8a9cb3601c	Sur L2	2025-12-14 04:04:00-04
019b1b07-980e-735e-8f79-14cc7ac14970	019b1b07-931f-70e3-80bb-0e8a9cb3601c	Oeste L2	2025-12-14 04:04:01-04
019b1b07-9e41-72b5-9a7f-dc9f1f9c7595	019b1b07-9c4d-709a-9806-3d88c99b5b64	Palmasola L3	2025-12-14 04:04:02-04
019b1b07-a08c-709a-a785-09ece199f91b	019b1b07-9c4d-709a-9806-3d88c99b5b64	Hamacas L3	2025-12-14 04:04:03-04
019b1b07-a278-7202-a92c-2fb81c69cf66	019b1b07-9c4d-709a-9806-3d88c99b5b64	Este L3	2025-12-14 04:04:03-04
019b1b07-a4b8-7025-b308-398022a96e86	019b1b07-9c4d-709a-9806-3d88c99b5b64	Satélite Norte L3	2025-12-14 04:04:04-04
019b1b07-ac97-716b-bde9-df7d7c46f21e	019b1b07-aab5-70e7-93fd-945f5f2bbe9e	Equipetrol L4	2025-12-14 04:04:06-04
019b1b07-af17-7160-bee2-9165d797ac39	019b1b07-aab5-70e7-93fd-945f5f2bbe9e	Villa L4	2025-12-14 04:04:07-04
019b1b07-b0f2-7011-8aa8-09bd2622f720	019b1b07-aab5-70e7-93fd-945f5f2bbe9e	Plan 3000 L4	2025-12-14 04:04:07-04
019b1b07-b32e-7323-bc4d-e04125b2f802	019b1b07-aab5-70e7-93fd-945f5f2bbe9e	Palmasola L4	2025-12-14 04:04:08-04
019b1b07-b95d-72b0-95c7-db01307d2c58	019b1b07-b75e-73ef-befe-a15908c3fe23	Plan 3000 L5	2025-12-14 04:04:09-04
019b1b07-bb99-70aa-aacf-288d0ead6458	019b1b07-b75e-73ef-befe-a15908c3fe23	Cristo Redentor L5	2025-12-14 04:04:10-04
019b1b07-bf49-722f-aaa8-880acca4736e	019b1b07-b75e-73ef-befe-a15908c3fe23	Satélite Norte L5	2025-12-14 04:04:11-04
019b1b07-c547-7234-844a-8dc1f84b5eee	019b1b07-c367-71d9-8d78-9544e21b9723	Hamacas L6	2025-12-14 04:04:12-04
019b1b07-c780-71d7-9329-2db8d4ddb2a2	019b1b07-c367-71d9-8d78-9544e21b9723	Las Palmas L6	2025-12-14 04:04:13-04
019b1b07-c962-73ab-b83a-fb2391dc7176	019b1b07-c367-71d9-8d78-9544e21b9723	Centro L6	2025-12-14 04:04:13-04
019b1b07-cb32-72ad-9d8c-0c8c786a5c89	019b1b07-c367-71d9-8d78-9544e21b9723	Palmasola L6	2025-12-14 04:04:14-04
019b1b07-cd68-7156-a275-48a1c04a8847	019b1b07-c367-71d9-8d78-9544e21b9723	Plan 3000 L6	2025-12-14 04:04:14-04
019b1b07-d380-704c-82e5-6803122e03ec	019b1b07-d138-7082-9013-e2d74695e2be	Este L7	2025-12-14 04:04:16-04
019b1b07-d569-7153-9ed6-c6ef2dec4d3d	019b1b07-d138-7082-9013-e2d74695e2be	Norte L7	2025-12-14 04:04:16-04
019b1b07-db72-70ec-8b26-14c00b1f3ab3	019b1b07-d992-71d7-b7d3-272ef49174a3	Palmasola L8	2025-12-14 04:04:18-04
019b1b07-dd5e-733a-b9aa-6c8cd9476d90	019b1b07-d992-71d7-b7d3-272ef49174a3	Cristo Redentor L8	2025-12-14 04:04:18-04
019b1b07-e3cd-73f9-afab-69afda7f7c90	019b1b07-e18b-732d-8b72-b7b2a2a50e18	Cristo Redentor L9	2025-12-14 04:04:20-04
019b1b07-e59d-71c1-8d42-5191f746d73e	019b1b07-e18b-732d-8b72-b7b2a2a50e18	Hamacas L9	2025-12-14 04:04:21-04
019b1b07-e78f-7311-837a-f00a8fa633d1	019b1b07-e18b-732d-8b72-b7b2a2a50e18	Las Palmas L9	2025-12-14 04:04:21-04
019b1b07-ea47-7394-905b-743e56c22e70	019b1b07-e18b-732d-8b72-b7b2a2a50e18	Satélite Norte L9	2025-12-14 04:04:22-04
019b1b07-ec7e-73de-90dd-e4cd8f778dd0	019b1b07-e18b-732d-8b72-b7b2a2a50e18	Sur L9	2025-12-14 04:04:22-04
019b1b07-f261-713f-ae0e-25f69be1ea43	019b1b07-f037-701d-bbf0-1bc28af2c0da	Plan 3000 L10	2025-12-14 04:04:24-04
019b1b07-f440-710e-b816-a65dd09f8efa	019b1b07-f037-701d-bbf0-1bc28af2c0da	Oeste L10	2025-12-14 04:04:24-04
019b1b07-f62b-7144-89cb-e73aedcdce19	019b1b07-f037-701d-bbf0-1bc28af2c0da	Este L10	2025-12-14 04:04:25-04
019b1b07-f87e-7034-9ab7-b932a26301bd	019b1b07-f037-701d-bbf0-1bc28af2c0da	Cristo Redentor L10	2025-12-14 04:04:25-04
019b1b07-feb7-7205-864c-321471b9829a	019b1b07-fc5e-71db-952a-7afb885b0168	Palmasola L11	2025-12-14 04:04:27-04
019b1b08-00a1-7339-aeaf-02f778491f01	019b1b07-fc5e-71db-952a-7afb885b0168	Este L11	2025-12-14 04:04:27-04
019b1b08-027e-7008-911d-60113dadce7b	019b1b07-fc5e-71db-952a-7afb885b0168	Centro L11	2025-12-14 04:04:28-04
019b1b08-0875-72ac-ae73-d3ed1b5a1ed3	019b1b08-069f-7193-bde3-69643c8a5088	Urbarí L12	2025-12-14 04:04:29-04
019b1b08-0cb1-72a3-93b6-5a5b67e3038f	019b1b08-069f-7193-bde3-69643c8a5088	Palmasola L12	2025-12-14 04:04:31-04
019b1b08-0f19-71d1-a821-a5e436cd9e2a	019b1b08-069f-7193-bde3-69643c8a5088	Centro L12	2025-12-14 04:04:31-04
019b1b08-1520-701f-8628-e0f15e89c3eb	019b1b08-133a-7057-b23e-7bd07c0a89e1	Satélite Norte L13	2025-12-14 04:04:33-04
019b1b08-1763-713f-9b79-57145d22a418	019b1b08-133a-7057-b23e-7bd07c0a89e1	Palmasola L13	2025-12-14 04:04:33-04
019b1b08-1d81-7200-8233-111e0309016c	019b1b08-1b2f-729f-b301-bf498e5f78cd	Villa L14	2025-12-14 04:04:35-04
019b1b08-21bd-7350-8845-be31ea202217	019b1b08-1b2f-729f-b301-bf498e5f78cd	Oeste L14	2025-12-14 04:04:36-04
019b1b08-2394-7062-8f00-fc70e07234ff	019b1b08-1b2f-729f-b301-bf498e5f78cd	Centro L14	2025-12-14 04:04:36-04
019b1b08-29b0-719f-ad7e-b352fdf81d3e	019b1b08-27b8-7047-b95d-f93a453705ab	Plan 3000 M1	2025-12-14 04:04:38-04
019b1b08-2c11-71fc-a36c-2a40d394eea7	019b1b08-27b8-7047-b95d-f93a453705ab	Palmasola M1	2025-12-14 04:04:39-04
019b1b08-31dc-7308-aa9d-65c0bf0a004b	019b1b08-2fa7-71e0-8ea1-4af868596e9c	Los Pozos M2	2025-12-14 04:04:40-04
019b1b08-33b1-734f-9a2c-7a9ae9450710	019b1b08-2fa7-71e0-8ea1-4af868596e9c	Oeste M2	2025-12-14 04:04:41-04
019b1b08-37cd-7391-8a11-606c16d3fa82	019b1b08-2fa7-71e0-8ea1-4af868596e9c	Este M2	2025-12-14 04:04:42-04
019b1b08-405f-7371-a4ca-6303452d5249	019b1b08-3e22-73b2-af91-2e8d7e3183f2	Sur M3	2025-12-14 04:04:44-04
019b1b08-4234-7272-a352-2a989694c277	019b1b08-3e22-73b2-af91-2e8d7e3183f2	Los Pozos M3	2025-12-14 04:04:44-04
019b1b08-4849-7252-b9d4-a888e9f2d927	019b1b08-4673-71aa-9844-feab48b5ddd8	Plan 3000 M4	2025-12-14 04:04:46-04
019b1b08-4a90-72cc-86c0-f1a6f865d590	019b1b08-4673-71aa-9844-feab48b5ddd8	Hamacas M4	2025-12-14 04:04:46-04
019b1b08-507a-73d0-b7fd-e1761dd44077	019b1b08-4e4e-7214-a70f-93591e738cd1	Los Pozos M5	2025-12-14 04:04:48-04
019b1b08-525f-7336-96ce-0e49f16f7e19	019b1b08-4e4e-7214-a70f-93591e738cd1	Villa M5	2025-12-14 04:04:48-04
019b1b08-5440-7278-ba63-7e5549eb1d0d	019b1b08-4e4e-7214-a70f-93591e738cd1	Este M5	2025-12-14 04:04:49-04
019b1b08-5a52-7275-88c4-84e3a9eae297	019b1b08-5862-71e7-aa47-178f0426c4a9	Palmasola M6	2025-12-14 04:04:50-04
019b1b08-5c8a-7056-92ec-8ffa07ea287f	019b1b08-5862-71e7-aa47-178f0426c4a9	Las Palmas M6	2025-12-14 04:04:51-04
019b1b08-5e89-7044-aaba-92dbfdbc0bba	019b1b08-5862-71e7-aa47-178f0426c4a9	Satélite Norte M6	2025-12-14 04:04:51-04
019b1b08-64a5-73d8-a2c1-c8b4dc58fbb9	019b1b08-62ab-7222-9376-9f161f53a238	Satélite Norte M7	2025-12-14 04:04:53-04
019b1b08-6700-7043-b2b2-47c7bd802f0d	019b1b08-62ab-7222-9376-9f161f53a238	Las Palmas M7	2025-12-14 04:04:54-04
019b1b08-68f9-71ef-8f91-c75c693d3332	019b1b08-62ab-7222-9376-9f161f53a238	Oeste M7	2025-12-14 04:04:54-04
019b1b08-6b3c-7002-9706-3b73bc6cfcb7	019b1b08-62ab-7222-9376-9f161f53a238	Los Pozos M7	2025-12-14 04:04:55-04
019b1b08-713e-7154-86e9-47f964b53f40	019b1b08-6efd-7226-8ba4-701583fa74fa	Las Palmas M8	2025-12-14 04:04:56-04
019b1b08-732d-7164-876e-cba16eb5493d	019b1b08-6efd-7226-8ba4-701583fa74fa	Equipetrol M8	2025-12-14 04:04:57-04
019b1b08-7565-72d4-879d-05daa1d81805	019b1b08-6efd-7226-8ba4-701583fa74fa	Centro M8	2025-12-14 04:04:57-04
019b1b08-7914-73a8-a947-da273bd78b41	019b1b08-6efd-7226-8ba4-701583fa74fa	Urbanización M8	2025-12-14 04:04:58-04
019b1b08-7f07-70e8-82d3-8e4e452aa086	019b1b08-7d27-71d2-8367-879cb4c71d42	Sur M9	2025-12-14 04:05:00-04
019b1b08-815c-703d-8880-76ef1a967587	019b1b08-7d27-71d2-8367-879cb4c71d42	Urbarí M9	2025-12-14 04:05:00-04
019b1b08-85ac-710b-acc3-4b0e02c84858	019b1b08-7d27-71d2-8367-879cb4c71d42	Los Pozos M9	2025-12-14 04:05:01-04
019b1b08-8e04-73fd-baa1-878cca4516c8	019b1b08-8bc8-721e-bfdd-1e2dbbe06bb6	Satélite Norte M10	2025-12-14 04:05:04-04
019b1b08-8ffa-73a9-8839-e5fb37c03c72	019b1b08-8bc8-721e-bfdd-1e2dbbe06bb6	Los Pozos M10	2025-12-14 04:05:04-04
019b1b08-9226-733c-8a73-ccbb3950d315	019b1b08-8bc8-721e-bfdd-1e2dbbe06bb6	Norte M10	2025-12-14 04:05:05-04
019b1b08-941c-7276-a5d5-1303e6e3ee01	019b1b08-8bc8-721e-bfdd-1e2dbbe06bb6	Centro M10	2025-12-14 04:05:05-04
019b1b08-95ee-721b-8a7b-f09323ab2f70	019b1b08-8bc8-721e-bfdd-1e2dbbe06bb6	Sur M10	2025-12-14 04:05:06-04
019b1b08-9bdb-708e-9d09-f22d0de3ddea	019b1b08-99fa-7087-9825-ddde7eaf7f42	Los Pozos M11	2025-12-14 04:05:07-04
019b1b08-9e26-71a0-9a32-42a57987e8ae	019b1b08-99fa-7087-9825-ddde7eaf7f42	Las Palmas M11	2025-12-14 04:05:08-04
019b1b08-a008-7128-a37b-4aadd78941aa	019b1b08-99fa-7087-9825-ddde7eaf7f42	Plan 3000 M11	2025-12-14 04:05:08-04
019b1b08-a60a-7052-a32d-4576ae9f4eb2	019b1b08-a427-7280-b2ab-0ae1edfe054d	Hamacas M12	2025-12-14 04:05:10-04
019b1b08-a7ee-7275-b6e4-ae3fa1ffeed0	019b1b08-a427-7280-b2ab-0ae1edfe054d	Centro M12	2025-12-14 04:05:10-04
019b1b08-aa40-710a-9b76-3ccc52ac119c	019b1b08-a427-7280-b2ab-0ae1edfe054d	Villa M12	2025-12-14 04:05:11-04
019b1b08-ac28-7393-a3f5-ab5a5094492e	019b1b08-a427-7280-b2ab-0ae1edfe054d	Este M12	2025-12-14 04:05:11-04
019b1b08-adfe-7085-9c47-2f3efa8cdb54	019b1b08-a427-7280-b2ab-0ae1edfe054d	Oeste M12	2025-12-14 04:05:12-04
019b1b08-b496-7281-9fb9-2157aa336b0f	019b1b08-b23b-702d-a8a7-f1480df8f7f4	Equipetrol M13	2025-12-14 04:05:14-04
019b1b08-b674-73c7-90b0-54bd35d155e0	019b1b08-b23b-702d-a8a7-f1480df8f7f4	Norte M13	2025-12-14 04:05:14-04
019b1b08-bac9-7053-b1c6-4dedc5e7e45b	019b1b08-b23b-702d-a8a7-f1480df8f7f4	Las Palmas M13	2025-12-14 04:05:15-04
019b1b08-c144-7126-a2a7-269916cd3f2b	019b1b08-bf09-72da-98d0-4d09f28b1d64	Equipetrol M14	2025-12-14 04:05:17-04
019b1b08-c323-70f8-b42c-a1373111c750	019b1b08-bf09-72da-98d0-4d09f28b1d64	Palmasola M14	2025-12-14 04:05:17-04
019b1b08-c50e-722f-b704-ad7a04ff2d0f	019b1b08-bf09-72da-98d0-4d09f28b1d64	Centro M14	2025-12-14 04:05:18-04
019b1b08-c74a-7156-8cfe-b0390a3c60ed	019b1b08-bf09-72da-98d0-4d09f28b1d64	Villa M14	2025-12-14 04:05:18-04
019b1b08-cd30-7219-b4e6-9159711402ee	019b1b08-cafd-7026-8c90-508e3e958e9e	Norte N1	2025-12-14 04:05:20-04
019b1b08-cf09-7080-815e-f97ba09221f7	019b1b08-cafd-7026-8c90-508e3e958e9e	Este N1	2025-12-14 04:05:20-04
019b1b08-d314-73bc-9180-abf4e67e290e	019b1b08-cafd-7026-8c90-508e3e958e9e	Satélite Norte N1	2025-12-14 04:05:21-04
019b1b08-d94a-7297-bcf4-4245cab65d78	019b1b08-d74c-71f3-99fc-f17080d5f410	Villa N2	2025-12-14 04:05:23-04
019b1b08-db90-732a-9f85-f27eaadbf2a9	019b1b08-d74c-71f3-99fc-f17080d5f410	Las Palmas N2	2025-12-14 04:05:23-04
019b1b08-dd64-718d-82d2-81ae1307c53e	019b1b08-d74c-71f3-99fc-f17080d5f410	Norte N2	2025-12-14 04:05:24-04
019b1b08-e33e-72a9-a80d-b04a31d4703e	019b1b08-e16c-7280-99e8-f4d130c61ef4	Hamacas N3	2025-12-14 04:05:25-04
019b1b08-e512-718b-802a-382b0bc8e8a3	019b1b08-e16c-7280-99e8-f4d130c61ef4	Los Pozos N3	2025-12-14 04:05:26-04
019b1b08-eb94-729b-a52b-c517ff331da3	019b1b08-e95b-73dd-96d6-7aff730cd37c	Este N4	2025-12-14 04:05:28-04
019b1b08-ed88-7106-93ad-f93a7b7cd4b8	019b1b08-e95b-73dd-96d6-7aff730cd37c	Las Palmas N4	2025-12-14 04:05:28-04
019b1b08-ef69-70c6-a64c-c62029949047	019b1b08-e95b-73dd-96d6-7aff730cd37c	Palmasola N4	2025-12-14 04:05:29-04
019b1b08-f1b0-72c6-9987-43f7a01530cf	019b1b08-e95b-73dd-96d6-7aff730cd37c	Los Pozos N4	2025-12-14 04:05:29-04
019b1b08-f7b5-7304-97c7-08ead14004ee	019b1b08-f5d4-717f-beb5-e73f491557e5	Los Pozos N5	2025-12-14 04:05:31-04
019b1b08-fa10-7354-af16-ec8118e28eea	019b1b08-f5d4-717f-beb5-e73f491557e5	Norte N5	2025-12-14 04:05:31-04
019b1b08-fbf4-70a9-ad98-26eb27981b0b	019b1b08-f5d4-717f-beb5-e73f491557e5	Las Palmas N5	2025-12-14 04:05:32-04
019b1b09-01ee-716c-b039-42158476178c	019b1b08-fffc-71f2-b402-e781d9263d2b	Plan 3000 N6	2025-12-14 04:05:33-04
019b1b09-0433-7077-a1fe-804111032e2e	019b1b08-fffc-71f2-b402-e781d9263d2b	Cristo Redentor N6	2025-12-14 04:05:34-04
019b1b09-0a39-700b-8222-442936f4c6a8	019b1b09-07d7-7273-85d7-0dd18e244491	Urbarí N7	2025-12-14 04:05:35-04
019b1b09-0c16-7365-8883-e33673c109a7	019b1b09-07d7-7273-85d7-0dd18e244491	Los Pozos N7	2025-12-14 04:05:36-04
019b1b09-129a-71b2-aef7-45e3b2dcfd02	019b1b09-1041-7135-ad92-fd50872ccc94	Palmasola N8	2025-12-14 04:05:38-04
019b1b09-1482-70d4-9b27-bc8c7a687bf1	019b1b09-1041-7135-ad92-fd50872ccc94	Cristo Redentor N8	2025-12-14 04:05:38-04
019b1b09-16b0-7165-9c15-f7600d8b1e6b	019b1b09-1041-7135-ad92-fd50872ccc94	Villa N8	2025-12-14 04:05:39-04
019b1b09-1ca5-7149-aa59-b3b35c5ce469	019b1b09-1a62-73d2-8e07-752a1eb24363	Villa N9	2025-12-14 04:05:40-04
019b1b09-1e89-70bb-8a84-faed783f4ede	019b1b09-1a62-73d2-8e07-752a1eb24363	Este N9	2025-12-14 04:05:41-04
019b1b09-20d8-7267-8d96-f8a8d94583eb	019b1b09-1a62-73d2-8e07-752a1eb24363	Urbarí N9	2025-12-14 04:05:41-04
019b1b09-22bb-7224-b71d-8b3e6d4948cb	019b1b09-1a62-73d2-8e07-752a1eb24363	Las Palmas N9	2025-12-14 04:05:42-04
019b1b09-28c6-72a4-b7ea-52c35ff784e1	019b1b09-26d2-7254-9a77-f5660f169c02	Los Pozos N10	2025-12-14 04:05:43-04
019b1b09-2b0a-720d-96a1-a00c5b45e0f5	019b1b09-26d2-7254-9a77-f5660f169c02	Las Palmas N10	2025-12-14 04:05:44-04
019b1b09-30e2-708d-a512-027e4c9e6804	019b1b09-2eb2-708e-909e-236d0af8ddaa	Equipetrol N11	2025-12-14 04:05:45-04
019b1b09-32c0-7065-85c4-c4b1488b023f	019b1b09-2eb2-708e-909e-236d0af8ddaa	Palmasola N11	2025-12-14 04:05:46-04
019b1b09-34e6-7257-99db-76985c8972c6	019b1b09-2eb2-708e-909e-236d0af8ddaa	Plan 3000 N11	2025-12-14 04:05:46-04
019b1b09-371a-73d4-aca2-3590add903d4	019b1b09-2eb2-708e-909e-236d0af8ddaa	Cristo Redentor N11	2025-12-14 04:05:47-04
019b1b09-3d1c-703c-b383-6fe209b26b68	019b1b09-3add-702c-9dad-2216b7526fb4	Sur N12	2025-12-14 04:05:48-04
019b1b09-3ee2-7376-a1ab-44adf8b39f05	019b1b09-3add-702c-9dad-2216b7526fb4	Urbarí N12	2025-12-14 04:05:49-04
019b1b09-44ed-722a-b275-8d025daeae47	019b1b09-4316-72aa-9717-73a1ff35ce65	Urbarí N13	2025-12-14 04:05:50-04
019b1b09-474a-7134-ad15-a6419c9be125	019b1b09-4316-72aa-9717-73a1ff35ce65	Centro N13	2025-12-14 04:05:51-04
019b1b09-492f-7244-acda-0948ce2eca4f	019b1b09-4316-72aa-9717-73a1ff35ce65	Equipetrol N13	2025-12-14 04:05:52-04
019b1b09-4b84-709c-98cc-de7e764c3250	019b1b09-4316-72aa-9717-73a1ff35ce65	Sur N13	2025-12-14 04:05:52-04
019b1b09-4d5e-7397-a5f3-d96669880281	019b1b09-4316-72aa-9717-73a1ff35ce65	Plan 3000 N13	2025-12-14 04:05:53-04
019b1b09-53ed-71e6-82b8-a503e546681d	019b1b09-519a-73dd-92c1-d322d0c4613d	Cristo Redentor N14	2025-12-14 04:05:54-04
019b1b09-55d5-73f3-b471-d20a13f216eb	019b1b09-519a-73dd-92c1-d322d0c4613d	Hamacas N14	2025-12-14 04:05:55-04
019b1b09-5bbd-7310-bac1-4624e95c44b5	019b1b09-59dd-7218-ad8c-77be0c0cf6b1	Palmasola O1	2025-12-14 04:05:56-04
019b1b09-5df2-72a5-9121-a23559b105b7	019b1b09-59dd-7218-ad8c-77be0c0cf6b1	Plan 3000 O1	2025-12-14 04:05:57-04
019b1b09-5fd7-72f7-9c5c-5f43c49f2ccc	019b1b09-59dd-7218-ad8c-77be0c0cf6b1	Villa O1	2025-12-14 04:05:57-04
019b1b09-61bc-7260-984a-5a3fbb41a674	019b1b09-59dd-7218-ad8c-77be0c0cf6b1	Urbanización O1	2025-12-14 04:05:58-04
019b1b09-63e6-72ac-84dc-ad6e09036cd0	019b1b09-59dd-7218-ad8c-77be0c0cf6b1	Urbarí O1	2025-12-14 04:05:58-04
019b1b09-697e-7282-b989-1cd0f307f97d	019b1b09-6797-7359-ab4c-af90c4886143	Oeste O2	2025-12-14 04:06:00-04
019b1b09-6bc5-71d2-bf1c-a97c4fdaf50e	019b1b09-6797-7359-ab4c-af90c4886143	Hamacas O2	2025-12-14 04:06:00-04
019b1b09-71d9-7178-95c9-b05a44ee5b54	019b1b09-6ff9-7085-95aa-118ae36a0bec	Hamacas O3	2025-12-14 04:06:02-04
019b1b09-73c9-7065-b1aa-3c684aa0ecda	019b1b09-6ff9-7085-95aa-118ae36a0bec	Urbanización O3	2025-12-14 04:06:02-04
019b1b09-7600-7207-ac00-bb764b8b40bb	019b1b09-6ff9-7085-95aa-118ae36a0bec	Las Palmas O3	2025-12-14 04:06:03-04
019b1b09-77e5-736e-be0f-ca9607764656	019b1b09-6ff9-7085-95aa-118ae36a0bec	Villa O3	2025-12-14 04:06:04-04
019b1b09-7a27-7240-bea0-97553acfe656	019b1b09-6ff9-7085-95aa-118ae36a0bec	Sur O3	2025-12-14 04:06:04-04
019b1b09-8023-72be-b899-58f693a84eba	019b1b09-7de2-71d4-ba50-cf7e4662ae84	Las Palmas O4	2025-12-14 04:06:06-04
019b1b09-820b-726c-afa2-3029b960167f	019b1b09-7de2-71d4-ba50-cf7e4662ae84	Sur O4	2025-12-14 04:06:06-04
019b1b09-8805-721c-85b8-231c22de121b	019b1b09-8622-71d3-adf9-bbec0e976f37	Sur O5	2025-12-14 04:06:08-04
019b1b09-8a08-701e-be9d-21a87eca9e48	019b1b09-8622-71d3-adf9-bbec0e976f37	Centro O5	2025-12-14 04:06:08-04
019b1b09-8e0a-707e-9790-761bf9c11530	019b1b09-8622-71d3-adf9-bbec0e976f37	Las Palmas O5	2025-12-14 04:06:09-04
019b1b09-8fed-720c-aa8b-1842881689f6	019b1b09-8622-71d3-adf9-bbec0e976f37	Equipetrol O5	2025-12-14 04:06:10-04
019b1b09-9654-70b6-96f1-bffa5841f07a	019b1b09-9411-723a-ae40-e733e4b4e275	Equipetrol O6	2025-12-14 04:06:11-04
019b1b09-9828-70a7-9e86-a005a3e12788	019b1b09-9411-723a-ae40-e733e4b4e275	Los Pozos O6	2025-12-14 04:06:12-04
019b1b09-9a0c-7143-ab23-50bf32f6deec	019b1b09-9411-723a-ae40-e733e4b4e275	Hamacas O6	2025-12-14 04:06:12-04
019b1b09-9fe2-736f-92fd-b90357969bd0	019b1b09-9e10-71ca-b0bf-1f28fcec3a1a	Palmasola O7	2025-12-14 04:06:14-04
019b1b09-a20b-73bb-895c-235fff9378e3	019b1b09-9e10-71ca-b0bf-1f28fcec3a1a	Urbarí O7	2025-12-14 04:06:14-04
019b1b09-a3da-7363-ad8e-c215adbab6e8	019b1b09-9e10-71ca-b0bf-1f28fcec3a1a	Los Pozos O7	2025-12-14 04:06:15-04
019b1b09-aba8-71a7-bafe-7bdacf8f15db	019b1b09-a9d8-7336-b90e-f37ff0ecfdeb	Los Pozos O8	2025-12-14 04:06:17-04
019b1b09-add8-7185-a567-cab9ebc08f34	019b1b09-a9d8-7336-b90e-f37ff0ecfdeb	Norte O8	2025-12-14 04:06:17-04
019b1b09-afba-7168-afd0-9239af6f1ab8	019b1b09-a9d8-7336-b90e-f37ff0ecfdeb	Este O8	2025-12-14 04:06:18-04
019b1b09-b5e3-70c1-98b5-483e2325ea79	019b1b09-b3fe-7384-923f-40498594705c	Urbarí O9	2025-12-14 04:06:19-04
019b1b09-b813-709e-ae28-9e59f41262ee	019b1b09-b3fe-7384-923f-40498594705c	Palmasola O9	2025-12-14 04:06:20-04
019b1b09-b9f5-7377-9992-b5a8887e488e	019b1b09-b3fe-7384-923f-40498594705c	Norte O9	2025-12-14 04:06:20-04
019b1b09-bbce-72df-8888-de43e3930870	019b1b09-b3fe-7384-923f-40498594705c	Las Palmas O9	2025-12-14 04:06:21-04
019b1b09-be26-7025-b1f3-9a93e460a652	019b1b09-b3fe-7384-923f-40498594705c	Oeste O9	2025-12-14 04:06:21-04
019b1b09-c437-70a9-b2f7-c8347d8da9ae	019b1b09-c1e4-70c5-90eb-445abd712dec	Plan 3000 O10	2025-12-14 04:06:23-04
019b1b09-c61f-716c-908d-11cc09c315a8	019b1b09-c1e4-70c5-90eb-445abd712dec	Norte O10	2025-12-14 04:06:24-04
019b1b09-ce5c-73bc-88fe-ac15e691e812	019b1b09-cc13-70ca-88d9-29bdbf6cfb73	Urbarí O11	2025-12-14 04:06:26-04
019b1b09-d2a4-70d3-98e7-4d527d611674	019b1b09-cc13-70ca-88d9-29bdbf6cfb73	Los Pozos O11	2025-12-14 04:06:27-04
019b1b09-d8a5-7207-b80b-5afe4cdb5de8	019b1b09-d6cb-7029-a5a7-42aeb20be928	Norte O12	2025-12-14 04:06:28-04
019b1b09-da95-707f-aa95-d84b5bc5093f	019b1b09-d6cb-7029-a5a7-42aeb20be928	Hamacas O12	2025-12-14 04:06:29-04
019b1b09-dcfa-7210-bc38-5d1b825f9ba4	019b1b09-d6cb-7029-a5a7-42aeb20be928	Cristo Redentor O12	2025-12-14 04:06:29-04
019b1b09-dedb-7227-9199-b105406947d8	019b1b09-d6cb-7029-a5a7-42aeb20be928	Villa O12	2025-12-14 04:06:30-04
019b1b09-e0b9-7063-a781-f776cf31f75b	019b1b09-d6cb-7029-a5a7-42aeb20be928	Las Palmas O12	2025-12-14 04:06:30-04
019b1b09-e775-70c1-a953-00b929f8a9c2	019b1b09-e525-7062-813b-78ab0a0d3542	Satélite Norte O13	2025-12-14 04:06:32-04
019b1b09-e950-708d-b4d6-2f1bf0ee2cc9	019b1b09-e525-7062-813b-78ab0a0d3542	Urbarí O13	2025-12-14 04:06:33-04
019b1b09-eb24-70bd-84f8-fd7094a9632e	019b1b09-e525-7062-813b-78ab0a0d3542	Oeste O13	2025-12-14 04:06:33-04
019b1b09-f1ae-7282-9192-e7d7ca1e8a24	019b1b09-ef60-711d-bb54-04c99f29b151	Palmasola O14	2025-12-14 04:06:35-04
019b1b09-f563-7156-8008-e3c96fe2d69f	019b1b09-ef60-711d-bb54-04c99f29b151	Urbanización O14	2025-12-14 04:06:36-04
019b1b09-f7a9-73ae-9380-60130be2440c	019b1b09-ef60-711d-bb54-04c99f29b151	Centro O14	2025-12-14 04:06:36-04
019b1b09-f99e-70a3-824a-840306af0441	019b1b09-ef60-711d-bb54-04c99f29b151	Hamacas O14	2025-12-14 04:06:37-04
019b1b09-ffea-7181-8efc-baefa1fdceba	019b1b09-fe00-708b-b81a-ff5c9193b6d7	Los Pozos P1	2025-12-14 04:06:38-04
019b1b0a-0222-71f5-85c7-0722da92f815	019b1b09-fe00-708b-b81a-ff5c9193b6d7	Centro P1	2025-12-14 04:06:39-04
019b1b0a-03eb-72d2-b81b-ff09176af0cf	019b1b09-fe00-708b-b81a-ff5c9193b6d7	Sur P1	2025-12-14 04:06:39-04
019b1b0a-05bd-72c3-9e45-35c66284021b	019b1b09-fe00-708b-b81a-ff5c9193b6d7	Oeste P1	2025-12-14 04:06:40-04
019b1b0a-0805-7028-9b8a-1ec1febc5247	019b1b09-fe00-708b-b81a-ff5c9193b6d7	Norte P1	2025-12-14 04:06:40-04
019b1b0a-0e32-733a-a292-15779e4c9112	019b1b0a-0bc3-72de-bc06-46b81f34b9a3	Sur P2	2025-12-14 04:06:42-04
019b1b0a-1006-7322-8e1d-3080578b53aa	019b1b0a-0bc3-72de-bc06-46b81f34b9a3	Centro P2	2025-12-14 04:06:42-04
019b1b0a-123e-7033-ad5a-4954a4334f01	019b1b0a-0bc3-72de-bc06-46b81f34b9a3	Villa P2	2025-12-14 04:06:43-04
019b1b0a-15ff-73f7-abf2-a4487fa370a4	019b1b0a-0bc3-72de-bc06-46b81f34b9a3	Las Palmas P2	2025-12-14 04:06:44-04
019b1b0a-1c91-721d-b34f-ccf133c175f8	019b1b0a-1a3f-73aa-9741-4f9e81f3a718	Centro P3	2025-12-14 04:06:46-04
019b1b0a-2506-7324-90f3-e8cd12567640	019b1b0a-22b1-7040-8f5f-d505f4294be3	Hamacas P4	2025-12-14 04:06:48-04
019b1b0a-26e0-72be-b8fe-7b0a375cad7a	019b1b0a-22b1-7040-8f5f-d505f4294be3	Satélite Norte P4	2025-12-14 04:06:48-04
019b1b0a-2cf9-7221-8804-ff672784da98	019b1b0a-2b19-7323-9197-1f12627e5dc7	Norte P5	2025-12-14 04:06:50-04
019b1b0a-3574-70c8-b2b9-01f27789c0e5	019b1b0a-339d-72c7-9c4d-36735219ff1f	Este P6	2025-12-14 04:06:52-04
019b1b0a-37c0-7301-824f-5d06eccfafe3	019b1b0a-339d-72c7-9c4d-36735219ff1f	Urbanización P6	2025-12-14 04:06:53-04
019b1b0a-399d-7318-9b32-3f58237d64a7	019b1b0a-339d-72c7-9c4d-36735219ff1f	Villa P6	2025-12-14 04:06:53-04
019b1b0a-3b76-71eb-b8a5-5d94053e63fd	019b1b0a-339d-72c7-9c4d-36735219ff1f	Norte P6	2025-12-14 04:06:54-04
019b1b0a-3db8-716d-ae32-cec53eae4538	019b1b0a-339d-72c7-9c4d-36735219ff1f	Palmasola P6	2025-12-14 04:06:54-04
019b1b0a-43e3-704f-9ecd-a1cc4184d1c9	019b1b0a-41f4-7390-a5d3-3924b836163c	Oeste P7	2025-12-14 04:06:56-04
019b1b0a-4627-715e-83a9-1d3c5bc7da4e	019b1b0a-41f4-7390-a5d3-3924b836163c	Urbarí P7	2025-12-14 04:06:56-04
019b1b0a-4801-7254-850a-6592af654d60	019b1b0a-41f4-7390-a5d3-3924b836163c	Palmasola P7	2025-12-14 04:06:57-04
019b1b0a-4fcc-72c3-9a84-7b2a7018bdc4	019b1b0a-4dde-71f0-a56a-c527af5d073f	Norte P8	2025-12-14 04:06:59-04
019b1b0a-5204-700c-87a3-4f199ee6b76d	019b1b0a-4dde-71f0-a56a-c527af5d073f	Oeste P8	2025-12-14 04:06:59-04
019b1b0a-53e6-725e-aa00-5b9b33083062	019b1b0a-4dde-71f0-a56a-c527af5d073f	Urbarí P8	2025-12-14 04:07:00-04
019b1b0a-562f-725b-9d46-633899986fcb	019b1b0a-4dde-71f0-a56a-c527af5d073f	Los Pozos P8	2025-12-14 04:07:00-04
019b1b0a-5815-72c6-b8f5-2da7a18458ed	019b1b0a-4dde-71f0-a56a-c527af5d073f	Plan 3000 P8	2025-12-14 04:07:01-04
019b1b0a-5e10-7068-a1c5-503a7d405e4e	019b1b0a-5c20-7334-a04d-bac5ae3d81c1	Satélite Norte P9	2025-12-14 04:07:02-04
019b1b0a-6086-71dd-81fe-e1e7a922b369	019b1b0a-5c20-7334-a04d-bac5ae3d81c1	Urbanización P9	2025-12-14 04:07:03-04
019b1b0a-6264-7020-b675-d599fbaf399b	019b1b0a-5c20-7334-a04d-bac5ae3d81c1	Las Palmas P9	2025-12-14 04:07:04-04
019b1b0a-68f4-7046-8529-2a36daafef4e	019b1b0a-66a2-70b7-8c00-faac7f852aaf	Urbarí P10	2025-12-14 04:07:05-04
019b1b0a-6ac6-730f-9a43-77a0f8d5debf	019b1b0a-66a2-70b7-8c00-faac7f852aaf	Palmasola P10	2025-12-14 04:07:06-04
019b1b0a-70c3-7159-a167-349441705867	019b1b0a-6ed4-7282-8b45-2f0d1647f01a	Urbarí P11	2025-12-14 04:07:07-04
019b1b0a-7307-7289-8392-4193386c3106	019b1b0a-6ed4-7282-8b45-2f0d1647f01a	Las Palmas P11	2025-12-14 04:07:08-04
019b1b0a-74ed-73f6-b905-7c75ffdffd9d	019b1b0a-6ed4-7282-8b45-2f0d1647f01a	Villa P11	2025-12-14 04:07:08-04
019b1b0a-76df-73a3-a665-ac7457de75c7	019b1b0a-6ed4-7282-8b45-2f0d1647f01a	Los Pozos P11	2025-12-14 04:07:09-04
019b1b0a-791e-7268-a2ef-3a64e74a6eb7	019b1b0a-6ed4-7282-8b45-2f0d1647f01a	Palmasola P11	2025-12-14 04:07:09-04
019b1b0a-7f62-7219-ba7a-f8c6584b4a70	019b1b0a-7d69-70f4-91d0-01366385c360	Las Palmas P12	2025-12-14 04:07:11-04
019b1b0a-83b9-731e-a5c7-c41b446e2eff	019b1b0a-7d69-70f4-91d0-01366385c360	Cristo Redentor P12	2025-12-14 04:07:12-04
019b1b0a-85ec-70fb-9adf-af3eeda697ad	019b1b0a-7d69-70f4-91d0-01366385c360	Villa P12	2025-12-14 04:07:13-04
019b1b0a-8c14-72c7-9585-630f6773bbd9	019b1b0a-89ca-72ae-84fa-7e24b5d1a79c	Cristo Redentor P13	2025-12-14 04:07:14-04
019b1b0a-8df3-7033-8d37-b538e3879980	019b1b0a-89ca-72ae-84fa-7e24b5d1a79c	Oeste P13	2025-12-14 04:07:15-04
019b1b0a-947e-72aa-9f2a-14d29ebf2639	019b1b0a-921f-7165-812a-c60b48c707a1	Palmasola P14	2025-12-14 04:07:16-04
019b1b0a-9662-72bf-992b-52e8b21e6650	019b1b0a-921f-7165-812a-c60b48c707a1	Urbanización P14	2025-12-14 04:07:17-04
019b1b0a-984d-7126-a62b-a8aa7287311c	019b1b0a-921f-7165-812a-c60b48c707a1	Satélite Norte P14	2025-12-14 04:07:17-04
019b1b0a-9a9c-72f2-bb73-6f99f5d592b5	019b1b0a-921f-7165-812a-c60b48c707a1	Centro P14	2025-12-14 04:07:18-04
019b1b0a-a08b-7323-b373-d50aebd741e8	019b1b0a-9e4f-73f7-bb06-08bf7cd3a647	Satélite Norte Q1	2025-12-14 04:07:19-04
019b1b0a-a27c-70cc-b2e0-4b09c74f67e6	019b1b0a-9e4f-73f7-bb06-08bf7cd3a647	Urbarí Q1	2025-12-14 04:07:20-04
019b1b0a-a772-71f9-bc76-d3b86f842579	019b1b0a-9e4f-73f7-bb06-08bf7cd3a647	Norte Q1	2025-12-14 04:07:21-04
019b1b0a-ad70-71dd-aece-4ac1734833c9	019b1b0a-ab42-7088-944a-f38a6458b3ed	Las Palmas Q2	2025-12-14 04:07:23-04
019b1b0a-af42-73cb-a005-c24933922d70	019b1b0a-ab42-7088-944a-f38a6458b3ed	Este Q2	2025-12-14 04:07:23-04
019b1b0a-b603-71ad-9084-e3546c6c7bbf	019b1b0a-b3d0-7376-9d55-e0987dc5d0f1	Cristo Redentor Q3	2025-12-14 04:07:25-04
019b1b0a-b7fa-7010-802d-9bb294aeda0d	019b1b0a-b3d0-7376-9d55-e0987dc5d0f1	Este Q3	2025-12-14 04:07:25-04
019b1b0a-bffb-702f-878c-1c405a1cd1f0	019b1b0a-be0c-7072-9b24-a063507b46c6	Villa Q4	2025-12-14 04:07:27-04
019b1b0a-c26a-72d3-ae5b-3f9d6e4cbaab	019b1b0a-be0c-7072-9b24-a063507b46c6	Urbarí Q4	2025-12-14 04:07:28-04
019b1b0a-c888-728b-9214-49dcde963399	019b1b0a-c69d-73f9-a995-a9d0bc42e676	Hamacas Q5	2025-12-14 04:07:30-04
019b1b0a-cacd-734e-8fad-3e4327727eef	019b1b0a-c69d-73f9-a995-a9d0bc42e676	Urbarí Q5	2025-12-14 04:07:30-04
019b1b0a-ccae-708b-97d6-0445bd8fc93d	019b1b0a-c69d-73f9-a995-a9d0bc42e676	Las Palmas Q5	2025-12-14 04:07:31-04
019b1b0a-ce9b-7319-93b6-0399fb41f3f8	019b1b0a-c69d-73f9-a995-a9d0bc42e676	Sur Q5	2025-12-14 04:07:31-04
019b1b0a-d0e6-7343-94a6-7380249b25bd	019b1b0a-c69d-73f9-a995-a9d0bc42e676	Equipetrol Q5	2025-12-14 04:07:32-04
019b1b0a-d6ee-70da-9c45-ea538efe531e	019b1b0a-d4b4-70b2-91d0-ae1619fd462c	Sur Q6	2025-12-14 04:07:33-04
019b1b0a-d8f2-71fc-aab8-ae08c4dbde87	019b1b0a-d4b4-70b2-91d0-ae1619fd462c	Las Palmas Q6	2025-12-14 04:07:34-04
019b1b0a-db26-7088-86e5-a54a4acdf0e0	019b1b0a-d4b4-70b2-91d0-ae1619fd462c	Oeste Q6	2025-12-14 04:07:34-04
019b1b0a-e301-7260-93f2-043b3f11f419	019b1b0a-e112-73c1-aa05-fa1d64e03173	Las Palmas Q7	2025-12-14 04:07:36-04
019b1b0a-e54a-7133-a75e-f8ab5e68d29a	019b1b0a-e112-73c1-aa05-fa1d64e03173	Hamacas Q7	2025-12-14 04:07:37-04
019b1b0a-eda0-7353-9821-4bfd7f61a9e3	019b1b0a-eb60-7214-89bf-debb4cfb68ca	Norte Q8	2025-12-14 04:07:39-04
019b1b0a-ef7a-7322-b943-13f60d3c7d0b	019b1b0a-eb60-7214-89bf-debb4cfb68ca	Oeste Q8	2025-12-14 04:07:40-04
019b1b0a-f159-7186-ba47-cddd8fe373be	019b1b0a-eb60-7214-89bf-debb4cfb68ca	Satélite Norte Q8	2025-12-14 04:07:40-04
019b1b0a-f384-7288-af31-fec1ccb9956b	019b1b0a-eb60-7214-89bf-debb4cfb68ca	Este Q8	2025-12-14 04:07:41-04
019b1b0a-f56f-721b-a1e5-a4a47aa48ab7	019b1b0a-eb60-7214-89bf-debb4cfb68ca	Equipetrol Q8	2025-12-14 04:07:41-04
019b1b0a-fba6-7237-9106-604efac0692e	019b1b0a-f9a4-7343-aecf-f92d6af37a2d	Oeste Q9	2025-12-14 04:07:43-04
019b1b0a-fd8d-7067-a99a-ba89df4a3d54	019b1b0a-f9a4-7343-aecf-f92d6af37a2d	Las Palmas Q9	2025-12-14 04:07:43-04
019b1b0b-0390-701b-b402-92049158bbb5	019b1b0b-01b3-7326-a550-22901cd4b964	Villa Q10	2025-12-14 04:07:45-04
019b1b0b-05c4-7229-affb-2cce2df14b0e	019b1b0b-01b3-7326-a550-22901cd4b964	Urbarí Q10	2025-12-14 04:07:45-04
019b1b0b-07a9-72df-a540-a986fb8cee59	019b1b0b-01b3-7326-a550-22901cd4b964	Palmasola Q10	2025-12-14 04:07:46-04
019b1b0b-0ec9-722b-b960-c3865a073e16	019b1b0b-0bdd-7033-959f-ee017b0d5110	Cristo Redentor Q11	2025-12-14 04:07:48-04
019b1b0b-10fb-7143-b63e-f1bb0ddb2ee1	019b1b0b-0bdd-7033-959f-ee017b0d5110	Equipetrol Q11	2025-12-14 04:07:48-04
019b1b0b-12dd-7192-a6ed-188d90fea5c6	019b1b0b-0bdd-7033-959f-ee017b0d5110	Sur Q11	2025-12-14 04:07:49-04
019b1b0b-18c0-7061-a683-97acd59e2ed1	019b1b0b-16eb-7102-88aa-e6b565b303c4	Satélite Norte Q12	2025-12-14 04:07:50-04
019b1b0b-1a9e-728b-80a8-4e0ab3d84c51	019b1b0b-16eb-7102-88aa-e6b565b303c4	Oeste Q12	2025-12-14 04:07:51-04
019b1b0b-1cce-724e-b111-e87fc1b47eb9	019b1b0b-16eb-7102-88aa-e6b565b303c4	Hamacas Q12	2025-12-14 04:07:51-04
019b1b0b-22e9-731b-942a-e0491c5fe636	019b1b0b-20ab-7108-8e31-00155ba46752	Los Pozos Q13	2025-12-14 04:07:53-04
019b1b0b-24d3-739b-9af0-2e47f85614ea	019b1b0b-20ab-7108-8e31-00155ba46752	Cristo Redentor Q13	2025-12-14 04:07:53-04
019b1b0b-2913-7340-b316-0dfe815a299d	019b1b0b-20ab-7108-8e31-00155ba46752	Plan 3000 Q13	2025-12-14 04:07:54-04
019b1b0b-2f12-72c5-8ce2-775cb0c1ae59	019b1b0b-2d40-71e2-a19b-f5ba3053057c	Palmasola Q14	2025-12-14 04:07:56-04
019b1b0b-30ec-73f4-80d9-8c72c8b607a9	019b1b0b-2d40-71e2-a19b-f5ba3053057c	Oeste Q14	2025-12-14 04:07:56-04
019b1b0b-32bf-731d-8b2f-f71792bff3cc	019b1b0b-2d40-71e2-a19b-f5ba3053057c	Hamacas Q14	2025-12-14 04:07:57-04
\.


--
-- Data for Name: cuadrantes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cuadrantes (id, codigo, fila, columna, nombre, lat_min, lat_max, lng_min, lng_max, centro_lat, centro_lng, ciudad, zona, activo, created_at) FROM stdin;
019b1b00-9857-73c4-953e-b4fb25064c7b	A1	A	1	Cuadrante A1	-17.70900000	-17.70000000	-63.25000000	-63.23900000	-17.70450000	-63.24450000	Santa Cruz de la Sierra	Norte	t	2025-12-14 03:56:22-04
019b1b00-a6aa-705b-8142-3cca0af4e82c	A2	A	2	Cuadrante A2	-17.70900000	-17.70000000	-63.23900000	-63.22800000	-17.70450000	-63.23350000	Santa Cruz de la Sierra	Norte	t	2025-12-14 03:56:26-04
019b1b00-b16a-706d-87e5-79fca6695fb6	A3	A	3	Cuadrante A3	-17.70900000	-17.70000000	-63.22800000	-63.21700000	-17.70450000	-63.22250000	Santa Cruz de la Sierra	Norte	t	2025-12-14 03:56:28-04
019b1b00-b939-7209-8855-194cca25a5c5	A4	A	4	Cuadrante A4	-17.70900000	-17.70000000	-63.21700000	-63.20600000	-17.70450000	-63.21150000	Santa Cruz de la Sierra	Norte	t	2025-12-14 03:56:30-04
019b1b00-c7e6-70b9-88d9-705531f22ad7	A5	A	5	Cuadrante A5	-17.70900000	-17.70000000	-63.20600000	-63.19500000	-17.70450000	-63.20050000	Santa Cruz de la Sierra	Norte	t	2025-12-14 03:56:34-04
019b1b00-d262-71ad-84d0-0c0ce3feb1ed	A6	A	6	Cuadrante A6	-17.70900000	-17.70000000	-63.19500000	-63.18400000	-17.70450000	-63.18950000	Santa Cruz de la Sierra	Norte	t	2025-12-14 03:56:37-04
019b1b00-dcb3-7092-a87d-b169a9cfb4d7	A7	A	7	Cuadrante A7	-17.70900000	-17.70000000	-63.18400000	-63.17300000	-17.70450000	-63.17850000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:56:39-04
019b1b00-e4bf-7111-b308-ad3f370ef625	A8	A	8	Cuadrante A8	-17.70900000	-17.70000000	-63.17300000	-63.16200000	-17.70450000	-63.16750000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:56:42-04
019b1b00-ed27-7041-b0eb-5190ce4d7a4d	A9	A	9	Cuadrante A9	-17.70900000	-17.70000000	-63.16200000	-63.15100000	-17.70450000	-63.15650000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:56:44-04
019b1b00-f751-72c6-b3e0-30172deceae6	A10	A	10	Cuadrante A10	-17.70900000	-17.70000000	-63.15100000	-63.14000000	-17.70450000	-63.14550000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:56:46-04
019b1b01-057f-7280-88f4-30881489c569	A11	A	11	Cuadrante A11	-17.70900000	-17.70000000	-63.14000000	-63.12900000	-17.70450000	-63.13450000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:56:50-04
019b1b01-0e27-71bc-bcd1-09162be77279	A12	A	12	Cuadrante A12	-17.70900000	-17.70000000	-63.12900000	-63.11800000	-17.70450000	-63.12350000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:56:52-04
019b1b01-1638-739d-947e-f1c95c6fb5c5	A13	A	13	Cuadrante A13	-17.70900000	-17.70000000	-63.11800000	-63.10700000	-17.70450000	-63.11250000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:56:54-04
019b1b01-2033-70af-947a-7131287a0a2f	A14	A	14	Cuadrante A14	-17.70900000	-17.70000000	-63.10700000	-63.09600000	-17.70450000	-63.10150000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:56:57-04
019b1b01-2e21-732d-b525-5df98e2991fb	B1	B	1	Cuadrante B1	-17.71800000	-17.70900000	-63.25000000	-63.23900000	-17.71350000	-63.24450000	Santa Cruz de la Sierra	Norte	t	2025-12-14 03:57:00-04
019b1b01-3867-7188-9ae8-e17343566ead	B2	B	2	Cuadrante B2	-17.71800000	-17.70900000	-63.23900000	-63.22800000	-17.71350000	-63.23350000	Santa Cruz de la Sierra	Norte	t	2025-12-14 03:57:03-04
019b1b01-46f7-72bd-b5f9-37fac7ece605	B3	B	3	Cuadrante B3	-17.71800000	-17.70900000	-63.22800000	-63.21700000	-17.71350000	-63.22250000	Santa Cruz de la Sierra	Norte	t	2025-12-14 03:57:07-04
019b1b01-52b2-7076-bdbb-c36f0f6a6db4	B4	B	4	Cuadrante B4	-17.71800000	-17.70900000	-63.21700000	-63.20600000	-17.71350000	-63.21150000	Santa Cruz de la Sierra	Norte	t	2025-12-14 03:57:10-04
019b1b01-6088-714a-9914-2845c26a18c5	B5	B	5	Cuadrante B5	-17.71800000	-17.70900000	-63.20600000	-63.19500000	-17.71350000	-63.20050000	Santa Cruz de la Sierra	Norte	t	2025-12-14 03:57:13-04
019b1b01-6886-70e1-b422-0f1c1f2976d8	B6	B	6	Cuadrante B6	-17.71800000	-17.70900000	-63.19500000	-63.18400000	-17.71350000	-63.18950000	Santa Cruz de la Sierra	Norte	t	2025-12-14 03:57:15-04
019b1b01-7473-722c-9b60-fc717b1f031f	B7	B	7	Cuadrante B7	-17.71800000	-17.70900000	-63.18400000	-63.17300000	-17.71350000	-63.17850000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:57:18-04
019b1b01-8091-730e-80d4-e3909fc53ff9	B8	B	8	Cuadrante B8	-17.71800000	-17.70900000	-63.17300000	-63.16200000	-17.71350000	-63.16750000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:57:21-04
019b1b01-8c69-7105-a356-cdf8bde5d0c3	B9	B	9	Cuadrante B9	-17.71800000	-17.70900000	-63.16200000	-63.15100000	-17.71350000	-63.15650000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:57:24-04
019b1b01-9b18-70b9-a84f-c0a7f1346478	B10	B	10	Cuadrante B10	-17.71800000	-17.70900000	-63.15100000	-63.14000000	-17.71350000	-63.14550000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:57:28-04
019b1b01-a554-72c9-bff3-fb18488b9997	B11	B	11	Cuadrante B11	-17.71800000	-17.70900000	-63.14000000	-63.12900000	-17.71350000	-63.13450000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:57:31-04
019b1b01-adab-713c-8ed8-ef3bdaf014ae	B12	B	12	Cuadrante B12	-17.71800000	-17.70900000	-63.12900000	-63.11800000	-17.71350000	-63.12350000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:57:33-04
019b1b01-babf-70a0-bf41-728e9604929f	B13	B	13	Cuadrante B13	-17.71800000	-17.70900000	-63.11800000	-63.10700000	-17.71350000	-63.11250000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:57:36-04
019b1b01-c6c5-7395-b99c-b7ca7c2f992a	B14	B	14	Cuadrante B14	-17.71800000	-17.70900000	-63.10700000	-63.09600000	-17.71350000	-63.10150000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:57:39-04
019b1b01-d382-7140-9329-54b105e6ef00	C1	C	1	Cuadrante C1	-17.72700000	-17.71800000	-63.25000000	-63.23900000	-17.72250000	-63.24450000	Santa Cruz de la Sierra	Norte	t	2025-12-14 03:57:43-04
019b1b01-dfa0-7325-95df-f0dc6d01dfd4	C2	C	2	Cuadrante C2	-17.72700000	-17.71800000	-63.23900000	-63.22800000	-17.72250000	-63.23350000	Santa Cruz de la Sierra	Norte	t	2025-12-14 03:57:46-04
019b1b01-e7d6-71d7-9812-dd307461585f	C3	C	3	Cuadrante C3	-17.72700000	-17.71800000	-63.22800000	-63.21700000	-17.72250000	-63.22250000	Santa Cruz de la Sierra	Norte	t	2025-12-14 03:57:48-04
019b1b01-efa9-73bf-940e-4a3240fbc80b	C4	C	4	Cuadrante C4	-17.72700000	-17.71800000	-63.21700000	-63.20600000	-17.72250000	-63.21150000	Santa Cruz de la Sierra	Norte	t	2025-12-14 03:57:50-04
019b1b01-fa4e-73a5-9c6b-a9995f059279	C5	C	5	Cuadrante C5	-17.72700000	-17.71800000	-63.20600000	-63.19500000	-17.72250000	-63.20050000	Santa Cruz de la Sierra	Norte	t	2025-12-14 03:57:53-04
019b1b02-089d-72e2-8b55-cd3e13565924	C6	C	6	Cuadrante C6	-17.72700000	-17.71800000	-63.19500000	-63.18400000	-17.72250000	-63.18950000	Santa Cruz de la Sierra	Norte	t	2025-12-14 03:57:56-04
019b1b02-1487-721c-a35a-06b2c069ffea	C7	C	7	Cuadrante C7	-17.72700000	-17.71800000	-63.18400000	-63.17300000	-17.72250000	-63.17850000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:57:59-04
019b1b02-2096-719a-87be-1f95727fa3f4	C8	C	8	Cuadrante C8	-17.72700000	-17.71800000	-63.17300000	-63.16200000	-17.72250000	-63.16750000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:58:02-04
019b1b02-2c98-71a1-b044-6e6d6619c18f	C9	C	9	Cuadrante C9	-17.72700000	-17.71800000	-63.16200000	-63.15100000	-17.72250000	-63.15650000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:58:05-04
019b1b02-3437-718b-b15b-9bb0d66d3959	C10	C	10	Cuadrante C10	-17.72700000	-17.71800000	-63.15100000	-63.14000000	-17.72250000	-63.14550000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:58:07-04
019b1b02-3e56-7183-af6c-810c087bea77	C11	C	11	Cuadrante C11	-17.72700000	-17.71800000	-63.14000000	-63.12900000	-17.72250000	-63.13450000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:58:10-04
019b1b02-4c5b-7386-a42e-b7a654c437cb	C12	C	12	Cuadrante C12	-17.72700000	-17.71800000	-63.12900000	-63.11800000	-17.72250000	-63.12350000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:58:14-04
019b1b02-54a4-7129-b945-2f0f91ef3ac4	C13	C	13	Cuadrante C13	-17.72700000	-17.71800000	-63.11800000	-63.10700000	-17.72250000	-63.11250000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:58:16-04
019b1b02-6087-723a-b4d6-1bceceb78e7a	C14	C	14	Cuadrante C14	-17.72700000	-17.71800000	-63.10700000	-63.09600000	-17.72250000	-63.10150000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:58:19-04
019b1b02-6ec7-71e9-b3c6-37a189794ef5	D1	D	1	Cuadrante D1	-17.73600000	-17.72700000	-63.25000000	-63.23900000	-17.73150000	-63.24450000	Santa Cruz de la Sierra	Norte	t	2025-12-14 03:58:22-04
019b1b02-7ad0-73d1-a4ba-41d13fb59b81	D2	D	2	Cuadrante D2	-17.73600000	-17.72700000	-63.23900000	-63.22800000	-17.73150000	-63.23350000	Santa Cruz de la Sierra	Norte	t	2025-12-14 03:58:26-04
019b1b02-84f7-70fa-89ba-38671bf623c8	D3	D	3	Cuadrante D3	-17.73600000	-17.72700000	-63.22800000	-63.21700000	-17.73150000	-63.22250000	Santa Cruz de la Sierra	Norte	t	2025-12-14 03:58:28-04
019b1b02-8d79-7300-836a-a9ecea7bd834	D4	D	4	Cuadrante D4	-17.73600000	-17.72700000	-63.21700000	-63.20600000	-17.73150000	-63.21150000	Santa Cruz de la Sierra	Norte	t	2025-12-14 03:58:30-04
019b1b02-99c0-7087-89c9-2cb704681f8c	D5	D	5	Cuadrante D5	-17.73600000	-17.72700000	-63.20600000	-63.19500000	-17.73150000	-63.20050000	Santa Cruz de la Sierra	Norte	t	2025-12-14 03:58:33-04
019b1b02-a222-72e3-88dd-c0864f7a8599	D6	D	6	Cuadrante D6	-17.73600000	-17.72700000	-63.19500000	-63.18400000	-17.73150000	-63.18950000	Santa Cruz de la Sierra	Norte	t	2025-12-14 03:58:36-04
019b1b02-ae2b-73b0-b239-c4be7d32653a	D7	D	7	Cuadrante D7	-17.73600000	-17.72700000	-63.18400000	-63.17300000	-17.73150000	-63.17850000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:58:39-04
019b1b02-ba42-73ce-bd98-debe8d7ed4ac	D8	D	8	Cuadrante D8	-17.73600000	-17.72700000	-63.17300000	-63.16200000	-17.73150000	-63.16750000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:58:42-04
019b1b02-c48c-729d-bafc-4021c1564694	D9	D	9	Cuadrante D9	-17.73600000	-17.72700000	-63.16200000	-63.15100000	-17.73150000	-63.15650000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:58:44-04
019b1b02-ced5-7098-a830-8693997fcfbf	D10	D	10	Cuadrante D10	-17.73600000	-17.72700000	-63.15100000	-63.14000000	-17.73150000	-63.14550000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:58:47-04
019b1b02-d872-70b7-9448-f7df890eebe5	D11	D	11	Cuadrante D11	-17.73600000	-17.72700000	-63.14000000	-63.12900000	-17.73150000	-63.13450000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:58:49-04
019b1b02-e328-71dc-8286-da6a3f279a90	D12	D	12	Cuadrante D12	-17.73600000	-17.72700000	-63.12900000	-63.11800000	-17.73150000	-63.12350000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:58:52-04
019b1b02-ef56-73d4-a8b0-47445839e2c5	D13	D	13	Cuadrante D13	-17.73600000	-17.72700000	-63.11800000	-63.10700000	-17.73150000	-63.11250000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:58:55-04
019b1b02-fb8d-7006-aba0-ece4433b1bfa	D14	D	14	Cuadrante D14	-17.73600000	-17.72700000	-63.10700000	-63.09600000	-17.73150000	-63.10150000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:58:58-04
019b1b03-064e-733b-850b-41c873d82eb6	E1	E	1	Cuadrante E1	-17.74500000	-17.73600000	-63.25000000	-63.23900000	-17.74050000	-63.24450000	Santa Cruz de la Sierra	Norte	t	2025-12-14 03:59:01-04
019b1b03-1453-7277-95fd-0e0f8fedf0f4	E2	E	2	Cuadrante E2	-17.74500000	-17.73600000	-63.23900000	-63.22800000	-17.74050000	-63.23350000	Santa Cruz de la Sierra	Norte	t	2025-12-14 03:59:05-04
019b1b03-22a7-72f4-b78b-022e3c1430bf	E3	E	3	Cuadrante E3	-17.74500000	-17.73600000	-63.22800000	-63.21700000	-17.74050000	-63.22250000	Santa Cruz de la Sierra	Norte	t	2025-12-14 03:59:08-04
019b1b03-311d-7047-a48d-5d833ce6f19c	E4	E	4	Cuadrante E4	-17.74500000	-17.73600000	-63.21700000	-63.20600000	-17.74050000	-63.21150000	Santa Cruz de la Sierra	Norte	t	2025-12-14 03:59:12-04
019b1b03-3b40-73bc-8ec5-3d69c80687aa	E5	E	5	Cuadrante E5	-17.74500000	-17.73600000	-63.20600000	-63.19500000	-17.74050000	-63.20050000	Santa Cruz de la Sierra	Norte	t	2025-12-14 03:59:15-04
019b1b03-457c-70cd-8738-e538630c9fe1	E6	E	6	Cuadrante E6	-17.74500000	-17.73600000	-63.19500000	-63.18400000	-17.74050000	-63.18950000	Santa Cruz de la Sierra	Norte	t	2025-12-14 03:59:17-04
019b1b03-5411-7062-85d6-be858b564b4d	E7	E	7	Cuadrante E7	-17.74500000	-17.73600000	-63.18400000	-63.17300000	-17.74050000	-63.17850000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:59:21-04
019b1b03-606b-7024-8a0d-6ef4eac39ba0	E8	E	8	Cuadrante E8	-17.74500000	-17.73600000	-63.17300000	-63.16200000	-17.74050000	-63.16750000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:59:24-04
019b1b03-6aef-71ab-903d-b972fcf133fb	E9	E	9	Cuadrante E9	-17.74500000	-17.73600000	-63.16200000	-63.15100000	-17.74050000	-63.15650000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:59:27-04
019b1b03-7a35-7363-a960-71dad55030f6	E10	E	10	Cuadrante E10	-17.74500000	-17.73600000	-63.15100000	-63.14000000	-17.74050000	-63.14550000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:59:31-04
019b1b03-864a-720d-af51-c2e142d83192	E11	E	11	Cuadrante E11	-17.74500000	-17.73600000	-63.14000000	-63.12900000	-17.74050000	-63.13450000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:59:34-04
019b1b03-92d4-70ca-a674-fa7e7d312fcb	E12	E	12	Cuadrante E12	-17.74500000	-17.73600000	-63.12900000	-63.11800000	-17.74050000	-63.12350000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:59:37-04
019b1b03-9d6e-7103-a700-066291349bae	E13	E	13	Cuadrante E13	-17.74500000	-17.73600000	-63.11800000	-63.10700000	-17.74050000	-63.11250000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:59:40-04
019b1b03-a5e4-7160-b485-df05686f7cc0	E14	E	14	Cuadrante E14	-17.74500000	-17.73600000	-63.10700000	-63.09600000	-17.74050000	-63.10150000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 03:59:42-04
019b1b03-b271-708f-9d1e-11022509f1a7	F1	F	1	Cuadrante F1	-17.75400000	-17.74500000	-63.25000000	-63.23900000	-17.74950000	-63.24450000	Santa Cruz de la Sierra	Norte	t	2025-12-14 03:59:45-04
019b1b03-c0b4-702e-8df4-ec87472ccb32	F2	F	2	Cuadrante F2	-17.75400000	-17.74500000	-63.23900000	-63.22800000	-17.74950000	-63.23350000	Santa Cruz de la Sierra	Norte	t	2025-12-14 03:59:49-04
019b1b03-cf19-7258-91b6-e0d18649a584	F3	F	3	Cuadrante F3	-17.75400000	-17.74500000	-63.22800000	-63.21700000	-17.74950000	-63.22250000	Santa Cruz de la Sierra	Norte	t	2025-12-14 03:59:53-04
019b1b03-db17-70b0-80b4-6dcbe4ad7985	F4	F	4	Cuadrante F4	-17.75400000	-17.74500000	-63.21700000	-63.20600000	-17.74950000	-63.21150000	Santa Cruz de la Sierra	Norte	t	2025-12-14 03:59:56-04
019b1b03-e590-72f7-a6e9-189cc2820985	F5	F	5	Cuadrante F5	-17.75400000	-17.74500000	-63.20600000	-63.19500000	-17.74950000	-63.20050000	Santa Cruz de la Sierra	Norte	t	2025-12-14 03:59:58-04
019b1b03-f1d8-7298-8a7d-0d43022c3b16	F6	F	6	Cuadrante F6	-17.75400000	-17.74500000	-63.19500000	-63.18400000	-17.74950000	-63.18950000	Santa Cruz de la Sierra	Norte	t	2025-12-14 04:00:02-04
019b1b03-fe27-71b7-a22b-e058a57dc398	F7	F	7	Cuadrante F7	-17.75400000	-17.74500000	-63.18400000	-63.17300000	-17.74950000	-63.17850000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 04:00:05-04
019b1b04-05f5-7178-9d36-dd2caa7a081d	F8	F	8	Cuadrante F8	-17.75400000	-17.74500000	-63.17300000	-63.16200000	-17.74950000	-63.16750000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 04:00:07-04
019b1b04-0e32-73cc-aba8-319497bae801	F9	F	9	Cuadrante F9	-17.75400000	-17.74500000	-63.16200000	-63.15100000	-17.74950000	-63.15650000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 04:00:09-04
019b1b04-162b-71ad-9117-189c0df75323	F10	F	10	Cuadrante F10	-17.75400000	-17.74500000	-63.15100000	-63.14000000	-17.74950000	-63.14550000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 04:00:11-04
019b1b04-24a1-70a8-8455-e15c7d04d8c8	F11	F	11	Cuadrante F11	-17.75400000	-17.74500000	-63.14000000	-63.12900000	-17.74950000	-63.13450000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 04:00:15-04
019b1b04-2d0c-72ae-bbea-b04947d481f3	F12	F	12	Cuadrante F12	-17.75400000	-17.74500000	-63.12900000	-63.11800000	-17.74950000	-63.12350000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 04:00:17-04
019b1b04-3b1e-73f7-9b18-1d55ad45ca47	F13	F	13	Cuadrante F13	-17.75400000	-17.74500000	-63.11800000	-63.10700000	-17.74950000	-63.11250000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 04:00:20-04
019b1b04-42e2-73f2-8612-e55507c4f3ba	F14	F	14	Cuadrante F14	-17.75400000	-17.74500000	-63.10700000	-63.09600000	-17.74950000	-63.10150000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 04:00:22-04
019b1b04-4f69-73f7-b455-274d469a1dbe	G1	G	1	Cuadrante G1	-17.76300000	-17.75400000	-63.25000000	-63.23900000	-17.75850000	-63.24450000	Santa Cruz de la Sierra	Norte	t	2025-12-14 04:00:25-04
019b1b04-5d3e-733a-a177-2bc78f422970	G2	G	2	Cuadrante G2	-17.76300000	-17.75400000	-63.23900000	-63.22800000	-17.75850000	-63.23350000	Santa Cruz de la Sierra	Norte	t	2025-12-14 04:00:29-04
019b1b04-6969-71ee-85ca-10b94d9a5c4c	G3	G	3	Cuadrante G3	-17.76300000	-17.75400000	-63.22800000	-63.21700000	-17.75850000	-63.22250000	Santa Cruz de la Sierra	Norte	t	2025-12-14 04:00:32-04
019b1b04-71b5-720a-9fee-4b87397918dd	G4	G	4	Cuadrante G4	-17.76300000	-17.75400000	-63.21700000	-63.20600000	-17.75850000	-63.21150000	Santa Cruz de la Sierra	Norte	t	2025-12-14 04:00:34-04
019b1b04-8037-71f5-a2c4-0e43a29942c1	G5	G	5	Cuadrante G5	-17.76300000	-17.75400000	-63.20600000	-63.19500000	-17.75850000	-63.20050000	Santa Cruz de la Sierra	Norte	t	2025-12-14 04:00:38-04
019b1b04-8f13-725e-83d3-bbda0dd5ff9d	G6	G	6	Cuadrante G6	-17.76300000	-17.75400000	-63.19500000	-63.18400000	-17.75850000	-63.18950000	Santa Cruz de la Sierra	Norte	t	2025-12-14 04:00:42-04
019b1b04-9d69-7219-8474-939c8da540ab	G7	G	7	Cuadrante G7	-17.76300000	-17.75400000	-63.18400000	-63.17300000	-17.75850000	-63.17850000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 04:00:45-04
019b1b04-abed-7030-9acd-b357f019d8f2	G8	G	8	Cuadrante G8	-17.76300000	-17.75400000	-63.17300000	-63.16200000	-17.75850000	-63.16750000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 04:00:49-04
019b1b04-b5de-70fe-9cec-b5600a6027cf	G9	G	9	Cuadrante G9	-17.76300000	-17.75400000	-63.16200000	-63.15100000	-17.75850000	-63.15650000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 04:00:52-04
019b1b04-c446-735f-b54f-a00b683f3188	G10	G	10	Cuadrante G10	-17.76300000	-17.75400000	-63.15100000	-63.14000000	-17.75850000	-63.14550000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 04:00:55-04
019b1b04-d24f-7063-8705-be62894962db	G11	G	11	Cuadrante G11	-17.76300000	-17.75400000	-63.14000000	-63.12900000	-17.75850000	-63.13450000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 04:00:59-04
019b1b04-dac1-709e-a90c-2b7b857767c1	G12	G	12	Cuadrante G12	-17.76300000	-17.75400000	-63.12900000	-63.11800000	-17.75850000	-63.12350000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 04:01:01-04
019b1b04-e73c-72b1-b3fb-9085c88e37de	G13	G	13	Cuadrante G13	-17.76300000	-17.75400000	-63.11800000	-63.10700000	-17.75850000	-63.11250000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 04:01:04-04
019b1b04-ef2d-7199-b4cf-92b368d6424e	G14	G	14	Cuadrante G14	-17.76300000	-17.75400000	-63.10700000	-63.09600000	-17.75850000	-63.10150000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 04:01:06-04
019b1b04-fc3c-739c-af75-4fa9e4d5f5a1	H1	H	1	Cuadrante H1	-17.77200000	-17.76300000	-63.25000000	-63.23900000	-17.76750000	-63.24450000	Santa Cruz de la Sierra	Norte	t	2025-12-14 04:01:10-04
019b1b05-084b-73a1-b8df-4e3c0a9aed7b	H2	H	2	Cuadrante H2	-17.77200000	-17.76300000	-63.23900000	-63.22800000	-17.76750000	-63.23350000	Santa Cruz de la Sierra	Norte	t	2025-12-14 04:01:13-04
019b1b05-1698-7373-9447-5c262e4fb07b	H3	H	3	Cuadrante H3	-17.77200000	-17.76300000	-63.22800000	-63.21700000	-17.76750000	-63.22250000	Santa Cruz de la Sierra	Norte	t	2025-12-14 04:01:16-04
019b1b05-1e4d-73d3-a47d-99202f27dad6	H4	H	4	Cuadrante H4	-17.77200000	-17.76300000	-63.21700000	-63.20600000	-17.76750000	-63.21150000	Santa Cruz de la Sierra	Norte	t	2025-12-14 04:01:18-04
019b1b05-2835-73c5-88b3-3d70af34802f	H5	H	5	Cuadrante H5	-17.77200000	-17.76300000	-63.20600000	-63.19500000	-17.76750000	-63.20050000	Santa Cruz de la Sierra	Norte	t	2025-12-14 04:01:21-04
019b1b05-3430-7265-b028-1673a7f6484d	H6	H	6	Cuadrante H6	-17.77200000	-17.76300000	-63.19500000	-63.18400000	-17.76750000	-63.18950000	Santa Cruz de la Sierra	Norte	t	2025-12-14 04:01:24-04
019b1b05-427e-7187-b847-299a1d2ead23	H7	H	7	Cuadrante H7	-17.77200000	-17.76300000	-63.18400000	-63.17300000	-17.76750000	-63.17850000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 04:01:28-04
019b1b05-4e93-73fd-8e15-2e1c3461d981	H8	H	8	Cuadrante H8	-17.77200000	-17.76300000	-63.17300000	-63.16200000	-17.76750000	-63.16750000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 04:01:31-04
019b1b05-56b8-702d-bd58-ee9e6b1cbe94	H9	H	9	Cuadrante H9	-17.77200000	-17.76300000	-63.16200000	-63.15100000	-17.76750000	-63.15650000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 04:01:33-04
019b1b05-60e0-72a8-81bb-34663dce944e	H10	H	10	Cuadrante H10	-17.77200000	-17.76300000	-63.15100000	-63.14000000	-17.76750000	-63.14550000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 04:01:35-04
019b1b05-6b08-737b-8ab6-4c427cf7cedb	H11	H	11	Cuadrante H11	-17.77200000	-17.76300000	-63.14000000	-63.12900000	-17.76750000	-63.13450000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 04:01:38-04
019b1b05-72e9-7015-82af-9e6ad8a0555f	H12	H	12	Cuadrante H12	-17.77200000	-17.76300000	-63.12900000	-63.11800000	-17.76750000	-63.12350000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 04:01:40-04
019b1b05-7d10-7221-9984-19f2609210d2	H13	H	13	Cuadrante H13	-17.77200000	-17.76300000	-63.11800000	-63.10700000	-17.76750000	-63.11250000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 04:01:43-04
019b1b05-8776-722b-80d2-7ddda939c8af	H14	H	14	Cuadrante H14	-17.77200000	-17.76300000	-63.10700000	-63.09600000	-17.76750000	-63.10150000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 04:01:45-04
019b1b05-9424-71e6-a941-67523195d2de	I1	I	1	Cuadrante I1	-17.78100000	-17.77200000	-63.25000000	-63.23900000	-17.77650000	-63.24450000	Santa Cruz de la Sierra	Norte	t	2025-12-14 04:01:49-04
019b1b05-a347-7088-8b20-84fb3e2d1de9	I2	I	2	Cuadrante I2	-17.78100000	-17.77200000	-63.23900000	-63.22800000	-17.77650000	-63.23350000	Santa Cruz de la Sierra	Norte	t	2025-12-14 04:01:52-04
019b1b05-b2f6-7208-8806-f482ce8fd562	I3	I	3	Cuadrante I3	-17.78100000	-17.77200000	-63.22800000	-63.21700000	-17.77650000	-63.22250000	Santa Cruz de la Sierra	Norte	t	2025-12-14 04:01:56-04
019b1b05-c131-7161-bef2-f1793758fbca	I4	I	4	Cuadrante I4	-17.78100000	-17.77200000	-63.21700000	-63.20600000	-17.77650000	-63.21150000	Santa Cruz de la Sierra	Norte	t	2025-12-14 04:02:00-04
019b1b05-c98d-730c-a3b7-13361675e18e	I5	I	5	Cuadrante I5	-17.78100000	-17.77200000	-63.20600000	-63.19500000	-17.77650000	-63.20050000	Santa Cruz de la Sierra	Norte	t	2025-12-14 04:02:02-04
019b1b05-d667-70cd-8c6b-ce43bfa1c940	I6	I	6	Cuadrante I6	-17.78100000	-17.77200000	-63.19500000	-63.18400000	-17.77650000	-63.18950000	Santa Cruz de la Sierra	Norte	t	2025-12-14 04:02:06-04
019b1b05-e2b2-70c5-8625-c023829a6753	I7	I	7	Cuadrante I7	-17.78100000	-17.77200000	-63.18400000	-63.17300000	-17.77650000	-63.17850000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 04:02:09-04
019b1b05-ef3f-7142-a4ec-95aabc937147	I8	I	8	Cuadrante I8	-17.78100000	-17.77200000	-63.17300000	-63.16200000	-17.77650000	-63.16750000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 04:02:12-04
019b1b05-fa84-73cc-8e60-05030a991a26	I9	I	9	Cuadrante I9	-17.78100000	-17.77200000	-63.16200000	-63.15100000	-17.77650000	-63.15650000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 04:02:15-04
019b1b06-0505-7192-9854-e9987577741e	I10	I	10	Cuadrante I10	-17.78100000	-17.77200000	-63.15100000	-63.14000000	-17.77650000	-63.14550000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 04:02:17-04
019b1b06-0f4d-70d0-afe2-a09189793751	I11	I	11	Cuadrante I11	-17.78100000	-17.77200000	-63.14000000	-63.12900000	-17.77650000	-63.13450000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 04:02:20-04
019b1b06-1dcb-7290-a39f-4661ce8a0cb8	I12	I	12	Cuadrante I12	-17.78100000	-17.77200000	-63.12900000	-63.11800000	-17.77650000	-63.12350000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 04:02:24-04
019b1b06-2791-7062-ad29-ce1e6a0c891d	I13	I	13	Cuadrante I13	-17.78100000	-17.77200000	-63.11800000	-63.10700000	-17.77650000	-63.11250000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 04:02:26-04
019b1b06-3005-7210-8845-9a346e15492d	I14	I	14	Cuadrante I14	-17.78100000	-17.77200000	-63.10700000	-63.09600000	-17.77650000	-63.10150000	Santa Cruz de la Sierra	Noreste	t	2025-12-14 04:02:28-04
019b1b06-3e8e-719e-8779-8ac6b995da23	J1	J	1	Cuadrante J1	-17.79000000	-17.78100000	-63.25000000	-63.23900000	-17.78550000	-63.24450000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:02:32-04
019b1b06-4d37-73c8-b750-b1d0f9e54a90	J2	J	2	Cuadrante J2	-17.79000000	-17.78100000	-63.23900000	-63.22800000	-17.78550000	-63.23350000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:02:36-04
019b1b06-55b8-71e4-9a6b-43f2c4c6b84f	J3	J	3	Cuadrante J3	-17.79000000	-17.78100000	-63.22800000	-63.21700000	-17.78550000	-63.22250000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:02:38-04
019b1b06-5d8a-73c8-ace3-11998b0a3a0b	J4	J	4	Cuadrante J4	-17.79000000	-17.78100000	-63.21700000	-63.20600000	-17.78550000	-63.21150000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:02:40-04
019b1b06-6bea-70a0-bbec-74c3a605a188	J5	J	5	Cuadrante J5	-17.79000000	-17.78100000	-63.20600000	-63.19500000	-17.78550000	-63.20050000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:02:44-04
019b1b06-7624-73d8-bc4c-5aac69c3122a	J6	J	6	Cuadrante J6	-17.79000000	-17.78100000	-63.19500000	-63.18400000	-17.78550000	-63.18950000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:02:46-04
019b1b06-8259-708d-9368-590c022bbc08	J7	J	7	Cuadrante J7	-17.79000000	-17.78100000	-63.18400000	-63.17300000	-17.78550000	-63.17850000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:02:50-04
019b1b06-90ac-71ba-af56-9b0237bf030c	J8	J	8	Cuadrante J8	-17.79000000	-17.78100000	-63.17300000	-63.16200000	-17.78550000	-63.16750000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:02:53-04
019b1b06-9d0f-70c5-81b0-3c3bf2286e36	J9	J	9	Cuadrante J9	-17.79000000	-17.78100000	-63.16200000	-63.15100000	-17.78550000	-63.15650000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:02:56-04
019b1b06-a6c8-7124-8f16-db232fa6ab80	J10	J	10	Cuadrante J10	-17.79000000	-17.78100000	-63.15100000	-63.14000000	-17.78550000	-63.14550000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:02:59-04
019b1b06-b164-70bf-a417-a0122e5c951f	J11	J	11	Cuadrante J11	-17.79000000	-17.78100000	-63.14000000	-63.12900000	-17.78550000	-63.13450000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:03:02-04
019b1b06-bf60-72b2-a664-a63df1963b5e	J12	J	12	Cuadrante J12	-17.79000000	-17.78100000	-63.12900000	-63.11800000	-17.78550000	-63.12350000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:03:05-04
019b1b06-c741-7118-b644-21ff68053554	J13	J	13	Cuadrante J13	-17.79000000	-17.78100000	-63.11800000	-63.10700000	-17.78550000	-63.11250000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:03:07-04
019b1b06-d38c-7124-80fe-85ce8c43272a	J14	J	14	Cuadrante J14	-17.79000000	-17.78100000	-63.10700000	-63.09600000	-17.78550000	-63.10150000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:03:10-04
019b1b06-e172-7010-9610-29899d48df98	K1	K	1	Cuadrante K1	-17.79900000	-17.79000000	-63.25000000	-63.23900000	-17.79450000	-63.24450000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:03:14-04
019b1b06-ed57-7192-b84c-d58cd6730caf	K2	K	2	Cuadrante K2	-17.79900000	-17.79000000	-63.23900000	-63.22800000	-17.79450000	-63.23350000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:03:17-04
019b1b06-f9d7-736d-94f3-034c142e832f	K3	K	3	Cuadrante K3	-17.79900000	-17.79000000	-63.22800000	-63.21700000	-17.79450000	-63.22250000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:03:20-04
019b1b07-0428-7081-9326-d596bd1c842c	K4	K	4	Cuadrante K4	-17.79900000	-17.79000000	-63.21700000	-63.20600000	-17.79450000	-63.21150000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:03:23-04
019b1b07-1214-73b9-a753-50f118f50722	K5	K	5	Cuadrante K5	-17.79900000	-17.79000000	-63.20600000	-63.19500000	-17.79450000	-63.20050000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:03:26-04
019b1b07-1e25-71a6-b701-d0bd2cbd7e1d	K6	K	6	Cuadrante K6	-17.79900000	-17.79000000	-63.19500000	-63.18400000	-17.79450000	-63.18950000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:03:29-04
019b1b07-2cbd-71bf-a5a1-292b7c656f19	K7	K	7	Cuadrante K7	-17.79900000	-17.79000000	-63.18400000	-63.17300000	-17.79450000	-63.17850000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:03:33-04
019b1b07-3ace-7117-9bcf-490f6410cfed	K8	K	8	Cuadrante K8	-17.79900000	-17.79000000	-63.17300000	-63.16200000	-17.79450000	-63.16750000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:03:37-04
019b1b07-44f9-7199-ac4f-4fd239445e70	K9	K	9	Cuadrante K9	-17.79900000	-17.79000000	-63.16200000	-63.15100000	-17.79450000	-63.15650000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:03:39-04
019b1b07-4cee-70c6-a1ba-225a76fc7cfd	K10	K	10	Cuadrante K10	-17.79900000	-17.79000000	-63.15100000	-63.14000000	-17.79450000	-63.14550000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:03:41-04
019b1b07-5b40-708c-bc97-dad916399c87	K11	K	11	Cuadrante K11	-17.79900000	-17.79000000	-63.14000000	-63.12900000	-17.79450000	-63.13450000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:03:45-04
019b1b07-65ac-720f-8025-25cea0e703e5	K12	K	12	Cuadrante K12	-17.79900000	-17.79000000	-63.12900000	-63.11800000	-17.79450000	-63.12350000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:03:48-04
019b1b07-6e61-70f3-bebc-d6195f5229b1	K13	K	13	Cuadrante K13	-17.79900000	-17.79000000	-63.11800000	-63.10700000	-17.79450000	-63.11250000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:03:50-04
019b1b07-76c1-731e-a5d5-447fb8f79ba6	K14	K	14	Cuadrante K14	-17.79900000	-17.79000000	-63.10700000	-63.09600000	-17.79450000	-63.10150000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:03:52-04
019b1b07-853e-708c-bfee-447d882dc7c5	L1	L	1	Cuadrante L1	-17.80800000	-17.79900000	-63.25000000	-63.23900000	-17.80350000	-63.24450000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:03:56-04
019b1b07-931f-70e3-80bb-0e8a9cb3601c	L2	L	2	Cuadrante L2	-17.80800000	-17.79900000	-63.23900000	-63.22800000	-17.80350000	-63.23350000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:03:59-04
019b1b07-9c4d-709a-9806-3d88c99b5b64	L3	L	3	Cuadrante L3	-17.80800000	-17.79900000	-63.22800000	-63.21700000	-17.80350000	-63.22250000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:04:02-04
019b1b07-aab5-70e7-93fd-945f5f2bbe9e	L4	L	4	Cuadrante L4	-17.80800000	-17.79900000	-63.21700000	-63.20600000	-17.80350000	-63.21150000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:04:05-04
019b1b07-b75e-73ef-befe-a15908c3fe23	L5	L	5	Cuadrante L5	-17.80800000	-17.79900000	-63.20600000	-63.19500000	-17.80350000	-63.20050000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:04:09-04
019b1b07-c367-71d9-8d78-9544e21b9723	L6	L	6	Cuadrante L6	-17.80800000	-17.79900000	-63.19500000	-63.18400000	-17.80350000	-63.18950000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:04:12-04
019b1b07-d138-7082-9013-e2d74695e2be	L7	L	7	Cuadrante L7	-17.80800000	-17.79900000	-63.18400000	-63.17300000	-17.80350000	-63.17850000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:04:15-04
019b1b07-d992-71d7-b7d3-272ef49174a3	L8	L	8	Cuadrante L8	-17.80800000	-17.79900000	-63.17300000	-63.16200000	-17.80350000	-63.16750000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:04:17-04
019b1b07-e18b-732d-8b72-b7b2a2a50e18	L9	L	9	Cuadrante L9	-17.80800000	-17.79900000	-63.16200000	-63.15100000	-17.80350000	-63.15650000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:04:19-04
019b1b07-f037-701d-bbf0-1bc28af2c0da	L10	L	10	Cuadrante L10	-17.80800000	-17.79900000	-63.15100000	-63.14000000	-17.80350000	-63.14550000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:04:23-04
019b1b07-fc5e-71db-952a-7afb885b0168	L11	L	11	Cuadrante L11	-17.80800000	-17.79900000	-63.14000000	-63.12900000	-17.80350000	-63.13450000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:04:26-04
019b1b08-069f-7193-bde3-69643c8a5088	L12	L	12	Cuadrante L12	-17.80800000	-17.79900000	-63.12900000	-63.11800000	-17.80350000	-63.12350000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:04:29-04
019b1b08-133a-7057-b23e-7bd07c0a89e1	L13	L	13	Cuadrante L13	-17.80800000	-17.79900000	-63.11800000	-63.10700000	-17.80350000	-63.11250000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:04:32-04
019b1b08-1b2f-729f-b301-bf498e5f78cd	L14	L	14	Cuadrante L14	-17.80800000	-17.79900000	-63.10700000	-63.09600000	-17.80350000	-63.10150000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:04:34-04
019b1b08-27b8-7047-b95d-f93a453705ab	M1	M	1	Cuadrante M1	-17.81700000	-17.80800000	-63.25000000	-63.23900000	-17.81250000	-63.24450000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:04:37-04
019b1b08-2fa7-71e0-8ea1-4af868596e9c	M2	M	2	Cuadrante M2	-17.81700000	-17.80800000	-63.23900000	-63.22800000	-17.81250000	-63.23350000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:04:39-04
019b1b08-3e22-73b2-af91-2e8d7e3183f2	M3	M	3	Cuadrante M3	-17.81700000	-17.80800000	-63.22800000	-63.21700000	-17.81250000	-63.22250000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:04:43-04
019b1b08-4673-71aa-9844-feab48b5ddd8	M4	M	4	Cuadrante M4	-17.81700000	-17.80800000	-63.21700000	-63.20600000	-17.81250000	-63.21150000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:04:45-04
019b1b08-4e4e-7214-a70f-93591e738cd1	M5	M	5	Cuadrante M5	-17.81700000	-17.80800000	-63.20600000	-63.19500000	-17.81250000	-63.20050000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:04:47-04
019b1b08-5862-71e7-aa47-178f0426c4a9	M6	M	6	Cuadrante M6	-17.81700000	-17.80800000	-63.19500000	-63.18400000	-17.81250000	-63.18950000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:04:50-04
019b1b08-62ab-7222-9376-9f161f53a238	M7	M	7	Cuadrante M7	-17.81700000	-17.80800000	-63.18400000	-63.17300000	-17.81250000	-63.17850000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:04:53-04
019b1b08-6efd-7226-8ba4-701583fa74fa	M8	M	8	Cuadrante M8	-17.81700000	-17.80800000	-63.17300000	-63.16200000	-17.81250000	-63.16750000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:04:56-04
019b1b08-7d27-71d2-8367-879cb4c71d42	M9	M	9	Cuadrante M9	-17.81700000	-17.80800000	-63.16200000	-63.15100000	-17.81250000	-63.15650000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:04:59-04
019b1b08-8bc8-721e-bfdd-1e2dbbe06bb6	M10	M	10	Cuadrante M10	-17.81700000	-17.80800000	-63.15100000	-63.14000000	-17.81250000	-63.14550000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:05:03-04
019b1b08-99fa-7087-9825-ddde7eaf7f42	M11	M	11	Cuadrante M11	-17.81700000	-17.80800000	-63.14000000	-63.12900000	-17.81250000	-63.13450000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:05:07-04
019b1b08-a427-7280-b2ab-0ae1edfe054d	M12	M	12	Cuadrante M12	-17.81700000	-17.80800000	-63.12900000	-63.11800000	-17.81250000	-63.12350000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:05:09-04
019b1b08-b23b-702d-a8a7-f1480df8f7f4	M13	M	13	Cuadrante M13	-17.81700000	-17.80800000	-63.11800000	-63.10700000	-17.81250000	-63.11250000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:05:13-04
019b1b08-bf09-72da-98d0-4d09f28b1d64	M14	M	14	Cuadrante M14	-17.81700000	-17.80800000	-63.10700000	-63.09600000	-17.81250000	-63.10150000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:05:16-04
019b1b08-cafd-7026-8c90-508e3e958e9e	N1	N	1	Cuadrante N1	-17.82600000	-17.81700000	-63.25000000	-63.23900000	-17.82150000	-63.24450000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:05:19-04
019b1b08-d74c-71f3-99fc-f17080d5f410	N2	N	2	Cuadrante N2	-17.82600000	-17.81700000	-63.23900000	-63.22800000	-17.82150000	-63.23350000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:05:22-04
019b1b08-e16c-7280-99e8-f4d130c61ef4	N3	N	3	Cuadrante N3	-17.82600000	-17.81700000	-63.22800000	-63.21700000	-17.82150000	-63.22250000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:05:25-04
019b1b08-e95b-73dd-96d6-7aff730cd37c	N4	N	4	Cuadrante N4	-17.82600000	-17.81700000	-63.21700000	-63.20600000	-17.82150000	-63.21150000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:05:27-04
019b1b08-f5d4-717f-beb5-e73f491557e5	N5	N	5	Cuadrante N5	-17.82600000	-17.81700000	-63.20600000	-63.19500000	-17.82150000	-63.20050000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:05:30-04
019b1b08-fffc-71f2-b402-e781d9263d2b	N6	N	6	Cuadrante N6	-17.82600000	-17.81700000	-63.19500000	-63.18400000	-17.82150000	-63.18950000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:05:33-04
019b1b09-07d7-7273-85d7-0dd18e244491	N7	N	7	Cuadrante N7	-17.82600000	-17.81700000	-63.18400000	-63.17300000	-17.82150000	-63.17850000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:05:35-04
019b1b09-1041-7135-ad92-fd50872ccc94	N8	N	8	Cuadrante N8	-17.82600000	-17.81700000	-63.17300000	-63.16200000	-17.82150000	-63.16750000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:05:37-04
019b1b09-1a62-73d2-8e07-752a1eb24363	N9	N	9	Cuadrante N9	-17.82600000	-17.81700000	-63.16200000	-63.15100000	-17.82150000	-63.15650000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:05:40-04
019b1b09-26d2-7254-9a77-f5660f169c02	N10	N	10	Cuadrante N10	-17.82600000	-17.81700000	-63.15100000	-63.14000000	-17.82150000	-63.14550000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:05:43-04
019b1b09-2eb2-708e-909e-236d0af8ddaa	N11	N	11	Cuadrante N11	-17.82600000	-17.81700000	-63.14000000	-63.12900000	-17.82150000	-63.13450000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:05:45-04
019b1b09-3add-702c-9dad-2216b7526fb4	N12	N	12	Cuadrante N12	-17.82600000	-17.81700000	-63.12900000	-63.11800000	-17.82150000	-63.12350000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:05:48-04
019b1b09-4316-72aa-9717-73a1ff35ce65	N13	N	13	Cuadrante N13	-17.82600000	-17.81700000	-63.11800000	-63.10700000	-17.82150000	-63.11250000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:05:50-04
019b1b09-519a-73dd-92c1-d322d0c4613d	N14	N	14	Cuadrante N14	-17.82600000	-17.81700000	-63.10700000	-63.09600000	-17.82150000	-63.10150000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:05:54-04
019b1b09-59dd-7218-ad8c-77be0c0cf6b1	O1	O	1	Cuadrante O1	-17.83500000	-17.82600000	-63.25000000	-63.23900000	-17.83050000	-63.24450000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:05:56-04
019b1b09-6797-7359-ab4c-af90c4886143	O2	O	2	Cuadrante O2	-17.83500000	-17.82600000	-63.23900000	-63.22800000	-17.83050000	-63.23350000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:05:59-04
019b1b09-6ff9-7085-95aa-118ae36a0bec	O3	O	3	Cuadrante O3	-17.83500000	-17.82600000	-63.22800000	-63.21700000	-17.83050000	-63.22250000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:06:01-04
019b1b09-7de2-71d4-ba50-cf7e4662ae84	O4	O	4	Cuadrante O4	-17.83500000	-17.82600000	-63.21700000	-63.20600000	-17.83050000	-63.21150000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:06:05-04
019b1b09-8622-71d3-adf9-bbec0e976f37	O5	O	5	Cuadrante O5	-17.83500000	-17.82600000	-63.20600000	-63.19500000	-17.83050000	-63.20050000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:06:07-04
019b1b09-9411-723a-ae40-e733e4b4e275	O6	O	6	Cuadrante O6	-17.83500000	-17.82600000	-63.19500000	-63.18400000	-17.83050000	-63.18950000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:06:11-04
019b1b09-9e10-71ca-b0bf-1f28fcec3a1a	O7	O	7	Cuadrante O7	-17.83500000	-17.82600000	-63.18400000	-63.17300000	-17.83050000	-63.17850000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:06:13-04
019b1b09-a9d8-7336-b90e-f37ff0ecfdeb	O8	O	8	Cuadrante O8	-17.83500000	-17.82600000	-63.17300000	-63.16200000	-17.83050000	-63.16750000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:06:16-04
019b1b09-b3fe-7384-923f-40498594705c	O9	O	9	Cuadrante O9	-17.83500000	-17.82600000	-63.16200000	-63.15100000	-17.83050000	-63.15650000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:06:19-04
019b1b09-c1e4-70c5-90eb-445abd712dec	O10	O	10	Cuadrante O10	-17.83500000	-17.82600000	-63.15100000	-63.14000000	-17.83050000	-63.14550000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:06:22-04
019b1b09-cc13-70ca-88d9-29bdbf6cfb73	O11	O	11	Cuadrante O11	-17.83500000	-17.82600000	-63.14000000	-63.12900000	-17.83050000	-63.13450000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:06:25-04
019b1b09-d6cb-7029-a5a7-42aeb20be928	O12	O	12	Cuadrante O12	-17.83500000	-17.82600000	-63.12900000	-63.11800000	-17.83050000	-63.12350000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:06:28-04
019b1b09-e525-7062-813b-78ab0a0d3542	O13	O	13	Cuadrante O13	-17.83500000	-17.82600000	-63.11800000	-63.10700000	-17.83050000	-63.11250000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:06:31-04
019b1b09-ef60-711d-bb54-04c99f29b151	O14	O	14	Cuadrante O14	-17.83500000	-17.82600000	-63.10700000	-63.09600000	-17.83050000	-63.10150000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:06:34-04
019b1b09-fe00-708b-b81a-ff5c9193b6d7	P1	P	1	Cuadrante P1	-17.84400000	-17.83500000	-63.25000000	-63.23900000	-17.83950000	-63.24450000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:06:38-04
019b1b0a-0bc3-72de-bc06-46b81f34b9a3	P2	P	2	Cuadrante P2	-17.84400000	-17.83500000	-63.23900000	-63.22800000	-17.83950000	-63.23350000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:06:41-04
019b1b0a-1a3f-73aa-9741-4f9e81f3a718	P3	P	3	Cuadrante P3	-17.84400000	-17.83500000	-63.22800000	-63.21700000	-17.83950000	-63.22250000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:06:45-04
019b1b0a-22b1-7040-8f5f-d505f4294be3	P4	P	4	Cuadrante P4	-17.84400000	-17.83500000	-63.21700000	-63.20600000	-17.83950000	-63.21150000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:06:47-04
019b1b0a-2b19-7323-9197-1f12627e5dc7	P5	P	5	Cuadrante P5	-17.84400000	-17.83500000	-63.20600000	-63.19500000	-17.83950000	-63.20050000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:06:49-04
019b1b0a-339d-72c7-9c4d-36735219ff1f	P6	P	6	Cuadrante P6	-17.84400000	-17.83500000	-63.19500000	-63.18400000	-17.83950000	-63.18950000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:06:52-04
019b1b0a-41f4-7390-a5d3-3924b836163c	P7	P	7	Cuadrante P7	-17.84400000	-17.83500000	-63.18400000	-63.17300000	-17.83950000	-63.17850000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:06:55-04
019b1b0a-4dde-71f0-a56a-c527af5d073f	P8	P	8	Cuadrante P8	-17.84400000	-17.83500000	-63.17300000	-63.16200000	-17.83950000	-63.16750000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:06:58-04
019b1b0a-5c20-7334-a04d-bac5ae3d81c1	P9	P	9	Cuadrante P9	-17.84400000	-17.83500000	-63.16200000	-63.15100000	-17.83950000	-63.15650000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:07:02-04
019b1b0a-66a2-70b7-8c00-faac7f852aaf	P10	P	10	Cuadrante P10	-17.84400000	-17.83500000	-63.15100000	-63.14000000	-17.83950000	-63.14550000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:07:05-04
019b1b0a-6ed4-7282-8b45-2f0d1647f01a	P11	P	11	Cuadrante P11	-17.84400000	-17.83500000	-63.14000000	-63.12900000	-17.83950000	-63.13450000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:07:07-04
019b1b0a-7d69-70f4-91d0-01366385c360	P12	P	12	Cuadrante P12	-17.84400000	-17.83500000	-63.12900000	-63.11800000	-17.83950000	-63.12350000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:07:10-04
019b1b0a-89ca-72ae-84fa-7e24b5d1a79c	P13	P	13	Cuadrante P13	-17.84400000	-17.83500000	-63.11800000	-63.10700000	-17.83950000	-63.11250000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:07:14-04
019b1b0a-921f-7165-812a-c60b48c707a1	P14	P	14	Cuadrante P14	-17.84400000	-17.83500000	-63.10700000	-63.09600000	-17.83950000	-63.10150000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:07:16-04
019b1b0a-9e4f-73f7-bb06-08bf7cd3a647	Q1	Q	1	Cuadrante Q1	-17.85300000	-17.84400000	-63.25000000	-63.23900000	-17.84850000	-63.24450000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:07:19-04
019b1b0a-ab42-7088-944a-f38a6458b3ed	Q2	Q	2	Cuadrante Q2	-17.85300000	-17.84400000	-63.23900000	-63.22800000	-17.84850000	-63.23350000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:07:22-04
019b1b0a-b3d0-7376-9d55-e0987dc5d0f1	Q3	Q	3	Cuadrante Q3	-17.85300000	-17.84400000	-63.22800000	-63.21700000	-17.84850000	-63.22250000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:07:24-04
019b1b0a-be0c-7072-9b24-a063507b46c6	Q4	Q	4	Cuadrante Q4	-17.85300000	-17.84400000	-63.21700000	-63.20600000	-17.84850000	-63.21150000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:07:27-04
019b1b0a-c69d-73f9-a995-a9d0bc42e676	Q5	Q	5	Cuadrante Q5	-17.85300000	-17.84400000	-63.20600000	-63.19500000	-17.84850000	-63.20050000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:07:29-04
019b1b0a-d4b4-70b2-91d0-ae1619fd462c	Q6	Q	6	Cuadrante Q6	-17.85300000	-17.84400000	-63.19500000	-63.18400000	-17.84850000	-63.18950000	Santa Cruz de la Sierra	Sur	t	2025-12-14 04:07:33-04
019b1b0a-e112-73c1-aa05-fa1d64e03173	Q7	Q	7	Cuadrante Q7	-17.85300000	-17.84400000	-63.18400000	-63.17300000	-17.84850000	-63.17850000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:07:36-04
019b1b0a-eb60-7214-89bf-debb4cfb68ca	Q8	Q	8	Cuadrante Q8	-17.85300000	-17.84400000	-63.17300000	-63.16200000	-17.84850000	-63.16750000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:07:39-04
019b1b0a-f9a4-7343-aecf-f92d6af37a2d	Q9	Q	9	Cuadrante Q9	-17.85300000	-17.84400000	-63.16200000	-63.15100000	-17.84850000	-63.15650000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:07:42-04
019b1b0b-01b3-7326-a550-22901cd4b964	Q10	Q	10	Cuadrante Q10	-17.85300000	-17.84400000	-63.15100000	-63.14000000	-17.84850000	-63.14550000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:07:44-04
019b1b0b-0bdd-7033-959f-ee017b0d5110	Q11	Q	11	Cuadrante Q11	-17.85300000	-17.84400000	-63.14000000	-63.12900000	-17.84850000	-63.13450000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:07:47-04
019b1b0b-16eb-7102-88aa-e6b565b303c4	Q12	Q	12	Cuadrante Q12	-17.85300000	-17.84400000	-63.12900000	-63.11800000	-17.84850000	-63.12350000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:07:50-04
019b1b0b-20ab-7108-8e31-00155ba46752	Q13	Q	13	Cuadrante Q13	-17.85300000	-17.84400000	-63.11800000	-63.10700000	-17.84850000	-63.11250000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:07:52-04
019b1b0b-2d40-71e2-a19b-f5ba3053057c	Q14	Q	14	Cuadrante Q14	-17.85300000	-17.84400000	-63.10700000	-63.09600000	-17.84850000	-63.10150000	Santa Cruz de la Sierra	Este	t	2025-12-14 04:07:55-04
\.


--
-- Data for Name: expansiones_reporte; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.expansiones_reporte (id, reporte_id, cuadrante_expandido_id, nivel, fecha_expansion) FROM stdin;
\.


--
-- Data for Name: failed_jobs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.failed_jobs (id, uuid, connection, queue, payload, exception, failed_at) FROM stdin;
\.


--
-- Data for Name: grupo_miembros; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.grupo_miembros (id, grupo_id, usuario_id, rol, notificaciones_activas, joined_at) FROM stdin;
\.


--
-- Data for Name: grupos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.grupos (id, cuadrante_id, nombre, descripcion, imagen_url, publico, requiere_aprobacion, created_at, updated_at) FROM stdin;
019b1b00-a470-72d6-9e1d-1ded345743a1	019b1b00-9857-73c4-953e-b4fb25064c7b	Grupo Cuadrante A1	Grupo comunitario del Cuadrante A1 - Zona Norte	\N	t	f	2025-12-14 03:56:25-04	2025-12-14 03:56:25-04
019b1b00-af8f-71f8-a7af-8ac00f4b9766	019b1b00-a6aa-705b-8142-3cca0af4e82c	Grupo Cuadrante A2	Grupo comunitario del Cuadrante A2 - Zona Norte	\N	t	f	2025-12-14 03:56:28-04	2025-12-14 03:56:28-04
019b1b00-b765-70cb-9295-60b8cdab198c	019b1b00-b16a-706d-87e5-79fca6695fb6	Grupo Cuadrante A3	Grupo comunitario del Cuadrante A3 - Zona Norte	\N	t	f	2025-12-14 03:56:30-04	2025-12-14 03:56:30-04
019b1b00-c5d5-704d-84cb-03cc7a3a2320	019b1b00-b939-7209-8855-194cca25a5c5	Grupo Cuadrante A4	Grupo comunitario del Cuadrante A4 - Zona Norte	\N	t	f	2025-12-14 03:56:34-04	2025-12-14 03:56:34-04
019b1b00-d07e-7280-adb7-7ab9b6fc7bdd	019b1b00-c7e6-70b9-88d9-705531f22ad7	Grupo Cuadrante A5	Grupo comunitario del Cuadrante A5 - Zona Norte	\N	t	f	2025-12-14 03:56:36-04	2025-12-14 03:56:36-04
019b1b00-dabb-72fe-a700-a129389601fd	019b1b00-d262-71ad-84d0-0c0ce3feb1ed	Grupo Cuadrante A6	Grupo comunitario del Cuadrante A6 - Zona Norte	\N	t	f	2025-12-14 03:56:39-04	2025-12-14 03:56:39-04
019b1b00-e2ca-710d-a20c-7b12e5d098f6	019b1b00-dcb3-7092-a87d-b169a9cfb4d7	Grupo Cuadrante A7	Grupo comunitario del Cuadrante A7 - Zona Noreste	\N	t	f	2025-12-14 03:56:41-04	2025-12-14 03:56:41-04
019b1b00-eb48-72bd-86b5-644c6b291e0d	019b1b00-e4bf-7111-b308-ad3f370ef625	Grupo Cuadrante A8	Grupo comunitario del Cuadrante A8 - Zona Noreste	\N	t	f	2025-12-14 03:56:43-04	2025-12-14 03:56:43-04
019b1b00-f560-7151-b6be-5fa2d1c1dcf9	019b1b00-ed27-7041-b0eb-5190ce4d7a4d	Grupo Cuadrante A9	Grupo comunitario del Cuadrante A9 - Zona Noreste	\N	t	f	2025-12-14 03:56:46-04	2025-12-14 03:56:46-04
019b1b01-03b5-7117-9838-e3bb15226fe2	019b1b00-f751-72c6-b3e0-30172deceae6	Grupo Cuadrante A10	Grupo comunitario del Cuadrante A10 - Zona Noreste	\N	t	f	2025-12-14 03:56:49-04	2025-12-14 03:56:49-04
019b1b01-0bcf-701a-8dee-895fd3d68f4d	019b1b01-057f-7280-88f4-30881489c569	Grupo Cuadrante A11	Grupo comunitario del Cuadrante A11 - Zona Noreste	\N	t	f	2025-12-14 03:56:52-04	2025-12-14 03:56:52-04
019b1b01-1454-7338-a4e5-5426fdef5c38	019b1b01-0e27-71bc-bcd1-09162be77279	Grupo Cuadrante A12	Grupo comunitario del Cuadrante A12 - Zona Noreste	\N	t	f	2025-12-14 03:56:54-04	2025-12-14 03:56:54-04
019b1b01-1de2-73ac-9eec-5ec8ba7e85e5	019b1b01-1638-739d-947e-f1c95c6fb5c5	Grupo Cuadrante A13	Grupo comunitario del Cuadrante A13 - Zona Noreste	\N	t	f	2025-12-14 03:56:56-04	2025-12-14 03:56:56-04
019b1b01-2c2f-737e-a05a-17b73bd7dafb	019b1b01-2033-70af-947a-7131287a0a2f	Grupo Cuadrante A14	Grupo comunitario del Cuadrante A14 - Zona Noreste	\N	t	f	2025-12-14 03:57:00-04	2025-12-14 03:57:00-04
019b1b01-367b-70dc-b8f5-dba0231fcac8	019b1b01-2e21-732d-b525-5df98e2991fb	Grupo Cuadrante B1	Grupo comunitario del Cuadrante B1 - Zona Norte	\N	t	f	2025-12-14 03:57:02-04	2025-12-14 03:57:02-04
019b1b01-44a4-7342-8573-b76979210eed	019b1b01-3867-7188-9ae8-e17343566ead	Grupo Cuadrante B2	Grupo comunitario del Cuadrante B2 - Zona Norte	\N	t	f	2025-12-14 03:57:06-04	2025-12-14 03:57:06-04
019b1b01-50e3-7382-983c-9106e26588aa	019b1b01-46f7-72bd-b5f9-37fac7ece605	Grupo Cuadrante B3	Grupo comunitario del Cuadrante B3 - Zona Norte	\N	t	f	2025-12-14 03:57:09-04	2025-12-14 03:57:09-04
019b1b01-5eaf-72a7-8963-8b1d92522ce6	019b1b01-52b2-7076-bdbb-c36f0f6a6db4	Grupo Cuadrante B4	Grupo comunitario del Cuadrante B4 - Zona Norte	\N	t	f	2025-12-14 03:57:13-04	2025-12-14 03:57:13-04
019b1b01-664f-73a6-9f3e-a69d3ba224ca	019b1b01-6088-714a-9914-2845c26a18c5	Grupo Cuadrante B5	Grupo comunitario del Cuadrante B5 - Zona Norte	\N	t	f	2025-12-14 03:57:15-04	2025-12-14 03:57:15-04
019b1b01-729c-717f-97a6-d4a0d44ea7ee	019b1b01-6886-70e1-b422-0f1c1f2976d8	Grupo Cuadrante B6	Grupo comunitario del Cuadrante B6 - Zona Norte	\N	t	f	2025-12-14 03:57:18-04	2025-12-14 03:57:18-04
019b1b01-7eb5-7268-8652-8ee4d56912ad	019b1b01-7473-722c-9b60-fc717b1f031f	Grupo Cuadrante B7	Grupo comunitario del Cuadrante B7 - Zona Noreste	\N	t	f	2025-12-14 03:57:21-04	2025-12-14 03:57:21-04
019b1b01-8a8f-72b8-91e6-6d1a4f206298	019b1b01-8091-730e-80d4-e3909fc53ff9	Grupo Cuadrante B8	Grupo comunitario del Cuadrante B8 - Zona Noreste	\N	t	f	2025-12-14 03:57:24-04	2025-12-14 03:57:24-04
019b1b01-992e-72d6-a9e4-1d46741f3f3c	019b1b01-8c69-7105-a356-cdf8bde5d0c3	Grupo Cuadrante B9	Grupo comunitario del Cuadrante B9 - Zona Noreste	\N	t	f	2025-12-14 03:57:28-04	2025-12-14 03:57:28-04
019b1b01-a371-70e4-93ac-4bab86c9411a	019b1b01-9b18-70b9-a84f-c0a7f1346478	Grupo Cuadrante B10	Grupo comunitario del Cuadrante B10 - Zona Noreste	\N	t	f	2025-12-14 03:57:30-04	2025-12-14 03:57:30-04
019b1b01-abc0-70c9-86b8-f11379626aed	019b1b01-a554-72c9-bff3-fb18488b9997	Grupo Cuadrante B11	Grupo comunitario del Cuadrante B11 - Zona Noreste	\N	t	f	2025-12-14 03:57:32-04	2025-12-14 03:57:32-04
019b1b01-b8e4-72d1-8386-b7c06bd101de	019b1b01-adab-713c-8ed8-ef3bdaf014ae	Grupo Cuadrante B12	Grupo comunitario del Cuadrante B12 - Zona Noreste	\N	t	f	2025-12-14 03:57:36-04	2025-12-14 03:57:36-04
019b1b01-c4d6-71cb-9165-b2b29a6e296e	019b1b01-babf-70a0-bf41-728e9604929f	Grupo Cuadrante B13	Grupo comunitario del Cuadrante B13 - Zona Noreste	\N	t	f	2025-12-14 03:57:39-04	2025-12-14 03:57:39-04
019b1b01-d1a1-7322-8055-3c505c436502	019b1b01-c6c5-7395-b99c-b7ca7c2f992a	Grupo Cuadrante B14	Grupo comunitario del Cuadrante B14 - Zona Noreste	\N	t	f	2025-12-14 03:57:42-04	2025-12-14 03:57:42-04
019b1b01-ddce-71e1-a3ec-26d61f5e7820	019b1b01-d382-7140-9329-54b105e6ef00	Grupo Cuadrante C1	Grupo comunitario del Cuadrante C1 - Zona Norte	\N	t	f	2025-12-14 03:57:45-04	2025-12-14 03:57:45-04
019b1b01-e58c-73fc-811c-58f8c6da0dd9	019b1b01-dfa0-7325-95df-f0dc6d01dfd4	Grupo Cuadrante C2	Grupo comunitario del Cuadrante C2 - Zona Norte	\N	t	f	2025-12-14 03:57:47-04	2025-12-14 03:57:47-04
019b1b01-edc4-73b8-b213-a95202d1967b	019b1b01-e7d6-71d7-9812-dd307461585f	Grupo Cuadrante C3	Grupo comunitario del Cuadrante C3 - Zona Norte	\N	t	f	2025-12-14 03:57:49-04	2025-12-14 03:57:49-04
019b1b01-f808-7328-bf0b-f5eb54061a05	019b1b01-efa9-73bf-940e-4a3240fbc80b	Grupo Cuadrante C4	Grupo comunitario del Cuadrante C4 - Zona Norte	\N	t	f	2025-12-14 03:57:52-04	2025-12-14 03:57:52-04
019b1b02-06ce-7112-bbb1-5cfc3d531cd9	019b1b01-fa4e-73a5-9c6b-a9995f059279	Grupo Cuadrante C5	Grupo comunitario del Cuadrante C5 - Zona Norte	\N	t	f	2025-12-14 03:57:56-04	2025-12-14 03:57:56-04
019b1b02-12c4-70f6-b268-68f49a06424e	019b1b02-089d-72e2-8b55-cd3e13565924	Grupo Cuadrante C6	Grupo comunitario del Cuadrante C6 - Zona Norte	\N	t	f	2025-12-14 03:57:59-04	2025-12-14 03:57:59-04
019b1b02-1e53-7326-958b-026c61c6e324	019b1b02-1487-721c-a35a-06b2c069ffea	Grupo Cuadrante C7	Grupo comunitario del Cuadrante C7 - Zona Noreste	\N	t	f	2025-12-14 03:58:02-04	2025-12-14 03:58:02-04
019b1b02-2a59-7135-a113-00a5b1ac1686	019b1b02-2096-719a-87be-1f95727fa3f4	Grupo Cuadrante C8	Grupo comunitario del Cuadrante C8 - Zona Noreste	\N	t	f	2025-12-14 03:58:05-04	2025-12-14 03:58:05-04
019b1b02-3272-706f-a8ff-9a3269703f91	019b1b02-2c98-71a1-b044-6e6d6619c18f	Grupo Cuadrante C9	Grupo comunitario del Cuadrante C9 - Zona Noreste	\N	t	f	2025-12-14 03:58:07-04	2025-12-14 03:58:07-04
019b1b02-3c1b-710f-81a9-7cab9229dc3a	019b1b02-3437-718b-b15b-9bb0d66d3959	Grupo Cuadrante C10	Grupo comunitario del Cuadrante C10 - Zona Noreste	\N	t	f	2025-12-14 03:58:09-04	2025-12-14 03:58:09-04
019b1b02-4a69-734f-a249-4c71ce99c7ce	019b1b02-3e56-7183-af6c-810c087bea77	Grupo Cuadrante C11	Grupo comunitario del Cuadrante C11 - Zona Noreste	\N	t	f	2025-12-14 03:58:13-04	2025-12-14 03:58:13-04
019b1b02-52bd-7370-8070-ed871d1b3255	019b1b02-4c5b-7386-a42e-b7a654c437cb	Grupo Cuadrante C12	Grupo comunitario del Cuadrante C12 - Zona Noreste	\N	t	f	2025-12-14 03:58:15-04	2025-12-14 03:58:15-04
019b1b02-5eab-7222-8f1f-9cd9a77c7d48	019b1b02-54a4-7129-b945-2f0f91ef3ac4	Grupo Cuadrante C13	Grupo comunitario del Cuadrante C13 - Zona Noreste	\N	t	f	2025-12-14 03:58:18-04	2025-12-14 03:58:18-04
019b1b02-6c9a-7393-b9b8-650b422e7fdb	019b1b02-6087-723a-b4d6-1bceceb78e7a	Grupo Cuadrante C14	Grupo comunitario del Cuadrante C14 - Zona Noreste	\N	t	f	2025-12-14 03:58:22-04	2025-12-14 03:58:22-04
019b1b02-78eb-7243-b3e2-f66f2f0ff88d	019b1b02-6ec7-71e9-b3c6-37a189794ef5	Grupo Cuadrante D1	Grupo comunitario del Cuadrante D1 - Zona Norte	\N	t	f	2025-12-14 03:58:25-04	2025-12-14 03:58:25-04
019b1b02-8303-72b3-b108-7caaf51529d4	019b1b02-7ad0-73d1-a4ba-41d13fb59b81	Grupo Cuadrante D2	Grupo comunitario del Cuadrante D2 - Zona Norte	\N	t	f	2025-12-14 03:58:28-04	2025-12-14 03:58:28-04
019b1b02-8b10-72d9-b3fc-517398f69432	019b1b02-84f7-70fa-89ba-38671bf623c8	Grupo Cuadrante D3	Grupo comunitario del Cuadrante D3 - Zona Norte	\N	t	f	2025-12-14 03:58:30-04	2025-12-14 03:58:30-04
019b1b02-9776-710c-aacd-f247fc8663b6	019b1b02-8d79-7300-836a-a9ecea7bd834	Grupo Cuadrante D4	Grupo comunitario del Cuadrante D4 - Zona Norte	\N	t	f	2025-12-14 03:58:33-04	2025-12-14 03:58:33-04
019b1b02-a033-739d-a1cf-4f46785c2ce4	019b1b02-99c0-7087-89c9-2cb704681f8c	Grupo Cuadrante D5	Grupo comunitario del Cuadrante D5 - Zona Norte	\N	t	f	2025-12-14 03:58:35-04	2025-12-14 03:58:35-04
019b1b02-ac55-7223-ac7a-5d9efd093d39	019b1b02-a222-72e3-88dd-c0864f7a8599	Grupo Cuadrante D6	Grupo comunitario del Cuadrante D6 - Zona Norte	\N	t	f	2025-12-14 03:58:38-04	2025-12-14 03:58:38-04
019b1b02-b859-7281-addd-1fb2cd4bec3a	019b1b02-ae2b-73b0-b239-c4be7d32653a	Grupo Cuadrante D7	Grupo comunitario del Cuadrante D7 - Zona Noreste	\N	t	f	2025-12-14 03:58:41-04	2025-12-14 03:58:41-04
019b1b02-c2a6-72ba-8333-854610c921ea	019b1b02-ba42-73ce-bd98-debe8d7ed4ac	Grupo Cuadrante D8	Grupo comunitario del Cuadrante D8 - Zona Noreste	\N	t	f	2025-12-14 03:58:44-04	2025-12-14 03:58:44-04
019b1b02-cc81-7208-8b79-05c00b50c959	019b1b02-c48c-729d-bafc-4021c1564694	Grupo Cuadrante D9	Grupo comunitario del Cuadrante D9 - Zona Noreste	\N	t	f	2025-12-14 03:58:46-04	2025-12-14 03:58:46-04
019b1b02-d686-70e8-a1f8-ae6971084cf2	019b1b02-ced5-7098-a830-8693997fcfbf	Grupo Cuadrante D10	Grupo comunitario del Cuadrante D10 - Zona Noreste	\N	t	f	2025-12-14 03:58:49-04	2025-12-14 03:58:49-04
019b1b02-e0e1-7032-9dd5-ab47c570d73a	019b1b02-d872-70b7-9448-f7df890eebe5	Grupo Cuadrante D11	Grupo comunitario del Cuadrante D11 - Zona Noreste	\N	t	f	2025-12-14 03:58:52-04	2025-12-14 03:58:52-04
019b1b02-ed1b-715d-9f90-948851db96e9	019b1b02-e328-71dc-8286-da6a3f279a90	Grupo Cuadrante D12	Grupo comunitario del Cuadrante D12 - Zona Noreste	\N	t	f	2025-12-14 03:58:55-04	2025-12-14 03:58:55-04
019b1b02-f99b-7188-a1cf-37218c4d0918	019b1b02-ef56-73d4-a8b0-47445839e2c5	Grupo Cuadrante D13	Grupo comunitario del Cuadrante D13 - Zona Noreste	\N	t	f	2025-12-14 03:58:58-04	2025-12-14 03:58:58-04
019b1b03-03fe-7056-aeae-33a221283b39	019b1b02-fb8d-7006-aba0-ece4433b1bfa	Grupo Cuadrante D14	Grupo comunitario del Cuadrante D14 - Zona Noreste	\N	t	f	2025-12-14 03:59:01-04	2025-12-14 03:59:01-04
019b1b03-1276-71c4-b86f-424aa674e0bc	019b1b03-064e-733b-850b-41c873d82eb6	Grupo Cuadrante E1	Grupo comunitario del Cuadrante E1 - Zona Norte	\N	t	f	2025-12-14 03:59:04-04	2025-12-14 03:59:04-04
019b1b03-20c0-7049-bf2b-273b5aeda7ae	019b1b03-1453-7277-95fd-0e0f8fedf0f4	Grupo Cuadrante E2	Grupo comunitario del Cuadrante E2 - Zona Norte	\N	t	f	2025-12-14 03:59:08-04	2025-12-14 03:59:08-04
019b1b03-2f29-70cd-ba65-a5e5280a404e	019b1b03-22a7-72f4-b78b-022e3c1430bf	Grupo Cuadrante E3	Grupo comunitario del Cuadrante E3 - Zona Norte	\N	t	f	2025-12-14 03:59:12-04	2025-12-14 03:59:12-04
019b1b03-3957-72c8-b475-4fda962a1247	019b1b03-311d-7047-a48d-5d833ce6f19c	Grupo Cuadrante E4	Grupo comunitario del Cuadrante E4 - Zona Norte	\N	t	f	2025-12-14 03:59:14-04	2025-12-14 03:59:14-04
019b1b03-43ae-705a-a2f6-7ae6914f518f	019b1b03-3b40-73bc-8ec5-3d69c80687aa	Grupo Cuadrante E5	Grupo comunitario del Cuadrante E5 - Zona Norte	\N	t	f	2025-12-14 03:59:17-04	2025-12-14 03:59:17-04
019b1b03-5225-704e-8649-9f07d13dcf6e	019b1b03-457c-70cd-8738-e538630c9fe1	Grupo Cuadrante E6	Grupo comunitario del Cuadrante E6 - Zona Norte	\N	t	f	2025-12-14 03:59:21-04	2025-12-14 03:59:21-04
019b1b03-5e88-7108-9cb9-84e7a37d260f	019b1b03-5411-7062-85d6-be858b564b4d	Grupo Cuadrante E7	Grupo comunitario del Cuadrante E7 - Zona Noreste	\N	t	f	2025-12-14 03:59:24-04	2025-12-14 03:59:24-04
019b1b03-68f4-72ed-9b1b-64ba3552133e	019b1b03-606b-7024-8a0d-6ef4eac39ba0	Grupo Cuadrante E8	Grupo comunitario del Cuadrante E8 - Zona Noreste	\N	t	f	2025-12-14 03:59:26-04	2025-12-14 03:59:26-04
019b1b03-77e4-723f-9485-e965363569aa	019b1b03-6aef-71ab-903d-b972fcf133fb	Grupo Cuadrante E9	Grupo comunitario del Cuadrante E9 - Zona Noreste	\N	t	f	2025-12-14 03:59:30-04	2025-12-14 03:59:30-04
019b1b03-83ee-716d-a2ba-98f9c5a7ae96	019b1b03-7a35-7363-a960-71dad55030f6	Grupo Cuadrante E10	Grupo comunitario del Cuadrante E10 - Zona Noreste	\N	t	f	2025-12-14 03:59:33-04	2025-12-14 03:59:33-04
019b1b03-90d4-7336-b22d-63f2dfe8d297	019b1b03-864a-720d-af51-c2e142d83192	Grupo Cuadrante E11	Grupo comunitario del Cuadrante E11 - Zona Noreste	\N	t	f	2025-12-14 03:59:37-04	2025-12-14 03:59:37-04
019b1b03-9b2e-70d8-af4c-d8b9b4a14539	019b1b03-92d4-70ca-a674-fa7e7d312fcb	Grupo Cuadrante E12	Grupo comunitario del Cuadrante E12 - Zona Noreste	\N	t	f	2025-12-14 03:59:39-04	2025-12-14 03:59:39-04
019b1b03-a388-71dc-87dd-da69b18d8faf	019b1b03-9d6e-7103-a700-066291349bae	Grupo Cuadrante E13	Grupo comunitario del Cuadrante E13 - Zona Noreste	\N	t	f	2025-12-14 03:59:41-04	2025-12-14 03:59:41-04
019b1b03-b03f-7240-9e79-cc73b72f14fd	019b1b03-a5e4-7160-b485-df05686f7cc0	Grupo Cuadrante E14	Grupo comunitario del Cuadrante E14 - Zona Noreste	\N	t	f	2025-12-14 03:59:45-04	2025-12-14 03:59:45-04
019b1b03-beb6-7190-b3b0-4735285307c1	019b1b03-b271-708f-9d1e-11022509f1a7	Grupo Cuadrante F1	Grupo comunitario del Cuadrante F1 - Zona Norte	\N	t	f	2025-12-14 03:59:48-04	2025-12-14 03:59:48-04
019b1b03-ccd8-71ee-ad87-6e3171472f28	019b1b03-c0b4-702e-8df4-ec87472ccb32	Grupo Cuadrante F2	Grupo comunitario del Cuadrante F2 - Zona Norte	\N	t	f	2025-12-14 03:59:52-04	2025-12-14 03:59:52-04
019b1b03-d93b-70bc-aa49-4a01d254e1c8	019b1b03-cf19-7258-91b6-e0d18649a584	Grupo Cuadrante F3	Grupo comunitario del Cuadrante F3 - Zona Norte	\N	t	f	2025-12-14 03:59:55-04	2025-12-14 03:59:55-04
019b1b03-e3a3-701f-b513-ec242927ea8d	019b1b03-db17-70b0-80b4-6dcbe4ad7985	Grupo Cuadrante F4	Grupo comunitario del Cuadrante F4 - Zona Norte	\N	t	f	2025-12-14 03:59:58-04	2025-12-14 03:59:58-04
019b1b03-eff1-71ab-b91b-2ce2d19256ba	019b1b03-e590-72f7-a6e9-189cc2820985	Grupo Cuadrante F5	Grupo comunitario del Cuadrante F5 - Zona Norte	\N	t	f	2025-12-14 04:00:01-04	2025-12-14 04:00:01-04
019b1b03-fbf6-731c-9658-1d5257fd24b1	019b1b03-f1d8-7298-8a7d-0d43022c3b16	Grupo Cuadrante F6	Grupo comunitario del Cuadrante F6 - Zona Norte	\N	t	f	2025-12-14 04:00:04-04	2025-12-14 04:00:04-04
019b1b04-0411-7180-9495-43044d3b8c1d	019b1b03-fe27-71b7-a22b-e058a57dc398	Grupo Cuadrante F7	Grupo comunitario del Cuadrante F7 - Zona Noreste	\N	t	f	2025-12-14 04:00:06-04	2025-12-14 04:00:06-04
019b1b04-0c0e-7221-a2f9-ec8e59321ed6	019b1b04-05f5-7178-9d36-dd2caa7a081d	Grupo Cuadrante F8	Grupo comunitario del Cuadrante F8 - Zona Noreste	\N	t	f	2025-12-14 04:00:08-04	2025-12-14 04:00:08-04
019b1b04-143d-721e-8ac6-ae4df6e00be4	019b1b04-0e32-73cc-aba8-319497bae801	Grupo Cuadrante F9	Grupo comunitario del Cuadrante F9 - Zona Noreste	\N	t	f	2025-12-14 04:00:10-04	2025-12-14 04:00:10-04
019b1b04-22d8-734e-9f09-df8db945e33d	019b1b04-162b-71ad-9117-189c0df75323	Grupo Cuadrante F10	Grupo comunitario del Cuadrante F10 - Zona Noreste	\N	t	f	2025-12-14 04:00:14-04	2025-12-14 04:00:14-04
019b1b04-2b1e-722b-9fbc-98f3c24b2861	019b1b04-24a1-70a8-8455-e15c7d04d8c8	Grupo Cuadrante F11	Grupo comunitario del Cuadrante F11 - Zona Noreste	\N	t	f	2025-12-14 04:00:16-04	2025-12-14 04:00:16-04
019b1b04-38db-70bf-add6-c6e95623ff48	019b1b04-2d0c-72ae-bbea-b04947d481f3	Grupo Cuadrante F12	Grupo comunitario del Cuadrante F12 - Zona Noreste	\N	t	f	2025-12-14 04:00:20-04	2025-12-14 04:00:20-04
019b1b04-40fa-7037-aeff-393ae01398e8	019b1b04-3b1e-73f7-9b18-1d55ad45ca47	Grupo Cuadrante F13	Grupo comunitario del Cuadrante F13 - Zona Noreste	\N	t	f	2025-12-14 04:00:22-04	2025-12-14 04:00:22-04
019b1b04-4d25-739f-ba8d-3cfc3c3171af	019b1b04-42e2-73f2-8612-e55507c4f3ba	Grupo Cuadrante F14	Grupo comunitario del Cuadrante F14 - Zona Noreste	\N	t	f	2025-12-14 04:00:25-04	2025-12-14 04:00:25-04
019b1b04-5b67-7345-afc3-7979316156a1	019b1b04-4f69-73f7-b455-274d469a1dbe	Grupo Cuadrante G1	Grupo comunitario del Cuadrante G1 - Zona Norte	\N	t	f	2025-12-14 04:00:29-04	2025-12-14 04:00:29-04
019b1b04-6786-7033-8edf-739952267df3	019b1b04-5d3e-733a-a177-2bc78f422970	Grupo Cuadrante G2	Grupo comunitario del Cuadrante G2 - Zona Norte	\N	t	f	2025-12-14 04:00:32-04	2025-12-14 04:00:32-04
019b1b04-6f6f-7129-974b-0b083bb311f8	019b1b04-6969-71ee-85ca-10b94d9a5c4c	Grupo Cuadrante G3	Grupo comunitario del Cuadrante G3 - Zona Norte	\N	t	f	2025-12-14 04:00:34-04	2025-12-14 04:00:34-04
019b1b04-7e69-7073-ab9b-8efe9bbacab5	019b1b04-71b5-720a-9fee-4b87397918dd	Grupo Cuadrante G4	Grupo comunitario del Cuadrante G4 - Zona Norte	\N	t	f	2025-12-14 04:00:37-04	2025-12-14 04:00:37-04
019b1b04-8cc4-7287-92fa-e8f400f9c07a	019b1b04-8037-71f5-a2c4-0e43a29942c1	Grupo Cuadrante G5	Grupo comunitario del Cuadrante G5 - Zona Norte	\N	t	f	2025-12-14 04:00:41-04	2025-12-14 04:00:41-04
019b1b04-9b32-705a-bf66-1df4ca6bd802	019b1b04-8f13-725e-83d3-bbda0dd5ff9d	Grupo Cuadrante G6	Grupo comunitario del Cuadrante G6 - Zona Norte	\N	t	f	2025-12-14 04:00:45-04	2025-12-14 04:00:45-04
019b1b04-a9b8-7204-b4a6-bb5d99576607	019b1b04-9d69-7219-8474-939c8da540ab	Grupo Cuadrante G7	Grupo comunitario del Cuadrante G7 - Zona Noreste	\N	t	f	2025-12-14 04:00:49-04	2025-12-14 04:00:49-04
019b1b04-b3de-72bd-838a-f0fdd750c92f	019b1b04-abed-7030-9acd-b357f019d8f2	Grupo Cuadrante G8	Grupo comunitario del Cuadrante G8 - Zona Noreste	\N	t	f	2025-12-14 04:00:51-04	2025-12-14 04:00:51-04
019b1b04-c206-720b-bfae-29b4431ca997	019b1b04-b5de-70fe-9cec-b5600a6027cf	Grupo Cuadrante G9	Grupo comunitario del Cuadrante G9 - Zona Noreste	\N	t	f	2025-12-14 04:00:55-04	2025-12-14 04:00:55-04
019b1b04-d06b-7352-be38-9c28dae7ace3	019b1b04-c446-735f-b54f-a00b683f3188	Grupo Cuadrante G10	Grupo comunitario del Cuadrante G10 - Zona Noreste	\N	t	f	2025-12-14 04:00:58-04	2025-12-14 04:00:58-04
019b1b04-d8c5-714d-abcc-f0c7fd29df71	019b1b04-d24f-7063-8705-be62894962db	Grupo Cuadrante G11	Grupo comunitario del Cuadrante G11 - Zona Noreste	\N	t	f	2025-12-14 04:01:01-04	2025-12-14 04:01:01-04
019b1b04-e508-732c-99c2-efb71d266ba4	019b1b04-dac1-709e-a90c-2b7b857767c1	Grupo Cuadrante G12	Grupo comunitario del Cuadrante G12 - Zona Noreste	\N	t	f	2025-12-14 04:01:04-04	2025-12-14 04:01:04-04
019b1b04-ed48-7061-a0e8-9ce76ab80dd8	019b1b04-e73c-72b1-b3fb-9085c88e37de	Grupo Cuadrante G13	Grupo comunitario del Cuadrante G13 - Zona Noreste	\N	t	f	2025-12-14 04:01:06-04	2025-12-14 04:01:06-04
019b1b04-f9e6-72e7-a02b-aa752517f4d8	019b1b04-ef2d-7199-b4cf-92b368d6424e	Grupo Cuadrante G14	Grupo comunitario del Cuadrante G14 - Zona Noreste	\N	t	f	2025-12-14 04:01:09-04	2025-12-14 04:01:09-04
019b1b05-066b-718a-93b8-133ac03067dc	019b1b04-fc3c-739c-af75-4fa9e4d5f5a1	Grupo Cuadrante H1	Grupo comunitario del Cuadrante H1 - Zona Norte	\N	t	f	2025-12-14 04:01:12-04	2025-12-14 04:01:12-04
019b1b05-1443-7294-95f6-14bb720421b1	019b1b05-084b-73a1-b8df-4e3c0a9aed7b	Grupo Cuadrante H2	Grupo comunitario del Cuadrante H2 - Zona Norte	\N	t	f	2025-12-14 04:01:16-04	2025-12-14 04:01:16-04
019b1b05-1c74-724c-b8be-b80cd55d10d6	019b1b05-1698-7373-9447-5c262e4fb07b	Grupo Cuadrante H3	Grupo comunitario del Cuadrante H3 - Zona Norte	\N	t	f	2025-12-14 04:01:18-04	2025-12-14 04:01:18-04
019b1b05-2669-70d6-9bfd-e69a896fbb6b	019b1b05-1e4d-73d3-a47d-99202f27dad6	Grupo Cuadrante H4	Grupo comunitario del Cuadrante H4 - Zona Norte	\N	t	f	2025-12-14 04:01:21-04	2025-12-14 04:01:21-04
019b1b05-3252-7321-9e3c-02394c058c5f	019b1b05-2835-73c5-88b3-3d70af34802f	Grupo Cuadrante H5	Grupo comunitario del Cuadrante H5 - Zona Norte	\N	t	f	2025-12-14 04:01:24-04	2025-12-14 04:01:24-04
019b1b05-4045-738f-8ec6-8ced89b618ab	019b1b05-3430-7265-b028-1673a7f6484d	Grupo Cuadrante H6	Grupo comunitario del Cuadrante H6 - Zona Norte	\N	t	f	2025-12-14 04:01:27-04	2025-12-14 04:01:27-04
019b1b05-4cb8-7045-a008-743e84a1437a	019b1b05-427e-7187-b847-299a1d2ead23	Grupo Cuadrante H7	Grupo comunitario del Cuadrante H7 - Zona Noreste	\N	t	f	2025-12-14 04:01:30-04	2025-12-14 04:01:30-04
019b1b05-54e6-73ee-acb1-efa7792e4df2	019b1b05-4e93-73fd-8e15-2e1c3461d981	Grupo Cuadrante H8	Grupo comunitario del Cuadrante H8 - Zona Noreste	\N	t	f	2025-12-14 04:01:32-04	2025-12-14 04:01:32-04
019b1b05-5e81-71ec-8931-e72434cf4972	019b1b05-56b8-702d-bd58-ee9e6b1cbe94	Grupo Cuadrante H9	Grupo comunitario del Cuadrante H9 - Zona Noreste	\N	t	f	2025-12-14 04:01:35-04	2025-12-14 04:01:35-04
019b1b05-68c1-71c3-b610-d89cfe41d4d5	019b1b05-60e0-72a8-81bb-34663dce944e	Grupo Cuadrante H10	Grupo comunitario del Cuadrante H10 - Zona Noreste	\N	t	f	2025-12-14 04:01:37-04	2025-12-14 04:01:37-04
019b1b05-70fe-7204-a5b8-cad093bbeb1f	019b1b05-6b08-737b-8ab6-4c427cf7cedb	Grupo Cuadrante H11	Grupo comunitario del Cuadrante H11 - Zona Noreste	\N	t	f	2025-12-14 04:01:40-04	2025-12-14 04:01:40-04
019b1b05-7b2e-72a3-8571-67bab28b24bc	019b1b05-72e9-7015-82af-9e6ad8a0555f	Grupo Cuadrante H12	Grupo comunitario del Cuadrante H12 - Zona Noreste	\N	t	f	2025-12-14 04:01:42-04	2025-12-14 04:01:42-04
019b1b05-856a-71f0-b3c7-24ce9dec2ea7	019b1b05-7d10-7221-9984-19f2609210d2	Grupo Cuadrante H13	Grupo comunitario del Cuadrante H13 - Zona Noreste	\N	t	f	2025-12-14 04:01:45-04	2025-12-14 04:01:45-04
019b1b05-91be-70eb-90cf-c2d82d4e5f63	019b1b05-8776-722b-80d2-7ddda939c8af	Grupo Cuadrante H14	Grupo comunitario del Cuadrante H14 - Zona Noreste	\N	t	f	2025-12-14 04:01:48-04	2025-12-14 04:01:48-04
019b1b05-a15b-7169-b12c-e3e9f1103edb	019b1b05-9424-71e6-a941-67523195d2de	Grupo Cuadrante I1	Grupo comunitario del Cuadrante I1 - Zona Norte	\N	t	f	2025-12-14 04:01:52-04	2025-12-14 04:01:52-04
019b1b05-b0a2-7082-9884-b2139df963dc	019b1b05-a347-7088-8b20-84fb3e2d1de9	Grupo Cuadrante I2	Grupo comunitario del Cuadrante I2 - Zona Norte	\N	t	f	2025-12-14 04:01:56-04	2025-12-14 04:01:56-04
019b1b05-bf3c-72b7-85d0-376443339aef	019b1b05-b2f6-7208-8806-f482ce8fd562	Grupo Cuadrante I3	Grupo comunitario del Cuadrante I3 - Zona Norte	\N	t	f	2025-12-14 04:02:00-04	2025-12-14 04:02:00-04
019b1b05-c799-719d-b616-6a051f9bb6e0	019b1b05-c131-7161-bef2-f1793758fbca	Grupo Cuadrante I4	Grupo comunitario del Cuadrante I4 - Zona Norte	\N	t	f	2025-12-14 04:02:02-04	2025-12-14 04:02:02-04
019b1b05-d405-720d-a9ca-1e2b91d14983	019b1b05-c98d-730c-a3b7-13361675e18e	Grupo Cuadrante I5	Grupo comunitario del Cuadrante I5 - Zona Norte	\N	t	f	2025-12-14 04:02:05-04	2025-12-14 04:02:05-04
019b1b05-e0cc-7057-943e-5bd096fa95b5	019b1b05-d667-70cd-8c6b-ce43bfa1c940	Grupo Cuadrante I6	Grupo comunitario del Cuadrante I6 - Zona Norte	\N	t	f	2025-12-14 04:02:08-04	2025-12-14 04:02:08-04
019b1b05-ed49-704b-a61c-9d2a8b9b9723	019b1b05-e2b2-70c5-8625-c023829a6753	Grupo Cuadrante I7	Grupo comunitario del Cuadrante I7 - Zona Noreste	\N	t	f	2025-12-14 04:02:11-04	2025-12-14 04:02:11-04
019b1b05-f81c-71d4-b592-222613540f30	019b1b05-ef3f-7142-a4ec-95aabc937147	Grupo Cuadrante I8	Grupo comunitario del Cuadrante I8 - Zona Noreste	\N	t	f	2025-12-14 04:02:14-04	2025-12-14 04:02:14-04
019b1b06-031a-7363-b450-7d22fe2679e3	019b1b05-fa84-73cc-8e60-05030a991a26	Grupo Cuadrante I9	Grupo comunitario del Cuadrante I9 - Zona Noreste	\N	t	f	2025-12-14 04:02:17-04	2025-12-14 04:02:17-04
019b1b06-0d67-7331-a407-08f65f784436	019b1b06-0505-7192-9854-e9987577741e	Grupo Cuadrante I10	Grupo comunitario del Cuadrante I10 - Zona Noreste	\N	t	f	2025-12-14 04:02:20-04	2025-12-14 04:02:20-04
019b1b06-1b8b-709a-8d5e-393c3b8f6bc3	019b1b06-0f4d-70d0-afe2-a09189793751	Grupo Cuadrante I11	Grupo comunitario del Cuadrante I11 - Zona Noreste	\N	t	f	2025-12-14 04:02:23-04	2025-12-14 04:02:23-04
019b1b06-25c2-70e1-ba3d-457097ec0c8c	019b1b06-1dcb-7290-a39f-4661ce8a0cb8	Grupo Cuadrante I12	Grupo comunitario del Cuadrante I12 - Zona Noreste	\N	t	f	2025-12-14 04:02:26-04	2025-12-14 04:02:26-04
019b1b06-2da6-7277-a7c6-203390956406	019b1b06-2791-7062-ad29-ce1e6a0c891d	Grupo Cuadrante I13	Grupo comunitario del Cuadrante I13 - Zona Noreste	\N	t	f	2025-12-14 04:02:28-04	2025-12-14 04:02:28-04
019b1b06-3c40-70d1-b648-6ebf924548a2	019b1b06-3005-7210-8845-9a346e15492d	Grupo Cuadrante I14	Grupo comunitario del Cuadrante I14 - Zona Noreste	\N	t	f	2025-12-14 04:02:32-04	2025-12-14 04:02:32-04
019b1b06-4b3f-73be-a8c4-ae69c3e4ba04	019b1b06-3e8e-719e-8779-8ac6b995da23	Grupo Cuadrante J1	Grupo comunitario del Cuadrante J1 - Zona Sur	\N	t	f	2025-12-14 04:02:35-04	2025-12-14 04:02:35-04
019b1b06-5366-738f-a701-1cfe8cdff067	019b1b06-4d37-73c8-b750-b1d0f9e54a90	Grupo Cuadrante J2	Grupo comunitario del Cuadrante J2 - Zona Sur	\N	t	f	2025-12-14 04:02:38-04	2025-12-14 04:02:38-04
019b1b06-5ba7-730c-8475-66eeca84f6a0	019b1b06-55b8-71e4-9a6b-43f2c4c6b84f	Grupo Cuadrante J3	Grupo comunitario del Cuadrante J3 - Zona Sur	\N	t	f	2025-12-14 04:02:40-04	2025-12-14 04:02:40-04
019b1b06-699b-720e-9954-1bc0ddca2bc2	019b1b06-5d8a-73c8-ace3-11998b0a3a0b	Grupo Cuadrante J4	Grupo comunitario del Cuadrante J4 - Zona Sur	\N	t	f	2025-12-14 04:02:43-04	2025-12-14 04:02:43-04
019b1b06-744c-70f7-a15d-3b95cf5dcd8c	019b1b06-6bea-70a0-bbec-74c3a605a188	Grupo Cuadrante J5	Grupo comunitario del Cuadrante J5 - Zona Sur	\N	t	f	2025-12-14 04:02:46-04	2025-12-14 04:02:46-04
019b1b06-8077-7190-9b54-c36bccf7e4fd	019b1b06-7624-73d8-bc4c-5aac69c3122a	Grupo Cuadrante J6	Grupo comunitario del Cuadrante J6 - Zona Sur	\N	t	f	2025-12-14 04:02:49-04	2025-12-14 04:02:49-04
019b1b06-8e7a-73bb-b1ab-9f515a8811b4	019b1b06-8259-708d-9368-590c022bbc08	Grupo Cuadrante J7	Grupo comunitario del Cuadrante J7 - Zona Este	\N	t	f	2025-12-14 04:02:53-04	2025-12-14 04:02:53-04
019b1b06-9ad9-706f-856f-e511f4fcfb1b	019b1b06-90ac-71ba-af56-9b0237bf030c	Grupo Cuadrante J8	Grupo comunitario del Cuadrante J8 - Zona Este	\N	t	f	2025-12-14 04:02:56-04	2025-12-14 04:02:56-04
019b1b06-a4df-70ea-bb92-e63a4e3126b3	019b1b06-9d0f-70c5-81b0-3c3bf2286e36	Grupo Cuadrante J9	Grupo comunitario del Cuadrante J9 - Zona Este	\N	t	f	2025-12-14 04:02:58-04	2025-12-14 04:02:58-04
019b1b06-af38-714e-9b36-995d69d9d53c	019b1b06-a6c8-7124-8f16-db232fa6ab80	Grupo Cuadrante J10	Grupo comunitario del Cuadrante J10 - Zona Este	\N	t	f	2025-12-14 04:03:01-04	2025-12-14 04:03:01-04
019b1b06-bd8d-725d-a6ec-c0d70ace20fc	019b1b06-b164-70bf-a417-a0122e5c951f	Grupo Cuadrante J11	Grupo comunitario del Cuadrante J11 - Zona Este	\N	t	f	2025-12-14 04:03:05-04	2025-12-14 04:03:05-04
019b1b06-c550-7174-bf74-69d5d61e9d5f	019b1b06-bf60-72b2-a664-a63df1963b5e	Grupo Cuadrante J12	Grupo comunitario del Cuadrante J12 - Zona Este	\N	t	f	2025-12-14 04:03:07-04	2025-12-14 04:03:07-04
019b1b06-d150-7107-9b89-20fc086d6f55	019b1b06-c741-7118-b644-21ff68053554	Grupo Cuadrante J13	Grupo comunitario del Cuadrante J13 - Zona Este	\N	t	f	2025-12-14 04:03:10-04	2025-12-14 04:03:10-04
019b1b06-df9d-71f1-aaf5-86d0d001b2f3	019b1b06-d38c-7124-80fe-85ce8c43272a	Grupo Cuadrante J14	Grupo comunitario del Cuadrante J14 - Zona Este	\N	t	f	2025-12-14 04:03:13-04	2025-12-14 04:03:13-04
019b1b06-eb78-70f0-9719-db4cac059b33	019b1b06-e172-7010-9610-29899d48df98	Grupo Cuadrante K1	Grupo comunitario del Cuadrante K1 - Zona Sur	\N	t	f	2025-12-14 04:03:16-04	2025-12-14 04:03:16-04
019b1b06-f787-7264-8e5d-32fbf957ac0c	019b1b06-ed57-7192-b84c-d58cd6730caf	Grupo Cuadrante K2	Grupo comunitario del Cuadrante K2 - Zona Sur	\N	t	f	2025-12-14 04:03:20-04	2025-12-14 04:03:20-04
019b1b07-01e0-70db-9c9c-4103dcd3631e	019b1b06-f9d7-736d-94f3-034c142e832f	Grupo Cuadrante K3	Grupo comunitario del Cuadrante K3 - Zona Sur	\N	t	f	2025-12-14 04:03:22-04	2025-12-14 04:03:22-04
019b1b07-1028-72f5-b6cd-dad7ce0c0286	019b1b07-0428-7081-9326-d596bd1c842c	Grupo Cuadrante K4	Grupo comunitario del Cuadrante K4 - Zona Sur	\N	t	f	2025-12-14 04:03:26-04	2025-12-14 04:03:26-04
019b1b07-1c3f-72dc-b199-0d6b0def6840	019b1b07-1214-73b9-a753-50f118f50722	Grupo Cuadrante K5	Grupo comunitario del Cuadrante K5 - Zona Sur	\N	t	f	2025-12-14 04:03:29-04	2025-12-14 04:03:29-04
019b1b07-2ae2-73a9-87aa-937a653cb033	019b1b07-1e25-71a6-b701-d0bd2cbd7e1d	Grupo Cuadrante K6	Grupo comunitario del Cuadrante K6 - Zona Sur	\N	t	f	2025-12-14 04:03:33-04	2025-12-14 04:03:33-04
019b1b07-3891-7042-b9c4-d0474b6bc45c	019b1b07-2cbd-71bf-a5a1-292b7c656f19	Grupo Cuadrante K7	Grupo comunitario del Cuadrante K7 - Zona Este	\N	t	f	2025-12-14 04:03:36-04	2025-12-14 04:03:36-04
019b1b07-42a6-7290-906d-72f21801e3ba	019b1b07-3ace-7117-9bcf-490f6410cfed	Grupo Cuadrante K8	Grupo comunitario del Cuadrante K8 - Zona Este	\N	t	f	2025-12-14 04:03:39-04	2025-12-14 04:03:39-04
019b1b07-4afe-72fc-8f1d-b09c61279c34	019b1b07-44f9-7199-ac4f-4fd239445e70	Grupo Cuadrante K9	Grupo comunitario del Cuadrante K9 - Zona Este	\N	t	f	2025-12-14 04:03:41-04	2025-12-14 04:03:41-04
019b1b07-58e8-73bc-b511-799bedec19a9	019b1b07-4cee-70c6-a1ba-225a76fc7cfd	Grupo Cuadrante K10	Grupo comunitario del Cuadrante K10 - Zona Este	\N	t	f	2025-12-14 04:03:45-04	2025-12-14 04:03:45-04
019b1b07-63b9-7129-83be-64c9d5a56afb	019b1b07-5b40-708c-bc97-dad916399c87	Grupo Cuadrante K11	Grupo comunitario del Cuadrante K11 - Zona Este	\N	t	f	2025-12-14 04:03:47-04	2025-12-14 04:03:47-04
019b1b07-6c1d-72bf-b272-8262c283e243	019b1b07-65ac-720f-8025-25cea0e703e5	Grupo Cuadrante K12	Grupo comunitario del Cuadrante K12 - Zona Este	\N	t	f	2025-12-14 04:03:49-04	2025-12-14 04:03:49-04
019b1b07-7475-72ed-af94-1e1e9e103b6e	019b1b07-6e61-70f3-bebc-d6195f5229b1	Grupo Cuadrante K13	Grupo comunitario del Cuadrante K13 - Zona Este	\N	t	f	2025-12-14 04:03:52-04	2025-12-14 04:03:52-04
019b1b07-82f2-71a5-8409-3720bab1ec3d	019b1b07-76c1-731e-a5d5-447fb8f79ba6	Grupo Cuadrante K14	Grupo comunitario del Cuadrante K14 - Zona Este	\N	t	f	2025-12-14 04:03:55-04	2025-12-14 04:03:55-04
019b1b07-9140-71d1-a8e1-732730e1b96b	019b1b07-853e-708c-bfee-447d882dc7c5	Grupo Cuadrante L1	Grupo comunitario del Cuadrante L1 - Zona Sur	\N	t	f	2025-12-14 04:03:59-04	2025-12-14 04:03:59-04
019b1b07-9a16-71a4-a8ba-25568b2d6c47	019b1b07-931f-70e3-80bb-0e8a9cb3601c	Grupo Cuadrante L2	Grupo comunitario del Cuadrante L2 - Zona Sur	\N	t	f	2025-12-14 04:04:01-04	2025-12-14 04:04:01-04
019b1b07-a86e-7244-9623-92e279e6a342	019b1b07-9c4d-709a-9806-3d88c99b5b64	Grupo Cuadrante L3	Grupo comunitario del Cuadrante L3 - Zona Sur	\N	t	f	2025-12-14 04:04:05-04	2025-12-14 04:04:05-04
019b1b07-b50c-71fa-b5d7-b243071d241a	019b1b07-aab5-70e7-93fd-945f5f2bbe9e	Grupo Cuadrante L4	Grupo comunitario del Cuadrante L4 - Zona Sur	\N	t	f	2025-12-14 04:04:08-04	2025-12-14 04:04:08-04
019b1b07-c194-7385-8779-af5e6667fe98	019b1b07-b75e-73ef-befe-a15908c3fe23	Grupo Cuadrante L5	Grupo comunitario del Cuadrante L5 - Zona Sur	\N	t	f	2025-12-14 04:04:11-04	2025-12-14 04:04:11-04
019b1b07-cf45-7269-80db-5abe8e7142c6	019b1b07-c367-71d9-8d78-9544e21b9723	Grupo Cuadrante L6	Grupo comunitario del Cuadrante L6 - Zona Sur	\N	t	f	2025-12-14 04:04:15-04	2025-12-14 04:04:15-04
019b1b07-d73e-716c-8a48-e2e568fe4045	019b1b07-d138-7082-9013-e2d74695e2be	Grupo Cuadrante L7	Grupo comunitario del Cuadrante L7 - Zona Este	\N	t	f	2025-12-14 04:04:17-04	2025-12-14 04:04:17-04
019b1b07-df9f-73a9-87dd-ee78950793fc	019b1b07-d992-71d7-b7d3-272ef49174a3	Grupo Cuadrante L8	Grupo comunitario del Cuadrante L8 - Zona Este	\N	t	f	2025-12-14 04:04:19-04	2025-12-14 04:04:19-04
019b1b07-ee56-73a6-80d9-7bc61d644978	019b1b07-e18b-732d-8b72-b7b2a2a50e18	Grupo Cuadrante L9	Grupo comunitario del Cuadrante L9 - Zona Este	\N	t	f	2025-12-14 04:04:23-04	2025-12-14 04:04:23-04
019b1b07-fa62-73a5-9e5a-aacc6c473775	019b1b07-f037-701d-bbf0-1bc28af2c0da	Grupo Cuadrante L10	Grupo comunitario del Cuadrante L10 - Zona Este	\N	t	f	2025-12-14 04:04:26-04	2025-12-14 04:04:26-04
019b1b08-04cb-7276-aec0-9ccfbe295412	019b1b07-fc5e-71db-952a-7afb885b0168	Grupo Cuadrante L11	Grupo comunitario del Cuadrante L11 - Zona Este	\N	t	f	2025-12-14 04:04:29-04	2025-12-14 04:04:29-04
019b1b08-10f9-73cc-8253-1cf57a47b2b6	019b1b08-069f-7193-bde3-69643c8a5088	Grupo Cuadrante L12	Grupo comunitario del Cuadrante L12 - Zona Este	\N	t	f	2025-12-14 04:04:32-04	2025-12-14 04:04:32-04
019b1b08-1940-716e-b12a-01872d16a73e	019b1b08-133a-7057-b23e-7bd07c0a89e1	Grupo Cuadrante L13	Grupo comunitario del Cuadrante L13 - Zona Este	\N	t	f	2025-12-14 04:04:34-04	2025-12-14 04:04:34-04
019b1b08-2577-716a-bcb0-404d74fa6d6c	019b1b08-1b2f-729f-b301-bf498e5f78cd	Grupo Cuadrante L14	Grupo comunitario del Cuadrante L14 - Zona Este	\N	t	f	2025-12-14 04:04:37-04	2025-12-14 04:04:37-04
019b1b08-2dd9-70cb-a98c-968c75a770ec	019b1b08-27b8-7047-b95d-f93a453705ab	Grupo Cuadrante M1	Grupo comunitario del Cuadrante M1 - Zona Sur	\N	t	f	2025-12-14 04:04:39-04	2025-12-14 04:04:39-04
019b1b08-3c25-7341-9d85-dc6bdc94a958	019b1b08-2fa7-71e0-8ea1-4af868596e9c	Grupo Cuadrante M2	Grupo comunitario del Cuadrante M2 - Zona Sur	\N	t	f	2025-12-14 04:04:43-04	2025-12-14 04:04:43-04
019b1b08-440d-7025-ad55-6189e55991ac	019b1b08-3e22-73b2-af91-2e8d7e3183f2	Grupo Cuadrante M3	Grupo comunitario del Cuadrante M3 - Zona Sur	\N	t	f	2025-12-14 04:04:45-04	2025-12-14 04:04:45-04
019b1b08-4c68-7065-a2b6-bac236c92e18	019b1b08-4673-71aa-9844-feab48b5ddd8	Grupo Cuadrante M4	Grupo comunitario del Cuadrante M4 - Zona Sur	\N	t	f	2025-12-14 04:04:47-04	2025-12-14 04:04:47-04
019b1b08-5695-7124-b6a7-750c4c82aa34	019b1b08-4e4e-7214-a70f-93591e738cd1	Grupo Cuadrante M5	Grupo comunitario del Cuadrante M5 - Zona Sur	\N	t	f	2025-12-14 04:04:49-04	2025-12-14 04:04:49-04
019b1b08-60c2-7323-b2de-22326cd29d47	019b1b08-5862-71e7-aa47-178f0426c4a9	Grupo Cuadrante M6	Grupo comunitario del Cuadrante M6 - Zona Sur	\N	t	f	2025-12-14 04:04:52-04	2025-12-14 04:04:52-04
019b1b08-6d20-72e9-be88-f9fde3a1957e	019b1b08-62ab-7222-9376-9f161f53a238	Grupo Cuadrante M7	Grupo comunitario del Cuadrante M7 - Zona Este	\N	t	f	2025-12-14 04:04:55-04	2025-12-14 04:04:55-04
019b1b08-7b52-73c5-b230-68755554b298	019b1b08-6efd-7226-8ba4-701583fa74fa	Grupo Cuadrante M8	Grupo comunitario del Cuadrante M8 - Zona Este	\N	t	f	2025-12-14 04:04:59-04	2025-12-14 04:04:59-04
019b1b08-89eb-71e4-bb0d-74619b5f69a1	019b1b08-7d27-71d2-8367-879cb4c71d42	Grupo Cuadrante M9	Grupo comunitario del Cuadrante M9 - Zona Este	\N	t	f	2025-12-14 04:05:03-04	2025-12-14 04:05:03-04
019b1b08-982a-71c5-910f-1ef5ef385c80	019b1b08-8bc8-721e-bfdd-1e2dbbe06bb6	Grupo Cuadrante M10	Grupo comunitario del Cuadrante M10 - Zona Este	\N	t	f	2025-12-14 04:05:06-04	2025-12-14 04:05:06-04
019b1b08-a1e9-72ad-b444-ef33c2d7b611	019b1b08-99fa-7087-9825-ddde7eaf7f42	Grupo Cuadrante M11	Grupo comunitario del Cuadrante M11 - Zona Este	\N	t	f	2025-12-14 04:05:09-04	2025-12-14 04:05:09-04
019b1b08-b063-73a1-bc51-d82d54442c30	019b1b08-a427-7280-b2ab-0ae1edfe054d	Grupo Cuadrante M12	Grupo comunitario del Cuadrante M12 - Zona Este	\N	t	f	2025-12-14 04:05:12-04	2025-12-14 04:05:12-04
019b1b08-bd1b-72b3-8e5f-40c6796243d0	019b1b08-b23b-702d-a8a7-f1480df8f7f4	Grupo Cuadrante M13	Grupo comunitario del Cuadrante M13 - Zona Este	\N	t	f	2025-12-14 04:05:16-04	2025-12-14 04:05:16-04
019b1b08-c91f-73d1-920e-10a3462a34f0	019b1b08-bf09-72da-98d0-4d09f28b1d64	Grupo Cuadrante M14	Grupo comunitario del Cuadrante M14 - Zona Este	\N	t	f	2025-12-14 04:05:19-04	2025-12-14 04:05:19-04
019b1b08-d510-73a6-ab71-5fc08aaf048b	019b1b08-cafd-7026-8c90-508e3e958e9e	Grupo Cuadrante N1	Grupo comunitario del Cuadrante N1 - Zona Sur	\N	t	f	2025-12-14 04:05:22-04	2025-12-14 04:05:22-04
019b1b08-df45-7281-ba7b-8ff31db2111a	019b1b08-d74c-71f3-99fc-f17080d5f410	Grupo Cuadrante N2	Grupo comunitario del Cuadrante N2 - Zona Sur	\N	t	f	2025-12-14 04:05:24-04	2025-12-14 04:05:24-04
019b1b08-e755-704a-ac33-b8f2b51690d2	019b1b08-e16c-7280-99e8-f4d130c61ef4	Grupo Cuadrante N3	Grupo comunitario del Cuadrante N3 - Zona Sur	\N	t	f	2025-12-14 04:05:26-04	2025-12-14 04:05:26-04
019b1b08-f395-71f9-8ce8-ca7a92a746b3	019b1b08-e95b-73dd-96d6-7aff730cd37c	Grupo Cuadrante N4	Grupo comunitario del Cuadrante N4 - Zona Sur	\N	t	f	2025-12-14 04:05:30-04	2025-12-14 04:05:30-04
019b1b08-fe2e-7292-9735-66c47550cff3	019b1b08-f5d4-717f-beb5-e73f491557e5	Grupo Cuadrante N5	Grupo comunitario del Cuadrante N5 - Zona Sur	\N	t	f	2025-12-14 04:05:32-04	2025-12-14 04:05:32-04
019b1b09-060a-733f-be49-d79705941ddd	019b1b08-fffc-71f2-b402-e781d9263d2b	Grupo Cuadrante N6	Grupo comunitario del Cuadrante N6 - Zona Sur	\N	t	f	2025-12-14 04:05:34-04	2025-12-14 04:05:34-04
019b1b09-0e56-71f1-9324-357c68c66196	019b1b09-07d7-7273-85d7-0dd18e244491	Grupo Cuadrante N7	Grupo comunitario del Cuadrante N7 - Zona Este	\N	t	f	2025-12-14 04:05:36-04	2025-12-14 04:05:36-04
019b1b09-188c-7059-a732-6d20261d7e37	019b1b09-1041-7135-ad92-fd50872ccc94	Grupo Cuadrante N8	Grupo comunitario del Cuadrante N8 - Zona Este	\N	t	f	2025-12-14 04:05:39-04	2025-12-14 04:05:39-04
019b1b09-250c-728f-a59b-d9bcc310c6d6	019b1b09-1a62-73d2-8e07-752a1eb24363	Grupo Cuadrante N9	Grupo comunitario del Cuadrante N9 - Zona Este	\N	t	f	2025-12-14 04:05:42-04	2025-12-14 04:05:42-04
019b1b09-2cd8-72c9-8a3f-26cb9a6a9593	019b1b09-26d2-7254-9a77-f5660f169c02	Grupo Cuadrante N10	Grupo comunitario del Cuadrante N10 - Zona Este	\N	t	f	2025-12-14 04:05:44-04	2025-12-14 04:05:44-04
019b1b09-390b-7180-83eb-2c7aa9a51418	019b1b09-2eb2-708e-909e-236d0af8ddaa	Grupo Cuadrante N11	Grupo comunitario del Cuadrante N11 - Zona Este	\N	t	f	2025-12-14 04:05:47-04	2025-12-14 04:05:47-04
019b1b09-40bc-720c-a79c-4e98df994acd	019b1b09-3add-702c-9dad-2216b7526fb4	Grupo Cuadrante N12	Grupo comunitario del Cuadrante N12 - Zona Este	\N	t	f	2025-12-14 04:05:49-04	2025-12-14 04:05:49-04
019b1b09-4fbb-736e-bea9-19b3e8a2e386	019b1b09-4316-72aa-9717-73a1ff35ce65	Grupo Cuadrante N13	Grupo comunitario del Cuadrante N13 - Zona Este	\N	t	f	2025-12-14 04:05:53-04	2025-12-14 04:05:53-04
019b1b09-5809-721a-a945-61fe767b13be	019b1b09-519a-73dd-92c1-d322d0c4613d	Grupo Cuadrante N14	Grupo comunitario del Cuadrante N14 - Zona Este	\N	t	f	2025-12-14 04:05:55-04	2025-12-14 04:05:55-04
019b1b09-65bd-7128-96d1-65fcb9b4bd11	019b1b09-59dd-7218-ad8c-77be0c0cf6b1	Grupo Cuadrante O1	Grupo comunitario del Cuadrante O1 - Zona Sur	\N	t	f	2025-12-14 04:05:59-04	2025-12-14 04:05:59-04
019b1b09-6db3-71d5-bfd9-d21789d25591	019b1b09-6797-7359-ab4c-af90c4886143	Grupo Cuadrante O2	Grupo comunitario del Cuadrante O2 - Zona Sur	\N	t	f	2025-12-14 04:06:01-04	2025-12-14 04:06:01-04
019b1b09-7bf9-71d6-8c3c-c3dbf856a134	019b1b09-6ff9-7085-95aa-118ae36a0bec	Grupo Cuadrante O3	Grupo comunitario del Cuadrante O3 - Zona Sur	\N	t	f	2025-12-14 04:06:05-04	2025-12-14 04:06:05-04
019b1b09-83e7-7143-9a1d-4bc8b5b36e6e	019b1b09-7de2-71d4-ba50-cf7e4662ae84	Grupo Cuadrante O4	Grupo comunitario del Cuadrante O4 - Zona Sur	\N	t	f	2025-12-14 04:06:07-04	2025-12-14 04:06:07-04
019b1b09-9226-72d3-acdd-35703c26d1db	019b1b09-8622-71d3-adf9-bbec0e976f37	Grupo Cuadrante O5	Grupo comunitario del Cuadrante O5 - Zona Sur	\N	t	f	2025-12-14 04:06:10-04	2025-12-14 04:06:10-04
019b1b09-9c38-7266-864b-d6b61d2f5bd1	019b1b09-9411-723a-ae40-e733e4b4e275	Grupo Cuadrante O6	Grupo comunitario del Cuadrante O6 - Zona Sur	\N	t	f	2025-12-14 04:06:13-04	2025-12-14 04:06:13-04
019b1b09-a7f6-7044-92f8-3e98f6f0e6f8	019b1b09-9e10-71ca-b0bf-1f28fcec3a1a	Grupo Cuadrante O7	Grupo comunitario del Cuadrante O7 - Zona Este	\N	t	f	2025-12-14 04:06:16-04	2025-12-14 04:06:16-04
019b1b09-b1b1-7013-8b96-aa8e80c06e54	019b1b09-a9d8-7336-b90e-f37ff0ecfdeb	Grupo Cuadrante O8	Grupo comunitario del Cuadrante O8 - Zona Este	\N	t	f	2025-12-14 04:06:18-04	2025-12-14 04:06:18-04
019b1b09-bffb-729a-b999-5cdea150c984	019b1b09-b3fe-7384-923f-40498594705c	Grupo Cuadrante O9	Grupo comunitario del Cuadrante O9 - Zona Este	\N	t	f	2025-12-14 04:06:22-04	2025-12-14 04:06:22-04
019b1b09-ca3e-7022-94ba-3d8a252cb660	019b1b09-c1e4-70c5-90eb-445abd712dec	Grupo Cuadrante O10	Grupo comunitario del Cuadrante O10 - Zona Este	\N	t	f	2025-12-14 04:06:25-04	2025-12-14 04:06:25-04
019b1b09-d484-72fd-8c0f-efc17b5b5ef6	019b1b09-cc13-70ca-88d9-29bdbf6cfb73	Grupo Cuadrante O11	Grupo comunitario del Cuadrante O11 - Zona Este	\N	t	f	2025-12-14 04:06:27-04	2025-12-14 04:06:27-04
019b1b09-e331-732a-9ea3-a5dde37ee426	019b1b09-d6cb-7029-a5a7-42aeb20be928	Grupo Cuadrante O12	Grupo comunitario del Cuadrante O12 - Zona Este	\N	t	f	2025-12-14 04:06:31-04	2025-12-14 04:06:31-04
019b1b09-ed71-72e2-93c0-d0f32946b976	019b1b09-e525-7062-813b-78ab0a0d3542	Grupo Cuadrante O13	Grupo comunitario del Cuadrante O13 - Zona Este	\N	t	f	2025-12-14 04:06:34-04	2025-12-14 04:06:34-04
019b1b09-fb84-723f-8baa-979709ed7aa0	019b1b09-ef60-711d-bb54-04c99f29b151	Grupo Cuadrante O14	Grupo comunitario del Cuadrante O14 - Zona Este	\N	t	f	2025-12-14 04:06:37-04	2025-12-14 04:06:37-04
019b1b0a-09e1-7154-9fe6-c8872879afce	019b1b09-fe00-708b-b81a-ff5c9193b6d7	Grupo Cuadrante P1	Grupo comunitario del Cuadrante P1 - Zona Sur	\N	t	f	2025-12-14 04:06:41-04	2025-12-14 04:06:41-04
019b1b0a-1856-7212-a101-4e37ea6d51ac	019b1b0a-0bc3-72de-bc06-46b81f34b9a3	Grupo Cuadrante P2	Grupo comunitario del Cuadrante P2 - Zona Sur	\N	t	f	2025-12-14 04:06:45-04	2025-12-14 04:06:45-04
019b1b0a-20bd-73e9-8d6f-6c70f953ecc4	019b1b0a-1a3f-73aa-9741-4f9e81f3a718	Grupo Cuadrante P3	Grupo comunitario del Cuadrante P3 - Zona Sur	\N	t	f	2025-12-14 04:06:47-04	2025-12-14 04:06:47-04
019b1b0a-28d5-73bc-a11f-f6ab06365808	019b1b0a-22b1-7040-8f5f-d505f4294be3	Grupo Cuadrante P4	Grupo comunitario del Cuadrante P4 - Zona Sur	\N	t	f	2025-12-14 04:06:49-04	2025-12-14 04:06:49-04
019b1b0a-3137-72b8-bf28-9218a898d892	019b1b0a-2b19-7323-9197-1f12627e5dc7	Grupo Cuadrante P5	Grupo comunitario del Cuadrante P5 - Zona Sur	\N	t	f	2025-12-14 04:06:51-04	2025-12-14 04:06:51-04
019b1b0a-3f9f-70b2-9f77-201de2752835	019b1b0a-339d-72c7-9c4d-36735219ff1f	Grupo Cuadrante P6	Grupo comunitario del Cuadrante P6 - Zona Sur	\N	t	f	2025-12-14 04:06:55-04	2025-12-14 04:06:55-04
019b1b0a-4c0c-71d4-827d-60371dd1dd6a	019b1b0a-41f4-7390-a5d3-3924b836163c	Grupo Cuadrante P7	Grupo comunitario del Cuadrante P7 - Zona Este	\N	t	f	2025-12-14 04:06:58-04	2025-12-14 04:06:58-04
019b1b0a-59e8-71f5-9225-ebf82ef42532	019b1b0a-4dde-71f0-a56a-c527af5d073f	Grupo Cuadrante P8	Grupo comunitario del Cuadrante P8 - Zona Este	\N	t	f	2025-12-14 04:07:01-04	2025-12-14 04:07:01-04
019b1b0a-64c7-726b-981a-ef5bca08889d	019b1b0a-5c20-7334-a04d-bac5ae3d81c1	Grupo Cuadrante P9	Grupo comunitario del Cuadrante P9 - Zona Este	\N	t	f	2025-12-14 04:07:04-04	2025-12-14 04:07:04-04
019b1b0a-6c96-7079-9b49-b4d55de1483d	019b1b0a-66a2-70b7-8c00-faac7f852aaf	Grupo Cuadrante P10	Grupo comunitario del Cuadrante P10 - Zona Este	\N	t	f	2025-12-14 04:07:06-04	2025-12-14 04:07:06-04
019b1b0a-7b0f-73f4-94dc-4b921453e4d0	019b1b0a-6ed4-7282-8b45-2f0d1647f01a	Grupo Cuadrante P11	Grupo comunitario del Cuadrante P11 - Zona Este	\N	t	f	2025-12-14 04:07:10-04	2025-12-14 04:07:10-04
019b1b0a-87e5-723e-9265-61754469aaa0	019b1b0a-7d69-70f4-91d0-01366385c360	Grupo Cuadrante P12	Grupo comunitario del Cuadrante P12 - Zona Este	\N	t	f	2025-12-14 04:07:13-04	2025-12-14 04:07:13-04
019b1b0a-9034-7044-a2bf-91575a89b27b	019b1b0a-89ca-72ae-84fa-7e24b5d1a79c	Grupo Cuadrante P13	Grupo comunitario del Cuadrante P13 - Zona Este	\N	t	f	2025-12-14 04:07:15-04	2025-12-14 04:07:15-04
019b1b0a-9c73-712b-95c1-dddde829e96a	019b1b0a-921f-7165-812a-c60b48c707a1	Grupo Cuadrante P14	Grupo comunitario del Cuadrante P14 - Zona Este	\N	t	f	2025-12-14 04:07:18-04	2025-12-14 04:07:18-04
019b1b0a-a953-719c-b69a-41985a453f3d	019b1b0a-9e4f-73f7-bb06-08bf7cd3a647	Grupo Cuadrante Q1	Grupo comunitario del Cuadrante Q1 - Zona Sur	\N	t	f	2025-12-14 04:07:22-04	2025-12-14 04:07:22-04
019b1b0a-b129-73ec-b80b-60689de2b56f	019b1b0a-ab42-7088-944a-f38a6458b3ed	Grupo Cuadrante Q2	Grupo comunitario del Cuadrante Q2 - Zona Sur	\N	t	f	2025-12-14 04:07:24-04	2025-12-14 04:07:24-04
019b1b0a-bc0f-73b7-95c9-5f2f268861e5	019b1b0a-b3d0-7376-9d55-e0987dc5d0f1	Grupo Cuadrante Q3	Grupo comunitario del Cuadrante Q3 - Zona Sur	\N	t	f	2025-12-14 04:07:26-04	2025-12-14 04:07:26-04
019b1b0a-c457-71ac-93ed-4d9a54405e00	019b1b0a-be0c-7072-9b24-a063507b46c6	Grupo Cuadrante Q4	Grupo comunitario del Cuadrante Q4 - Zona Sur	\N	t	f	2025-12-14 04:07:29-04	2025-12-14 04:07:29-04
019b1b0a-d2d6-72a0-9dff-656e5ede1724	019b1b0a-c69d-73f9-a995-a9d0bc42e676	Grupo Cuadrante Q5	Grupo comunitario del Cuadrante Q5 - Zona Sur	\N	t	f	2025-12-14 04:07:32-04	2025-12-14 04:07:32-04
019b1b0a-dec6-72f2-b66a-3ff13088863e	019b1b0a-d4b4-70b2-91d0-ae1619fd462c	Grupo Cuadrante Q6	Grupo comunitario del Cuadrante Q6 - Zona Sur	\N	t	f	2025-12-14 04:07:35-04	2025-12-14 04:07:35-04
019b1b0a-e987-72f9-b3ff-5ad9aca75e02	019b1b0a-e112-73c1-aa05-fa1d64e03173	Grupo Cuadrante Q7	Grupo comunitario del Cuadrante Q7 - Zona Este	\N	t	f	2025-12-14 04:07:38-04	2025-12-14 04:07:38-04
019b1b0a-f759-738f-aad0-c0fef29bbdd8	019b1b0a-eb60-7214-89bf-debb4cfb68ca	Grupo Cuadrante Q8	Grupo comunitario del Cuadrante Q8 - Zona Este	\N	t	f	2025-12-14 04:07:42-04	2025-12-14 04:07:42-04
019b1b0a-ffcc-707b-8d55-b4e83db8549a	019b1b0a-f9a4-7343-aecf-f92d6af37a2d	Grupo Cuadrante Q9	Grupo comunitario del Cuadrante Q9 - Zona Este	\N	t	f	2025-12-14 04:07:44-04	2025-12-14 04:07:44-04
019b1b0b-09f2-71e4-83c4-30ce06c907be	019b1b0b-01b3-7326-a550-22901cd4b964	Grupo Cuadrante Q10	Grupo comunitario del Cuadrante Q10 - Zona Este	\N	t	f	2025-12-14 04:07:46-04	2025-12-14 04:07:46-04
019b1b0b-14c8-7329-9b99-b59bf0edfbcc	019b1b0b-0bdd-7033-959f-ee017b0d5110	Grupo Cuadrante Q11	Grupo comunitario del Cuadrante Q11 - Zona Este	\N	t	f	2025-12-14 04:07:49-04	2025-12-14 04:07:49-04
019b1b0b-1eb7-7142-bc66-f7c502e2f8ba	019b1b0b-16eb-7102-88aa-e6b565b303c4	Grupo Cuadrante Q12	Grupo comunitario del Cuadrante Q12 - Zona Este	\N	t	f	2025-12-14 04:07:52-04	2025-12-14 04:07:52-04
019b1b0b-2b0e-73b4-8d11-9a02d0c88738	019b1b0b-20ab-7108-8e31-00155ba46752	Grupo Cuadrante Q13	Grupo comunitario del Cuadrante Q13 - Zona Este	\N	t	f	2025-12-14 04:07:55-04	2025-12-14 04:07:55-04
019b1b0b-371f-70a2-9364-d0c88845469f	019b1b0b-2d40-71e2-a19b-f5ba3053057c	Grupo Cuadrante Q14	Grupo comunitario del Cuadrante Q14 - Zona Este	\N	t	f	2025-12-14 04:07:58-04	2025-12-14 04:07:58-04
\.


--
-- Data for Name: job_batches; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.job_batches (id, name, total_jobs, pending_jobs, failed_jobs, failed_job_ids, options, cancelled_at, created_at, finished_at) FROM stdin;
\.


--
-- Data for Name: jobs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.jobs (id, queue, payload, attempts, reserved_at, available_at, created_at) FROM stdin;
\.


--
-- Data for Name: migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.migrations (id, migration, batch) FROM stdin;
1	0001_01_01_000000_create_users_table	1
2	0001_01_01_000001_create_cache_table	1
3	0001_01_01_000002_create_jobs_table	1
4	2024_01_01_000000_create_permission_tables	1
5	2024_01_01_100000_create_usuarios_table	1
6	2024_01_01_100001_create_configuracion_notificaciones_usuario_table	1
7	2024_01_01_100002_create_cuadrantes_table	1
8	2024_01_01_100003_create_cuadrante_barrios_table	1
9	2024_01_01_100004_create_categorias_table	1
10	2024_01_01_100005_create_reportes_table	1
11	2024_01_01_100006_create_reporte_caracteristicas_table	1
12	2024_01_01_100007_create_reporte_imagenes_table	1
13	2024_01_01_100008_create_reporte_videos_table	1
14	2024_01_01_100009_create_respuestas_table	1
15	2024_01_01_100010_create_respuesta_imagenes_table	1
16	2024_01_01_100011_create_respuesta_videos_table	1
17	2024_01_01_100012_create_grupos_table	1
18	2024_01_01_100013_create_grupo_miembros_table	1
19	2024_01_01_100014_create_expansiones_reporte_table	1
20	2024_01_01_100015_create_notificaciones_table	1
21	2024_01_01_100016_create_notificacion_datos_table	1
22	2024_01_01_100017_create_configuracion_sistema_table	1
23	2024_01_01_100018_create_indexes_for_tables	1
24	2025_12_11_005646_modify_model_has_roles_for_uuid_support	1
\.


--
-- Data for Name: model_has_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.model_has_permissions (permission_id, model_type, model_id) FROM stdin;
\.


--
-- Data for Name: model_has_roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.model_has_roles (role_id, model_type, model_id) FROM stdin;
\.


--
-- Data for Name: notificacion_datos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notificacion_datos (id, notificacion_id, clave, valor, created_at) FROM stdin;
\.


--
-- Data for Name: notificaciones; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notificaciones (id, usuario_id, tipo, titulo, mensaje, leida, enviada_push, enviada_email, created_at) FROM stdin;
\.


--
-- Data for Name: password_reset_tokens; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.password_reset_tokens (email, token, created_at) FROM stdin;
\.


--
-- Data for Name: permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.permissions (id, name, guard_name, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: reporte_caracteristicas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reporte_caracteristicas (id, reporte_id, clave, valor, created_at) FROM stdin;
\.


--
-- Data for Name: reporte_imagenes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reporte_imagenes (id, reporte_id, url, orden, created_at) FROM stdin;
\.


--
-- Data for Name: reporte_videos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reporte_videos (id, reporte_id, url, orden, created_at) FROM stdin;
\.


--
-- Data for Name: reportes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reportes (id, usuario_id, categoria_id, cuadrante_id, tipo_reporte, titulo, descripcion, ubicacion_exacta_lat, ubicacion_exacta_lng, direccion_referencia, fecha_perdida, fecha_reporte, estado, prioridad, nivel_expansion, max_expansion, proxima_expansion, contacto_publico, telefono_contacto, email_contacto, recompensa, vistas, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: respuesta_imagenes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.respuesta_imagenes (id, respuesta_id, url, orden, created_at) FROM stdin;
\.


--
-- Data for Name: respuesta_videos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.respuesta_videos (id, respuesta_id, url, orden, created_at) FROM stdin;
\.


--
-- Data for Name: respuestas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.respuestas (id, reporte_id, usuario_id, tipo_respuesta, mensaje, ubicacion_lat, ubicacion_lng, direccion_referencia, verificada, util, created_at) FROM stdin;
\.


--
-- Data for Name: role_has_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.role_has_permissions (permission_id, role_id) FROM stdin;
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.roles (id, name, guard_name, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sessions (id, user_id, ip_address, user_agent, payload, last_activity) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, name, email, email_verified_at, password, remember_token, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: usuarios; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.usuarios (id, nombre, email, telefono, avatar_url, puntos_ayuda, fecha_registro, activo, ubicacion_actual_lat, ubicacion_actual_lng, rol, contrasena, created_at, updated_at) FROM stdin;
\.


--
-- Name: failed_jobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.failed_jobs_id_seq', 1, false);


--
-- Name: jobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.jobs_id_seq', 1, false);


--
-- Name: migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.migrations_id_seq', 24, true);


--
-- Name: permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.permissions_id_seq', 1, false);


--
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.roles_id_seq', 1, false);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 1, false);


--
-- Name: cache_locks cache_locks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cache_locks
    ADD CONSTRAINT cache_locks_pkey PRIMARY KEY (key);


--
-- Name: cache cache_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cache
    ADD CONSTRAINT cache_pkey PRIMARY KEY (key);


--
-- Name: categorias categorias_nombre_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categorias
    ADD CONSTRAINT categorias_nombre_unique UNIQUE (nombre);


--
-- Name: categorias categorias_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categorias
    ADD CONSTRAINT categorias_pkey PRIMARY KEY (id);


--
-- Name: configuracion_notificaciones_usuario configuracion_notificaciones_usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.configuracion_notificaciones_usuario
    ADD CONSTRAINT configuracion_notificaciones_usuario_pkey PRIMARY KEY (id);


--
-- Name: configuracion_notificaciones_usuario configuracion_notificaciones_usuario_usuario_id_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.configuracion_notificaciones_usuario
    ADD CONSTRAINT configuracion_notificaciones_usuario_usuario_id_unique UNIQUE (usuario_id);


--
-- Name: configuracion_sistema configuracion_sistema_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.configuracion_sistema
    ADD CONSTRAINT configuracion_sistema_pkey PRIMARY KEY (clave);


--
-- Name: cuadrante_barrios cuadrante_barrios_cuadrante_id_nombre_barrio_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cuadrante_barrios
    ADD CONSTRAINT cuadrante_barrios_cuadrante_id_nombre_barrio_unique UNIQUE (cuadrante_id, nombre_barrio);


--
-- Name: cuadrante_barrios cuadrante_barrios_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cuadrante_barrios
    ADD CONSTRAINT cuadrante_barrios_pkey PRIMARY KEY (id);


--
-- Name: cuadrantes cuadrantes_codigo_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cuadrantes
    ADD CONSTRAINT cuadrantes_codigo_unique UNIQUE (codigo);


--
-- Name: cuadrantes cuadrantes_fila_columna_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cuadrantes
    ADD CONSTRAINT cuadrantes_fila_columna_unique UNIQUE (fila, columna);


--
-- Name: cuadrantes cuadrantes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cuadrantes
    ADD CONSTRAINT cuadrantes_pkey PRIMARY KEY (id);


--
-- Name: expansiones_reporte expansiones_reporte_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expansiones_reporte
    ADD CONSTRAINT expansiones_reporte_pkey PRIMARY KEY (id);


--
-- Name: expansiones_reporte expansiones_reporte_reporte_id_cuadrante_expandido_id_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expansiones_reporte
    ADD CONSTRAINT expansiones_reporte_reporte_id_cuadrante_expandido_id_unique UNIQUE (reporte_id, cuadrante_expandido_id);


--
-- Name: failed_jobs failed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.failed_jobs
    ADD CONSTRAINT failed_jobs_pkey PRIMARY KEY (id);


--
-- Name: failed_jobs failed_jobs_uuid_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.failed_jobs
    ADD CONSTRAINT failed_jobs_uuid_unique UNIQUE (uuid);


--
-- Name: grupo_miembros grupo_miembros_grupo_id_usuario_id_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grupo_miembros
    ADD CONSTRAINT grupo_miembros_grupo_id_usuario_id_unique UNIQUE (grupo_id, usuario_id);


--
-- Name: grupo_miembros grupo_miembros_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grupo_miembros
    ADD CONSTRAINT grupo_miembros_pkey PRIMARY KEY (id);


--
-- Name: grupos grupos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grupos
    ADD CONSTRAINT grupos_pkey PRIMARY KEY (id);


--
-- Name: job_batches job_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.job_batches
    ADD CONSTRAINT job_batches_pkey PRIMARY KEY (id);


--
-- Name: jobs jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- Name: model_has_permissions model_has_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.model_has_permissions
    ADD CONSTRAINT model_has_permissions_pkey PRIMARY KEY (permission_id, model_id, model_type);


--
-- Name: model_has_roles model_has_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.model_has_roles
    ADD CONSTRAINT model_has_roles_pkey PRIMARY KEY (role_id, model_id, model_type);


--
-- Name: notificacion_datos notificacion_datos_notificacion_id_clave_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notificacion_datos
    ADD CONSTRAINT notificacion_datos_notificacion_id_clave_unique UNIQUE (notificacion_id, clave);


--
-- Name: notificacion_datos notificacion_datos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notificacion_datos
    ADD CONSTRAINT notificacion_datos_pkey PRIMARY KEY (id);


--
-- Name: notificaciones notificaciones_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notificaciones
    ADD CONSTRAINT notificaciones_pkey PRIMARY KEY (id);


--
-- Name: password_reset_tokens password_reset_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_pkey PRIMARY KEY (email);


--
-- Name: permissions permissions_name_guard_name_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_name_guard_name_unique UNIQUE (name, guard_name);


--
-- Name: permissions permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- Name: reporte_caracteristicas reporte_caracteristicas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reporte_caracteristicas
    ADD CONSTRAINT reporte_caracteristicas_pkey PRIMARY KEY (id);


--
-- Name: reporte_caracteristicas reporte_caracteristicas_reporte_id_clave_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reporte_caracteristicas
    ADD CONSTRAINT reporte_caracteristicas_reporte_id_clave_unique UNIQUE (reporte_id, clave);


--
-- Name: reporte_imagenes reporte_imagenes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reporte_imagenes
    ADD CONSTRAINT reporte_imagenes_pkey PRIMARY KEY (id);


--
-- Name: reporte_videos reporte_videos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reporte_videos
    ADD CONSTRAINT reporte_videos_pkey PRIMARY KEY (id);


--
-- Name: reportes reportes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reportes
    ADD CONSTRAINT reportes_pkey PRIMARY KEY (id);


--
-- Name: respuesta_imagenes respuesta_imagenes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.respuesta_imagenes
    ADD CONSTRAINT respuesta_imagenes_pkey PRIMARY KEY (id);


--
-- Name: respuesta_videos respuesta_videos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.respuesta_videos
    ADD CONSTRAINT respuesta_videos_pkey PRIMARY KEY (id);


--
-- Name: respuestas respuestas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.respuestas
    ADD CONSTRAINT respuestas_pkey PRIMARY KEY (id);


--
-- Name: role_has_permissions role_has_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_has_permissions
    ADD CONSTRAINT role_has_permissions_pkey PRIMARY KEY (permission_id, role_id);


--
-- Name: roles roles_name_guard_name_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_name_guard_name_unique UNIQUE (name, guard_name);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: users users_email_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_unique UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: usuarios usuarios_email_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_email_unique UNIQUE (email);


--
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id);


--
-- Name: idx_cuadrante_barrios_cuadrante; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cuadrante_barrios_cuadrante ON public.cuadrante_barrios USING btree (cuadrante_id);


--
-- Name: idx_expansiones_reporte; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_expansiones_reporte ON public.expansiones_reporte USING btree (reporte_id);


--
-- Name: idx_notificacion_datos_notificacion; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notificacion_datos_notificacion ON public.notificacion_datos USING btree (notificacion_id);


--
-- Name: idx_reporte_caracteristicas_reporte; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reporte_caracteristicas_reporte ON public.reporte_caracteristicas USING btree (reporte_id);


--
-- Name: idx_reporte_imagenes_reporte; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reporte_imagenes_reporte ON public.reporte_imagenes USING btree (reporte_id);


--
-- Name: idx_reporte_videos_reporte; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reporte_videos_reporte ON public.reporte_videos USING btree (reporte_id);


--
-- Name: idx_respuesta_imagenes_respuesta; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_respuesta_imagenes_respuesta ON public.respuesta_imagenes USING btree (respuesta_id);


--
-- Name: idx_respuesta_videos_respuesta; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_respuesta_videos_respuesta ON public.respuesta_videos USING btree (respuesta_id);


--
-- Name: idx_respuestas_reporte; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_respuestas_reporte ON public.respuestas USING btree (reporte_id);


--
-- Name: jobs_queue_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX jobs_queue_index ON public.jobs USING btree (queue);


--
-- Name: model_has_permissions_model_id_model_type_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX model_has_permissions_model_id_model_type_index ON public.model_has_permissions USING btree (model_id, model_type);


--
-- Name: model_has_roles_model_id_model_type_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX model_has_roles_model_id_model_type_index ON public.model_has_roles USING btree (model_id, model_type);


--
-- Name: sessions_last_activity_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX sessions_last_activity_index ON public.sessions USING btree (last_activity);


--
-- Name: sessions_user_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX sessions_user_id_index ON public.sessions USING btree (user_id);


--
-- Name: configuracion_notificaciones_usuario configuracion_notificaciones_usuario_usuario_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.configuracion_notificaciones_usuario
    ADD CONSTRAINT configuracion_notificaciones_usuario_usuario_id_foreign FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE;


--
-- Name: cuadrante_barrios cuadrante_barrios_cuadrante_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cuadrante_barrios
    ADD CONSTRAINT cuadrante_barrios_cuadrante_id_foreign FOREIGN KEY (cuadrante_id) REFERENCES public.cuadrantes(id) ON DELETE CASCADE;


--
-- Name: expansiones_reporte expansiones_reporte_reporte_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expansiones_reporte
    ADD CONSTRAINT expansiones_reporte_reporte_id_foreign FOREIGN KEY (reporte_id) REFERENCES public.reportes(id) ON DELETE CASCADE;


--
-- Name: grupo_miembros grupo_miembros_grupo_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grupo_miembros
    ADD CONSTRAINT grupo_miembros_grupo_id_foreign FOREIGN KEY (grupo_id) REFERENCES public.grupos(id) ON DELETE CASCADE;


--
-- Name: grupo_miembros grupo_miembros_usuario_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grupo_miembros
    ADD CONSTRAINT grupo_miembros_usuario_id_foreign FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE;


--
-- Name: grupos grupos_cuadrante_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grupos
    ADD CONSTRAINT grupos_cuadrante_id_foreign FOREIGN KEY (cuadrante_id) REFERENCES public.cuadrantes(id);


--
-- Name: model_has_permissions model_has_permissions_permission_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.model_has_permissions
    ADD CONSTRAINT model_has_permissions_permission_id_foreign FOREIGN KEY (permission_id) REFERENCES public.permissions(id) ON DELETE CASCADE;


--
-- Name: model_has_roles model_has_roles_role_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.model_has_roles
    ADD CONSTRAINT model_has_roles_role_id_foreign FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;


--
-- Name: notificacion_datos notificacion_datos_notificacion_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notificacion_datos
    ADD CONSTRAINT notificacion_datos_notificacion_id_foreign FOREIGN KEY (notificacion_id) REFERENCES public.notificaciones(id) ON DELETE CASCADE;


--
-- Name: notificaciones notificaciones_usuario_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notificaciones
    ADD CONSTRAINT notificaciones_usuario_id_foreign FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE;


--
-- Name: reporte_caracteristicas reporte_caracteristicas_reporte_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reporte_caracteristicas
    ADD CONSTRAINT reporte_caracteristicas_reporte_id_foreign FOREIGN KEY (reporte_id) REFERENCES public.reportes(id) ON DELETE CASCADE;


--
-- Name: reporte_imagenes reporte_imagenes_reporte_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reporte_imagenes
    ADD CONSTRAINT reporte_imagenes_reporte_id_foreign FOREIGN KEY (reporte_id) REFERENCES public.reportes(id) ON DELETE CASCADE;


--
-- Name: reporte_videos reporte_videos_reporte_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reporte_videos
    ADD CONSTRAINT reporte_videos_reporte_id_foreign FOREIGN KEY (reporte_id) REFERENCES public.reportes(id) ON DELETE CASCADE;


--
-- Name: reportes reportes_categoria_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reportes
    ADD CONSTRAINT reportes_categoria_id_foreign FOREIGN KEY (categoria_id) REFERENCES public.categorias(id);


--
-- Name: reportes reportes_cuadrante_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reportes
    ADD CONSTRAINT reportes_cuadrante_id_foreign FOREIGN KEY (cuadrante_id) REFERENCES public.cuadrantes(id);


--
-- Name: reportes reportes_usuario_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reportes
    ADD CONSTRAINT reportes_usuario_id_foreign FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE;


--
-- Name: respuesta_imagenes respuesta_imagenes_respuesta_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.respuesta_imagenes
    ADD CONSTRAINT respuesta_imagenes_respuesta_id_foreign FOREIGN KEY (respuesta_id) REFERENCES public.respuestas(id) ON DELETE CASCADE;


--
-- Name: respuesta_videos respuesta_videos_respuesta_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.respuesta_videos
    ADD CONSTRAINT respuesta_videos_respuesta_id_foreign FOREIGN KEY (respuesta_id) REFERENCES public.respuestas(id) ON DELETE CASCADE;


--
-- Name: respuestas respuestas_reporte_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.respuestas
    ADD CONSTRAINT respuestas_reporte_id_foreign FOREIGN KEY (reporte_id) REFERENCES public.reportes(id) ON DELETE CASCADE;


--
-- Name: respuestas respuestas_usuario_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.respuestas
    ADD CONSTRAINT respuestas_usuario_id_foreign FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE;


--
-- Name: role_has_permissions role_has_permissions_permission_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_has_permissions
    ADD CONSTRAINT role_has_permissions_permission_id_foreign FOREIGN KEY (permission_id) REFERENCES public.permissions(id) ON DELETE CASCADE;


--
-- Name: role_has_permissions role_has_permissions_role_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_has_permissions
    ADD CONSTRAINT role_has_permissions_role_id_foreign FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;


--
-- PostgreSQL database dump complete
--

\unrestrict xRrAsbLI0rSN2hzi5D24Z7AM6UpdelBKLJhyekeJnefhDBZXvLCN7ja0YEnnBri


COPY public.roles (id, name, guard_name, created_at, updated_at) FROM stdin;
1usuarioweb2025-12-13 17:28:482025-12-13 17:28:48
3administradorweb2025-12-13 17:40:162025-12-13 17:40:16
4editorweb2025-12-13 18:49:422025-12-13 18:49:42
\.

