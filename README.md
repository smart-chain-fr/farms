# SMAK_Farming
### *The farming tool for Vortex, the Smartlink DEX !*

![Vortex logo](https://gateway.pinata.cloud/ipfs/QmSMzh5JEuPgPNHns9Svk25aPwQn2NtR1TFkd7n3mj2Ktp)



## Summary

##### I. Install the tools

##### II. Tests and compilation

##### III. Deployment

---

## I. Install the tools

#### I. 1) Install LIGO

OpenTezos offers great documentation so we will use it as a reference:
https://opentezos.com/ligo/installation

- You may simply execute LIGO through Docker to run the ligo CLI : 
`docker run --rm -v "$PWD":"$PWD" -w "$PWD" ligolang/ligo:0.30.0 [command without "ligo"]`

_Example:_
- To compile a smart-contract, you may use: 
`docker run --rm -v "$PWD":"$PWD" -w "$PWD" ligolang/ligo:0.30.0 compile contract [args]`

The list of ligo CLI is available on LIGOland:
https://ligolang.org/docs/api/cli-commands/

#### I. 2) Install Node
Node 14 or higher is required to run the originate function.

###### Install node on MAC
- Go to https://nodejs.org/en/download/ and choose "macOS Installer".
Follow the instructions on the wizard.
Once it is complete, to check that the installation was successful :
- run `node -v`
- run `npm -v`


###### Install node on Linux
- Open your terminal, and run:
sudo apt update
sudo apt install nodejs npm
Once it is complete, to check that the installation was successful, run:
- run `node -v`
- run `npm -v`

#### I.3) Install Taquito

_cf._ https://opentezos.com/dapp/taquito

#### I.4) Install Python

- You may download from Python (https://wiki.python.org/moin/BeginnersGuide/Download) or install it from the CLI.
- You may use python3.

#### I.5) Install Pytezos

_cf._ https://pypi.org/project/pytezos/


---

## II. Compilation and tests

#### II.1) Compilation of the Farm smart contract 

- At root, with the last LIGO version run `ligo compile contract src/contract/farm/main.mligo > src/contract/test/compiled/farm.tz`
- OR with docker run `docker run --rm -v "$PWD":"$PWD" -w "$PWD" ligolang/ligo:0.30.0 compile contract src/contract/farm/main.mligo -e main > src/contract/test/compiled/farm.tz`

#### II.2) Compilation of the Database smart contract

- At root, with the latest LIGO version run `ligo compile contract src/contract/database/main.mligo > src/contract/test/compiled/database.tz`
- OR with docker run `docker run --rm -v "$PWD":"$PWD" -w "$PWD" ligolang/ligo:0.30.0 compile contract src/contract/database/main.mligo -e main > src/contract/test/compiled/database.tz`


#### II.3) Tests

- In the contract/test/ repository, run `pytest [-k "filename"] [-s]`
- OR If you want to have more verbose run `python3 -m unittest test_farm.py -v` for Farm tests or `python3 -m unittest test_database.py -v` for Database tests
- OR If you want to run a specific test, run `python3 -m unittest test_farm.py -v -k 'test_initializeReward_5week_20Kreward_75rate_initialization_should_work'`


#### II.4) Simulate of the Database smart contract


- compile empty storage  `docker run --rm -v "$PWD":"$PWD" -w "$PWD" ligolang/ligo:0.30.0 compile storage src/contract/database/main.mligo  '{admin=("tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5":address); all_farms=(Set.empty: address set); all_farms_data=(Big_map.empty: (address, farm_metadata) big_map); inverse_farms=(Big_map.empty : (address, (address, string) map) big_map) }' -e main`

- compile storage (containing a farm)  `docker run --rm -v "$PWD":"$PWD" -w "$PWD" ligolang/ligo:0.30.0 compile storage src/contract/database/main.mligo  '{admin=("tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5":address); all_farms=(Set.add ("KT1UxQFSXmhMG18fcoD9J5UzADEZwVshjQkM":address) Set.empty); all_farms_data=Big_map.literal[(("KT1UxQFSXmhMG18fcoD9J5UzADEZwVshjQkM":address), {lp_address=("KT1CBGs21NgGZXymSKNW9MCxzopq9HpRHsh2":address); farm_lp_info="info"})]; inverse_farms=Big_map.literal[(("KT1CBGs21NgGZXymSKNW9MCxzopq9HpRHsh2":address), Map.literal[(("KT1UxQFSXmhMG18fcoD9J5UzADEZwVshjQkM":address), "info")])] }' -e main`

- compile Remove_farm entrypoint  `docker run --rm -v "$PWD":"$PWD" -w "$PWD" ligolang/ligo:0.30.0 compile parameter src/contract/database/main.mligo 'Remove_farm({farm_address=("KT1UxQFSXmhMG18fcoD9J5UzADEZwVshjQkM":address); lp_address=("KT1CBGs21NgGZXymSKNW9MCxzopq9HpRHsh2":address)})' -e main`


- dry-run Remove_farm entrypoint `docker run --rm -v "$PWD":"$PWD" -w "$PWD" ligolang/ligo:0.30.0 dry-run --sender=tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5 src/contract/database/main.mligo main 'Remove_farm({farm_address=("KT1UxQFSXmhMG18fcoD9J5UzADEZwVshjQkM":address)})' '{admin=("tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5":address); all_farms=(Set.add ("KT1UxQFSXmhMG18fcoD9J5UzADEZwVshjQkM":address) Set.empty); all_farms_data=Big_map.literal[(("KT1UxQFSXmhMG18fcoD9J5UzADEZwVshjQkM":address), {lp_address=("KT1CBGs21NgGZXymSKNW9MCxzopq9HpRHsh2":address); farm_lp_info="info"})]; inverse_farms=Big_map.literal[(("KT1CBGs21NgGZXymSKNW9MCxzopq9HpRHsh2":address), Map.literal[(("KT1UxQFSXmhMG18fcoD9J5UzADEZwVshjQkM":address), "info")])] }'`


- dry-run Remove_farm entrypoint (with incomplete inverse_map) `docker run --rm -v "$PWD":"$PWD" -w "$PWD" ligolang/ligo:0.30.0 dry-run --sender=tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5 src/contract/database/main.mligo main 'Remove_farm({farm_address=("KT1UxQFSXmhMG18fcoD9J5UzADEZwVshjQkM":address)})' '{admin=("tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5":address); all_farms=(Set.add ("KT1UxQFSXmhMG18fcoD9J5UzADEZwVshjQkM":address) Set.empty); all_farms_data=Big_map.literal[(("KT1UxQFSXmhMG18fcoD9J5UzADEZwVshjQkM":address), {lp_address=("KT1CBGs21NgGZXymSKNW9MCxzopq9HpRHsh2":address); farm_lp_info="info"})]; inverse_farms=(Big_map.empty : (address, (address, string) map) big_map)  }'`

- dry-run change admin 
```
docker run --rm -v "$PWD":"$PWD" -w "$PWD" ligolang/ligo:0.30.0 dry-run --sender=tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5 src/contract/database/main.mligo main 'Change_admin({new_admin=("tz1Tr5mdFTtGZp9p2KUuWXxJHB6HSAZBj15u":address)})' '{admin=("tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5":address); all_farms=(Set.add ("KT1UxQFSXmhMG18fcoD9J5UzADEZwVshjQkM":address) Set.empty); all_farms_data=Big_map.literal[(("KT1UxQFSXmhMG18fcoD9J5UzADEZwVshjQkM":address), {lp_address=("KT1CBGs21NgGZXymSKNW9MCxzopq9HpRHsh2":address); farm_lp_info="info"})]; inverse_farms=(Big_map.empty : (address, (address, string) map) big_map)  }'
```

```
docker run --rm -v "$PWD":"$PWD" -w "$PWD" ligolang/ligo:0.30.0 dry-run --sender=tz1Tr5mdFTtGZp9p2KUuWXxJHB6HSAZBj15u src/contract/database/main.mligo main 'Change_admin({new_admin=("tz1Tr5mdFTtGZp9p2KUuWXxJHB6HSAZBj15u":address)})' '{admin=("tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5":address); all_farms=(Set.add ("KT1UxQFSXmhMG18fcoD9J5UzADEZwVshjQkM":address) Set.empty); all_farms_data=Big_map.literal[(("KT1UxQFSXmhMG18fcoD9J5UzADEZwVshjQkM":address), {lp_address=("KT1CBGs21NgGZXymSKNW9MCxzopq9HpRHsh2":address); farm_lp_info="info"})]; inverse_farms=(Big_map.empty : (address, (address, string) map) big_map)  }'
```

---

## III. Deployment

#### III.1) Initialisation

* Create the database initial storage artefact : at root, run `docker run --rm -v "$PWD":"$PWD" -w "$PWD" ligolang/ligo:0.30.0 compile contract src/contract/database/main.mligo --michelson-format json > deploy/artefact/database.json`

* Create the farm initial storage artefact : at root, run `docker run --rm -v "$PWD":"$PWD" -w "$PWD" ligolang/ligo:0.30.0 compile contract src/contract/farm/main.mligo --michelson-format json > deploy/artefact/farm.json`

* Install dependencies, go to the /deploy folder and run `npm install`

#### III.2) Update environment variables

Adapt your .env file in the /deploy folder:

PK=[private key]

ADMIN=[admin address]

SMAK=[SMAK token contract address]

RPC=[network]

FARMSDB=[Farms contract address]

LP=[LP token address]

INFOFARM=[name of the LP pair]

RATE=[decreasing rate x10000]

REWARDS=[number of SMAK tokens as rewards for the entire farm lifetime]

WEEKS=[length of the farm lifetime]

#### III.3) Deploy the smart-contracts and the database

- In the folder /deploy, run `tsc deploy.ts --resolveJsonModule -esModuleInterop`

- Be sure to compile your database and farm, following  III.1 and  III.2 The database contract reference all farm pools and is only needed to be generated once at the start of the project.

- In the folder /deploy, run `node deploy_database.js`.

#### III.4) Originate a farm pool

- In the folder /deploy, run `node deploy_farm.js`. ( check again your environment variables )

It will:
* originate a new farm contract with the storage in the .ts file
* call the entrypoint increaseReward (with 0 as argument)
* approve the newly created farm smart-contract to spend SMAK for the amount in total_reward (will allow to transfer some SMAK tokens to the claiming users)
* call the entrypoint addFarm in the FARMS contract to register the newly created farm

## IV. Staking

The front-end will call the entry point approve on the LP token contract in order to allow the farm contract to use LP tokens owned by the user.

[//]: # "https://i.ibb.co/1XdhScd/Smartlink-Farm-dark.png"
![Staking schema - night mode](https://i.ibb.co/zP9Rxtg/Smartlink-Farm-light.png)
###### Staking mechanism schema