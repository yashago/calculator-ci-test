# syntax=docker/dockerfile:1

# ---- build: compile the Spring Boot jar (tests already ran in the CI build-test job) ----
# eclipse-temurin:21-jdk-noble
FROM eclipse-temurin@sha256:70898f0f893a6b772a0f29834d8b022e3ac20b6a0c33a922973cf66342ef56be AS build
WORKDIR /workspace

# Dependencies first, so source-only changes reuse this layer
COPY mvnw pom.xml ./
COPY .mvn/ .mvn/
RUN --mount=type=cache,target=/root/.m2 ./mvnw -B -q dependency:go-offline

COPY src/ src/
RUN --mount=type=cache,target=/root/.m2 ./mvnw -B -q package -DskipTests

# Split the fat jar into layers ordered from least to most frequently changed
RUN java -Djarmode=tools -jar target/calculator.jar extract --layers --launcher --destination /layers

# ---- runtime ----
# eclipse-temurin:21-jre-noble
FROM eclipse-temurin@sha256:22138efd69393501fccd8176ae16b01791ed71ff801b28f0359415389b17c766
WORKDIR /app

COPY --from=build /layers/dependencies/ ./
COPY --from=build /layers/spring-boot-loader/ ./
COPY --from=build /layers/snapshot-dependencies/ ./
COPY --from=build /layers/application/ ./

# Image tag, served by /api/v1/version
ARG APP_VERSION=dev
ENV APP_VERSION=${APP_VERSION} \
    JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75 -XX:+ExitOnOutOfMemoryError"

# Numeric UID so Kubernetes runAsNonRoot can verify it
USER 10001:10001
EXPOSE 8080

# Health is checked by Kubernetes probes (/actuator/health/liveness, /actuator/health/readiness)
ENTRYPOINT ["java", "org.springframework.boot.loader.launch.JarLauncher"]
