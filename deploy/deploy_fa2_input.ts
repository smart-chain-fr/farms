import { InMemorySigner } from '@taquito/signer';
import { TezosToolkit, MichelsonMap } from '@taquito/taquito';
import fa2 from './artefact/fa2.json';
import * as dotenv from 'dotenv'

dotenv.config(({path:__dirname+'/.env'}))

const rpc = "http://127.0.0.1:8732" //"https://hangzhounet.api.tez.ie/" //"https://127.0.0.1:8732" //"https://rpc.tzkt.io/granadanet/" //"https://granadanet.smartpy.io/"
const pk: string = "edskRuatoqjfYJ2iY6cMKtYakCECcL537iM7U21Mz4ieW3J51L9AZcHaxziWPZSEq4A8hu5e5eJzvzTY1SdwKNF8Pkpg5M6Xev";
const Tezos = new TezosToolkit(rpc);
const signer = new InMemorySigner(pk);
Tezos.setProvider({ signer: signer })


let paused = false
let ledger = new MichelsonMap();
const operators_init = [];
const admin = "tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5"
let token_metadata = new MichelsonMap();
const input_fa2_token_id = 1;
const input_reserve_address = "tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5";
const mint_amount = 100;
ledger.set({0:input_reserve_address, 1:input_fa2_token_id}, mint_amount);

async function orig() {

    const store = {
        'paused' : paused,
        'ledger' : ledger,
        //'tokens' : token_metadata,
        'operators' : operators_init,
        'administrator' : admin
    }

    try {
        const originated = await Tezos.contract.originate({
            code: fa2,
            storage: store,
        })
        console.log(`Waiting for farm ${originated.contractAddress} to be confirmed...`);
        await originated.confirmation(2);
        console.log('confirmed fa2: ', originated.contractAddress);

    } catch (error: any) {
        console.log(error)
    }
}


orig();
