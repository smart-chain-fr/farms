

type storage_farm = {
    admin: address;
    creation_time: timestamp;
    lp_token_address: address;
    rate: nat;
    reserve_address: address;
    smak_address: address;
    total_reward: nat;
    weeks: nat;
    user_stakes : (address, nat) big_map;
    user_points : (address, (nat, nat) map ) big_map;
    farm_points : (nat, nat) map;
}

let noOperations : operation list = []

type return = operation list * storage_farm

let week_in_seconds : nat  = 604800n

type stake_param = nat

// Entrypoints
type entrypoint = 
| SetAdmin of (address)
| StakeSome of (stake_param)
