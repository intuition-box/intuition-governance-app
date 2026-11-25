# The governance site as a container: the static export of packages/ui,
# built with the workspace's own toolchain, then served by nginx on port 80.
# The export has no server (`next start` refuses `output: "export"`). Build
# it from the repository root, because the build needs the whole workspace.

# Build: Node 26 as .nvmrc pins, and pnpm 11.21.0 as a standalone binary,
# the packageManager in package.json and the pnpm that reads allowBuilds in
# pnpm-workspace.yaml. Never corepack: Node 26 no longer bundles it.
FROM node:26-slim AS build
ENV PNPM_HOME=/pnpm
# pnpm 11 puts its binary in a bin/ folder of its home.
ENV PATH=$PNPM_HOME/bin:$PATH
# git lets next.config.js take the build ID from the commit, as a release
# build does. python3, make and g++ let node-gyp compile bufferutil and
# utf-8-validate, which ship no prebuilt binary for linux-arm64 and whose
# install scripts have no fallback. This stage is discarded, so the image
# stays small.
RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates curl git \
    python3 make g++ \
  && rm -rf /var/lib/apt/lists/* \
  && curl -fsSL https://get.pnpm.io/install.sh \
  | env PNPM_VERSION=11.21.0 ENV="$HOME/.bashrc" SHELL="$(which bash)" bash -
WORKDIR /app
# The dependencies first, so a change to the code alone reuses this layer.
# It needs every workspace package's manifest: a new package needs a line.
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY packages/aragon-ods-fork/package.json packages/aragon-ods-fork/
COPY packages/drill-report/package.json packages/drill-report/
COPY packages/ui/package.json packages/ui/
RUN pnpm install --frozen-lockfile
COPY . .
# Optional, see packages/ui/.env.example. The build inlines them, so they
# are build arguments; at runtime they change nothing.
ARG NEXT_PUBLIC_GOVERNANCE_NETWORK
ARG NEXT_PUBLIC_RPC_URL
ARG NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID
RUN pnpm --filter dao-ui build

# Serve: the static export in packages/ui/out, and nothing else.
FROM nginx:1.29-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/packages/ui/out /usr/share/nginx/html
EXPOSE 80
