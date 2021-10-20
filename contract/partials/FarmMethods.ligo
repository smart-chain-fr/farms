#include "Error.ligo"
#include "FarmTypes.ligo"
//#include "../main/fa12.mligo"

// Should update the admin
// Params : admin (address) 
function setAdmin(const admin : address; var s : storage) : return is
block {
    if Tezos.sender = s.admin then s.admin := admin
    else failwith(only_admin);
} with (noOperations, s)

function stakeSome(const lp_amount : nat; const s : storage) : return is
block {
    const lp_contract : option(contract(parameter)) = Tezos.get_contract_opt(s.lp_token_address);
    const op : operation = Tezos.transaction(Transfer(Tezos.sender, s.reserve_address, lp_amount), 0mutez, lp_contract);
    const ops : list(operations) = list op end;
} with (ops, s)