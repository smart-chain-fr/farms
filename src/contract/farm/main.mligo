#include "partials/methods.mligo"

let main (action, storage : entrypoint * storage_farm) : return =
    match action with
    | Initialize() -> initialize(storage)
    | Stake(value) -> stake_some(value, storage)
    | Unstake(value) -> unstake_some(value, storage)
    | Claim_all() -> claim_all(storage)
    | Set_admin(admin) -> set_admin(admin, storage)
    | Increase_reward(value) -> increase_reward(value, storage)