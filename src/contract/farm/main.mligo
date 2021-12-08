#import "partials/methods.mligo" "FARM"

let main (action, storage : FARM.entrypoint * FARM.storage_farm) : FARM.return =
    match action with
    | Initialize()           -> FARM.initialize      storage
    | Stake(value)           -> FARM.stake_some      storage value
    | Unstake(value)         -> FARM.unstake_some    storage value
    | Claim_all()            -> FARM.claim_all       storage
    | Set_admin(admin)       -> FARM.set_admin       storage admin
    | Increase_reward(value) -> FARM.increase_reward storage value