# syntax=docker/dockerfile:1

# Base images are pinned by digest (multi-arch index) for reproducible builds;
# Dependabot bumps them. Build and runtime share Debian 13 (glibc), so any native
# module compiled in the build stage also runs in the runtime stage.
ARG BUILD_IMAGE=node:24-trixie-slim@sha256:54f84b4cf8432b21aaffd5d3ce8d41e12cea0d10d33c09d2f3c9879d49d6b446
ARG RUNTIME_IMAGE=gcr.io/distroless/nodejs24-debian13:nonroot@sha256:a6c34457f6da4295807e051411c7783739c65b997a324fed14e4fa292615ae91

# ---- deps: install exact dependency versions from the lockfile ---------------
FROM ${BUILD_IMAGE} AS deps
WORKDIR /app
COPY package.json package-lock.json ./
# Cache mount keeps the npm cache out of the image layers but reuses it between builds.
RUN --mount=type=cache,target=/root/.npm \
    npm ci --no-audit --no-fund

# ---- build: compile the standalone Next.js server ----------------------------
FROM ${BUILD_IMAGE} AS build
WORKDIR /app
ENV NEXT_TELEMETRY_DISABLED=1
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

# ---- runtime: distroless, non-root, no shell or package manager --------------
FROM ${RUNTIME_IMAGE} AS runtime

ARG APP_VERSION=dev
LABEL org.opencontainers.image.title="web" \
      org.opencontainers.image.description="Next.js Hello World service with a BFF health API" \
      org.opencontainers.image.source="https://github.com/aung-myatkyaw/messagespring-devops-challenge" \
      org.opencontainers.image.revision="${APP_VERSION}" \
      org.opencontainers.image.version="${APP_VERSION}"

WORKDIR /app
ENV NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1 \
    PORT=3000 \
    HOSTNAME=0.0.0.0 \
    APP_VERSION=${APP_VERSION}

# Files stay owned by root: the app user can read but not modify its own code.
# Only .next/cache needs to be writable; it is mounted as tmpfs/emptyDir at runtime.
COPY --from=build /app/.next/standalone ./
COPY --from=build /app/.next/static ./.next/static

# uid/gid 65532 ("nonroot" in distroless).
USER 65532:65532
EXPOSE 3000

# Exec form: there is no shell in distroless. Docker and Compose use this;
# Kubernetes ignores it and uses the pod's probes on the same endpoint.
HEALTHCHECK --interval=30s --timeout=3s --start-period=15s --retries=3 \
    CMD ["/nodejs/bin/node", "-e", "fetch('http://127.0.0.1:' + (process.env.PORT || 3000) + '/api/health').then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"]

# The distroless entrypoint is the node binary; this is its argument.
CMD ["server.js"]
