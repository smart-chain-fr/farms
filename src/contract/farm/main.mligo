#import "partials/methods.mligo" "FARM"

let main (action, storage : FARM.entrypoint * FARM.storage_farm) : FARM.return =
    match action with
    | Initialize() -> FARM.initialize(storage)
    | Stake(value) -> FARM.stake_some(value, storage)
    | Unstake(value) -> FARM.unstake_some(value, storage)
    | Claim_all() -> FARM.claim_all(storage)
    | Set_admin(admin) -> FARM.set_admin(admin, storage)
    | Increase_reward(value) -> FARM.increase_reward(value, storage)