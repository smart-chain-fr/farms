#include "../../../../lib/contract/fa12.mligo"
#include "types.mligo"
#include "error.mligo"

// -----------------
// --  CONSTANTS  --
// -----------------
let week_in_seconds : nat  = 604800n
let no_operation : operation list = []
let empty_nat_list : nat list = []
let add : bool = true
let subtract : bool = false

// -----------------
// --  INTERNALS  --
// -----------------
let get_current_week (s : storage_farm) : nat = 
    let delay : nat = abs(Tezos.now - s.creation_time) in
    delay / week_in_seconds + 1n

let get_weeks_list_indices (first, last : nat * nat) : nat list =
    let rec append (acc, elt, last: nat list * nat * nat) : nat list = 
        if elt <= last then append (elt :: acc, elt + 1n, last) 
        else acc
    in
    append(([]:nat list), first, last)

let sendReward(token_amount, user_address, smak_address, reserve_address : nat * address * address * address) : operation = 
    let smak_contract_otp : smak_transfer contract option = Tezos.get_entrypoint_opt "%transfer" smak_address in
    let transfer_smak : smak_transfer contract = 
        match smak_contract_otp with
        | Some c -> c
        | None -> (failwith unknown_smak_contract:  smak_transfer contract)
    in
    let transfer_param : smak_transfer = reserve_address,  (user_address , token_amount ) in 
    let op : operation = Tezos.transaction (transfer_param) 0mutez transfer_smak in
    op

let power (x, y : nat * nat) : nat = 
    let rec multiply(acc, elt, last: nat * nat * nat ) : nat = if last = 0n then acc else multiply(acc * elt, elt, abs(last - 1n)) in
    multiply(1n, x, y)

let add_or_subtract_list(lst1, lst2, is_added : nat list * nat list * bool) : nat list =
    let rec merge_list(lst1, lst2, res : nat list * nat list * nat list) : nat list =
        match lst1, lst2 with
        [], [] -> res
        | [], _lst -> failwith "size don't match"
        | _lst, [] -> failwith "size don't match"
        | hd1::tl1, hd2::tl2 ->
            let new_hd : nat = if (is_added = true) then hd1 + hd2 else abs(hd1 - hd2) in
            merge_list(tl1, tl2, new_hd :: res)
    in
    let rec reverse_list(lst, res : nat list * nat list) : nat list =
        match lst, res with
        [], res -> res
        |  hd1::tl1, lst -> reverse_list(tl1, hd1 :: lst)
    in
    reverse_list(merge_list(lst1, lst2, empty_nat_list), empty_nat_list)

let compute_new_rewards (current_week, rate, total_weeks, total_reward, reward_at_week : nat * nat * nat * nat * nat list) : nat list =
    let weeks_list_indices : nat list = get_weeks_list_indices(1n, total_weeks) in 
    //let _print : unit = assert_with_error (false) (List.size weeks_list_indices : string) in
 
    let update_reward_per_week (week_indice : nat) : nat =
        let t_before : nat = power(rate, abs(week_indice - 1n)) in  
        let t_before_divisor : nat = power(10_000n, abs(week_indice - 1n)) in
        let un_moins_rate : nat = abs(10_000n - rate) in 
        let m_10000_4 : nat = power(10_000n, abs(total_weeks - 1n)) in
        let numerator : nat = un_moins_rate * m_10000_4 in 
        let t_I_max : nat = power(rate, total_weeks) in 
        let m_10000_5 : nat = power(10_000n, total_weeks) in
        let denominator : nat = abs(m_10000_5 - t_I_max) in
        let final_denominator : nat = t_before_divisor * denominator in 
        let final_numerator : nat = numerator * total_reward * t_before in 
        final_numerator / final_denominator
    in
    let rec update_rewards(lst1, lst2, res : nat list * nat list * nat list) : nat list =
        match lst1, lst2 with
        [], [] -> res
        | [], _lst -> failwith "size don't match"
        | _lst, [] -> failwith "size don't match"
        | hd1::tl1, hd2::tl2 ->
            let new_res : nat list =
                if hd1 < current_week
                then hd2 :: res
                else update_reward_per_week(hd1) :: res
            in
            update_rewards(tl1, tl2, new_res)
    in
    // let rec reverse_list (lst, res : nat list * nat list) : nat list =
    //     match lst, res with
    //     [], _lst -> _lst
    //     |  hd1::tl1, _lst -> reverse_list(tl1, hd1 :: _lst)
    // in
    // let final_reward_list : nat list = update_rewards(weeks_list_indices, reward_at_week, empty_nat_list) in
    // reverse_list(final_reward_list, empty_nat_list)
    update_rewards(weeks_list_indices, reward_at_week, empty_nat_list)


// ------------------
// -- ENTRY POINTS --
// ------------------
let set_admin(new_admin, storage : address * storage_farm) : return =
    let admin_address : address = storage.admin in
    let _check_if_admin : unit = assert_with_error (Tezos.sender = admin_address) only_admin in
    let _check_if_no_tez : unit = assert_with_error (Tezos.amount = 0tez) amount_must_be_zero_tez in
    let final_storage = { storage with admin = new_admin } in
    (no_operation, final_storage)

let initialize(storage : storage_farm) : return =
    let creation_time : timestamp = storage.creation_time in
    let initialized_creation_time : timestamp = Tezos.now in
    let current_week : nat = get_current_week(storage) in
    let rate : nat = storage.rate in 
    let total_weeks : nat = storage.total_weeks in
    let total_reward : nat = storage.total_reward in
    let reward_at_week : nat list = storage.reward_at_week in

    let _check_if_admin : unit = assert_with_error (Tezos.sender = storage.admin) only_admin in
    let _check_if_no_tez : unit = assert_with_error (Tezos.amount = 0tez) amount_must_be_zero_tez in
    let _check_current_week : unit = assert_with_error (initialized_creation_time < creation_time + int(week_in_seconds)) no_week_left in
    let _check_if_unitialized : unit = assert_with_error (List.size reward_at_week = 0n) contract_already_initialized in

    let rec initialize_at_zero(list_to_initialize, total_weeks : nat list * nat) : nat list=
        if total_weeks = 0n then list_to_initialize
        else initialize_at_zero(0n :: list_to_initialize, abs(total_weeks - 1n))
    in

    let reward_at_week_initialized_at_zero : nat list = initialize_at_zero(empty_nat_list, total_weeks) in

    let new_reward_at_week : nat list = compute_new_rewards(current_week, rate, total_weeks, total_reward, reward_at_week_initialized_at_zero) in
    let final_storage = { storage with reward_at_week = new_reward_at_week ;
                                       creation_time = initialized_creation_time } in
    (no_operation, final_storage)

let increase_reward(value, storage : nat * storage_farm) : return =
    let total_weeks : nat = storage.total_weeks in
    let total_reward : nat = storage.total_reward in
    let current_time : timestamp = Tezos.now in
    let creation_time : timestamp = storage.creation_time in
    let delta : nat = value in
    let initialized_creation_time: timestamp = if (delta = 0n) then current_time else creation_time in
    let current_week : nat = get_current_week(storage) in
    let rate : nat = storage.rate in 
    let reward_at_week : nat list = storage.reward_at_week in

    let _check_if_admin : unit = assert_with_error (Tezos.sender = storage.admin) only_admin in
    let _check_if_no_tez : unit = assert_with_error (Tezos.amount = 0tez) amount_must_be_zero_tez in
    let _check_current_week : unit = assert_with_error (current_time < creation_time + int(total_weeks * week_in_seconds)) no_week_left in
    let _check_if_positive : unit = assert_with_error (value = 0n) increase_amount_is_null in

    let folded (acc, elt: nat * nat) : nat = acc + elt in
    let sum_R : nat = List.fold folded reward_at_week 0n in
    let new_total_reward : nat = delta + abs(storage.total_reward - sum_R) in

    let new_reward_at_week : nat list = compute_new_rewards(current_week, rate, total_weeks, total_reward, reward_at_week) in

    let final_storage = { storage with total_reward = new_total_reward ;
                                       reward_at_week = new_reward_at_week ;
                                       creation_time = initialized_creation_time } in
    (no_operation, final_storage)

let stake_some(lp_amount, storage : nat * storage_farm) : return =
    let current_time : timestamp = Tezos.now in
    let sender_address : address = Tezos.sender in // Avoids recalculating Tezos.sender each time for gas
    let farm_points : nat list = storage.farm_points in
    let user_points : (address, nat list) big_map = storage.user_points in
    let total_weeks : nat = storage.total_weeks in
    let lp_contract_opt : parameter contract option = Tezos.get_contract_opt(storage.lp_token_address) in
    let lp_contract : parameter contract =
        match lp_contract_opt with
        | None -> (failwith(unknown_lp_contract) : parameter contract)
        | Some(x) -> x
    in
    let current_week : nat = get_current_week(storage) in
    let endofweek_in_seconds : timestamp = storage.creation_time + int(current_week * week_in_seconds) in

    let _check_if_no_tez : unit = assert_with_error (Tezos.amount = 0tez) amount_must_be_zero_tez in
    let _check_amount_positive : unit = assert_with_error (lp_amount > 0n) amount_is_null in // TODO : why ?
    let _check_current_week : unit = assert_with_error (current_time < storage.creation_time + int(storage.total_weeks * week_in_seconds)) no_week_left in
    let _check_in_week : unit = assert_with_error (current_time - endofweek_in_seconds < 0) time_too_early in

    // create a transfer transaction (for LP token contract)
    let transfer_param : transfer = { address_from = sender_address; address_to = Tezos.self_address; value = lp_amount } in 
    let op : operation = Tezos.transaction (Transfer(transfer_param)) 0mutez lp_contract in
    let operations : operation list = [ op; ] in
    // update current storage with updated user_stakes map
    let existing_bal_opt : nat option = Big_map.find_opt sender_address storage.user_stakes in
    let new_user_stakes : (address, nat) big_map =
        match existing_bal_opt with
        | None -> Big_map.add sender_address lp_amount storage.user_stakes
        | Some(v) -> Big_map.update sender_address (Some(lp_amount + v)) storage.user_stakes
    in    

    let before_end_week : nat = abs(current_time - endofweek_in_seconds) in 
    let points_current_week : nat = before_end_week * lp_amount in
    let points_next_weeks : nat = week_in_seconds * lp_amount in
    
    //create the point week list to add
    let rec calculate_new_points_by_week(total_weeks, acc : nat * nat list) : nat list =
        if total_weeks = 0n then acc
        else begin
                let value = 
                    if total_weeks < current_week then 0n
                    else if total_weeks = current_week then points_current_week
                    else points_next_weeks
                in
                calculate_new_points_by_week(abs(total_weeks - 1n), value :: acc)
             end
    in

    let new_points_by_weeks : nat list = calculate_new_points_by_week(total_weeks, empty_nat_list) in

    let personal_user_points (user_points, sender_address : (address, nat list) big_map * address ) : nat list =
        match Big_map.find_opt sender_address user_points with
        | None -> new_points_by_weeks
        | Some(user_week_points) -> add_or_subtract_list(user_week_points, new_points_by_weeks, add)
    in
    
    let new_user_points : nat list = personal_user_points(user_points, sender_address) in
    let new_final_map : (address, nat list) big_map = Big_map.update sender_address (Some(new_user_points)) user_points in
    let new_farm_points : nat list = add_or_subtract_list(farm_points, new_points_by_weeks, add) in

    let final_storage = { storage with user_stakes = new_user_stakes; user_points = new_final_map; farm_points = new_farm_points } in
    (operations, final_storage)

let unstake_some(lp_amount, storage : nat * storage_farm) : return =
    let current_time : timestamp = Tezos.now in
    let current_week : nat = get_current_week(storage) in
    let farm_points : nat list = storage.farm_points in
    let user_points : (address, nat list) big_map = storage.user_points in
    let total_weeks : nat = storage.total_weeks in
    let _check_if_no_tez : unit = assert_with_error (Tezos.amount = 0tez) amount_must_be_zero_tez in
    let sender_address : address = Tezos.sender in // Avoids recalculating Tezos.sender each time for gas
    let endofweek_in_seconds : timestamp = storage.creation_time + int(current_week * week_in_seconds) in 

    // update current storage with updated user_stakes map
    let existing_bal_opt : nat option = Big_map.find_opt sender_address storage.user_stakes in
    let user_stakes : nat =
        match existing_bal_opt with
        | None -> (failwith(no_stakes): nat)
        | Some(v) -> v
    in
    let _check_lp_amount : unit = assert_with_error (user_stakes >= lp_amount) unstake_more_than_stake in
    let new_user_stakes : (address, nat) big_map = Big_map.update sender_address (Some(abs(user_stakes - lp_amount))) storage.user_stakes in
    let lp_contract_opt : parameter contract option = Tezos.get_contract_opt(storage.lp_token_address) in
    let lp_contract : parameter contract =
        match lp_contract_opt with
        | None -> (failwith(unknown_lp_contract) : parameter contract)
        | Some(x) -> x
    in
    // create a transfer transaction (for LP token contract)
    let transfer_param : transfer = { address_from = Tezos.self_address; address_to = sender_address; value = lp_amount } in 
    let op : operation = Tezos.transaction (Transfer(transfer_param)) 0mutez lp_contract in
    let operations : operation list = [ op; ] in

    if (current_time < endofweek_in_seconds ) then // TODO : simplify before end of life

        let before_end_week : nat = abs(current_time - endofweek_in_seconds) in 
        let points_current_week : nat = before_end_week * lp_amount in
        let points_next_weeks : nat = week_in_seconds * lp_amount in
        
        //create the point week list to substract
        let rec calculate_new_points_by_week(total_weeks, acc : nat * nat list) : nat list =
            if total_weeks = 0n then acc
            else begin
                    let value = 
                        if total_weeks < current_week then 0n
                        else if total_weeks = current_week then points_current_week
                        else points_next_weeks
                    in
                    calculate_new_points_by_week(abs(total_weeks - 1n), value :: acc)
                end
        in
        let new_points_by_weeks : nat list = calculate_new_points_by_week(total_weeks, empty_nat_list) in

        let personal_user_points (user_points, sender_address : (address, nat list) big_map * address ) : nat list =
            match Big_map.find_opt sender_address user_points with
            | None -> failwith "Some points should exist"
            | Some(user_week_points) -> add_or_subtract_list(user_week_points, new_points_by_weeks, subtract)
        in

        let new_user_points : nat list = personal_user_points(user_points, sender_address) in
        let final_user_points : (address, nat list) big_map = Big_map.update sender_address (Some(new_user_points)) user_points in
        let new_farm_points : nat list = add_or_subtract_list(farm_points, new_points_by_weeks, subtract) in

        let final_storage = { storage with user_stakes = new_user_stakes; user_points = final_user_points; farm_points = new_farm_points } in
        (operations, final_storage)

    else    

        let final_storage = { storage with user_stakes = new_user_stakes} in
        (operations, final_storage)

let claim_all(storage : storage_farm) : return = 
    let farm_points : nat list = storage.farm_points in
    let user_points : (address, nat list) big_map = storage.user_points in
    let sender_address : address = Tezos.sender in // Avoids recalculating Tezos.sender each time for gas
    let smak_address : address = storage.smak_address in
    let reserve_address : address = storage.reserve_address in

    let _check_if_no_tez : unit = assert_with_error (Tezos.amount = 0tez) amount_must_be_zero_tez in

    match Big_map.find_opt sender_address user_points with
    | None -> (no_operation, storage)
    | Some(user_points) ->
        let rec aux (acc, user_points, farm_points, reward_at_weeks : nat * nat list * nat list * nat list) : nat =
            match user_points, farm_points, reward_at_weeks with 
            [], [], [] -> acc
            | [], lst2, lst3 -> failwith "size don't match"
            | lst1, [], lst3 -> failwith "size don't match"
            | lst1, lst2, [] -> failwith "size don't match"
            | hd1::_tl1, hd2::_tl2, hd3::_tl3 ->
                let acc = acc + hd1 * hd3 / hd2 in
                aux (acc, user_points, farm_points, reward_at_weeks)
        in

        let total_reward_for_user : nat = aux( 0n, user_points, farm_points, storage.reward_at_week) in
        let send_reward : operation = sendReward(total_reward_for_user, sender_address, smak_address, reserve_address) in

        let new_user_points = List.map (fun (_i : nat) -> 0n) user_points in
        let user_points_map = Big_map.update sender_address (Some(new_user_points)) storage.user_points in

        let final_storage = { storage with user_points = user_points_map } in
        ([send_reward], final_storage)