import { InMemorySigner } from '@taquito/signer';
import { TezosToolkit, MichelsonMap } from '@taquito/taquito';
import farm from './ressources/Farm.json';
import dotenv from 'dotenv'

dotenv.config(({path:__dirname+'/.env'}))

const rpc = process.env.RPC || "http://127.0.0.1:20000/"
const pk: string = process.env.SAND_PK || "edsk3QoqBuvdamxouPhin7swCvkQNgq4jP5KZPbwWNnwdZpSpJiEbq";
const Tezos = new TezosToolkit(rpc);
const signer = new InMemorySigner(pk);
Tezos.setProvider({ signer: signer })

const farms = process.env.FARMS || ""

const admin = process.env.SAND_ADMIN || "tz1VSUr8wwNhLAzempoch5d6hLRiTh8Cjcjb";
const creation_time = new Date();
let farm_points = new MichelsonMap();
const lp = 'KT1W12FCPyUC79RGfWXTvnTKBtPBLraoDcqM';
const rate = 7500;
let reward_at_week = new MichelsonMap();
const smak = process.env.SMAK || lp;
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
    if (smak !== lp) {
        const op = await (await Tezos.contract.at(smak)).methods.approve(originated.contractAddress, rewards ).send();
        console.log(`Waiting for ${op.hash} to be confirmed...`);
        await op.confirmation(3);
        console.log('confirmed: ', op.hash);
    }

    if (farms !== "") {
        const params = {
            'farm_address': originated.contractAddress,
            'lp_address': lp,
            'farm_lp_info': 'SMAK-XTZ'
        }
        const op2 = await (await Tezos.contract.at(farms)).methods.AddFarm(params).send();
        console.log(op2.hash)
    }
}


orig();
