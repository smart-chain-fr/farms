import { InMemorySigner } from '@taquito/signer';
import { TezosToolkit, MichelsonMap } from '@taquito/taquito';
import farm from './ressources/Farm.json';
import dotenv from 'dotenv'

dotenv.config(({path:__dirname+'/.env'}))

const Tezos = new TezosToolkit('https://granadanet.api.tez.ie/');
const pk: string = process.env.PK || "";
const signer = new InMemorySigner(pk);
Tezos.setProvider({ signer: signer })

const admin = process.env.ADMIN || "";
const creation_time = new Date();
let farm_points = new MichelsonMap();
const lp = 'KT1W12FCPyUC79RGfWXTvnTKBtPBLraoDcqM';
const rate = 7500;
let reward_at_week = new MichelsonMap();
const smak = "KT1XtQeSap9wvJGY1Lmek84NU6PK6cjzC9Qd";
const rewards = 2500000;
let user_points = new MichelsonMap();
let user_stakes = new MichelsonMap();
const weeks = 5;

async function orig() {

    // for (let i = 0; i < weeks + 1; i++) {
    //     farm_points[i] = 0
    // }
    const store = {
        'admin': admin,
        'creation_time': creation_time,
        'farm_points': farm_points,
        'lp_token_address': lp,
        'rate': rate,
        'reserve_address': admin,
        'reward_at_week': reward_at_week,
        'smak_address': smak,
        'total_reward': rewards,
        'user_points': user_points,
        'user_stakes': user_stakes,
        'weeks': weeks,
    }
    const originated = await Tezos.contract.originate({
        code: farm,
        storage: store,
    })
    console.log(`Waiting for ${originated.contractAddress} to be confirmed...`);
    await originated.confirmation(2);
    console.log('confirmed: ', originated.contractAddress);
    const op = await (await Tezos.contract.at(smak)).methods.approve(originated.contractAddress, rewards ).send();
    console.log(`Waiting for ${op.hash} to be confirmed...`);
    await op.confirmation(3);
    console.log('confirmed: ', op.hash);
}
 

orig();
