import { InMemorySigner } from '@taquito/signer';
import { TezosToolkit, MichelsonMap } from '@taquito/taquito';
import fa12 from './artefact/fa12.json';
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
//const reward_fa2_token_id = process.env.REWARD_TOKEN_ID;
const farmAddress = process.env.FARM_ADDRESS; //"KT1MRRhLYf3A2eJiZsDkT3FL8GjTeMNSazyQ";
const reward_fa12_contract = process.env.REWARD_CONTRACT_ADDRESS; //"KT1CVLPrSkgzHhSWaaBSvWLGp2fce1iY3wnP";
const rewards = process.env.REWARD_AMOUNT;

async function approve() {

    try {

        const op2 = await (await Tezos.contract.at(reward_fa12_contract)).methods.approve(farmAddress, rewards).send();
        console.log(`Waiting for approve ${op2.hash} to be confirmed...`);
        await op2.confirmation(3);
        console.log('confirmed approve: ', op2.hash);

    } catch (error: any) {
        console.log(error)
    }
}


approve();
