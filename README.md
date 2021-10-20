# SMAK_Farming
### *The farming tool for Vortex, the Smartlink DEX !*

![Vortex logo](https://gateway.pinata.cloud/ipfs/QmSMzh5JEuPgPNHns9Svk25aPwQn2NtR1TFkd7n3mj2Ktp)

#### Run and compile test files with Docker
1. Run `docker run --rm -v "$PWD":"$PWD" -w "$PWD" ligolang/ligo:0.26.0 compile-contract main/main.ligo main > main/compiled/Farms.tz`
2. In the test repository, run `pytest [-k "filename"] [-s]` (in option to display console logs)

#### CLI on Granada Testnet (testing / in progress)
Reference: https://tezos.gitlab.io/active/cli-commands.html

* Approval request:
from fa1.2 contract [FA1.2 contract address] as [Admin address] approve 20000 from [Farms.tz contract address]

* get contract entrypoints for [Farms.tz]

* get contract entrypoint type of [entrypoint] for [Farms.tz]

#### Originate Smart Contracts
1. Run "tsc deploy/deploy.ts"
2. Run "node deploy.js"
#### Originate Smart Contracts
1. In deploy folder, run `tsc deploy.ts`
2. Run `node deploy.js`

#### [In progress]
1. In deploy folder, run `npm run storage` to generate the storage.json file in correct format.
