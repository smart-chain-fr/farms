#import "partials/methods.mligo" "FARM"


let main (action, s : entrypoint * FARM.storage_farm) : return =
    match action with
    | SetAdmin(admin) -> FARM.setAdmin(admin, s)
    | Stake(value) -> FARM.stakeSome(value, s)
    | Unstake(value) -> FARM.unstakeSome(value, s)
    | ClaimAll() -> FARM.claimAll(s)
    | IncreaseReward(value) -> FARM.increaseReward(value, s)