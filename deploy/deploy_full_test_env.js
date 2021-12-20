"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    Object.defineProperty(o, k2, { enumerable: true, get: function() { return m[k]; } });
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (_) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
exports.__esModule = true;
var signer_1 = require("@taquito/signer");
var taquito_1 = require("@taquito/taquito");
var farm_json_1 = __importDefault(require("./artefact/farm.json"));
var fa12_json_1 = __importDefault(require("./artefact/fa12.json"));
var fa2_json_1 = __importDefault(require("./artefact/fa2.json"));
var database_json_1 = __importDefault(require("./artefact/database.json"));
var dotenv = __importStar(require("dotenv"));
dotenv.config(({ path: __dirname + '/.env.farm_fa12_fa2' }));
var rpc = process.env.RPC; //"http://127.0.0.1:8732"
var pk = "edskRuatoqjfYJ2iY6cMKtYakCECcL537iM7U21Mz4ieW3J51L9AZcHaxziWPZSEq4A8hu5e5eJzvzTY1SdwKNF8Pkpg5M6Xev";
var Tezos = new taquito_1.TezosToolkit(rpc);
var signer = new signer_1.InMemorySigner(pk);
Tezos.setProvider({ signer: signer });
var database_address = process.env.FARMSDB_ADDRESS || undefined; //"KT1HCLH3bCGnVrjZuVwP8aScgdMNr9qbjmSf";
var admin = process.env.ADMIN_ADDRESS; //"tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5";
var creation_time = new Date();
var farm_points = [];
var input_token_address = process.env.INPUT_CONTRACT_ADDRESS; //'KT1V5U9hTaXArCKLAW2HC41epX8BXoZaFEQE';
var input_token_id = process.env.INPUT_TOKEN_ID || undefined; //1;
var reward_fa2_token_id = process.env.REWARD_TOKEN_ID || undefined; //1;
var reward_token_address = process.env.REWARD_CONTRACT_ADDRESS; //"KT1WUc6Q1V8XzikB8qgQbCwL7PdWvJLEZE9s"
var reward_reserve_address = process.env.REWARD_RESERVE_ADDRESS; //"tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5";
var infoFarm = process.env.INFOFARM || '';
var rate = process.env.RATE || 9500;
var reward_at_week = [];
var rewards = process.env.REWARD_AMOUNT; //50000000;
var user_points = new taquito_1.MichelsonMap();
var user_stakes = new taquito_1.MichelsonMap();
var total_weeks = process.env.WEEKS; //5;
var farm_address = process.env.FARM_ADDRESS || undefined;
// For FA1.2 input
var fa12_input_tokens = new taquito_1.MichelsonMap();
var fa12_input_allowances = new taquito_1.MichelsonMap();
var fa12_input_total_supply = process.env.INPUT_FA12_TOTAL_SUPPLY || 20000;
var fa12_input_metadata = new taquito_1.MichelsonMap();
var fa12_input_token_metadata = new taquito_1.MichelsonMap();
// For FA2 input
var fa2_input_paused = false;
var fa2_input_ledger = new taquito_1.MichelsonMap();
var fa2_input_operators_init = [];
// For FA1.2 reward
var fa12_reward_tokens = new taquito_1.MichelsonMap();
var fa12_reward_allowances = new taquito_1.MichelsonMap();
var fa12_reward_total_supply = process.env.REWARD_AMOUNT || 30000000;
var fa12_reward_metadata = new taquito_1.MichelsonMap();
var fa12_reward_token_metadata = new taquito_1.MichelsonMap();
// FA2 reward
var fa2_reward_paused = false;
var fa2_reward_ledger = new taquito_1.MichelsonMap();
var fa2_reward_operators_init = [];
fa2_reward_ledger.set({ 0: reward_reserve_address, 1: reward_fa2_token_id }, rewards);
// database
var database_all_farms = new Array();
var database_all_farms_data = new taquito_1.MichelsonMap();
var database_inverse_farms = new taquito_1.MichelsonMap();
function orig() {
    return __awaiter(this, void 0, void 0, function () {
        var farm_store, fa2_input_store, fa2_reward_store, fa12_input_store, fa12_reward_store, database_store, fa12_input_originated, fa2_input_originated, fa12_reward_originated, fa2_reward_originated, database_originated, farm_originated, op, database_contract, op3, error_1;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    farm_store = {
                        'admin': admin,
                        'creation_time': creation_time,
                        'farm_points': farm_points,
                        'input_token_address': input_token_address,
                        'input_fa2_token_id_opt': input_token_id,
                        'reward_fa2_token_id_opt': reward_fa2_token_id,
                        'reward_token_address': reward_token_address,
                        'reward_reserve_address': reward_reserve_address,
                        'rate': rate,
                        'reward_at_week': reward_at_week,
                        'total_reward': rewards,
                        'user_points': user_points,
                        'user_stakes': user_stakes,
                        'total_weeks': total_weeks
                    };
                    fa2_input_store = {
                        'paused': fa2_input_paused,
                        'ledger': fa2_input_ledger,
                        //'tokens' : token_metadata,
                        'operators': fa2_input_operators_init,
                        'administrator': admin
                    };
                    fa2_reward_store = {
                        'paused': fa2_reward_paused,
                        'ledger': fa2_reward_ledger,
                        //'tokens' : token_metadata,
                        'operators': fa2_reward_operators_init,
                        'administrator': admin
                    };
                    fa12_input_store = {
                        'tokens': fa12_input_tokens,
                        'allowances': fa12_input_allowances,
                        'admin': admin,
                        'total_supply': fa12_input_total_supply,
                        'metadata': fa12_input_metadata,
                        'token_metadata': fa12_input_token_metadata
                    };
                    fa12_reward_store = {
                        'tokens': fa12_reward_tokens,
                        'allowances': fa12_reward_allowances,
                        'admin': admin,
                        'total_supply': fa12_reward_total_supply,
                        'metadata': fa12_reward_metadata,
                        'token_metadata': fa12_reward_token_metadata
                    };
                    database_store = {
                        'admin': admin,
                        'all_farms': database_all_farms,
                        'all_farms_data': database_all_farms_data,
                        'inverse_farms': database_inverse_farms
                    };
                    _a.label = 1;
                case 1:
                    _a.trys.push([1, 24, , 25]);
                    if (!(input_token_id === undefined)) return [3 /*break*/, 4];
                    return [4 /*yield*/, Tezos.contract.originate({
                            code: fa12_json_1["default"],
                            storage: fa12_input_store
                        })];
                case 2:
                    fa12_input_originated = _a.sent();
                    console.log("Waiting for FA1.2 (as input) " + fa12_input_originated.contractAddress + " to be confirmed...");
                    return [4 /*yield*/, fa12_input_originated.confirmation(2)];
                case 3:
                    _a.sent();
                    console.log('confirmed fa12: ', fa12_input_originated.contractAddress);
                    input_token_address = fa12_input_originated.contractAddress;
                    farm_store.input_token_address = input_token_address;
                    return [3 /*break*/, 7];
                case 4: return [4 /*yield*/, Tezos.contract.originate({
                        code: fa2_json_1["default"],
                        storage: fa2_input_store
                    })];
                case 5:
                    fa2_input_originated = _a.sent();
                    console.log("Waiting for FA2 (as input) " + fa2_input_originated.contractAddress + " to be confirmed...");
                    return [4 /*yield*/, fa2_input_originated.confirmation(2)];
                case 6:
                    _a.sent();
                    console.log('confirmed fa2: ', fa2_input_originated.contractAddress);
                    input_token_address = fa2_input_originated.contractAddress;
                    farm_store.input_token_address = input_token_address;
                    _a.label = 7;
                case 7:
                    if (!(reward_fa2_token_id === undefined)) return [3 /*break*/, 10];
                    return [4 /*yield*/, Tezos.contract.originate({
                            code: fa12_json_1["default"],
                            storage: fa12_reward_store
                        })];
                case 8:
                    fa12_reward_originated = _a.sent();
                    console.log("Waiting for FA1.2 (as reward) " + fa12_reward_originated.contractAddress + " to be confirmed...");
                    return [4 /*yield*/, fa12_reward_originated.confirmation(2)];
                case 9:
                    _a.sent();
                    console.log('confirmed fa12 (as reward): ', fa12_reward_originated.contractAddress);
                    reward_token_address = fa12_reward_originated.contractAddress;
                    farm_store.reward_token_address = reward_token_address;
                    return [3 /*break*/, 13];
                case 10: return [4 /*yield*/, Tezos.contract.originate({
                        code: fa2_json_1["default"],
                        storage: fa2_reward_store
                    })];
                case 11:
                    fa2_reward_originated = _a.sent();
                    console.log("Waiting for FA2 (as reward) " + fa2_reward_originated.contractAddress + " to be confirmed...");
                    return [4 /*yield*/, fa2_reward_originated.confirmation(2)];
                case 12:
                    _a.sent();
                    console.log('confirmed fa2: ', fa2_reward_originated.contractAddress);
                    reward_token_address = fa2_reward_originated.contractAddress;
                    farm_store.reward_token_address = reward_token_address;
                    _a.label = 13;
                case 13: return [4 /*yield*/, Tezos.contract.originate({
                        code: database_json_1["default"],
                        storage: database_store
                    })];
                case 14:
                    database_originated = _a.sent();
                    console.log("Waiting for farm database " + database_originated.contractAddress + " to be confirmed...");
                    return [4 /*yield*/, database_originated.confirmation(2)];
                case 15:
                    _a.sent();
                    console.log("FARMS DATABASE=", database_originated.contractAddress);
                    database_address = database_originated.contractAddress;
                    return [4 /*yield*/, Tezos.contract.originate({
                            code: farm_json_1["default"],
                            storage: farm_store
                        })];
                case 16:
                    farm_originated = _a.sent();
                    console.log("Waiting for farm " + farm_originated.contractAddress + " to be confirmed...");
                    return [4 /*yield*/, farm_originated.confirmation(2)];
                case 17:
                    _a.sent();
                    console.log('confirmed farm: ', farm_originated.contractAddress);
                    farm_address = farm_originated.contractAddress;
                    return [4 /*yield*/, Tezos.contract.at(farm_address)];
                case 18: return [4 /*yield*/, (_a.sent()).methods.initialize().send()];
                case 19:
                    op = _a.sent();
                    console.log("Waiting for initialize() " + op.hash + " to be confirmed...");
                    return [4 /*yield*/, op.confirmation(3)];
                case 20:
                    _a.sent();
                    console.log('confirmed initialize(): ', op.hash);
                    // update_operators transaction must be sent by <reward_reserve_address> 
                    // const op2 = await (await Tezos.contract.at(reward_token_address)).methods.update_operators([{add_operator: {owner:reward_reserve_address, operator: farmAddress, token_id:reward_fa2_token_id}}]).send();
                    // console.log(`Waiting for update_operators ${op2.hash} to be confirmed...`);
                    // await op2.confirmation(3);
                    // console.log('confirmed update_operators: ', op2.hash);
                    console.log("update_operators transaction must be sent by <reward_reserve_address> ");
                    console.log("update_operators([{add_operator: {owner:reward_reserve_address, operator: farmAddress, token_id:reward_fa2_token_id}}])");
                    return [4 /*yield*/, Tezos.contract.at(database_address)];
                case 21:
                    database_contract = _a.sent();
                    return [4 /*yield*/, database_contract.methods.add_farm(farm_address, infoFarm, input_token_address).send()];
                case 22:
                    op3 = _a.sent();
                    console.log("Waiting for addFarm " + op3.hash + " to be confirmed...");
                    return [4 /*yield*/, op3.confirmation(3)];
                case 23:
                    _a.sent();
                    console.log('confirmed addFarm: ', op3.hash);
                    console.log("./tezos-client remember contract fa12_input", input_token_address);
                    console.log("./tezos-client remember contract fa2_reward", reward_token_address);
                    console.log("./tezos-client remember contract database", database_address);
                    console.log("./tezos-client remember contract farm_fa12_fa2", farm_address);
                    return [3 /*break*/, 25];
                case 24:
                    error_1 = _a.sent();
                    console.log(error_1);
                    return [3 /*break*/, 25];
                case 25: return [2 /*return*/];
            }
        });
    });
}
orig();
