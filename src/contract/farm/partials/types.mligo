type week = nat
type week_in_seconds = nat
type stake_param = nat
type reward_param = nat
type smak_transfer = address * (address * nat)

type storage_farm = {
    admin: address;
    creation_time: timestamp;
    lp_token_address: address;
    rate: nat;
    reserve_address: address;
    // reward_at_week : (week, nat) map; // change to list
    // farm_points : (nat, nat) map; // change to list
    reward_at_week : nat list; // change to list
    farm_points : nat list; // change to list
    smak_address: address;
    total_reward: nat;
    // user_points : (address, (nat, nat) map ) big_map; 
    user_points : (address, nat list) big_map;
    user_stakes : (address, nat) big_map;
    total_weeks: nat
}

type no_operation = operation list
type return = operation list * storage_farm

type entrypoint = 
| Set_admin of (address)
| Stake of (stake_param)
| Unstake of (stake_param)
| Claim_all of (unit)
| Increase_reward of (reward_param)