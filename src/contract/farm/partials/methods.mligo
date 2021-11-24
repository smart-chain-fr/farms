#include "../../../../lib/contract/fa12.mligo"
#include "types.mligo"
#include "error.mligo"

// -----------------
// --  CONSTANTS  --
// -----------------
let week_in_seconds : nat  = 604800n
let no_operation : operation list = []
let empty_nat_list : nat list = []

// -----------------
// --  INTERNALS  --
// -----------------
let get_current_week(s : storage_farm) : nat = 
    let delay : nat = abs(Tezos.now - s.creation_time) in
    delay / week_in_seconds + 1n

let get_weeks_indices(first, last : nat * nat) : nat list =
    let rec append ( acc, elt, last: nat list * nat * nat) : nat list = if elt <= last then append (elt :: acc, elt + 1n, last) else acc in
    append(([]:nat list), first, last)

let get_weeks_indices_as_set(first, last : nat * nat) : nat set =
    let rec append ( acc, elt, last: nat set * nat * nat) : nat set = if elt <= last then append (Set.add elt acc, elt + 1n, last) else acc in
    append((Set.empty : nat set), first, last)

let sendReward(token_amount, user_address, s : nat * address * storage_farm) : operation = 
    let smak_contract_otp : smak_transfer contract option = Tezos.get_entrypoint_opt "%transfer" s.smak_address in
    let transfer_smak : smak_transfer contract = match smak_contract_otp with
        | Some c -> c
        | None -> (failwith unknown_smak_contract:  smak_transfer contract)
    in
    // create a transfer transaction (for LP token contract)
    let transfer_param : smak_transfer = s.reserve_address,  (user_address , token_amount ) in 
    let op : operation = Tezos.transaction (transfer_param) 0mutez transfer_smak in
    op

let power(x, y : nat * nat) : nat = 
    let rec multiply(acc, elt, last: nat * nat * nat ) : nat = if last = 0n then acc else multiply(acc * elt, elt, abs(last - 1n)) in
    multiply(1n, x, y)

let compute_new_rewards(current_week, week_indices, rate, weeks_max, total_reward, reward_at_week : nat * nat list * nat * nat * nat * nat list) : nat list =
    let update_reward_per_week (week_indice : nat) : nat =
        let t_before : nat = power(rate, abs(week_indice - 1n)) in  
        let t_before_divisor : nat = power(10_000n, abs(week_indice - 1n)) in
        let un_moins_rate : nat = abs(10_000n - rate) in 
        let m_10000_4 : nat = power(10_000n, abs(weeks_max - 1n)) in
        let numerator : nat = un_moins_rate * m_10000_4 in 
        let t_I_max : nat = power(rate, weeks_max) in 
        let m_10000_5 : nat = power(10_000n, weeks_max) in
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

    let rec reverse_list (lst, res : nat list * nat list) : nat list =
        match lst, res with
            [], _lst -> _lst
            |  hd1::tl1, _lst -> reverse_list(tl1, hd1 :: _lst)
    in


    let final_reward_list : nat list = update_rewards(week_indices, reward_at_week, empty_nat_list) in
    reverse_list(final_reward_list, empty_nat_list)

// ------------------
// -- ENTRY POINTS --
// ------------------
let set_admin(new_admin, storage : address * storage_farm) : return =
    let admin_address : address = storage.admin in
    let _check_if_admin : unit = assert_with_error (Tezos.sender = admin_address) only_admin in
    let _check_if_no_tez : unit = assert_with_error (Tezos.amount = 0tez) amount_must_be_zero_tez in
    let final_storage = { storage with admin = new_admin } in
    (no_operation, final_storage)

//TODO : Initialize
let increase_reward(value, storage : nat * storage_farm) : return =
    let total_weeks : nat = storage.total_weeks in
    let total_reward : nat = storage.total_reward in
    let current_time : timestamp = Tezos.now in
    let creation_time : timestamp = storage.creation_time in
    let delta : nat = value in
    let initialized_creation_time: timestamp = if (delta = 0n) then current_time else creation_time in
    let current_week : nat = get_current_week(storage) in
    let rate : nat = storage.rate in 
    let week_indices : nat list = get_weeks_indices(1n, total_weeks) in 
    let reward_at_week : nat list = storage.reward_at_week in

    let _check_if_admin : unit = assert_with_error (Tezos.sender = storage.admin) only_admin in
    let _check_if_no_tez : unit = assert_with_error (Tezos.amount = 0tez) amount_must_be_zero_tez in
    let _check_current_week : unit = assert_with_error (current_time < creation_time + int(total_weeks * week_in_seconds)) no_week_left in

    let folded (acc, elt: nat * nat) : nat = acc + elt in
    let sum_R : nat = List.fold folded reward_at_week 0n in
    let new_total_reward : nat = delta + abs(storage.total_reward - sum_R) in

    let new_reward_at_week : nat list = compute_new_rewards(current_week, week_indices, rate, total_weeks, total_reward, reward_at_week) in

    let final_storage = { storage with total_reward = new_total_reward ;
                                       reward_at_week = new_reward_at_week ;
                                       creation_time = initialized_creation_time } in
    (no_operation, final_storage)

let stake_some(lp_amount, s : nat * storage_farm) : return =
    let current_time : timestamp = Tezos.now in
    let sender_address : address = Tezos.sender in // Avoids recalculating Tezos.sender each time for gas
    let farm_points : nat list = s.farm_points in
    let user_points : (address, nat list) big_map = s.user_points in
    let total_weeks : nat = s.total_weeks in
    let lp_contract_opt : parameter contract option = Tezos.get_contract_opt(s.lp_token_address) in
    let lp_contract : parameter contract = match lp_contract_opt with
        | None -> (failwith(unknown_lp_contract) : parameter contract)
        | Some(x) -> x
    in
    let current_week : nat = get_current_week(s) in
    let endofweek_in_seconds : timestamp = s.creation_time + int(current_week * week_in_seconds) in

    let _check_if_no_tez : unit = assert_with_error (Tezos.amount = 0tez) amount_must_be_zero_tez in
    let _check_amount_positive : unit = assert_with_error (lp_amount > 0n) amount_is_null in // TODO : why ?
    let _check_current_week : unit = assert_with_error (current_time < s.creation_time + int(s.total_weeks * week_in_seconds)) no_week_left in
    let _check_in_week : unit = assert_with_error (current_time - endofweek_in_seconds < 0) time_too_early in

    // create a transfer transaction (for LP token contract)
    let transfer_param : transfer = { address_from = sender_address; address_to = Tezos.self_address; value = lp_amount } in 
    let op : operation = Tezos.transaction (Transfer(transfer_param)) 0mutez lp_contract in
    let operations : operation list = [ op; ] in
    // update current storage with updated user_stakes map
    let existing_bal_opt : nat option = Big_map.find_opt sender_address s.user_stakes in
    let new_user_stakes : (address, nat) big_map = match existing_bal_opt with
        | None -> Big_map.add sender_address lp_amount s.user_stakes
        | Some(v) -> Big_map.update sender_address (Some(lp_amount + v)) s.user_stakes
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



    let rec add_list(lst1, lst2, res : nat list * nat list * nat list) : nat list =
        match lst1, lst2 with
            [], [] -> res
            | [], _lst -> failwith "size don't match"
            | _lst, [] -> failwith "size don't match"
            | hd1::tl1, hd2::tl2 ->
                let new_hd : nat = hd1 + hd2 in
                add_list(tl1, tl2, new_hd :: res)
    in

    let rec reverse_list (lst, res : nat list * nat list) : nat list =
        match lst, res with
            [], _lst -> _lst
            |  hd1::tl1, _lst -> reverse_list(tl1, hd1 :: _lst)
    in

    let personal_user_points (user_points, sender_address : (address, nat list) big_map * address ) : nat list =
        match Big_map.find_opt sender_address user_points with
            | None -> new_points_by_weeks
            | Some(user_week_points) -> reverse_list(add_list(user_week_points, new_points_by_weeks, empty_nat_list), empty_nat_list)
    in

    let new_user_points : nat list = personal_user_points(user_points, sender_address) in
    let new_final_map : (address, nat list) big_map = Big_map.update sender_address (Some(new_user_points)) user_points in

    let new_farm_points : nat list = reverse_list(add_list(farm_points, new_points_by_weeks, empty_nat_list), empty_nat_list) in

    let final_storage = { s with user_stakes = new_user_stakes; user_points = new_final_map; farm_points = new_farm_points } in
    (operations, final_storage)

let unstake_some(lp_amount, s : nat * storage_farm) : return =
    let current_time : timestamp = Tezos.now in
    let current_week : nat = get_current_week(s) in
    let farm_points : nat list = s.farm_points in
    let user_points : (address, nat list) big_map = s.user_points in
    let total_weeks : nat = s.total_weeks in
    let _check_if_no_tez : unit = assert_with_error (Tezos.amount = 0tez) amount_must_be_zero_tez in
    let sender_address : address = Tezos.sender in // Avoids recalculating Tezos.sender each time for gas
    let endofweek_in_seconds : timestamp = s.creation_time + int(current_week * week_in_seconds) in 

    // update current storage with updated user_stakes map
    let existing_bal_opt : nat option = Big_map.find_opt sender_address s.user_stakes in
    let user_stakes : nat = match existing_bal_opt with
        | None -> (failwith(no_stakes): nat)
        | Some(v) -> v
    in
    let _check_lp_amount : unit = assert_with_error (user_stakes >= lp_amount) unstake_more_than_stake in
    let new_user_stakes : (address, nat) big_map = Big_map.update sender_address (Some(abs(user_stakes - lp_amount))) s.user_stakes in
    let lp_contract_opt : parameter contract option = Tezos.get_contract_opt(s.lp_token_address) in
    let lp_contract : parameter contract = match lp_contract_opt with
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

        let rec reverse_list (lst, res : nat list * nat list) : nat list =
            match lst, res with
                [], _lst -> _lst
                |  hd1::tl1, _lst -> reverse_list(tl1, hd1 :: _lst)
        in

        let new_points_by_weeks : nat list = calculate_new_points_by_week(total_weeks, empty_nat_list) in

        let rec substract_list(lst1, lst2, res : nat list * nat list * nat list) : nat list =
            match lst1, lst2 with
                [], [] -> res
                | [], _lst -> failwith "size don't match"
                | _lst, [] -> failwith "size don't match"
                | hd1::tl1, hd2::tl2 ->
                    let new_hd : nat = abs(hd1 - hd2) in
                    substract_list(tl1, tl2, new_hd :: res)
        in

        let personal_user_points (user_points, sender_address : (address, nat list) big_map * address ) : nat list =
            match Big_map.find_opt sender_address user_points with
                | None -> failwith "Some points should exist"    // TODO : refacto error & verify legitimity
                | Some(user_week_points) -> reverse_list(substract_list(user_week_points, new_points_by_weeks, empty_nat_list), empty_nat_list) 
        in

        let new_user_points : nat list = personal_user_points(user_points, sender_address) in
        let new_final_map : (address, nat list) big_map = Big_map.update sender_address (Some(new_user_points)) user_points in

        let new_farm_points : nat list = reverse_list(substract_list(farm_points, new_points_by_weeks, empty_nat_list), empty_nat_list)  in

        let final_storage = { s with user_stakes = new_user_stakes; user_points = new_final_map; farm_points = new_farm_points } in
        (operations, final_storage)

    else    

        let final_storage = { s with user_stakes = new_user_stakes} in
        (operations, final_storage)

let claim_all(s : storage_farm) : return = 
    let farm_points : nat list = s.farm_points in
    let user_points : (address, nat list) big_map = s.user_points in
    let sender_address : address = Tezos.sender in // Avoids recalculating Tezos.sender each time for gas

    let _check_if_no_tez : unit = assert_with_error (Tezos.amount = 0tez) amount_must_be_zero_tez in

    match Big_map.find_opt sender_address user_points with
            | None -> (no_operation, s)
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

                let total_reward_for_user : nat = aux( 0n, user_points, farm_points, s.reward_at_week) in

                let send_reward : operation = sendReward(total_reward_for_user, sender_address, s) in// TODO storage a enlever

                let new_user_points = List.map (fun (_i : nat) -> 0n) user_points in

                let user_points_map = Big_map.update sender_address (Some(new_user_points)) s.user_points in

                let final_storage = { s with user_points = user_points_map } in
                ([send_reward], final_storage)