FROM hexpm/elixir:1.17.0-erlang-27.0-debian-bookworm-20240612

ENV DEBIAN_FRONTEND noninteractive

ARG PHOENIX_VERSION=1.7.11
ARG NODEJS_VERSION=20.x

RUN apt-get update && apt-get upgrade -y && \
  apt-get install -y curl && \
  apt-get install -y git && \
  apt-get install -y apt-utils && \
  apt-get install -y build-essential && \
  apt-get install -y inotify-tools && \
  curl -sL https://deb.nodesource.com/setup_${NODEJS_VERSION} | bash && \
  apt-get install -y nodejs && \
  npm install --global yarn && \
  apt-get autoremove -y && \
  apt-get clean -y && \
  rm -rf /var/lib/apt/lists/* && \
  mix local.rebar --force && \
  mix local.hex --force && \
  mix archive.install --force hex phx_new #{PHOENIX_VERSION}
