FROM caddy:builder-alpine AS builder

RUN xcaddy build \
    --with github.com/relvacode/caddy-oidc@v0.4.3

FROM caddy:alpine

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
