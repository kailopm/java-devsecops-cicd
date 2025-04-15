# Stage 1 Build Java App
FROM maven:3.9.9-eclipse-temurin-24 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2 Distroless
FROM gcr.io/distroless/java17-debian11
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
CMD ["app.jar"]