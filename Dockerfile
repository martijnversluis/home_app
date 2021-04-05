FROM debian:jessie-slim

ARG SECRET_KEY_BASE

ENV ASDF_VERSION "v0.8.0"
ENV ERLANG_VERSION "23.3.1"
ENV ELIXIR_VERSION "1.11.4"
ENV NODEJS_VERSION "14.16.0"

ENV SECRET_KEY_BASE $SECRET_KEY_BASE
ENV MIX_ENV prod
ENV HOME /root
ENV PATH ${HOME}/.asdf/bin:${HOME}/.asdf/shims:${PATH}

RUN apt update
RUN apt install -y automake \
                   autoconf \
                   ca-certificates \
                   curl \
                   git \
                   libncurses5-dev \
                   libssl-dev \
                   make \
                   nodejs \
                   openssl \
                   perl \
                   unixodbc \
                   unixodbc-dev \
                   unzip

WORKDIR /home_app

RUN echo 'PATH=$HOME/.asdf/bin:$HOME/.asdf/shims:$PATH' >> /root/.profile
RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch $ASDF_VERSION
RUN asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git
RUN asdf install erlang $ERLANG_VERSION
RUN asdf global erlang $ERLANG_VERSION
RUN asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git
RUN asdf install elixir $ELIXIR_VERSION
RUN asdf global elixir $ELIXIR_VERSION
RUN asdf plugin-add nodejs https://github.com/asdf-vm/asdf-nodejs.git
RUN asdf install nodejs $NODEJS_VERSION
RUN asdf global nodejs $NODEJS_VERSION
RUN yes | mix local.hex --force
RUN yes | mix local.rebar --force

COPY . .

RUN mix deps.get --only prod
RUN mix compile
RUN npm install --prefix ./assets
RUN npm run deploy --prefix ./assets
RUN mix phx.digest

EXPOSE 4000
