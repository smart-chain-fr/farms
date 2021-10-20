import { InMemorySigner } from '@taquito/signer';
import { TezosToolkit } from '@taquito/taquito';
import farm from './ressources/Farm.json';
import dotenv from 'dotenv'

dotenv.config(({path:__dirname+'/.env'}))

const Tezos = new TezosToolkit('https://granadanet.api.tez.ie/');

const pk: string = process.env.PK || "";
const signer = new InMemorySigner(pk);
Tezos.setProvider({ signer: signer })
const admin = process.env.ADMIN || "";
const smak = process.env.SMAK || "";

const lp = 'KT1W12FCPyUC79RGfWXTvnTKBtPBLraoDcqM';
const rewards = 2500000;

async function orig() {
    const store = {
        'admin': admin,
        'creation_time': new Date().getTime(),
        'lp_token_address': lp,
        'rate': 7500,
        'reserve_address': admin,
        'smak_address': smak,
        'total_reward': rewards,
        'weeks': 5
    }
    const originated = Tezos.contract.originate({
        code: farm,
        storage: store,
    }).then(
        async (originationOp) => {
            console.log(`Waiting for ${originationOp.contractAddress} to be confirmed...`);
            await originationOp.confirmation(2);
            console.log('confirmed: ', originationOp.contractAddress);
            const op = await (await Tezos.contract.at(smak)).methods.approve(originationOp.contractAddress, rewards ).send();
            console.log(`Waiting for ${op.hash} to be confirmed...`);
            op.confirmation(3);
            console.log('confirmed: ', op.hash);
        }
    ).catch(e => {
        console.log(e)
    })
}
 

orig();
