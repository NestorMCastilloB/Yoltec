--
-- PostgreSQL database dump
--

\restrict aIEkioJsfXCG3MonCoJly7LanIlistdV6rSHWY4VEHRZ7wQaBhJd28BT1XnemtS

-- Dumped from database version 16.12 (6d3029c)
-- Dumped by pg_dump version 16.13 (Ubuntu 16.13-0ubuntu0.24.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: neondb_owner
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO neondb_owner;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: neondb_owner
--

COMMENT ON SCHEMA public IS '';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: analisis_documentos_ia; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.analisis_documentos_ia (
    id bigint NOT NULL,
    documento_id bigint NOT NULL,
    estatus character varying(255) DEFAULT 'pendiente'::character varying,
    datos_detectados json,
    diagnostico_sugerido character varying(255),
    descripcion_analisis text,
    nivel_confianza numeric(3,2),
    palabras_clave_detectadas json,
    validado_por bigint,
    estatus_validacion character varying(255) DEFAULT 'pendiente'::character varying,
    comentario_doctor text,
    diagnostico_final character varying(255),
    fecha_validacion timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.analisis_documentos_ia OWNER TO neondb_owner;

--
-- Name: analisis_documentos_ia_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.analisis_documentos_ia_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.analisis_documentos_ia_id_seq OWNER TO neondb_owner;

--
-- Name: analisis_documentos_ia_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.analisis_documentos_ia_id_seq OWNED BY public.analisis_documentos_ia.id;


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.audit_logs (
    id bigint NOT NULL,
    user_id bigint,
    accion character varying(255) NOT NULL,
    tabla character varying(255),
    registro_id bigint,
    datos_anteriores json,
    datos_nuevos json,
    ip_address character varying(255),
    user_agent text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.audit_logs OWNER TO neondb_owner;

--
-- Name: audit_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.audit_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.audit_logs_id_seq OWNER TO neondb_owner;

--
-- Name: audit_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.audit_logs_id_seq OWNED BY public.audit_logs.id;


--
-- Name: bitacoras; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.bitacoras (
    id bigint NOT NULL,
    paciente_id bigint NOT NULL,
    doctor_id bigint NOT NULL,
    descripcion text NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.bitacoras OWNER TO neondb_owner;

--
-- Name: bitacoras_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.bitacoras_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.bitacoras_id_seq OWNER TO neondb_owner;

--
-- Name: bitacoras_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.bitacoras_id_seq OWNED BY public.bitacoras.id;


--
-- Name: cache; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.cache (
    key character varying(255) NOT NULL,
    value text NOT NULL,
    expiration integer NOT NULL
);


ALTER TABLE public.cache OWNER TO neondb_owner;

--
-- Name: cache_locks; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.cache_locks (
    key character varying(255) NOT NULL,
    owner character varying(255) NOT NULL,
    expiration integer NOT NULL
);


ALTER TABLE public.cache_locks OWNER TO neondb_owner;

--
-- Name: citas; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.citas (
    id bigint NOT NULL,
    paciente_id bigint NOT NULL,
    doctor_id bigint NOT NULL,
    fecha date NOT NULL,
    hora time without time zone NOT NULL,
    motivo text,
    estatus character varying(255) DEFAULT 'pendiente'::character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.citas OWNER TO neondb_owner;

--
-- Name: citas_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.citas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.citas_id_seq OWNER TO neondb_owner;

--
-- Name: citas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.citas_id_seq OWNED BY public.citas.id;


--
-- Name: documentos_medicos; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.documentos_medicos (
    id bigint NOT NULL,
    paciente_id bigint NOT NULL,
    subido_por bigint NOT NULL,
    tipo_documento character varying(255) DEFAULT 'otro'::character varying,
    nombre_archivo character varying(255) NOT NULL,
    ruta_archivo character varying(255) NOT NULL,
    mime_type character varying(255) NOT NULL,
    tamano_bytes bigint NOT NULL,
    texto_extraido text,
    estatus_procesamiento character varying(255) DEFAULT 'pendiente'::character varying,
    datos_extraidos json,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.documentos_medicos OWNER TO neondb_owner;

--
-- Name: documentos_medicos_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.documentos_medicos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.documentos_medicos_id_seq OWNER TO neondb_owner;

--
-- Name: documentos_medicos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.documentos_medicos_id_seq OWNED BY public.documentos_medicos.id;


--
-- Name: migrations; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.migrations (
    id integer NOT NULL,
    migration character varying(255) NOT NULL,
    batch integer NOT NULL
);


ALTER TABLE public.migrations OWNER TO neondb_owner;

--
-- Name: migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.migrations_id_seq OWNER TO neondb_owner;

--
-- Name: migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.migrations_id_seq OWNED BY public.migrations.id;


--
-- Name: personal_access_tokens; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.personal_access_tokens (
    id bigint NOT NULL,
    tokenable_type character varying(255) NOT NULL,
    tokenable_id bigint NOT NULL,
    name character varying(255) NOT NULL,
    token character varying(64) NOT NULL,
    abilities text,
    last_used_at timestamp without time zone,
    expires_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.personal_access_tokens OWNER TO neondb_owner;

--
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.personal_access_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.personal_access_tokens_id_seq OWNER TO neondb_owner;

--
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.personal_access_tokens_id_seq OWNED BY public.personal_access_tokens.id;


--
-- Name: recetas; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.recetas (
    id bigint NOT NULL,
    cita_id bigint NOT NULL,
    contenido text NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.recetas OWNER TO neondb_owner;

--
-- Name: recetas_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.recetas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.recetas_id_seq OWNER TO neondb_owner;

--
-- Name: recetas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.recetas_id_seq OWNED BY public.recetas.id;


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.sessions (
    id character varying(255) NOT NULL,
    user_id bigint,
    ip_address character varying(45),
    user_agent text,
    payload text NOT NULL,
    last_activity integer NOT NULL
);


ALTER TABLE public.sessions OWNER TO neondb_owner;

--
-- Name: two_factor_codes; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.two_factor_codes (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    code character varying(255) NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    used boolean DEFAULT false,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.two_factor_codes OWNER TO neondb_owner;

--
-- Name: two_factor_codes_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.two_factor_codes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.two_factor_codes_id_seq OWNER TO neondb_owner;

--
-- Name: two_factor_codes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.two_factor_codes_id_seq OWNED BY public.two_factor_codes.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    numero_control character varying(255),
    username character varying(255),
    nombre character varying(255) NOT NULL,
    apellido character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    password character varying(255) NOT NULL,
    tipo character varying(255) DEFAULT 'alumno'::character varying,
    telefono character varying(255),
    fecha_nacimiento date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    es_admin boolean DEFAULT false
);


ALTER TABLE public.users OWNER TO neondb_owner;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO neondb_owner;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: analisis_documentos_ia id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.analisis_documentos_ia ALTER COLUMN id SET DEFAULT nextval('public.analisis_documentos_ia_id_seq'::regclass);


--
-- Name: audit_logs id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.audit_logs ALTER COLUMN id SET DEFAULT nextval('public.audit_logs_id_seq'::regclass);


--
-- Name: bitacoras id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.bitacoras ALTER COLUMN id SET DEFAULT nextval('public.bitacoras_id_seq'::regclass);


--
-- Name: citas id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.citas ALTER COLUMN id SET DEFAULT nextval('public.citas_id_seq'::regclass);


--
-- Name: documentos_medicos id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.documentos_medicos ALTER COLUMN id SET DEFAULT nextval('public.documentos_medicos_id_seq'::regclass);


--
-- Name: migrations id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.migrations ALTER COLUMN id SET DEFAULT nextval('public.migrations_id_seq'::regclass);


--
-- Name: personal_access_tokens id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.personal_access_tokens ALTER COLUMN id SET DEFAULT nextval('public.personal_access_tokens_id_seq'::regclass);


--
-- Name: recetas id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.recetas ALTER COLUMN id SET DEFAULT nextval('public.recetas_id_seq'::regclass);


--
-- Name: two_factor_codes id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.two_factor_codes ALTER COLUMN id SET DEFAULT nextval('public.two_factor_codes_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: analisis_documentos_ia; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.analisis_documentos_ia (id, documento_id, estatus, datos_detectados, diagnostico_sugerido, descripcion_analisis, nivel_confianza, palabras_clave_detectadas, validado_por, estatus_validacion, comentario_doctor, diagnostico_final, fecha_validacion, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.audit_logs (id, user_id, accion, tabla, registro_id, datos_anteriores, datos_nuevos, ip_address, user_agent, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: bitacoras; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.bitacoras (id, paciente_id, doctor_id, descripcion, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: cache; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.cache (key, value, expiration) FROM stdin;
\.


--
-- Data for Name: cache_locks; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.cache_locks (key, owner, expiration) FROM stdin;
\.


--
-- Data for Name: citas; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.citas (id, paciente_id, doctor_id, fecha, hora, motivo, estatus, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: documentos_medicos; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.documentos_medicos (id, paciente_id, subido_por, tipo_documento, nombre_archivo, ruta_archivo, mime_type, tamano_bytes, texto_extraido, estatus_procesamiento, datos_extraidos, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: migrations; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.migrations (id, migration, batch) FROM stdin;
2	2025_11_12_200331_create_citas_table	1
3	2025_11_12_200344_create_bitacoras_table	1
4	2025_11_12_200351_create_recetas_table	1
5	2025_11_13_073400_create_personal_access_tokens_table	1
6	2025_11_13_161436_create_sessions_table	1
7	2025_12_02_205354_create_cache_table	1
8	2026_03_03_000001_create_two_factor_codes_table	1
9	2026_03_03_000002_create_audit_logs_table	1
10	0001_01_01_000000_create_users_table	2
\.


--
-- Data for Name: personal_access_tokens; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.personal_access_tokens (id, tokenable_type, tokenable_id, name, token, abilities, last_used_at, expires_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: recetas; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.recetas (id, cita_id, contenido, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.sessions (id, user_id, ip_address, user_agent, payload, last_activity) FROM stdin;
\.


--
-- Data for Name: two_factor_codes; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.two_factor_codes (id, user_id, code, expires_at, used, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.users (id, numero_control, username, nombre, apellido, email, password, tipo, telefono, fecha_nacimiento, created_at, updated_at, es_admin) FROM stdin;
\.


--
-- Name: analisis_documentos_ia_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.analisis_documentos_ia_id_seq', 1, false);


--
-- Name: audit_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.audit_logs_id_seq', 1, false);


--
-- Name: bitacoras_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.bitacoras_id_seq', 1, false);


--
-- Name: citas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.citas_id_seq', 1, false);


--
-- Name: documentos_medicos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.documentos_medicos_id_seq', 1, false);


--
-- Name: migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.migrations_id_seq', 10, true);


--
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.personal_access_tokens_id_seq', 1, false);


--
-- Name: recetas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.recetas_id_seq', 1, false);


--
-- Name: two_factor_codes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.two_factor_codes_id_seq', 1, false);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: neondb_owner
--

SELECT pg_catalog.setval('public.users_id_seq', 1, false);


--
-- Name: analisis_documentos_ia analisis_documentos_ia_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.analisis_documentos_ia
    ADD CONSTRAINT analisis_documentos_ia_pkey PRIMARY KEY (id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: bitacoras bitacoras_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.bitacoras
    ADD CONSTRAINT bitacoras_pkey PRIMARY KEY (id);


--
-- Name: cache_locks cache_locks_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.cache_locks
    ADD CONSTRAINT cache_locks_pkey PRIMARY KEY (key);


--
-- Name: cache cache_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.cache
    ADD CONSTRAINT cache_pkey PRIMARY KEY (key);


--
-- Name: citas citas_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.citas
    ADD CONSTRAINT citas_pkey PRIMARY KEY (id);


--
-- Name: documentos_medicos documentos_medicos_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.documentos_medicos
    ADD CONSTRAINT documentos_medicos_pkey PRIMARY KEY (id);


--
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- Name: personal_access_tokens personal_access_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_pkey PRIMARY KEY (id);


--
-- Name: personal_access_tokens personal_access_tokens_token_key; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_token_key UNIQUE (token);


--
-- Name: recetas recetas_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.recetas
    ADD CONSTRAINT recetas_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: two_factor_codes two_factor_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.two_factor_codes
    ADD CONSTRAINT two_factor_codes_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: personal_access_tokens_tokenable_type_tokenable_id_index; Type: INDEX; Schema: public; Owner: neondb_owner
--

CREATE INDEX personal_access_tokens_tokenable_type_tokenable_id_index ON public.personal_access_tokens USING btree (tokenable_type, tokenable_id);


--
-- Name: sessions_last_activity_index; Type: INDEX; Schema: public; Owner: neondb_owner
--

CREATE INDEX sessions_last_activity_index ON public.sessions USING btree (last_activity);


--
-- Name: sessions_user_id_index; Type: INDEX; Schema: public; Owner: neondb_owner
--

CREATE INDEX sessions_user_id_index ON public.sessions USING btree (user_id);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: neondb_owner
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: cloud_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE cloud_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO neon_superuser WITH GRANT OPTION;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: cloud_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE cloud_admin IN SCHEMA public GRANT ALL ON TABLES TO neon_superuser WITH GRANT OPTION;


--
-- PostgreSQL database dump complete
--

\unrestrict aIEkioJsfXCG3MonCoJly7LanIlistdV6rSHWY4VEHRZ7wQaBhJd28BT1XnemtS

