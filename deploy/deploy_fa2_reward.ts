import { InMemorySigner } from '@taquito/signer';
import { TezosToolkit, MichelsonMap } from '@taquito/taquito';
import fa2 from './artefact/fa2.json';
import * as dotenv from 'dotenv'

dotenv.config(({path:__dirname+'/.env'}))

const rpc: string = process.env.RPC?.toString() || ""; //"http://127.0.0.1:8732" //"https://hangzhounet.api.tez.ie/" //"https://127.0.0.1:8732" //"https://rpc.tzkt.io/granadanet/" //"https://granadanet.smartpy.io/"
const pk: string = "edskRuatoqjfYJ2iY6cMKtYakCECcL537iM7U21Mz4ieW3J51L9AZcHaxziWPZSEq4A8hu5e5eJzvzTY1SdwKNF8Pkpg5M6Xev";
const Tezos = new TezosToolkit(rpc);
const signer = new InMemorySigner(pk);
Tezos.setProvider({ signer: signer })

let paused = false
let ledger = new MichelsonMap();
const operators_init = [];
const admin = process.env.ADMIN_ADDRESS; //"tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5"
let token_metadata = new MichelsonMap();
const reward_fa2_token_id = process.env.REWARD_TOKEN_ID;
const mint_amount = process.env.REWARD_AMOUNT;
const reward_reserve_address = process.env.REWARD_RESERVE_ADDRESS;
ledger.set({0:reward_reserve_address, 1:reward_fa2_token_id}, mint_amount);

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
        console.log(`Waiting for fa2 contract ${originated.contractAddress} to be confirmed...`);
        await originated.confirmation(2);
        console.log('confirmed fa2: ', originated.contractAddress);


    } catch (error: any) {
        console.log(error)
    }
}


orig();
