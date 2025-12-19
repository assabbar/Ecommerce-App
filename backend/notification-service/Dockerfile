# syntax=docker/dockerfile:1.4
FROM maven:3.9-eclipse-temurin-21 AS builder
WORKDIR /app

# Copy only pom.xml first
COPY pom.xml .
COPY notification-service/pom.xml ./notification-service/pom.xml
COPY api-gateway/pom.xml ./api-gateway/pom.xml
COPY product-service/pom.xml ./product-service/pom.xml
COPY order-service/pom.xml ./order-service/pom.xml
COPY inventory-service/pom.xml ./inventory-service/pom.xml

# Download dependencies with cache mount
RUN --mount=type=cache,target=/root/.m2 \
    mvn dependency:go-offline -pl notification-service -am

# Copy source code
COPY notification-service ./notification-service
COPY api-gateway ./api-gateway
COPY product-service ./product-service
COPY order-service ./order-service
COPY inventory-service ./inventory-service

# Build with cache mount
RUN --mount=type=cache,target=/root/.m2 \
    mvn clean package -pl notification-service -am -DskipTests -q

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=builder /app/notification-service/target/*.jar app.jar
EXPOSE 8083
ENTRYPOINT ["java", "-jar", "app.jar"]
