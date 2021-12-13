#include "tzip-12/fa2_interface.mligo"
#include "tzip-12/fa2_errors.mligo"

type entity = {
    balance : nat
}
type entity_key = address * token_id
type ledger = (entity_key, entity) map

type tokens = {
    total_supply : nat;
    metadata : token_metadata;
}

type storage = { 
    paused : bool;
    ledger : ledger;
    //tokens : (token_id,tokens) map;
    operators : operator_param set;
    administrator : address;
    //permissions_descriptor : permissions_descriptor_aux;
}

type return = (operation list * storage)

type entry_points = 
  |  Set_pause of bool
  |  Set_administrator of address
  |  Mint of (address * nat * nat)

type total_entry_points = (fa2_entry_points, "fa2_ep", entry_points, "specific_ep") michelson_or

let set_pause(param,s : bool * storage): return =
    if Tezos.sender = s.administrator then
        (([] : operation list), { s with paused=param })
    else 
        (failwith("only admin can do it") : return)

let set_administrator(param,s : address * storage): return =
    if Tezos.sender = s.administrator then
        (([] : operation list), { s with administrator=param })
    else 
        (failwith("only admin can do it") : return)

let mint(param, s : (address * nat * nat) * storage) : return =
    if Tezos.sender = s.administrator then
        let new_ledger = Map.add (param.0, param.1) {balance=param.2} s.ledger in 
        (([] : operation list), { s with ledger=new_ledger })
    else 
        (failwith("only admin can do it") : return)

let balance_of (param, s : balance_of_param * storage) : return =
    let get_balance = fun ( i : balance_of_request) -> 
        match Map.find_opt (i.owner, i.token_id) s.ledger with
        | Some e -> { request = i ; balance = e.balance }
        | None -> (failwith("unknown owner") : balance_of_response)
    in
    let balance_of_callback_param : balance_of_response list = List.map get_balance param.requests in
    let destination: (balance_of_response list) contract = param.callback in
    let balance_of_response_operation : operation = Tezos.transaction balance_of_callback_param 0mutez destination in
    ([balance_of_response_operation], s)


// let total_supply(params, s: total_supply_param_michelson * storage) : return =
//     if s.paused = true then
//         (failwith("contract in pause") : return)
//     else 
//         let p : total_supply_param = Layout.convert_from_right_comb(params: total_supply_param_michelson) in
//         let token_ids : token_id list = p.token_ids in 
//         let get_total_supply = fun ( i : token_id) -> match Map.find_opt i s.tokens with
//             | Some v -> { token_id = i ; total_supply =v.total_supply }
//             | None -> (failwith(token_undefined) : total_supply_response)
//         in
//         let responses : total_supply_response list = List.map get_total_supply token_ids in 
//         let convert = fun ( r : total_supply_response) -> Layout.convert_to_right_comb(r) in
//         let ret : total_supply_response_michelson list = List.map convert responses in 
//         let destination: (total_supply_response_michelson list) contract = p.callback in
//         let op : operation = Tezos.transaction ret 0mutez destination in
//         ([ op ], s)

// let token_metadata(params, s: token_metadata_param_michelson * storage) : return =
//     if s.paused = true then
//         (failwith("contract in pause") : return)
//     else 
//         let p : token_metadata_param = Layout.convert_from_right_comb(params: token_metadata_param_michelson) in
//         let token_ids : token_id list = p.token_ids in 
//         let get_metadata = fun ( i : token_id) -> match Map.find_opt i s.tokens with
//             | Some v -> v.metadata
//             | None -> (failwith("unknown token_id") : token_metadata)
//         in
//         let responses : token_metadata list = List.map get_metadata token_ids in 
//         let convert = fun ( r : token_metadata) -> Layout.convert_to_right_comb(r) in
//         let ret : token_metadata_michelson list = List.map convert responses in 
//         let destination: (token_metadata_michelson list) contract = p.callback in
//         let op : operation = Tezos.transaction ret 0mutez destination in
//         ([ op ], s)

let transfer(_params, s: transfer list * storage) : return =
    let current_sender : address = Tezos.sender in
    if s.paused = true then
        (failwith("contract in pause") : return)
    else 
        let apply_transfer = fun (l,i : ledger * transfer) ->
            let from_ : address = i.from_ in               
            let transfers : transfer_destination list = i.txs in
            let apply_transfer_destination = fun (acc,j : (ledger * transfer_destination)) ->
                let transfer_destination : transfer_destination = j in 
                let tr_amount : nat = transfer_destination.amount in 
                let tr_to_ : address = transfer_destination.to_ in
                let tr_tokenid : token_id = transfer_destination.token_id in
                let sent_by_owner : bool = (current_sender = from_) or (current_sender = s.administrator) in
                let sent_by_operator : bool = Set.mem {owner=from_; operator=current_sender; token_id=tr_tokenid} s.operators in
                if sent_by_owner or sent_by_operator then
                    let temp_state_ledger : ledger = if tr_amount > 0n then
                        let enough_funds : bool = match Map.find_opt (from_, tr_tokenid) acc with
                            | Some bal -> (bal.balance >= tr_amount)
                            | None -> false
                        in
                        if enough_funds then
                            let l_updated_from : ledger = match Map.find_opt (from_,tr_tokenid) acc with
                            | Some bal -> Map.update (from_,tr_tokenid) (Some {balance=abs(bal.balance - tr_amount)} ) acc 
                            | None -> (failwith("should not arrive here") : ledger)
                            in
                            let l_updated_from_to : ledger = match Map.find_opt (tr_to_,tr_tokenid) l_updated_from with
                            | Some bal -> Map.update (tr_to_,tr_tokenid) (Some {balance=bal.balance + tr_amount}) l_updated_from 
                            | None -> Map.add (tr_to_,tr_tokenid) {balance=tr_amount} l_updated_from
                            in
                            l_updated_from_to
                        else
                            (failwith(fa2_insufficient_balance) : ledger)
                    else
                        (failwith("transferring nothing !") : ledger)
                    in 
                    temp_state_ledger
                else
                    (failwith(fa2_not_operator) : ledger)
            in
            List.fold apply_transfer_destination transfers l
        in
        let new_ledger : ledger = List.fold apply_transfer _params s.ledger in
        (([] : operation list), {s with ledger=new_ledger})



let update_operators (_params,s : (update_operator list * storage)) : return =
    let current_sender : address = Tezos.sender in
    if current_sender <> s.administrator then
        (failwith("operators can only be modified by the admin") : return)
    else
        let apply_order = fun (acc,j : operator_param set * update_operator) ->   
            match j with
            | Add_operator opm ->
                if (current_sender = opm.owner or current_sender = s.administrator) then
                    Set.add opm acc
                else
                    (failwith(fa2_operators_not_supported) : operator_param set)
            | Remove_operator opm -> 
                if (current_sender = opm.owner or current_sender = s.administrator) then
                    Set.remove opm acc
                else
                    (failwith(fa2_operators_not_supported) : operator_param set)
        in
        let new_operators : operator_param set = List.fold apply_order _params s.operators in
        (([] : operation list), {s with operators=new_operators})


let is_operator(params,s : (is_operator_param * storage)) : return =
    let op_param : operator_param = params.operator in
    let response : is_operator_response = {operator=params.operator; is_operator=Set.mem op_param s.operators} in
    let destination: (is_operator_response) contract = params.callback in
    let op : operation = Tezos.transaction response 0mutez destination in
    ([ op ], s)


// let send_permissions_descriptor(param,s : (permissions_descriptor_michelson contract * storage)) : return =
//     let response : permissions_descriptor_michelson = Layout.convert_to_right_comb(s.permissions_descriptor) in
//     let destination: permissions_descriptor_michelson contract = param in
//     let op : operation = Tezos.transaction response 0mutez destination in
//     ([ op ], s)

let main (param,s : total_entry_points * storage) : return =
  match param with 
  | M_left fa2_ep -> (match fa2_ep with 
    | Transfer l -> transfer (l, s)
    | Balance_of p -> balance_of (p, s)
//    | Total_supply p -> total_supply (p,s)
//    | Token_metadata p -> token_metadata (p,s)
//    | Permissions_descriptor callback -> send_permissions_descriptor (callback, s)
    | Update_operators l -> update_operators (l,s)
    | Is_operator o -> is_operator (o,s)
    )
  | M_right specific_ep -> (match specific_ep with
    | Set_pause p -> set_pause (p,s)
    | Set_administrator p -> set_administrator (p,s)
    | Mint pp -> mint(pp , s)
    )


///////////////////// deploy FA2  ////////////////////////////////////
// ligo compile contract src/contract/fa2/fa2_main.mligo > src/contract/fa2/fa2_main.tz
// ligo compile contract src/contract/fa2/fa2_main.mligo --michelson-format json > deploy/artefact/fa2.json

// (empty) ligo compile storage src/contract/fa2/fa2_main.mligo '{administrator=("tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5": address); ledger=(Map.empty:ledger); operators=(Set.empty:operator_param set); paused=false }'
// (empty) tezos-client originate contract fa2test transferring 1 from bootstrap1  running '/home/frank/smart-chain/SMAK-Farms/src/contract/fa2/fa2_main.tz' --init '(Pair (Pair "tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5" {}) {} False)' --dry-run
// (empty) tezos-client originate contract fa2test transferring 1 from bootstrap1  running '/home/frank/smart-chain/SMAK-Farms/src/contract/fa2/fa2_main.tz' --init '(Pair (Pair "tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5" {}) {} False)' --burn-cap 0.6205

// ligo compile storage src/contract/fa2/fa2_main.mligo '{administrator=("tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5": address); ledger=Map.literal[((("tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5": address), 1n), {balance=100n})]; operators=(Set.empty:operator_param set); paused=false }'
// => produces     (Pair (Pair "tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5" { Elt (Pair "tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5" 1) 100 }) {} False)
// tezos-client originate contract input_fa2 transferring 1 from bootstrap1  running '/home/frank/smart-chain/SMAK-Farms/src/contract/fa2/fa2_main.tz' --init '(Pair (Pair "tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5" { Elt (Pair "tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5" 1) 100 }) {} False)' --dry-run
// tezos-client originate contract input_fa2 transferring 1 from bootstrap1  running '/home/frank/smart-chain/SMAK-Farms/src/contract/fa2/fa2_main.tz' --init '(Pair (Pair "tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5" { Elt (Pair "tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5" 1) 100 }) {} False)' --burn-cap 0.6295



///////////////////// deploy FA2 (for reward) ////////////////////////////////////
// tezos-client originate contract reward_fa2 transferring 1 from bootstrap1  running '/home/frank/smart-chain/SMAK-Farms/src/contract/fa2/fa2_main.tz' --init '(Pair (Pair "tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5" { Elt (Pair "tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5" 1) 1 }) {} False)' --dry-run
// tezos-client originate contract reward_fa2 transferring 1 from bootstrap1  running '/home/frank/smart-chain/SMAK-Farms/src/contract/fa2/fa2_main.tz' --init '(Pair (Pair "tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5" { Elt (Pair "tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5" 1) 1 }) {} False)' --burn-cap 0.62925





///////////////////// deploy Farm  ////////////////////////////////////
// sudo docker run --rm -v "$PWD":"$PWD" -w "$PWD" ligolang/ligo:0.30.0 compile contract src/contract/farm/main.mligo  > src/contract/farm/farm.tz
// sudo docker run --rm -v "$PWD":"$PWD" -w "$PWD" ligolang/ligo:0.30.0 compile storage src/contract/farm/main.mligo '{admin=("tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5": address)}'
// sudo docker run --rm -v "$PWD":"$PWD" -w "$PWD" ligolang/ligo:0.30.0 compile storage src/contract/farm/main.mligo '{admin=("tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5": address); creation_time=Tezos.now; input_token_address=("KT1F3MvWANZxMP9cDFWpmgdnPxTMM1ZoTeAn": address); input_fa2_token_id_opt=1n; reward_token_address=("KT1AAqwMaZ1Zw82BABBohg2hG9WpMfeEAmzf": address); reward_fa2_token_id_opt=1n; reward_reserve_address=("tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5": address); rate=7500n; reward_at_week=([] : nat list); farm_points=([] : nat list); total_reward=10000000n; user_points=(Big_map.empty : (address, nat list) big_map); user_stakes=(Big_map.empty : (address, nat) big_map); total_weeks=5n}'


// admin=("tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5": address); 
// creation_time=Tezos.now;
// input_token_address=("KT1F3MvWANZxMP9cDFWpmgdnPxTMM1ZoTeAn": address);
// input_fa2_token_id_opt=1n;
// reward_token_address=("KT1AAqwMaZ1Zw82BABBohg2hG9WpMfeEAmzf": address);
// reward_fa2_token_id_opt=1n;
// reward_reserve_address=("tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5": address);
// rate=7500n;
// reward_at_week=([] : nat list);
// farm_points=([] : nat list);
// total_reward=10000000n;
// user_points=(Big_map.empty : (address, nat list) big_map);
// user_stakes=(Big_map.empty : (address, nat) big_map);
// total_weeks=5n