# syntax=docker/dockerfile:1.4
FROM maven:3.9-eclipse-temurin-21 AS builder
WORKDIR /app

# Copy only pom.xml first to leverage Docker layer caching
COPY pom.xml .
COPY product-service/pom.xml ./product-service/pom.xml
COPY api-gateway/pom.xml ./api-gateway/pom.xml
COPY order-service/pom.xml ./order-service/pom.xml
COPY inventory-service/pom.xml ./inventory-service/pom.xml
COPY notification-service/pom.xml ./notification-service/pom.xml

# Download dependencies with cache mount (reuses between builds)
RUN --mount=type=cache,target=/root/.m2 \
    mvn dependency:go-offline -pl product-service -am

# Copy source code
COPY product-service ./product-service
COPY api-gateway ./api-gateway
COPY order-service ./order-service
COPY inventory-service ./inventory-service
COPY notification-service ./notification-service

# Build with cache mount
RUN --mount=type=cache,target=/root/.m2 \
    mvn clean package -pl product-service -am -DskipTests -q

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=builder /app/product-service/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
