-- Catalogo de marcas del proveedor y sus categorias funcionales.
--
-- Antes vivia dentro de la app (GpMarcas/GpAssets) como mapas literales: la
-- marca, su categoria, su color y su logo se cambiaban con un despliegue de
-- la app y no se podian corregir sin release. Aqui el catalogo es dato: se
-- corrige con un UPDATE y la app lo toma de GET /catalogo/marcas.
--
-- `logo_asset` es la ruta del logo dentro del paquete de assets. NULL es un
-- estado valido (marca sin logo: la ficha dibuja iniciales) y `color_hex`
-- tambien: ahi la ficha usa una franja neutra en vez de inventar un tinte.
-- El catalogo de productos (V2) no trae ninguno de los dos datos, asi que
-- esta tabla es la unica fuente de ellos.

CREATE TABLE catalogo_categorias (
    slug       VARCHAR(40)  PRIMARY KEY,
    nombre     VARCHAR(80)  NOT NULL,
    orden      SMALLINT     NOT NULL,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_catalogo_categorias_orden CHECK (orden > 0)
);

CREATE TABLE catalogo_marcas (
    slug        VARCHAR(40)  PRIMARY KEY,
    nombre      VARCHAR(80)  NOT NULL,
    categoria   VARCHAR(40)  REFERENCES catalogo_categorias (slug),
    color_hex   CHAR(7),
    logo_asset  VARCHAR(160),
    destacada   BOOLEAN      NOT NULL DEFAULT FALSE,
    orden       SMALLINT     NOT NULL DEFAULT 0,
    activo      BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_catalogo_marcas_color CHECK (color_hex IS NULL OR color_hex ~ '^#[0-9A-Fa-f]{6}$'),
    CONSTRAINT ck_catalogo_marcas_orden CHECK (orden >= 0)
);

CREATE INDEX idx_catalogo_marcas_categoria ON catalogo_marcas (categoria) WHERE activo;
CREATE INDEX idx_catalogo_marcas_destacada ON catalogo_marcas (orden) WHERE activo AND destacada;
CREATE INDEX idx_catalogo_marcas_nombre ON catalogo_marcas (nombre);

INSERT INTO catalogo_categorias (slug, nombre, orden) VALUES
    ('tiempo_aire', 'Tiempo Air', 1),
    ('internet', 'Internet', 2),
    ('television', 'Television', 3),
    ('entretenimiento', 'Entretenimiento', 4),
    ('servicios', 'Servicios', 5),
    ('transporte', 'Transporte', 6);

-- Semilla: 51 marcas con logo. `orden` fija la portada (las destacadas, en
-- este orden) y vale 0 en el resto, que se ordenan por nombre.
INSERT INTO catalogo_marcas (slug, nombre, categoria, color_hex, logo_asset, destacada, orden) VALUES
    ('amazon', 'Amazon', 'entretenimiento', '#FF9900', 'assets/images/marcas/amazon.png', FALSE, 0),
    ('andrea', 'Andrea', 'servicios', NULL, 'assets/logos/andrea.png', FALSE, 0),
    ('apple', 'Apple', 'entretenimiento', '#A2AAB3', 'assets/logos/apple.png', FALSE, 0),
    ('att', 'AT&T', 'tiempo_aire', '#00A8E0', 'assets/images/marcas/att.png', TRUE, 5),
    ('avon', 'Avon', 'servicios', '#C2185B', 'assets/logos/avon.png', FALSE, 0),
    ('axtel', 'Axtel', 'internet', '#00A0E0', 'assets/logos/axtel.png', FALSE, 0),
    ('bait', 'Bait', 'tiempo_aire', '#00A651', 'assets/images/marcas/bait.png', FALSE, 0),
    ('betterware', 'Betterware', 'servicios', NULL, 'assets/logos/betterware.png', FALSE, 0),
    ('cfe', 'CFE', 'servicios', '#E87722', 'assets/images/marcas/cfe.png', TRUE, 2),
    ('cinemex', 'Cinemex', 'entretenimiento', '#1257A6', 'assets/logos/cinemex.png', FALSE, 0),
    ('cinepolis', 'Cinepolis', 'entretenimiento', '#E03A3E', 'assets/logos/cinepolis.png', FALSE, 0),
    ('didi', 'DiDi', 'transporte', '#FF7B00', 'assets/logos/didi.png', FALSE, 0),
    ('dish', 'Dish', 'internet', '#1B4F9C', 'assets/images/marcas/dish.png', FALSE, 0),
    ('engie', 'Engie', 'servicios', '#124191', 'assets/logos/engie.png', FALSE, 0),
    ('free_fire', 'Free Fire', 'entretenimiento', '#F79E1B', 'assets/images/marcas/free_fire.png', FALSE, 0),
    ('gob_cdmx', 'Gobierno CDMX', 'servicios', NULL, 'assets/logos/gob_cdmx.png', FALSE, 0),
    ('gob_edomex', 'Gobierno Edomex', 'servicios', NULL, 'assets/logos/gob_edomex.png', FALSE, 0),
    ('google_play', 'Google Play', 'entretenimiento', '#34A853', 'assets/images/marcas/google_play.png', FALSE, 0),
    ('herbalife', 'Herbalife', 'servicios', '#7AB51D', 'assets/logos/herbalife.png', FALSE, 0),
    ('infonavit', 'Infonavit', 'servicios', '#0B6E9E', 'assets/logos/infonavit.png', FALSE, 0),
    ('izzi', 'Izzi', 'internet', '#E4002B', 'assets/images/marcas/izzi.png', TRUE, 3),
    ('jafra', 'Jafra', 'servicios', '#D81B60', 'assets/logos/jafra.png', FALSE, 0),
    ('mary_kay', 'Mary Kay', 'servicios', NULL, 'assets/logos/mary_kay.png', FALSE, 0),
    ('megacable', 'Megacable', 'internet', '#00539F', 'assets/images/marcas/megacable.png', FALSE, 0),
    ('movistar', 'Movistar', 'tiempo_aire', '#0B4EA2', 'assets/images/marcas/movistar.png', FALSE, 0),
    ('natura', 'Natura', 'servicios', '#76B82A', 'assets/logos/natura.png', FALSE, 0),
    ('naturgy', 'Naturgy', 'servicios', '#00A0B0', 'assets/images/marcas/naturgy.png', FALSE, 0),
    ('netflix', 'Netflix', 'entretenimiento', '#E50914', 'assets/images/marcas/netflix.png', FALSE, 0),
    ('nintendo', 'Nintendo', 'entretenimiento', '#E60012', 'assets/images/marcas/nintendo.png', FALSE, 0),
    ('pase', 'Pase', 'transporte', '#1B7FD4', 'assets/images/marcas/pase.png', FALSE, 0),
    ('pillofon', 'Pillofon', 'tiempo_aire', '#1B5FAA', 'assets/images/marcas/pillofon.png', FALSE, 0),
    ('playstation', 'PlayStation', 'entretenimiento', '#003791', 'assets/images/marcas/playstation.png', FALSE, 0),
    ('price_shoes', 'Price Shoes', 'servicios', NULL, 'assets/logos/price_shoes.png', FALSE, 0),
    ('roblox', 'Roblox', 'entretenimiento', '#E2231A', 'assets/images/marcas/roblox.png', FALSE, 0),
    ('sacmex', 'SACMEX', 'servicios', NULL, 'assets/logos/sacmex.png', FALSE, 0),
    ('sat', 'SAT', 'servicios', NULL, 'assets/logos/sat.png', FALSE, 0),
    ('sky', 'Sky', 'television', '#0A85C6', 'assets/images/marcas/sky.png', TRUE, 4),
    ('spotify', 'Spotify', 'entretenimiento', '#1DB954', 'assets/images/marcas/spotify.png', FALSE, 0),
    ('starbucks', 'Starbucks', 'entretenimiento', '#00754A', 'assets/images/marcas/starbucks.png', FALSE, 0),
    ('startv', 'StarTV', 'television', '#D2232A', 'assets/logos/startv.png', FALSE, 0),
    ('steam', 'Steam', 'entretenimiento', '#66C0F4', 'assets/logos/steam.png', FALSE, 0),
    ('telcel', 'Telcel', 'tiempo_aire', '#00A9E0', 'assets/images/marcas/telcel.png', TRUE, 1),
    ('televia', 'Televia', 'television', '#D22630', 'assets/images/marcas/televia.png', FALSE, 0),
    ('telmex', 'Telmex', 'internet', '#002E5D', 'assets/images/marcas/telmex.png', FALSE, 0),
    ('totalplay', 'Totalplay', 'internet', '#D6202B', 'assets/images/marcas/totalplay.png', FALSE, 0),
    ('tupperware', 'Tupperware', 'servicios', NULL, 'assets/logos/tupperware.png', FALSE, 0),
    ('uber', 'Uber', 'transporte', '#9BA3A8', 'assets/logos/uber.png', FALSE, 0),
    ('unefon', 'Unefon', 'tiempo_aire', '#C2185B', 'assets/images/marcas/unefon.png', FALSE, 0),
    ('virgin_mobile', 'Virgin Mobile', 'tiempo_aire', '#D8232A', 'assets/logos/virgin_mobile.png', FALSE, 0),
    ('xbox', 'Xbox', 'entretenimiento', '#107C10', 'assets/images/marcas/xbox.png', FALSE, 0),
    ('zeta_gas', 'Zeta Gas', 'servicios', '#EFA00B', 'assets/images/marcas/zeta_gas.png', FALSE, 0);
