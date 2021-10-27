# SMAK_Farming
### *The farming tool for Vortex, the Smartlink DEX !*

![Vortex logo](https://gateway.pinata.cloud/ipfs/QmSMzh5JEuPgPNHns9Svk25aPwQn2NtR1TFkd7n3mj2Ktp)



## Summary

###### I. Install the tools

###### II. Tests and compilation

###### III. Deployment



## I. Install the tools

#### I. 1) Install LIGO

OpenTezos offers great documentation so we will use it as a reference:
https://opentezos.com/ligo/installation

_You may simply execute LIGO through Docker to run the ligo CLI:_
`docker run --rm -v "$PWD":"$PWD" -w "$PWD" ligolang/ligo:0.27.0 [command without "ligo"]`

_Example:_
_To compile a smart-contract, you may use:_
`docker run --rm -v "$PWD":"$PWD" -w "$PWD" ligolang/ligo:0.27.0 compile contract [args]`

The list of ligo CLI is available on LIGOland:
https://ligolang.org/docs/api/cli-commands/

#### I. 2) Install Node
Node 14 or higher is required to run the originate function.

###### Install node on MAC
Go to https://nodejs.org/en/download/ and choose "macOS Installer".
Follow the instructions on the wizard.
Once it is complete, to check that the installation was successful, run:
`node -v`
`npm -v`

###### Install node on Linux
Open your terminal, and run:
sudo apt update
sudo apt install nodejs npm
Once it is complete, to check that the installation was successful, run:
`node -v`
`npm -v`

#### I.3) Install Taquito

_cf._ https://opentezos.com/dapp/taquito

#### I.4) Install Python

You may download from Python (https://wiki.python.org/moin/BeginnersGuide/Download) or install it from the CLI.
You may use python3.

#### I.5) Install Pytezos

_cf._ https://pypi.org/project/pytezos/



## II. Compilation and tests

#### II.1) Compilation du smart contract Farm

Run `ligo compile contract contract/main/main.mligo > contract/test/Farm.tz`
OR
docker run --rm -v "$PWD":"$PWD" -w "$PWD" ligolang/ligo:0.27.0 compile contract contract/main/main.mligo -e main > contract/test/Farm.tz

#### II.2) Compilation du smart contract Farms

Run `ligo compile contract contract/main/farms.mligo > contract/test/Farms.tz`
OR
docker run --rm -v "$PWD":"$PWD" -w "$PWD" ligolang/ligo:0.27.0 compile contract contract/main/farms.mligo -e main > contract/test/Farms.tz


#### II.2) Tests

In the contract/test/ repository, run `pytest [-k "filename"] [-s]`


## III. Deployment

#### III.1) Originate Smart Contract Farm

a) Go to the /deploy folder
`cd deploy`

b) Install dependencies
Run `npm install`

c) Run `docker run --rm -v "$PWD":"$PWD" -w "$PWD" ligolang/ligo:0.27.0 compile contract contract/main/main.mligo --michelson-format json > deploy/ressources/Farm.json`

d) Run `chmod +x deploy.sh && ./deploy.sh` or `bash deploy.sh`

#### III.2) Allow transfers on FA12 contracts (SMAK contract, LP contract) 

e) Call "approve" entrypoint on LP contract (Allow the Farm contract to use LP tokens owned by the user)

f) approve on SMAK contract (allow to transfer some SMAK token to the claiming user)

#### III.3) Compute rewards for the smart contract Farm

g) Execute the IncreaseReward entrypoint (with 0 as argument)

#### III.4) Originate Smart Contract Farms (if not already deployed)

h) deploy Farms

#### III.5) Add the new Farm contract into the Farms referentiel

i) Execute entrypoint AddFarm (with following arguments)
- Farms contract address
- LP contract address
- string info "SMAK-XTZ"

![Staking schema](https://i.ibb.co/PQmf81L/Farm-staking-1-light.png)
![Staking schema - night mode](https://i.ibb.co/QbXzjWM/Farm-staking-1.png)
