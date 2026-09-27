# Despliegue de `api-gesto-pago` (entorno Aurora)

Todo el entorno usa el prefijo **aurora**: proyecto de compose, contenedores, red, volumenes y esquema de base de datos.

Topología en el servidor:

```
aurora-api (contenedor) ──┬──► aurora-postgres17  (5432, ya existe)   red aurora-net
                          └──► aurora-redis810    (6379, ya existe)   red aurora-net
expuesto en http://100.91.46.42:8080  (Tailscale) y http://127.0.0.1:8080
```

Postgres y Redis **no** se tocan: solo se conectan a la red compartida `aurora-net`.

Nombres del entorno Aurora:

| Recurso | Nombre |
|---|---|
| Proyecto compose | `aurora` |
| Red externa | `aurora-net` |
| Contenedor API | `aurora-api` |
| Contenedor Postgres | `aurora-postgres17` |
| Contenedor Redis | `aurora-redis810` / `aurora-redis` (local) |
| Contenedor SonarQube | `aurora-sonarqube` |
| Esquema de Postgres | `aurora_pagos` |
| Base de datos | `aurora_pagos` |

---

## 0. Requisitos en el servidor

```bash
docker --version && docker compose version
```

Si tu `docker ps` usa podman (CachyOS/Asahi, típico por los contenedores rootless), todo lo de abajo funciona igual; la [sección 7](#7-si-tu-docker-es-podman) trae los comandos con `podman` a pelo.

## 1. Red compartida (una sola vez)

```bash
sudo docker network create aurora-net        # si ya existe: "network aurora-net already exists", ok
sudo docker network connect aurora-net aurora-postgres17
sudo docker network connect aurora-net aurora-redis810
sudo docker network ls                      # aurora-net debe listarse
```

Si tu runtime es podman rootless: `podman network create aurora-net` y `podman network connect aurora-net aurora-postgres17` (sin `sudo`).

## 2. Descargar el código del compose (o copia estos 2 archivos)

```bash
git clone https://github.com/BryanArredon/api-gesto-pago.git && cd api-gesto-pago
# o solo los archivos necesarios:
#   docker-compose.servidor.yml   .env.server.example
```

## 3. Crear el `.env.server` con los secretos

```bash
cp .env.server.example .env.server
$EDITOR .env.server     # PostgreSQL user/pass, DB_SCHEMA, JWT_SECRET, GESTOPAGO_*, ADMIN_PASSWORD, CORS
chmod 600 .env.server
```

Generar un `JWT_SECRET` nuevo para producción (mínimo 32 bytes, HS256):

```bash
openssl rand -base64 48
```

Antes de la primera corrida, asegúrate de que en `aurora-postgres17` existan la base y el usuario que pusiste en `.env.server`:

```bash
sudo docker exec -it aurora-postgres17 psql -U postgres -c "CREATE USER gestor_pagos WITH PASSWORD 'TU_PASSWORD';"
sudo docker exec -it aurora-postgres17 psql -U postgres -c "CREATE DATABASE aurora_pagos OWNER gestor_pagos;"
```

(Ajusta `POSTGRES_USER` si el superusuario de tu contenedor no es `postgres`; puedes ver el env con `docker inspect aurora-postgres17 --format '{{range .Config.Env}}{{println .}}{{end}}'`.) Flyway crea el esquema `aurora_pagos`, las tablas y el admin inicial al arrancar el API.

## 4. Levantar

```bash
docker compose -f docker-compose.servidor.yml up -d
docker compose -f docker-compose.servidor.yml logs -f api
```

Salud:

```bash
curl -s http://127.0.0.1:8080/actuator/health        # {"status":"UP"}
curl -s http://100.91.46.42:8080/actuator/health       # desde otra maquina con Tailscale
open http://100.91.46.42:8080/swagger-ui.html          # docs (solo Tailscale)
```

## 5. Actualizar a una imagen nueva

```bash
docker compose -f docker-compose.servidor.yml pull
docker compose -f docker-compose.servidor.yml up -d
docker image prune -f
```

O fijando versión (recomendado en producción, para poder volver atrás):

```bash
docker pull bryanarrendon/gesto-pago:1.0.0     # edita IMAGE_TAG en el compose
```

## 6. Publicar una imagen nueva desde tu Mac

```bash
cd /Volumes/RespaldoMacbook/UTNG/GestoPago_v2/api-gesto-pago
docker buildx build --platform linux/amd64 -t bryanarrendon/gesto-pago:latest -t bryanarrendon/gesto-pago:1.0.1 --push .
```

(`--platform linux/amd64` es obligatorio: tu Mac es arm64 y el servidor es x86_64. El build tarda ~4 min la primera vez; después las capas de gradle quedan cacheadas.)

## 7. Si tu docker es podman

Sin compose, con `podman run` directo (esto funciona en CachyOS rootless tal cual):

```bash
podman network create aurora-net
podman network connect aurora-net aurora-postgres17
podman network connect aurora-net aurora-redis810

podman run -d --name aurora-api --network aurora-net --restart=unless-stopped \
  --memory=900m --cpus=2 \
  -p 127.0.0.1:8080:8080 -p 100.91.46.42:8080:8080 \
  --env-file .env.server \
  -e SPRING_DATASOURCE_URL=jdbc:postgresql://aurora-postgres17:5432/aurora_pagos \
  -e DB_SCHEMA=aurora_pagos \
  -e REDIS_HOST=aurora-redis810 -e REDIS_PORT=6379 \
  -e SPRING_JPA_SHOW_SQL=false -e SPRING_JPA_HIBERNATE_DDL_AUTO=none \
  -e TZ=America/Mexico_City \
  bryanarrendon/gesto-pago:latest

podman logs -f aurora-api
podman stats aurora-api
```

Actualizar: `podman pull bryanarrendon/gesto-pago:latest && podman rm -f aurora-api` y repite el `podman run`.

---

## Entorno local (desarrollo)

```bash
docker compose up -d                       # aurora-redis + aurora-sonarqube
docker compose -f docker-compose-it.yml up -d   # aurora-postgres-it (5434) + aurora-redis-it (6380)
cp .env.example .env                       # apuntar a localhost:5432 / localhost:6379
sh gradlew bootRun
```

Tests:

```bash
sh gradlew test                 # unitarios (excluye *IntegrationTest)
sh gradlew integrationTest      # necesita docker-compose-it.yml arriba
sh gradlew sonar                 # requiere aurora-sonarqube en :9000
```

## Comandos de operación

```bash
docker logs -f aurora-api                                   # ver logs
docker restart aurora-api                                    # reiniciar
docker stats aurora-api --no-stream                          # RAM/CPU en vivo
docker exec -it aurora-api sh                               # shell dentro (usuario app)
docker system df                                            # espacio en disco
```

## Notas

- **Memoria:** el compose/podman limita a 900 MB y la JVM usa `MaxRAMPercentage=70` con GC serial. Medido: ~510 MB RSS arrancando en frío (emulado); en reposo se queda entre 350 y 450 MB junto a Postgres y Redis.
- **Imagen:** no contiene ni `.env` ni tests (ver `.dockerignore`); los secretos viven solo en `.env.server` en el servidor, con permisos 600.
- **Esquema:** en producción queda `SPRING_JPA_HIBERNATE_DDL_AUTO=none` para que solo Flyway (`spring.flyway.schemas=${DB_SCHEMA}`) toque las tablas. Si cambias `DB_SCHEMA`, Flyway crea el esquema nuevo vacío: no migra datos entre esquemas.
- **Historial de pagos:** Postgres es la fuente de verdad y Redis es la lectura prioritaria. Si Redis está caído, el historial se sigue sirviendo desde Postgres (degradado, no caído). Ver `PAGOS_HISTORIAL_REDIS_*` en `.env.server`.
- **Postgres/Redis** quedan bound a `127.0.0.1`; el API los alcanza por DNS interno de la red `aurora-net`, así que no hace falta abrir puertos.
- **Estado de Flyway:** las migraciones `V1..V6` corren solas en el primer arranque; si la BD ya existe, no vuelve a tocar nada.
- Si prefieres no crear la red y usar la red del host: quita el bloque `networks` y pon `network_mode: host` en el servicio `api` (queda en `0.0.0.0:8080`, alcanzable también desde la LAN).
- **Parseo XML de GestoPago:** se hace con DOM (`javax.xml.parsers`) y `disallow-doctype-decl` activado, sin depender de JAXB para las respuestas de operación. JAXB sigue usándose para el token y el catálogo.

## Para la app Flutter

- Teléfono real o emulador accessing el API por Tailscale:
  `flutter run --dart-define=API_BASE_URL=http://100.91.46.42:8080`
- Web en el servidor: agrega `http://100.91.46.42:3000` (y el que uses) a `CORS_ALLOWED_ORIGINS` del `.env.server` y reinicia.
- La app móvil no manda `Origin`, así que CORS solo aplica a la versión web.
