import { InMemorySigner } from '@taquito/signer';
import { TezosToolkit, MichelsonMap } from '@taquito/taquito';
import fa2 from './artefact/fa2.json';
import * as dotenv from 'dotenv'

dotenv.config(({path:__dirname+'/.env'}))

const rpc = process.env.RPC; //"http://127.0.0.1:8732" //"https://hangzhounet.api.tez.ie/" //"https://127.0.0.1:8732" //"https://rpc.tzkt.io/granadanet/" //"https://granadanet.smartpy.io/"
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
const operator_address = "KT1MRRhLYf3A2eJiZsDkT3FL8GjTeMNSazyQ";
const reward_fa2_contract = process.env.REWARD_CONTRACT_ADDRESS; //"KT1CVLPrSkgzHhSWaaBSvWLGp2fce1iY3wnP";

async function approve() {

    try {

        const op2 = await (await Tezos.contract.at(reward_fa2_contract)).methods.update_operators([{add_operator: {owner:admin, operator: operator_address, token_id:reward_fa2_token_id}}]).send();
        console.log(`Waiting for update_operators ${op2.hash} to be confirmed...`);
        await op2.confirmation(3);
        console.log('confirmed update_operators: ', op2.hash);

    } catch (error: any) {
        console.log(error)
    }
}


approve();
