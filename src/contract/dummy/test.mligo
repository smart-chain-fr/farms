type storage = int
type parameter =
  Increment of int list
| Decrement of int
| Reset
type return = operation list * storage
// Two entrypoints
let add (store, deltas : storage * int list) : storage = 
    let apply_sum = fun (acc, val : int * int) -> acc + val in
    let values : int = List.fold apply_sum deltas 0 in
    store + values
let sub (store, delta : storage * int) : storage = store - delta
(* Main access point that dispatches to the entrypoints according to
   the smart contract parameter. *)
let main (action, store : parameter * storage) : return =
 ([] : operation list),    // No operations
 (match action with
   Increment (n) -> add (store, n)
 | Decrement (n) -> sub (store, n)
 | Reset         -> 0)



 // ligo dry-run src/contract/dummy/test.mligo main 'Increment([1; 2; -2;])' '7'