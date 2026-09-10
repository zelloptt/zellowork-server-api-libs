FROM php:8.3-cli-bookworm

RUN apt-get update \
  && apt-get install -y --no-install-recommends libcurl4-openssl-dev \
  && docker-php-ext-install curl \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
COPY run.php /runner/run.php
ENTRYPOINT ["php", "/runner/run.php"]
