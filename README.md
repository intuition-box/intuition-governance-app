# Intuition governance UI

The veTRUST governance site for Intuition. It lists proposals straight from the chain, shows their veto window and state, and lets veTRUST holders veto, execute and create proposals, and wrap and lock TRUST. Everything is read directly over the public RPC. No indexer, subgraph, database, pinning credential or application backend is needed.

## Live site

The site runs at https://gov.intuition.box/, built from `main`.

Releases are also published on IPFS as static builds. Open one through a subdomain gateway:

https://bafybeih4kwjo23lgpxyevvabgymzjpgebslh7vibgn5p4hpespthodypnq.ipfs.dweb.link/

Use only the subdomain form (`https://<cid>.ipfs.dweb.link/`). Path gateways such as `ipfs.io/ipfs/<cid>` put every IPFS site on one shared origin.

### Releases

| Date       | CID                                                           | Commit    | Network                  |
| ---------- | ------------------------------------------------------------- | --------- | ------------------------ |
| 2026-11-13 | `bafybeih4kwjo23lgpxyevvabgymzjpgebslh7vibgn5p4hpespthodypnq` | `657e82b` | Intuition mainnet (1155) |

Each release has a new CID. Imported transaction history is stored per site origin, so it starts empty on each release.

## Develop

With pnpm 11.21.0 and Node 26, as `package.json` and `.nvmrc` pin them:

```sh
pnpm install --frozen-lockfile
pnpm --filter dao-ui dev
```

Builds target Intuition mainnet (chain 1155). Set `NEXT_PUBLIC_GOVERNANCE_NETWORK=testnet` for the testnet deployment (chain 13579). On testnet, **Import testnet fixtures** loads the deployed sample proposals in executed, vetoed, active and executable states. Importing only reads chain data; veto and execution need a connected wallet on the same network and an explicit confirmation.

**Setup & lock TRUST** (`/setup`) shows the configured contracts, including MultiVault and TrustBonding, and guides a funded wallet through wrapping TRUST, approving the amount and locking it. Existing locks can receive additions; expired locks can be withdrawn as wrapped TRUST.

The public RPC works without an environment file. Optional overrides are documented in `packages/ui/.env.example`. WalletConnect requires a project ID; an injected wallet does not.

## Build and verify a release

The build is reproducible: the build ID comes from the git commit, so the same commit produces the same files and the same CID.

```sh
cd packages/ui
pnpm build                                           # static export in packages/ui/out
npx -y ipfs-car@3.1.0 pack out --output site.car     # prints the root CID
```

To verify a release, check out its commit, run these two commands, and compare the printed CID with the table above. Publishing uploads the CAR file to an IPFS pinning service, which pins that exact CID.

## Host as a container

The `Dockerfile` builds the static export and serves it with nginx on port 80. Build it from the repository root. The optional `NEXT_PUBLIC_*` values in `packages/ui/.env.example` are build arguments, because the build inlines them. Like a release, the image takes its build ID from the commit, so a page's source names the commit it was built from.

## More

See [testnet setup, deployment provenance and limitations](docs/governance/testnet.md), the [RPC-first MVP specification](docs/governance/rpc-mvp.md), and the [Linear milestone plan](docs/governance/project-plan.md).

This monorepo derives from [Aragon's Taiko UI](https://github.com/aragon/taiko-ui), with a customized `aragon-ods-fork` component package and the application in `packages/ui`. Legacy template modules remain in the source tree; the active routes use the governance interface in `packages/ui/src/governance`.
