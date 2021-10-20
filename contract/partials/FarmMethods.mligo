#include "Error.mligo"
#include "FarmTypes.mligo"
#include "../main/fa12.mligo"

// Should update the admin
// Params : admin (address) 
let setAdmin(admin, s : address * storage_farm) : return =
    let new_admin = if Tezos.sender = s.admin then admin
    else (failwith(only_admin) : address) in 
    (noOperations, { s with admin = new_admin })

let get_current_week(s : storage_farm) : nat = (Tezos.now - s.creation_time) / week_in_seconds

let stakeSome(lp_amount, s : nat * storage_farm) : return =
    let lp_contract_opt : parameter contract option = Tezos.get_contract_opt(s.lp_token_address) in
    let lp_contract : parameter contract = match lp_contract_opt with
        | None -> (failwith(unknown_lp_contract) : parameter contract)
        | Some(x) -> x
    in
    // create a transfer transaction (for LP token contract)
    let transfer_param : transfer = { address_from = Tezos.sender; address_to = Tezos.self_address; value = lp_amount } in 
    let op : operation = Tezos.transaction (Transfer(transfer_param)) 0mutez lp_contract in
    let ops : operation list = [ op; ] in
    // update current storage with updated user_stakes map
    let existing_bal_opt : nat option = Map.find_opt Tezos.sender s.user_stakes in
    let new_user_stakes : (address, nat) map = match existing_bal_opt with
        | None -> Map.add Tezos.sender lp_amount s.user_stakes
        | Some(v) -> Map.update Tezos.sender (Some(lp_amount + v)) s.user_stakes
    in
    (ops, { s with user_stakes = new_user_stakes } )