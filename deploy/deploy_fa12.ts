import { InMemorySigner } from '@taquito/signer';
import { TezosToolkit, MichelsonMap } from '@taquito/taquito';
import fa12 from './artefact/fa12.json';
import * as dotenv from 'dotenv'

dotenv.config(({path:__dirname+'/.env'}))

const rpc = "https://granadanet.smartpy.io/"
const pk: string = "edskRuatoqjfYJ2iY6cMKtYakCECcL537iM7U21Mz4ieW3J51L9AZcHaxziWPZSEq4A8hu5e5eJzvzTY1SdwKNF8Pkpg5M6Xev";
const Tezos = new TezosToolkit(rpc);
const signer = new InMemorySigner(pk);
Tezos.setProvider({ signer: signer })


let tokens = new MichelsonMap();
let allowances = new MichelsonMap();
const admin = "tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5"
const total_supply = 20000
let metadata = new MichelsonMap();
let token_metadata = new MichelsonMap();

async function orig() {

    // for (let i = 0; i < weeks + 1; i++) {
    //     farm_points[i] = 0
    // }

    const store = {
        'tokens' : tokens,
        'allowances' : allowances,
        'admin' : admin,
        'total_supply' : total_supply,
        'metadata' : metadata,
        'token_metadata' : token_metadata
    }

    try {
        const originated = await Tezos.contract.originate({
            code: fa12,
            storage: store,
        })
        console.log(`Waiting for farm ${originated.contractAddress} to be confirmed...`);
        await originated.confirmation(2);
        console.log('confirmed fa12: ', originated.contractAddress);

    } catch (error: any) {
        console.log(error)
    }
}

orig();
