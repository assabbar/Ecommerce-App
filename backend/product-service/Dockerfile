FROM maven:3.9-eclipse-temurin-21 AS builder
WORKDIR /app
RUN echo "nameserver 8.8.8.8" > /etc/resolv.conf && echo "nameserver 1.1.1.1" >> /etc/resolv.conf
COPY pom.xml .
COPY product-service ./product-service
COPY api-gateway ./api-gateway
COPY order-service ./order-service
COPY inventory-service ./inventory-service
COPY notification-service ./notification-service
RUN mvn clean package -DskipTests -q

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=builder /app/product-service/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
