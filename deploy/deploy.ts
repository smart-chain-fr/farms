import { InMemorySigner } from '@taquito/signer';
import { TezosToolkit, MichelsonMap } from '@taquito/taquito';
import farm from './ressources/Farm.json';
import * as dotenv from 'dotenv'

dotenv.config(({path:__dirname+'/.env'}))

const rpc = process.env.RPC || "http://127.0.0.1:20000/"
const pk: string = process.env.SAND_PK || "edsk3QoqBuvdamxouPhin7swCvkQNgq4jP5KZPbwWNnwdZpSpJiEbq";
const Tezos = new TezosToolkit(rpc);
const signer = new InMemorySigner(pk);
Tezos.setProvider({ signer: signer })

const farms = process.env.FARMSDB || ""
const admin = process.env.SAND_ADMIN || "tz1VSUr8wwNhLAzempoch5d6hLRiTh8Cjcjb";
const creation_time = new Date();
let farm_points = new MichelsonMap();
const lp = 'KT1J4keEr6okoYToyN47MpgE6pgiwfoDmf23';
const infoFarm = 'test SMAK-XTZ';
const rate = 7500;
let reward_at_week = new MichelsonMap();
const smak = process.env.SMAK || lp;
const rewards = 2500002;
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
    console.log(`Waiting for farm ${originated.contractAddress} to be confirmed...`);
    await originated.confirmation(2);
    console.log('confirmed farm: ', originated.contractAddress);

    const farmAddress : string = originated.contractAddress as string
    const op = await (await Tezos.contract.at(farmAddress)).methods.increaseReward(0).send();
        console.log(`Waiting for increaseReward(0) ${op.hash} to be confirmed...`);
        await op.confirmation(3);
        console.log('confirmed increaseReward(0): ', op.hash);

    if (smak !== lp) {
        const op2 = await (await Tezos.contract.at(smak)).methods.approve(farmAddress, rewards).send();
        console.log(`Waiting for approve ${op2.hash} to be confirmed...`);
        await op2.confirmation(3);
        console.log('confirmed approve: ', op2.hash);
    }

    if (farms !== "") {
        const op3 = await (await Tezos.contract.at(farms)).methods.addFarm(farmAddress, infoFarm, lp).send();
        console.log(`Waiting for addFarm ${op3.hash} to be confirmed...`);
        await op3.confirmation(3);
        console.log('confirmed addFarm: ', op3.hash)
    }
}

orig();
