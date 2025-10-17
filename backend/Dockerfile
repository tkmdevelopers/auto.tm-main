## Multi-stage Dockerfile for NestJS + Sequelize (Postgres)
## Build locally (with internet) then transfer image tar.gz to offline Ubuntu server.

# -------- Dependencies & Build Stage --------
FROM node:20-bookworm-slim AS build
WORKDIR /app

# Install system deps needed for native modules (sharp, bcrypt) during build
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 make g++ \
    && rm -rf /var/lib/apt/lists/*

# Copy only package manifests first for better caching
COPY package.json ./
# If you have a lock file (package-lock.json or yarn.lock) copy it too for reproducible builds.
COPY package-lock.json* yarn.lock* ./

# Install all dependencies (including dev for build)
# Prefer npm ci when package-lock.json exists; fallback to npm install.
RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi

# Copy source (exclude via .dockerignore unwanted dirs)
COPY . .

# Build NestJS (outputs to dist/)
RUN npm run build

# Remove devDependencies to slim runtime
RUN npm prune --production

# -------- Runtime Stage --------
FROM node:20-bookworm-slim AS runtime
WORKDIR /app
ENV NODE_ENV=production

# Install minimal postgres client tools and curl (for container healthcheck)
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client curl \
    && rm -rf /var/lib/apt/lists/*

# Copy production node_modules & dist & package.json
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY --from=build /app/package.json ./package.json
COPY --from=build /app/config ./config
COPY --from=build /app/migrations ./migrations

# Copy uploads directory structure (will be volume-mounted for persistence)
COPY uploads ./uploads

# Entry script waits for DB then runs migrations then starts app
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 3080
ENTRYPOINT ["/entrypoint.sh"]
CMD ["node", "dist/main.js"]
