ARG ELIXIR_VERSION=1.18.2
ARG OTP_VERSION=27.2
ARG DEBIAN_VERSION=bookworm-20250113-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

# Build stage
FROM ${BUILDER_IMAGE} as builder

RUN apt-get update -y && apt-get install -y build-essential git ca-certificates openssl \
    && update-ca-certificates --fresh \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

WORKDIR /app

ENV MIX_ENV=prod
ENV HEX_UNSAFE_HTTPS=true

# Dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# Config
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

# Assets (esbuild + tailwind)
COPY priv priv
COPY assets assets
RUN mix assets.deploy

# Application
COPY lib lib
RUN mix compile

# Release
COPY config/runtime.exs config/
COPY rel rel
RUN mix release

# Runner stage
FROM ${RUNNER_IMAGE}

RUN apt-get update -y && \
    apt-get install -y libstdc++6 openssl libncurses6 locales ca-certificates curl \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

WORKDIR /app

RUN chown nobody:nogroup /app

USER nobody:nogroup

COPY --from=builder --chown=nobody:nogroup /app/_build/prod/rel/discuss ./

ENV HOME=/app

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8080/health/liveness || exit 1

CMD ["bin/discuss", "start"]
