#include "types.mligo"
#include "error.mligo"

// -----------------
// --  DEBUG  --
// -----------------
let rec print_elt_list (lst, indice : nat list * nat) : unit = 
    if indice = 0n then 
        match List.head_opt lst with
        | None -> failwith("[print_elt_list] indice out of bound")
        | Some(elt) -> failwith(elt)
    else
        match List.tail_opt lst with
        | None -> failwith("[print_elt_list] unreachable")
        | Some(tl) -> print_elt_list(tl, abs(indice - 1n))
        
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
let get_current_week (storage : storage_farm) : nat = 
    let delay : nat = abs(Tezos.now - storage.creation_time) in
    delay / week_in_seconds + 1n

let sendReward (token_amount : nat) (user_address : address) (reward_token_address : address) (reward_reserve_address : address) (reward_fa2_token_id_opt : nat option) : operation = 
    match reward_fa2_token_id_opt with
    | None -> //use FA12
        let fa12_contract_opt : fa12_transfer contract option = Tezos.get_entrypoint_opt "%transfer" reward_token_address in
        let transfer_fa12 : fa12_transfer contract = match fa12_contract_opt with
        | Some c -> c
        | None -> (failwith unknown_reward_token_entrypoint: fa12_transfer contract)
        in
        let transfer_param : fa12_transfer = reward_reserve_address, (user_address , token_amount) in 
        let op : operation = Tezos.transaction (transfer_param) 0mutez transfer_fa12 in
        op
    | Some(reward_fa2_token_id) -> // use FA2 
        let fa2_contract_opt : fa2_transfer contract option = Tezos.get_entrypoint_opt "%transfer" reward_token_address in
        let transfer_fa2 : fa2_transfer contract = match fa2_contract_opt with
        | Some c -> c
        | None -> (failwith unknown_reward_token_entrypoint: fa2_transfer contract)
        in
        let transfer_fa2_param : fa2_transfer = reward_reserve_address, (user_address, reward_fa2_token_id, token_amount) in 
        let op_fa2 : operation = Tezos.transaction (transfer_fa2_param) 0mutez transfer_fa2 in
        op_fa2


// let power (x : nat) (y : nat) : nat = 
//     let rec multiply(acc, elt, last: nat * nat * nat ) : nat = 
//         if last = 0n then acc 
//         else multiply(acc * elt, elt, abs(last - 1n))
//     in
//     multiply(1n, x, y)

let power (x, y : nat * nat) : nat = 
    let rec multiply(acc, elt, last: nat * nat * nat ) : nat = if last = 0n then acc else multiply(acc * elt, elt, abs(last - 1n)) in
    multiply(1n, x, y)
    
let rec reverse_list (lst, res : nat list * nat list) : nat list =
    match lst, res with
    [], _lst -> _lst
    |  hd1::tl1, _lst -> reverse_list(tl1, hd1 :: _lst)

let add_or_subtract_list (lst1 : nat list) (lst2 : nat list) (is_added : bool) : nat list =
    let rec merge_list (lst1, lst2, res : nat list * nat list * nat list) : nat list =
        match lst1, lst2 with
        [], [] -> res
        | [], _lst -> failwith "size don't match"
        | _lst, [] -> failwith "size don't match"
        | hd1::tl1, hd2::tl2 ->
            let new_hd : nat = if (is_added = true) then hd1 + hd2 else abs(hd1 - hd2) in
            merge_list(tl1, tl2, new_hd :: res)
    in
    reverse_list(merge_list(lst1, lst2, empty_nat_list), empty_nat_list)

let compute_new_rewards (total_reward:nat) (week_number:nat) (rate:nat) : nat list =
    let update_reward_per_week (week_indice : nat) : nat =
        let t_before : nat = power(rate, abs(week_indice - 1n)) in  
        let t_before_divisor : nat = power(10_000n, abs(week_indice - 1n)) in
        let un_moins_rate : nat = abs(10_000n - rate) in 
        let m_10000_4 : nat = power(10_000n, abs(week_number - 1n)) in
        let numerator : nat = un_moins_rate * m_10000_4 in 
        let t_I_max : nat = power(rate, week_number) in 
        let m_10000_5 : nat = power(10_000n, week_number) in
        let denominator : nat = abs(m_10000_5 - t_I_max) in
        let final_denominator : nat = t_before_divisor * denominator in 
        let final_numerator : nat = numerator * total_reward * t_before in 
        final_numerator / final_denominator
    in
    let rec create_reward_list (week_indice, res : nat * nat list ) : nat list =
        if (week_indice = 0n) then res
        else 
            create_reward_list (abs(week_indice - 1n), update_reward_per_week(week_indice) :: res)
    in
    
    create_reward_list(week_number, empty_nat_list)


// ------------------
// -- ENTRY POINTS --
// ------------------
let set_admin (storage : storage_farm) (new_admin : address) : return =
    let admin_address : address = storage.admin in
    let _check_if_admin : unit = assert_with_error (Tezos.sender = admin_address) only_admin in
    let _check_if_no_tez : unit = assert_with_error (Tezos.amount = 0tez) amount_must_be_zero_tez in
    let final_storage = { storage with admin = new_admin } in
    (no_operation, final_storage)

let initialize (storage : storage_farm) : return =
    let creation_time : timestamp = storage.creation_time in
    let initialized_creation_time : timestamp = Tezos.now in
    let _current_week : nat = get_current_week(storage) in
    let rate : nat = storage.rate in 
    let total_weeks : nat = storage.total_weeks in
    let total_reward : nat = storage.total_reward in
    let reward_at_week : nat list = storage.reward_at_week in

    let _check_if_admin : unit = assert_with_error (Tezos.sender = storage.admin) only_admin in
    let _check_if_no_tez : unit = assert_with_error (Tezos.amount = 0tez) amount_must_be_zero_tez in
    let _check_current_week : unit = assert_with_error (initialized_creation_time < creation_time + int(week_in_seconds)) no_week_left in
    let _check_if_unitialized : unit = assert_with_error (List.size reward_at_week = 0n) contract_already_initialized in

    let new_reward_at_week : nat list = compute_new_rewards total_reward total_weeks rate in
    
    let final_storage = { storage with reward_at_week = new_reward_at_week ;
                                       creation_time = initialized_creation_time } in
    (no_operation, final_storage)

let increase_reward (storage : storage_farm) (added_new_reward : nat ) : return =
    let total_weeks : nat = storage.total_weeks in
    let total_reward : nat = storage.total_reward in
    let current_time : timestamp = Tezos.now in
    let creation_time : timestamp = storage.creation_time in
    let delta : nat = added_new_reward in
    let initialized_creation_time: timestamp = if (delta = 0n) then current_time else creation_time in
    let current_week : nat = get_current_week(storage) in
    let rate : nat = storage.rate in 
    let reward_at_week : nat list = storage.reward_at_week in

    let _check_if_admin : unit = assert_with_error (Tezos.sender = storage.admin) only_admin in
    let _check_if_no_tez : unit = assert_with_error (Tezos.amount = 0tez) amount_must_be_zero_tez in
    let _check_current_week : unit = assert_with_error (current_time < creation_time + int(total_weeks * week_in_seconds)) no_week_left in
    let _check_if_positive : unit = assert_with_error (added_new_reward > 0n) increase_amount_is_null in

    let remaining_weeks : nat = abs(total_weeks - current_week) + 1n in
    let new_reward_at_week : nat list = compute_new_rewards added_new_reward remaining_weeks rate in

    let rec create_list (lst, acc : nat list * nat) : nat list =
        if acc = 0n then lst
        else create_list( 0n :: lst, abs(acc - 1n))
    in

    let new_list_to_add = create_list(new_reward_at_week, abs(current_week-1n)) in

    let final_reward_at_week = add_or_subtract_list reward_at_week new_list_to_add add in
    
    let final_storage = { storage with total_reward = total_reward + added_new_reward ;
                                       reward_at_week = final_reward_at_week ;
                                       creation_time = initialized_creation_time } in
    (no_operation, final_storage)

let stake_some (storage : storage_farm) (lp_amount : nat) : return =
    let input_token_address : address = storage.input_token_address in
    let current_time : timestamp = Tezos.now in
    let sender_address : address = Tezos.sender in // Avoids recalculating Tezos.sender each time for gas
    let farm_points : nat list = storage.farm_points in
    let user_points : (address, nat list) big_map = storage.user_points in
    let total_weeks : nat = storage.total_weeks in
    let current_week : nat = get_current_week(storage) in
    let endofweek_in_seconds : timestamp = storage.creation_time + int(current_week * week_in_seconds) in

    let _check_if_no_tez : unit = assert_with_error (Tezos.amount = 0tez) amount_must_be_zero_tez in
    let _check_amount_positive : unit = assert_with_error (lp_amount > 0n) amount_is_null in
    let _check_current_week : unit = assert_with_error (current_time < storage.creation_time + int(storage.total_weeks * week_in_seconds)) no_week_left in
    let _check_in_week : unit = assert_with_error (current_time - endofweek_in_seconds < 0) time_too_early in

    // create a transfer transaction (for LP token contract)
    let operations : operation list = match storage.input_fa2_token_id_opt with 
    | None -> // FA12 
        let smak_contract_opt : fa12_transfer contract option = Tezos.get_entrypoint_opt "%transfer" input_token_address in
        let transfer_fa12 : fa12_transfer contract = match smak_contract_opt with
        | Some c -> c
        | None -> (failwith unknown_input_token_entrypoint:  fa12_transfer contract)
        in
        let transfer_param : fa12_transfer = sender_address, (Tezos.self_address, lp_amount ) in 
        let op : operation = Tezos.transaction (transfer_param) 0mutez transfer_fa12 in
        [ op; ]
    | Some(tokenid) -> // FA2
        let input_fa2_contract_opt : fa2_transfer contract option = Tezos.get_entrypoint_opt "%transfer" input_token_address in
        let transfer_fa2 : fa2_transfer contract = match input_fa2_contract_opt with
        | Some c -> c
        | None -> (failwith unknown_input_token_entrypoint:  fa2_transfer contract)
        in
        let transfer_fa2_param : fa2_transfer = sender_address, (Tezos.self_address, tokenid, lp_amount) in 
        let op_fa2 : operation = Tezos.transaction (transfer_fa2_param) 0mutez transfer_fa2 in
        [ op_fa2; ]
    in
    
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
        | Some(user_week_points) -> 
            add_or_subtract_list user_week_points new_points_by_weeks add
    in
    let new_staked_user_points : nat list = personal_user_points(user_points, sender_address) in
    let new_user_points : (address, nat list) big_map = Big_map.update sender_address (Some(new_staked_user_points)) user_points in
    let new_farm_points : nat list = 
        if (List.size farm_points) = 0n then new_staked_user_points
        else add_or_subtract_list farm_points new_points_by_weeks add
    in
    let final_storage = { storage with user_stakes = new_user_stakes; user_points = new_user_points; farm_points = new_farm_points } in
    (operations, final_storage)

let unstake_some (storage : storage_farm) (lp_amount : nat) : return =
    let input_token_address : address = storage.input_token_address in
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

    // create a transfer transaction (for LP token contract)
    let operations : operation list = match storage.input_fa2_token_id_opt with 
    | None -> // FA12
        let lp_contract_opt : fa12_transfer contract option = Tezos.get_entrypoint_opt "%transfer" input_token_address in
        let transfer_fa12 : fa12_transfer contract = match lp_contract_opt with
        | Some c -> c
        | None -> (failwith unknown_input_token_entrypoint: fa12_transfer contract)
        in
        let transfer_fa12_param : fa12_transfer = Tezos.self_address,  (sender_address , lp_amount ) in    
        let op_fa12 : operation = Tezos.transaction (transfer_fa12_param) 0mutez transfer_fa12 in
        [ op_fa12; ]
    | Some (tokenid) -> // FA2
        let lp_contract_fa2_opt : fa2_transfer contract option = Tezos.get_entrypoint_opt "%transfer" input_token_address in
        let transfer_fa2 : fa2_transfer contract = match lp_contract_fa2_opt with
        | Some c -> c
        | None -> (failwith unknown_input_token_entrypoint: fa2_transfer contract)
        in
        let transfer_fa2_param : fa2_transfer = Tezos.self_address, (sender_address, tokenid, lp_amount) in    
        let op_fa2 : operation = Tezos.transaction (transfer_fa2_param) 0mutez transfer_fa2 in
        [ op_fa2; ]
    in

    if (current_time < endofweek_in_seconds ) then

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
            | Some(user_week_points) -> add_or_subtract_list user_week_points new_points_by_weeks subtract
        in

        let new_user_points : nat list = personal_user_points(user_points, sender_address) in
        let final_user_points : (address, nat list) big_map = Big_map.update sender_address (Some(new_user_points)) user_points in
        let new_farm_points : nat list = add_or_subtract_list farm_points new_points_by_weeks subtract in

        let final_storage = { storage with user_stakes = new_user_stakes; user_points = final_user_points; farm_points = new_farm_points } in
        (operations, final_storage)

    else    

        let final_storage = { storage with user_stakes = new_user_stakes} in
        (operations, final_storage)

let claim_all (storage : storage_farm) : return = 
    let farm_points : nat list = storage.farm_points in
    let user_points : (address, nat list) big_map = storage.user_points in
    let sender_address : address = Tezos.sender in // Avoids recalculating Tezos.sender each time for gas
    let reward_token_address : address = storage.reward_token_address in
    let reward_fa2_token_id_opt : nat option = storage.reward_fa2_token_id_opt in
    let reward_reserve_address : address = storage.reward_reserve_address in
    let current_week : nat = get_current_week(storage) in

    let _check_if_first_week : unit = assert_with_error (current_week > 1n) no_claim_first_week in
    let _check_if_no_tez : unit = assert_with_error (Tezos.amount = 0tez) amount_must_be_zero_tez in

    let elapsed_weeks : nat = abs(current_week-1n) in

    match Big_map.find_opt sender_address user_points with
    | None -> (no_operation, storage)
    | Some(user_points) ->
        let rec compute_total_reward (acc, elapsed_weeks, user_points, farm_points, reward_at_weeks : nat * nat * nat list * nat list * nat list) : nat =
            match user_points, farm_points, reward_at_weeks with 
            [], [], [] -> acc
            | [], lst2, lst3 -> failwith "size don't match"
            | lst1, [], lst3 -> failwith "size don't match"
            | lst1, lst2, [] -> failwith "size don't match"
            | hd1::tl1, hd2::tl2, hd3::tl3 ->
                if elapsed_weeks > 0n then
                    if hd2 = 0n then compute_total_reward (acc, abs(elapsed_weeks-1n), tl1, tl2, tl3)
                    else
                        let acc = acc + hd1 * hd3 / hd2 in
                        compute_total_reward (acc, abs(elapsed_weeks-1n), tl1, tl2, tl3)
                else acc
        in

        let total_reward_for_user : nat = compute_total_reward(0n, elapsed_weeks, user_points, farm_points, storage.reward_at_week) in
        let send_reward : operation = sendReward total_reward_for_user sender_address reward_token_address reward_reserve_address reward_fa2_token_id_opt in

        if (total_reward_for_user = 0n) then (no_operation, storage)
        else
            let rec create_new_user_point (new_user_points, elapsed_weeks, user_points : nat list * nat * nat list) : nat list =
                match user_points with
                [] -> new_user_points
                | hd1::tl1 ->
                    if elapsed_weeks > 0n then create_new_user_point(0n::new_user_points, abs(elapsed_weeks - 1n), tl1)
                    else create_new_user_point(hd1::new_user_points, elapsed_weeks , tl1)
            in

            let new_user_points : nat list = reverse_list(create_new_user_point (empty_nat_list, elapsed_weeks, user_points), empty_nat_list) in
            let user_points_map = Big_map.update sender_address (Some(new_user_points)) storage.user_points in

            let final_storage = { storage with user_points = user_points_map } in
            ([send_reward], final_storage)