# CLAUDE.md

Guidance for Claude Code in this repository.

## What this is

The veTRUST governance site for Intuition. It lists proposals straight from the chain over the public RPC, and lets veTRUST holders veto, execute and create proposals, and wrap and lock TRUST. There is no indexer, subgraph, database or backend.

## Toolchain

- pnpm 11.21.0 (`packageManager` in `package.json`) and Node 26 (`.nvmrc`). Never npm, yarn or bun.
- One lockfile: `pnpm-lock.yaml` at the root. CI rejects any other.
- Install scripts run only for the packages listed in `allowBuilds` in `pnpm-workspace.yaml`. A new dependency with an install script needs an entry there, or `pnpm install` fails.

## Packages

- `packages/ui` (`dao-ui`): the site. Next.js 15, pages router, static export.
- `packages/aragon-ods-fork` (`@aragon/ods`): the component library the site imports through `workspace:*`. Its `dist/` is committed: rebuild it with `pnpm --filter @aragon/ods build` after changing its source.
- `packages/drill-report`: a separate SvelteKit app. The site does not use it.

## Commands

```bash
pnpm install --frozen-lockfile
pnpm --filter dao-ui dev          # dev server
pnpm --filter dao-ui build        # static export in packages/ui/out
pnpm --filter dao-ui lint
pnpm --filter dao-ui type-check
pnpm --filter dao-ui test         # vitest
```

CI (`.github/workflows/dao-ui.yml`) runs lint, type-check, test and build.

## Where the code is

Every route renders the governance interface in `packages/ui/src/governance`:

| Route | Module |
| --- | --- |
| `/` and `/plugins/community-proposals/` | `screen.tsx`, the proposals; `?proposal=<id>` opens one |
| `/proposals/new/` | `create.tsx` |
| `/setup/` | `setup.tsx`, wrap and lock TRUST |

- `deployment.ts` pins the mainnet (1155) and testnet (13579) contracts. `NEXT_PUBLIC_GOVERNANCE_NETWORK=testnet` picks testnet at build time.
- `rpc.ts` reads the chain with viem and batches reads through Multicall3.
- `storage.ts` keeps imported transactions in `localStorage`, per chain, DAO and plugin.
- The governance tests are in `src/governance/__tests__`.

Legacy template modules (`src/plugins` and the code it uses) remain in the tree. No route uses them.

## Build and hosting

- `next.config.js` sets `output: "export"` and `trailingSlash: true`, so every route is a folder with an `index.html`. There is no server: `next start` does not work.
- The build ID is the git commit, so the same commit builds the same files. Releases go to IPFS, as the README describes.
- The `Dockerfile` builds the export and serves it with nginx on port 80. `nginx.conf` sets the redirects, cache rules and security headers. A new workspace package needs its `package.json` copied in the Dockerfile's dependency layer.
- A dynamic route must list its pages in `getStaticPaths` with `fallback: false`, as `pages/plugins/[id].tsx` does.

## Configuration

All optional, and inlined into the public JavaScript at build time, so never a secret: `NEXT_PUBLIC_GOVERNANCE_NETWORK`, `NEXT_PUBLIC_RPC_URL` and `NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID`. See `packages/ui/.env.example`.
