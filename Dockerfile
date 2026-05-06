# syntax=docker/dockerfile:1

FROM ruby:3.1-slim AS build
WORKDIR /site

RUN apt-get update \
 && apt-get install -y --no-install-recommends build-essential git \
 && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment 'true' \
 && bundle config set --local without 'development test' \
 && bundle install --jobs 4 --retry 3

COPY . .

# Override baseurl so the site works at the domain root on Railway
# (the committed _config.yml keeps the GitHub Pages baseurl intact).
# PAGES_REPO_NWO is required by the github-pages gem when not building inside git.
ARG PAGES_REPO_NWO=twahidin/hosting-parson
ENV PAGES_REPO_NWO=${PAGES_REPO_NWO}
RUN bundle exec jekyll build --destination /out --baseurl ""

FROM caddy:2-alpine
COPY --from=build /out /srv
COPY Caddyfile /etc/caddy/Caddyfile
EXPOSE 8080
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
