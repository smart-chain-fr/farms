# Testing Launch pool

## Start a node

### Install Tezos node from sources
```
https://tezos.gitlab.io/introduction/howtoget.html
```

### Configure a Tezos node for hangzhounet network
```
./tezos-node config init \
  --network hangzhounet \
  --data-dir ~/.tezos-node-hangzhounet
```

### Launching a Tezos node on hangzhounet
```
./tezos-node run \
  --network hangzhounet \
  --data-dir ~/.tezos-node-hangzhounet \
  --synchronisation-threshold 1 \
  --rpc-addr localhost:8732
```

### Get Tezos faucet
- Download your faucet account from `https://teztnets.xyz/hangzhounet-faucet`
- Activate your faucet account with `tezos-client activate account faucet with /tmp/hangzhounet.json`

### Test node interaction

Once the Tezos node is running , one must wait for synchronization with the rest of the network. Running the node should automatically start the synchronization.
- Verify the Tezos node is sync with `tezos-client bootstrapped`
- List known addresses (accounts registered on the node) with `./tezos-client list known addresses` 
- List contracts that have been deployed on the node with `./tezos-client list known contracts`

In a web browser , one can check the following URLs:
`http://127.0.0.1:8732/chains/main/blocks/head/context/constants`



## Deploy contracts for testing Launchpools

The Launch pool requires:
- an input contract which specifies which kind of token are being staked (FA1.2, FA2). 
- an output contract which specifies what kind of rewards are being given to stakers (FA1.2, FA2).
- the output contract (for reward) must also specify an address holding the rewards.

So, for testing launch pools, one must:
- deploy an input contract token (FA1.2, FA2).
- mint some token to a "user" who is going to stake these tokens to the launch pool.
- deploy an output contract token (FA1.2, FA2) for rewards.
- mint some token to a `reserve` address for rewards
- Approval: the holder of the reserve of rewards must allow the newly created launch pool to be able to use the rewards
    - for FA1.2, approve (farm_id, amount_reward)
    - for FA2, Add_operator(farm_id), Remove_operator(farm_id), specify the amount ????? 
- deploy a launch pool

Now all smart contracts are deployed and setup for testing the staking/unstaking.


### depoy FA2 contract for rewards (executed as admin)

- compile the deployment script `deploy_fa2_reward.ts`
```
tsc deploy_fa2_reward.ts --resolveJsonModule -esModuleInterop
```

- execute the deployment script `deploy_fa2_reward.js`
```
node deploy_fa2_reward.js
```
This script deploys a FA2 contract, and mint some tokens for admin and output the resulting fa2_reward contract address


### deploy the farm contract

- copy the fa2_reward contract address into the `deploy_farm.ts` (in field `reward_token_address`)



### authorize the farm contract to use the fa2_reward

- copy the fa2_reward contract address into the `approve_fa2_reward.ts` (in field `reward_fa2_contract`)

- compile the approval script `approve_fa2_reward.ts`
```
tsc approve_fa2_reward.ts --resolveJsonModule -esModuleInterop
```

- execute the approval script `approve_fa2_reward.js`
```
node approve_fa2_reward.js
```
This script authorize the `reward_fa2_contract` address to use the minted tokens (owned by admin)

