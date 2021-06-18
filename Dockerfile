ARG SECRET_KEY_BASE
ARG ERLANG_VERSION="23.2.7"

FROM bitwalker/alpine-elixir:1.10.4

ENV ELIXIR_VERSION 1.10
ENV SECRET_KEY_BASE $SECRET_KEY_BASE
ENV MIX_ENV prod
ENV HOME /root

RUN apk update
RUN apk upgrade
RUN apk add nodejs nodejs-npm

RUN elixir -v
RUN node -v

WORKDIR /home_app

RUN yes | mix local.hex --force
RUN yes | mix local.rebar --force

COPY . .

RUN mix deps.get --only prod
RUN mix compile
RUN npm install --prefix ./assets
RUN npm run deploy --prefix ./assets
RUN mix phx.digest

RUN apk del nodejs nodejs-npm
RUN rm -rf /var/cache/apk/*

EXPOSE 4000

CMD ["/home_app/bin/server"]
