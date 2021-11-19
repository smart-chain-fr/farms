
type week = nat
type week_in_seconds = nat
type stake_param = nat
type reward_param = nat
type smak_transfer = address * (address * nat)

type storage_farm = {
    admin: address;
    creation_time: timestamp;
    farm_points : (nat, nat) map;
    lp_token_address: address;
    rate: nat;
    reserve_address: address;
    reward_at_week : (week, nat) map;
    smak_address: address;
    total_reward: nat;
    user_points : (address, (nat, nat) map ) big_map;
    user_stakes : (address, nat) big_map;
    total_weeks: nat
}

type noOperations = operation list
type return = operation list * storage_farm

type entrypoint = 
| SetAdmin of (address)
| Stake of (stake_param)
| Unstake of (stake_param)
| ClaimAll of (unit)
| IncreaseReward of (reward_param)


