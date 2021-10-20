#include "../partials/FarmMethods.mligo"

let main (action, s : entrypoint * storage_farm) : return =
    match action with
    | SetAdmin(admin) -> setAdmin(admin, s)
    | StakeSome(value) -> stakeSome(value, s)