FROM maven:3.9-eclipse-temurin-21 AS builder
WORKDIR /app
COPY pom.xml .
COPY notification-service ./notification-service
COPY api-gateway ./api-gateway
COPY product-service ./product-service
COPY order-service ./order-service
COPY inventory-service ./inventory-service
RUN mvn clean package -DskipTests -q

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=builder /app/notification-service/target/*.jar app.jar
EXPOSE 8083
ENTRYPOINT ["java", "-jar", "app.jar"]
