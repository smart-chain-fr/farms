type week = nat
type week_in_seconds = nat
type stake_param = nat
type reward_param = nat
type fa12_transfer = address * (address * nat)

type storage_farm = {
    admin: address;
    creation_time: timestamp;
    lp_token_address: address;
    rate: nat;
    reserve_address: address;
    reward_at_week : nat list; // change to list
    farm_points : nat list; // change to list
    fa12_address: address;
    total_reward: nat;
    user_points : (address, nat list) big_map; // change to list
    user_stakes : (address, nat) big_map;
    total_weeks: nat
}

type no_operation = operation list
type return = operation list * storage_farm

type entrypoint = 
| Initialize of (unit)
| Stake of (stake_param)
| Unstake of (stake_param)
| Claim_all of (unit)
| Set_admin of (address)
| Increase_reward of (reward_param)