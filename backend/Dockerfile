FROM maven:3.9.11-eclipse-temurin-21-alpine AS build

WORKDIR /app

# Resolve dependencies in their own layer, keyed on pom.xml. As long as pom.xml
# is unchanged, this layer is cached and rebuilds after a code change skip the
# (slow) dependency download entirely.
COPY pom.xml .
RUN mvn -B dependency:go-offline

COPY src ./src
RUN mvn -B clean package

FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Run as an unprivileged user instead of root.
RUN addgroup -S app && adduser -S app -G app

COPY --from=build /app/target/*.jar app.jar

USER app

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
