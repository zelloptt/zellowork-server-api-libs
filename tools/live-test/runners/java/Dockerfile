FROM eclipse-temurin:17-jdk-jammy

RUN apt-get update \
  && apt-get install -y --no-install-recommends curl \
  && curl -fsSL -o /opt/json.jar \
    https://repo1.maven.org/maven2/org/json/json/20240303/json-20240303.jar \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /runner
COPY LiveTestMain.java /runner/LiveTestMain.java
COPY entrypoint.sh /runner/entrypoint.sh
RUN chmod +x /runner/entrypoint.sh
ENTRYPOINT ["/runner/entrypoint.sh"]
