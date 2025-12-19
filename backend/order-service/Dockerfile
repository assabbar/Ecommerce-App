# syntax=docker/dockerfile:1.4
FROM maven:3.9-eclipse-temurin-21 AS builder
WORKDIR /app

# Copy only pom.xml first
COPY pom.xml .
COPY order-service/pom.xml ./order-service/pom.xml
COPY inventory-service/pom.xml ./inventory-service/pom.xml
COPY api-gateway/pom.xml ./api-gateway/pom.xml
COPY product-service/pom.xml ./product-service/pom.xml
COPY notification-service/pom.xml ./notification-service/pom.xml

# Download dependencies with cache mount
RUN --mount=type=cache,target=/root/.m2 \
    mvn dependency:go-offline -pl order-service -am

# Copy source code
COPY order-service ./order-service
COPY inventory-service ./inventory-service
COPY api-gateway ./api-gateway
COPY product-service ./product-service
COPY notification-service ./notification-service

# Build with cache mount
RUN --mount=type=cache,target=/root/.m2 \
    mvn clean package -pl order-service -am -DskipTests -q

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=builder /app/order-service/target/*.jar app.jar
EXPOSE 8081
ENTRYPOINT ["java", "-jar", "app.jar"]
