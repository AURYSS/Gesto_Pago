# syntax=docker/dockerfile:1

# ---------- 1. Build + extracción de capas (solo la imagen de Gradle) ----------
FROM gradle:8.10.2-jdk17-alpine AS build
WORKDIR /src
ENV GRADLE_USER_HOME=/src/.gradle
# Copiar solo el descriptor primero: la capa de dependencias se cachea
COPY build.gradle settings.gradle ./
COPY gradle gradle
RUN gradle --no-daemon dependencies --quiet || true
COPY src src
# Los tests no se corren en el build de imagen (ver `sh gradlew test`)
RUN gradle --no-daemon clean bootJar -x test \
    && java -Djarmode=layertools -jar build/libs/*.jar extract \
    && rm -rf build/libs build/tmp build/classes build/resources

# ---------- 1.5 Binario estático de cloudflared para túneles TCP ----------
FROM cloudflare/cloudflared:latest AS cloudflared

# ---------- 2. Runtime ----------
FROM eclipse-temurin:17-jre-alpine AS runtime
RUN cp /usr/share/zoneinfo/America/Mexico_City /etc/localtime \
    && echo "America/Mexico_City" > /etc/timezone \
    && addgroup -g 10001 -S app \
    && adduser -u 10001 -S app -G app

COPY --from=cloudflared /usr/local/bin/cloudflared /usr/local/bin/cloudflared

WORKDIR /app
# Orden de capas = orden de cache: deps (estable) -> resources/classes -> loader
COPY --from=build --chown=app:app /src/dependencies/ ./
COPY --from=build --chown=app:app /src/snapshot-dependencies/ ./
COPY --from=build --chown=app:app /src/application/ ./
COPY --from=build --chown=app:app /src/spring-boot-loader/ ./

USER app
EXPOSE 8080 10000

# GC serial + límite por % de RAM + TieredStopAtLevel=1 para arranque rápido en Render
ENV JAVA_OPTS="-XX:TieredStopAtLevel=1 -XX:MaxRAMPercentage=70.0 -XX:InitialRAMPercentage=25.0 -XX:+UseSerialGC -XX:+ExitOnOutOfMemoryError -Dfile.encoding=UTF-8 -Duser.timezone=America/Mexico_City" \
    TZ="America/Mexico_City"

HEALTHCHECK --interval=30s --timeout=5s --start-period=45s --retries=3 \
    CMD wget -q -O - http://localhost:${PORT:-8080}/actuator/health | grep -q '"status":"UP"' || exit 1

ENTRYPOINT ["sh", "-c", "cloudflared access tcp --hostname ${CLOUDFLARED_DB_HOST:-db.bryandevs.com} --url localhost:${CLOUDFLARED_DB_PORT:-1050} >/dev/null 2>&1 & cloudflared access tcp --hostname ${CLOUDFLARED_REDIS_HOST:-redis.bryandevs.com} --url localhost:${CLOUDFLARED_REDIS_PORT:-6380} >/dev/null 2>&1 & sleep 2 && exec java $JAVA_OPTS -Dserver.port=${PORT:-8080} -cp /app org.springframework.boot.loader.launch.JarLauncher"]
