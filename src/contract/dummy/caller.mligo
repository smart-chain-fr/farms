type storage = address
type fa2_transfer_destination = address * (nat * nat)
type fa2_transfer = address * fa2_transfer_destination list
type fa2_transfer_list = fa2_transfer list

type parameter =
  CallTransfer of (address * nat * nat)
| Donothing of unit

type return = operation list * storage

let call_transfer(param,s : (address * nat * nat) * storage) : return =
    let fa2_contract_opt : fa2_transfer_list contract option = Tezos.get_entrypoint_opt "%transfer" s in
    let transfer_fa2 : fa2_transfer_list contract = match fa2_contract_opt with
    | Some c -> c
    | None -> (failwith "unknown entrypoint":  fa2_transfer_list contract)
    in
    let transfer_fa2_all_dest : fa2_transfer_destination list = [(param.0, (param.1, param.2))] in
    let transfer_fa2_param : fa2_transfer = Tezos.sender, transfer_fa2_all_dest in 
    let transfer_fa2_full : fa2_transfer_list = [ transfer_fa2_param; ] in
    let op_fa2 : operation = Tezos.transaction (transfer_fa2_full) 0mutez transfer_fa2 in
    ([ op_fa2; ], s)

(* Main access point that dispatches to the entrypoints according to
   the smart contract parameter. *)
let main (action, store : parameter * storage) : return =
    match action with
        CallTransfer (n) -> call_transfer (n, store)
        | Donothing         -> (([] : operation list), store)



 // ligo compile contract src/contract/dummy/caller.mligo
 // ligo compile contract src/contract/dummy/caller.mligo > src/contract/dummy/caller.tz
 // ligo compile storage src/contract/dummy/caller.mligo '("KT1WjaNHUpXiNutsDLWJugkvT7WtvWWtppg6" : address)'

// ligo compile parameter src/contract/dummy/caller.mligo 'CallTransfer(("tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5" : address), 1n, 10n)'
// => produces (Left (Pair (Pair "tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5" 1) 10))

// ./tezos-client get contract storage for dummy_fa2

// ./tezos-client originate contract dummy_caller_fa2 transferring 1 from test_account running '/home/frank/smart-chain/SMAK-Farms/src/contract/dummy/caller.tz' --init '"KT1WjaNHUpXiNutsDLWJugkvT7WtvWWtppg6"' --dry-run
// CALLTRANSFER
// ./tezos-client transfer 0 from test_account to dummy_caller_fa2 --arg '(Left (Pair (Pair "tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5" 1) 10))'
