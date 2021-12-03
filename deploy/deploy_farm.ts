import { InMemorySigner } from '@taquito/signer';
import { TezosToolkit, MichelsonMap } from '@taquito/taquito';
import farm from './artefact/farm.json';
import * as dotenv from 'dotenv'

dotenv.config(({path:__dirname+'/.env'}))

const rpc = "https://granadanet.smartpy.io/"
const pk: string = "edskRuatoqjfYJ2iY6cMKtYakCECcL537iM7U21Mz4ieW3J51L9AZcHaxziWPZSEq4A8hu5e5eJzvzTY1SdwKNF8Pkpg5M6Xev";
const Tezos = new TezosToolkit(rpc);
const signer = new InMemorySigner(pk);
Tezos.setProvider({ signer: signer })

const database = "KT1UUUiSjdiEHwtigYz2YgFAMfNPd8BJAVe4";
const admin = "tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5";
const creation_time = new Date();
const farm_points: [] = [];
const input_token_address = 'KT1J7AAzfgdVXSLkRiGVkjXCwWUG9rjJzN2Y';
const reward_token_address = "KT19LLvFdGmLgKPXqf4Tn22Y1wWqpCU1sg2d"
const reward_reserve_address = "tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5";
const infoFarm = process.env.INFOFARM || '';
const rate = process.env.RATE || 9500;
let reward_at_week: [] = [];
const rewards = 50000000;
let user_points = new MichelsonMap();
let user_stakes = new MichelsonMap();
const total_weeks = 5;


async function orig() {

    const store = {
        'admin': admin,
        'creation_time': creation_time,
        'farm_points': farm_points,
        'input_token_address': input_token_address,
        'reward_token_address': reward_token_address,
        'reward_reserve_address': reward_reserve_address,
        'rate': rate,
        'reward_at_week': reward_at_week,
        'total_reward': rewards,
        'user_points': user_points,
        'user_stakes': user_stakes,
        'total_weeks': total_weeks,
    }
    try {
        const originated = await Tezos.contract.originate({
            code: farm,
            storage: store,
        })
        console.log(`Waiting for farm ${originated.contractAddress} to be confirmed...`);
        await originated.confirmation(2);
        console.log('confirmed farm: ', originated.contractAddress);

        const farmAddress : string = originated.contractAddress as string
        const op = await (await Tezos.contract.at(farmAddress)).methods.initialize().send();
            console.log(`Waiting for initialize() ${op.hash} to be confirmed...`);
            await op.confirmation(3);
            console.log('confirmed initialize(): ', op.hash);


        const op2 = await (await Tezos.contract.at(reward_token_address)).methods.approve(farmAddress, rewards).send();
            console.log(`Waiting for approve ${op2.hash} to be confirmed...`);
            await op2.confirmation(3);
            console.log('confirmed approve: ', op2.hash);
        

        const database_contract = await Tezos.contract.at(database); 
        const op3 = await database_contract.methods.add_farm(farmAddress, infoFarm, input_token_address).send();
            console.log(`Waiting for addFarm ${op3.hash} to be confirmed...`);
            await op3.confirmation(3);
            console.log('confirmed addFarm: ', op3.hash)

    } catch (error: any) {
        console.log(error)
    }
}

orig();
