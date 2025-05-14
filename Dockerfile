# syntax=docker.io/docker/dockerfile:1

## Base Stage
# node:lts-alpine3.21
FROM node@sha256:ad1aedbcc1b0575074a91ac146d6956476c1f9985994810e4ee02efd932a68fd AS base
WORKDIR /app

COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* .npmrc* ./
RUN \
  if [ -f yarn.lock ]; then yarn --frozen-lockfile; \
  elif [ -f package-lock.json ]; then npm ci; \
  elif [ -f pnpm-lock.yaml ]; then corepack enable pnpm && corepack use pnpm@latest-10 && pnpm i; \
  else echo "Lockfile not found." && exit 1; \
  fi

## Build Stage
FROM base AS builder
WORKDIR /app

COPY . .
RUN \
  if [ -f yarn.lock ]; then yarn run build; \
  elif [ -f package-lock.json ]; then npm run build; \
  elif [ -f pnpm-lock.yaml ]; then corepack use pnpm@latest-10 && pnpm run build; \
  else echo "Lockfile not found." && exit 1; \
  fi

## Final Stage
FROM base AS runner
WORKDIR /app

ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0
ENV APP_ENV=INSERT_ENVIRONMENT
ENV NEXT_TELEMETRY_DISABLED=1

LABEL release-date="INSERT_RELEASE_DATE"

RUN addgroup --system --gid 1001 app_group && \
    adduser --system --uid 1001 app_user

COPY --from=builder --chown=app_user:app_group /app /app

USER app_user

EXPOSE 4242
CMD ["sh", "-c", "pnpm serve --host 0.0.0.0 --port 4242"]

HEALTHCHECK --interval=10s --timeout=15s --start-period=5s --retries=3 CMD curl -f http://localhost:4242/ || exit 1