type farm_metadata = {
    lp_address : address;
    farm_lp_info : string
}

type farms_storage = {
    admin : address;
    all_farms : address set;
    all_farms_data : (address, farm_metadata) big_map;
    inverse_farms : (address, (address, string) map) big_map
}

type addFarmParameter = {
    farm_address: address;
    lp_address: address;
    farm_lp_info : string
}

type removeFarmParameter = {
    farm_address: address
}

type farms_entrypoints = 
| Add_farm of addFarmParameter
| Remove_farm of removeFarmParameter


let noOperations : operation list = []

type return_farms = operation list * farms_storage

let addFarm(p, s : addFarmParameter * farms_storage) : return_farms =
    let _check_admin : bool = if Tezos.sender = s.admin then true else (failwith("Only admin") : bool) in
    let _check_amount : bool = if Tezos.amount > 0tez then (failwith("This smart contract does not accept tez") : bool) else true in
    let modified_set : address set = Set.add p.farm_address s.all_farms in 
    let modified_map : (address, farm_metadata) big_map = Big_map.add p.farm_address { lp_address = p.lp_address; farm_lp_info = p.farm_lp_info } s.all_farms_data in
    let modified_inverse_map : (address, (address, string) map) big_map = 
        match Big_map.find_opt p.lp_address s.inverse_farms  with
        | None -> Big_map.add p.lp_address (Map.add p.farm_address p.farm_lp_info (Map.empty : (address, string)map)) s.inverse_farms
        | Some(farms) -> Big_map.add p.lp_address (Map.add p.farm_address p.farm_lp_info farms) s.inverse_farms
    in
    (noOperations, { s with all_farms = modified_set; all_farms_data = modified_map; inverse_farms = modified_inverse_map })

let removeFarm(p, s : removeFarmParameter * farms_storage) : return_farms =
    let _check_admin : bool = if Tezos.sender = s.admin then true else (failwith("Only admin") : bool) in
    let _check_amount : bool = if Tezos.amount > 0tez then (failwith("This smart contract does not accept tez") : bool) else true in
    let corresponding_lp_address : address = match Map.find_opt p.farm_address s.all_farms_data with
    | None -> (failwith("unknown farm") : address)
    | Some(metadata) -> metadata.lp_address
    in
    let modified_set : address set = Set.remove p.farm_address s.all_farms in 
    let modified_map : (address, farm_metadata) big_map = Big_map.update p.farm_address (None : farm_metadata option) s.all_farms_data in
    let modified_inverse_map : (address, (address, string) map) big_map = 
        match Big_map.find_opt corresponding_lp_address s.inverse_farms  with
//        | None -> (failwith("lp_address parameter is not initialized in inverse_farms") : (address, (address, string) map) big_map)
        | None -> s.inverse_farms
        | Some(farms) -> Big_map.update corresponding_lp_address (Some(Map.update p.farm_address (None : string option) farms)) s.inverse_farms
    in
    (noOperations, { s with all_farms = modified_set; all_farms_data = modified_map; inverse_farms = modified_inverse_map })

let main(action, store : farms_entrypoints * farms_storage) : return_farms =
    match action with
    | Add_farm(fp) -> addFarm(fp, store)
    | Remove_farm(fp) -> removeFarm(fp, store)


