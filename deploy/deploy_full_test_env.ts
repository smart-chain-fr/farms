import { InMemorySigner } from '@taquito/signer';
import { TezosToolkit, MichelsonMap } from '@taquito/taquito';
import farm from './artefact/farm.json';
import fa12 from './artefact/fa12.json';
import fa2 from './artefact/fa2.json';
import database from './artefact/database.json';
import * as dotenv from 'dotenv'

dotenv.config(({path:__dirname+'/.env.preprod.anti_anti'}))

const rpc = process.env.RPC; //"http://127.0.0.1:8732"
const pk: string = "edskRuatoqjfYJ2iY6cMKtYakCECcL537iM7U21Mz4ieW3J51L9AZcHaxziWPZSEq4A8hu5e5eJzvzTY1SdwKNF8Pkpg5M6Xev";
const Tezos = new TezosToolkit(rpc);
const signer = new InMemorySigner(pk);
Tezos.setProvider({ signer: signer })

let database_address = process.env.FARMSDB_ADDRESS || undefined; //"KT1HCLH3bCGnVrjZuVwP8aScgdMNr9qbjmSf";
const admin = process.env.ADMIN_ADDRESS; //"tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5";
const creation_time = new Date();
const farm_points: [] = [];
let input_token_address = process.env.INPUT_CONTRACT_ADDRESS; //'KT1V5U9hTaXArCKLAW2HC41epX8BXoZaFEQE';
const input_token_id = process.env.INPUT_TOKEN_ID || undefined; //1;
const reward_fa2_token_id = process.env.REWARD_TOKEN_ID || undefined; //1;
let reward_token_address = process.env.REWARD_CONTRACT_ADDRESS; //"KT1WUc6Q1V8XzikB8qgQbCwL7PdWvJLEZE9s"
const reward_reserve_address = process.env.REWARD_RESERVE_ADDRESS; //"tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5";
const infoFarm = process.env.INFOFARM || '';
const rate = process.env.RATE || 9500;
let reward_at_week: [] = [];
const rewards = process.env.REWARD_AMOUNT; //50000000;
let user_points = new MichelsonMap();
let user_stakes = new MichelsonMap();
const total_weeks = process.env.WEEKS; //5;

let farm_address = process.env.FARM_ADDRESS || undefined;

// For FA1.2 input
let fa12_input_tokens = new MichelsonMap();
let fa12_input_allowances = new MichelsonMap();
const fa12_input_total_supply = process.env.INPUT_FA12_TOTAL_SUPPLY || 20000;
let fa12_input_metadata = new MichelsonMap();
let fa12_input_token_metadata = new MichelsonMap();

// For FA2 input
let fa2_input_paused = false
let fa2_input_ledger = new MichelsonMap();
const fa2_input_operators_init: [] = [];

// For FA1.2 reward
let fa12_reward_tokens = new MichelsonMap();
let fa12_reward_allowances = new MichelsonMap();
const fa12_reward_total_supply = process.env.REWARD_AMOUNT || 50000000;
let fa12_reward_metadata = new MichelsonMap();
let fa12_reward_token_metadata = new MichelsonMap();
fa12_reward_tokens.set(reward_reserve_address, rewards);

// FA2 reward
let fa2_reward_paused = false
let fa2_reward_ledger = new MichelsonMap();
const fa2_reward_operators_init: [] = [];
fa2_reward_ledger.set({0:reward_reserve_address, 1:reward_fa2_token_id}, rewards);


// database
let database_all_farms = new Array();
let database_all_farms_data = new MichelsonMap();
let database_inverse_farms = new MichelsonMap();

async function orig() {

    let farm_store = {
        'admin': admin,
        'creation_time': creation_time,
        'farm_points': farm_points,
        'input_token_address': input_token_address,
        'input_fa2_token_id_opt': input_token_id,
        'initialized': false,
        'reward_fa2_token_id_opt' : reward_fa2_token_id,
        'reward_token_address': reward_token_address,
        'reward_reserve_address': reward_reserve_address,
        'rate': rate,
        'reward_at_week': reward_at_week,
        'total_reward': rewards,
        'user_points': user_points,
        'user_stakes': user_stakes,
        'total_weeks': total_weeks,
    }

    const fa2_input_store = {
        'paused' : fa2_input_paused,
        'ledger' : fa2_input_ledger,
        //'tokens' : token_metadata,
        'operators' : fa2_input_operators_init,
        'administrator' : admin
    }

    const fa2_reward_store = {
        'paused' : fa2_reward_paused,
        'ledger' : fa2_reward_ledger,
        //'tokens' : token_metadata,
        'operators' : fa2_reward_operators_init,
        'administrator' : admin
    }

    const fa12_input_store = {
        'tokens' : fa12_input_tokens,
        'allowances' : fa12_input_allowances,
        'admin' : admin,
        'total_supply' : fa12_input_total_supply,
        'metadata' : fa12_input_metadata,
        'token_metadata' : fa12_input_token_metadata
    }

    const fa12_reward_store = {
        'tokens' : fa12_reward_tokens,
        'allowances' : fa12_reward_allowances,
        'admin' : admin,
        'total_supply' : fa12_reward_total_supply,
        'metadata' : fa12_reward_metadata,
        'token_metadata' : fa12_reward_token_metadata
    }

    const database_store = {
        'admin': admin,
        'all_farms': database_all_farms,
        'all_farms_data': database_all_farms_data,
        'inverse_farms': database_inverse_farms
    }

    try {
        // INPUT TOKEN contract
        if (input_token_address === undefined) {
            if (input_token_id === undefined) {
                // Originate a FA1.2 as input
                const fa12_input_originated = await Tezos.contract.originate({
                    code: fa12,
                    storage: fa12_input_store,
                })
                console.log(`Waiting for FA1.2 (as input) ${fa12_input_originated.contractAddress} to be confirmed...`);
                await fa12_input_originated.confirmation(2);
                console.log('confirmed fa12: ', fa12_input_originated.contractAddress);
                input_token_address = fa12_input_originated.contractAddress;      
                
                farm_store.input_token_address = input_token_address;
            } else {
                // Originate a FA2 as input
                const fa2_input_originated = await Tezos.contract.originate({
                    code: fa2,
                    storage: fa2_input_store,
                })
                console.log(`Waiting for FA2 (as input) ${fa2_input_originated.contractAddress} to be confirmed...`);
                await fa2_input_originated.confirmation(2);
                console.log('confirmed fa2: ', fa2_input_originated.contractAddress);
                input_token_address = fa2_input_originated.contractAddress;
                farm_store.input_token_address = input_token_address;
            }    
        }

        // REWARD TOKEN contract
        if (reward_token_address === undefined) {
            if (reward_fa2_token_id === undefined){
                // Originate a FA1.2 as reward
                const fa12_reward_originated = await Tezos.contract.originate({
                    code: fa12,
                    storage: fa12_reward_store,
                })
                console.log(`Waiting for FA1.2 (as reward) ${fa12_reward_originated.contractAddress} to be confirmed...`);
                await fa12_reward_originated.confirmation(2);
                console.log('confirmed fa12 (as reward): ', fa12_reward_originated.contractAddress);
                reward_token_address = fa12_reward_originated.contractAddress;      
                
                farm_store.reward_token_address = reward_token_address;
            } else {
                // Originate a FA2 as reward
                const fa2_reward_originated = await Tezos.contract.originate({
                    code: fa2,
                    storage: fa2_reward_store,
                })
                console.log(`Waiting for FA2 (as reward) ${fa2_reward_originated.contractAddress} to be confirmed...`);
                await fa2_reward_originated.confirmation(2);
                console.log('confirmed fa2: ', fa2_reward_originated.contractAddress);
                reward_token_address = fa2_reward_originated.contractAddress;
                
                farm_store.reward_token_address = reward_token_address;
            }    
        }

        // Originate farm database
        if (database_address === undefined) {
            const database_originated = await Tezos.contract.originate({
                code: database,
                storage: database_store,
            })
            console.log(`Waiting for farm database ${database_originated.contractAddress} to be confirmed...`);
            await database_originated.confirmation(2);
            console.log("FARMS DATABASE=", database_originated.contractAddress);
            database_address = database_originated.contractAddress    
        } 

        // Originate Farm contract
        const farm_originated = await Tezos.contract.originate({
            code: farm,
            storage: farm_store,
        })
        console.log(`Waiting for farm ${farm_originated.contractAddress} to be confirmed...`);
        await farm_originated.confirmation(2);
        console.log('confirmed farm: ', farm_originated.contractAddress);
        farm_address = farm_originated.contractAddress;


        const op = await (await Tezos.contract.at(farm_address)).methods.initialize().send();
            console.log(`Waiting for initialize() ${op.hash} to be confirmed...`);
            await op.confirmation(3);
            console.log('confirmed initialize(): ', op.hash);

        // update_operators transaction must be sent by <reward_reserve_address> 
        // const op2 = await (await Tezos.contract.at(reward_token_address)).methods.update_operators([{add_operator: {owner:reward_reserve_address, operator: farmAddress, token_id:reward_fa2_token_id}}]).send();
        // console.log(`Waiting for update_operators ${op2.hash} to be confirmed...`);
        // await op2.confirmation(3);
        // console.log('confirmed update_operators: ', op2.hash);
        console.log("update_operators transaction must be sent by <reward_reserve_address> ")
        console.log("update_operators([{add_operator: {owner:reward_reserve_address, operator: farmAddress, token_id:reward_fa2_token_id}}])")
        

        const database_contract = await Tezos.contract.at(database_address); 
        const op3 = await database_contract.methods.add_farm(farm_address, infoFarm, input_token_address).send();
            console.log(`Waiting for addFarm ${op3.hash} to be confirmed...`);
            await op3.confirmation(3);
            console.log('confirmed addFarm: ', op3.hash)

        
        console.log("./tezos-client remember contract fa12_input", input_token_address)
        console.log("./tezos-client remember contract fa2_reward", reward_token_address)
        console.log("./tezos-client remember contract database", database_address)
        console.log("./tezos-client remember contract farm_fa12_fa2", farm_address)


    } catch (error: any) {
        console.log(error)
    }
}

orig();
