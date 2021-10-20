type storage is record [
    admin: address;
    creation_time: timestamp;
    lp_token_address: address;
    rate: nat;
    reserve_address: address;
    smak_address: address;
    total_reward: nat;
    weeks: nat;
]

const noOperations : list (operation) = nil;
type return is list (operation)  * storage

// Entrypoints
type entrypoint is 
| SetAdmin of (address)
