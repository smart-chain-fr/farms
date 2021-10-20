#include "Error.mligo"
#include "FarmTypes.mligo"
#include "../main/fa12.mligo"

// Should update the admin
// Params : admin (address) 
let setAdmin(admin, s : address * storage_farm) : return =
    let new_admin = if Tezos.sender = s.admin then admin
    else (failwith(only_admin) : address) in 
    (noOperations, { s with admin = new_admin })

let get_current_week(s : storage_farm) : nat = 
    let delay : nat = abs(Tezos.now - s.creation_time) in
    delay / week_in_seconds

let get_future_weeks_indices(first, last : nat * nat) : nat list =
    let rec append ( acc, elt, last: nat list * nat * nat) : nat list = if elt <= last then append (elt :: acc, elt + 1n, last) else acc in
    append(([]:nat list), first, last)

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
    let existing_bal_opt : nat option = Big_map.find_opt Tezos.sender s.user_stakes in
    let new_user_stakes : (address, nat) big_map = match existing_bal_opt with
        | None -> Big_map.add Tezos.sender lp_amount s.user_stakes
        | Some(v) -> Big_map.update Tezos.sender (Some(lp_amount + v)) s.user_stakes
    in
    let current_week : nat = get_current_week(s) in
    let endofweek_in_seconds : timestamp = s.creation_time + int(current_week * week_in_seconds) in
    
    //assert_some (Tezos.now - endofweek_in_seconds < 0)
    let check_negative : bool = 
        if (Tezos.now - endofweek_in_seconds < 0) 
        then True 
        else (failwith("ERROR: The remaining time before end of week should be negative !! ") : bool)
    in
    let before_end_week : nat = abs(Tezos.now - endofweek_in_seconds) in 
    let points_current_week : nat = before_end_week * lp_amount in
    let points_next_weeks : nat = week_in_seconds * lp_amount in
    
    //user_points[user_address][current_week] += before_end_week * lp_amount
    let user_weeks_opt : (nat, nat) map option = Big_map.find_opt Tezos.sender s.user_points in
    let new_user_points : (address, (nat, nat) map ) big_map = match user_weeks_opt with
    | None -> Big_map.add Tezos.sender (Map.literal [(current_week, points_current_week)] : (nat, nat) map) s.user_points
    | Some(m) -> 
        let modified_current_week : (nat, nat) map = match (Map.find_opt current_week m) with
        | None -> (Map.literal [(current_week, points_current_week)] : (nat, nat) map)
        | Some(wpts) -> (Map.update current_week (Some(points_current_week + wpts)) m)
        in
        Big_map.update Tezos.sender (Some(modified_current_week)) s.user_points
    in 
    //farm_points[current_week] += before_end_week * lp_amount
    let new_farm_points = match Map.find_opt current_week s.farm_points with
    | None -> Map.add current_week points_current_week s.farm_points
    | Some(val) -> Map.update current_week (Some(val + points_current_week)) s.farm_points
    in
    //for (i = current_week + 1; i <= s.weeks; i++) 
    //    user_points[user_address][i] += week_in_seconds * lp_amount
    let future_weeks : nat list = get_future_weeks_indices(current_week + 1n, s.weeks) in
    let update_user_points_func = fun (a, v, i, m : address * nat * nat * (address, (nat, nat) map ) big_map) -> 
        match Big_map.find_opt a m with
        | None -> Big_map.add Tezos.sender (Map.literal [(i, v)] : (nat, nat) map) m
        | Some(weeks_map) ->
            let new_weeks_map : (nat, nat) map = match Map.find_opt i weeks_map with
            | None -> Map.add i v weeks_map
            | Some(value) -> Map.update i (Some(value +v)) weeks_map
            in
            Big_map.update a (Some(new_weeks_map)) m
    in
    let rec modify_user_points_func(resulting_acc, modificateur, weeks_indices : (address, (nat, nat) map ) big_map * nat * nat list) : (address, (nat, nat) map ) big_map =
        let week_indice_opt : nat option = List.head_opt weeks_indices in
        match week_indice_opt with
        | None -> resulting_acc
        | Some(week_indice) -> 
            let modified : (address, (nat, nat) map ) big_map = update_user_points_func(Tezos.sender, modificateur, week_indice, resulting_acc) in
            let remaining_weeks_opt : nat list option = List.tail_opt weeks_indices in
            let remaining_weeks : nat list = match remaining_weeks_opt with
            | None -> ([] : nat list)
            | Some(l) -> l
            in
            modify_user_points_func(modified, modificateur, remaining_weeks)
    in
    let final_user_points : (address, (nat, nat) map ) big_map  = modify_user_points_func(new_user_points, points_next_weeks, future_weeks)
    in

    //for (i = current_week + 1; i <= s.weeks; i++) 
    //    farm_points[i] += week_in_seconds * lp_amount 
    let update_farm_points_func = fun (v, i, m : nat * nat * (nat, nat) map) ->
        match (Map.find_opt i m) with
        | None -> Map.add i v m
        | Some(entry) -> Map.update i (Some(entry+v)) m
    in
    let rec modify_farm_points_func(farm_result, delta, weeks_indices : (nat, nat) map * nat * nat list) : (nat, nat) map =
        let week_indice_opt : nat option = List.head_opt weeks_indices in
        match week_indice_opt with
        | None -> farm_result
        | Some(week_indice) -> 
            let modified : (nat, nat) map = update_farm_points_func(delta, week_indice, farm_result) in
            let remaining_weeks_opt : nat list option = List.tail_opt weeks_indices in
            let remaining_weeks : nat list = match remaining_weeks_opt with
            | None -> ([] : nat list)
            | Some(l) -> l
            in
            modify_farm_points_func(modified, delta, remaining_weeks)
    in
    let final_farm_points : (nat, nat) map = modify_farm_points_func(new_farm_points, points_next_weeks, future_weeks) in

    (ops, { s with user_stakes = new_user_stakes; user_points = final_user_points; farm_points = final_farm_points } )