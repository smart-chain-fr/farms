import { InMemorySigner } from '@taquito/signer';
import { TezosToolkit, MichelsonMap } from '@taquito/taquito';
import database from './artefact/database.json';
import * as dotenv from 'dotenv'

dotenv.config(({path:__dirname+'/.env'}))

const rpc = "http://127.0.0.1:8732"
const pk: string = "edskRuatoqjfYJ2iY6cMKtYakCECcL537iM7U21Mz4ieW3J51L9AZcHaxziWPZSEq4A8hu5e5eJzvzTY1SdwKNF8Pkpg5M6Xev";
const Tezos = new TezosToolkit(rpc);
const signer = new InMemorySigner(pk);
Tezos.setProvider({ signer: signer })

const admin = "tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5";
let all_farms = new Array();
let all_farms_data = new MichelsonMap();
let inverse_farms = new MichelsonMap();

async function orig() {

    const store = {
        'admin': admin,
        'all_farms': all_farms,
        'all_farms_data': all_farms_data,
        'inverse_farms': inverse_farms
    }
    const originated = await Tezos.contract.originate({
        code: database,
        storage: store,
    })
    console.log(`Waiting for farm ${originated.contractAddress} to be confirmed...`);
    await originated.confirmation(2);
    console.log("FARMS=", originated.contractAddress);
}


orig();
