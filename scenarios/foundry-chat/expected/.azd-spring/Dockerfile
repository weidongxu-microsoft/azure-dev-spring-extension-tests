FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /workspace
COPY . .
RUN mvn -B -Dmaven.test.skip=true package

FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build --chown=10001:10001 ["/workspace/target/foundry-chat-0.0.1-SNAPSHOT.jar","/app/application.jar"]
COPY --chown=10001:10001 .azd-spring/application-azd.properties /app/.azd-spring/application.properties
EXPOSE 8080
USER 10001
ENTRYPOINT ["java", "-jar", "/app/application.jar"]
