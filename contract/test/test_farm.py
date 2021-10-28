from unittest import TestCase
from contextlib import contextmanager
from copy import deepcopy
from pytezos import ContractInterface, MichelsonRuntimeError, pytezos
from pytezos.michelson.types.big_map import big_map_diff_to_lazy_diff
import time

alice = 'tz1hNVs94TTjZh6BZ1PM5HL83A7aiZXkQ8ur'
admin = 'tz1fABJ97CJMSP2DKrQx2HAFazh6GgahQ7ZK'
bob = 'tz1c6PPijJnZYjKiSQND4pMtGMg6csGeAiiF'
oscar = 'tz1Phy92c2n817D17dUGzxNgw1qCkNSTWZY2'
fox = 'tz1XH5UyhRCUmCdUUbqD4tZaaqRTgGaFXt7q'

compiled_contract_path = "Farm.tz"
# Allows to load the smart contract with Pytest to simulate it with a false storage
initial_storage = ContractInterface.from_file(compiled_contract_path).storage.dummy()
initial_storage["admin"] = admin
initial_storage["total_reward"] = 10000000
initial_storage["weeks"] = 5
initial_storage["rate"] = 7500
initial_storage["smak_address"] = "KT1TwzD6zV3WeJ39ukuqxcfK2fJCnhvrdN1X"
initial_storage["lp_token_address"] ="KT1XtQeSap9wvJGY1Lmek84NU6PK6cjzC9Qd"
initial_storage["reserve_address"] = "tz1fABJ97CJMSP2DKrQx2HAFazh6GgahQ7ZK"

only_admin = "Only admin"
staking_amount_gt_0 = "The staking amount amount must be greater than zero"

class FarmsContractTest(TestCase):
    @classmethod
    def setUpClass(cls):
        cls.farms = ContractInterface.from_file(compiled_contract_path)
        cls.maxDiff = None

    @contextmanager
    def raisesMichelsonError(self, error_message):
        with self.assertRaises(MichelsonRuntimeError) as r:
            yield r

        error_msg = r.exception.format_stdout()
        if "FAILWITH" in error_msg:
            self.assertEqual(f"FAILWITH: '{error_message}'", r.exception.format_stdout())
        else:
            self.assertEqual(f"'{error_message}': ", r.exception.format_stdout())

    ######################
    # Tests for setAdmin #
    ######################

    def test_setAdmin_admin_sets_new_admin_should_work(self):
        init_storage = deepcopy(initial_storage)
        res = self.farms.setAdmin(bob).interpret(storage=init_storage, sender=admin)
        self.assertEqual(bob, res.storage["admin"])
        self.assertEqual([], res.operations)

    def test_setAdmin_user_sets_new_admin_should_fail(self):
        init_storage = deepcopy(initial_storage)
        with self.raisesMichelsonError(only_admin):
            res = self.farms.setAdmin(bob).interpret(storage=init_storage, sender=alice, now=int(604800 + 604800/2))


    ############################
    # Test rewards computation #
    ############################

    def test_initializeReward_5week_20Kreward_75rate_initialization_should_work(self):
        init_storage = deepcopy(initial_storage)
        init_storage["total_reward"] = 20_000_000
        init_storage["weeks"] = 5
        init_storage["rate"] = 7500
        res = self.farms.increaseReward(0).interpret(storage=init_storage, sender=admin)

        reward_week_1 = int(res.storage["reward_at_week"][1])
        reward_week_2 = int(res.storage["reward_at_week"][2])
        reward_week_3 = int(res.storage["reward_at_week"][3])
        reward_week_4 = int(res.storage["reward_at_week"][4])
        reward_week_5 = int(res.storage["reward_at_week"][5])
        self.assertEqual(reward_week_1, 6555697) 
        self.assertEqual(reward_week_2, 4916773) 
        self.assertEqual(reward_week_3, 3687580) 
        self.assertEqual(reward_week_4, 2765685)
        self.assertEqual(reward_week_5, 2074263) 

    def test_initializeReward_5week_30Kreward_80rate_initialization_should_work(self):
        init_storage = deepcopy(initial_storage)
        init_storage["total_reward"] = 30_000_000
        init_storage["weeks"] = 5
        init_storage["rate"] = 8000
        res = self.farms.increaseReward(0).interpret(storage=init_storage, sender=admin)

        reward_week_1 = int(res.storage["reward_at_week"][1])
        reward_week_2 = int(res.storage["reward_at_week"][2])
        reward_week_3 = int(res.storage["reward_at_week"][3])
        reward_week_4 = int(res.storage["reward_at_week"][4])
        reward_week_5 = int(res.storage["reward_at_week"][5])
        self.assertEqual(reward_week_1, 8924321) 
        self.assertEqual(reward_week_2, 7139457) 
        self.assertEqual(reward_week_3, 5711565) 
        self.assertEqual(reward_week_4, 4569252)
        self.assertEqual(reward_week_5, 3655402) 

    def test_initializeReward_3week_40Kreward_60rate_initialization_should_work(self):
        init_storage = deepcopy(initial_storage)
        init_storage["total_reward"] = 40_000_000
        init_storage["weeks"] = 3
        init_storage["rate"] = 6000
        res = self.farms.increaseReward(0).interpret(storage=init_storage, sender=admin)

        reward_week_1 = int(res.storage["reward_at_week"][1])
        reward_week_2 = int(res.storage["reward_at_week"][2])
        reward_week_3 = int(res.storage["reward_at_week"][3])
        self.assertEqual(reward_week_1, 20408163) 
        self.assertEqual(reward_week_2, 12244897) 
        self.assertEqual(reward_week_3, 7346938) 
        				
    #########################
    # Test rewards increase #
    ######################### 		

    def test_increaseReward_reward_50k_on_week_3_should_work(self):
        init_storage = deepcopy(initial_storage)
        init_storage["total_reward"] = 20_000_000
        init_storage["weeks"] = 5
        init_storage["rate"] = 7500
        init_storage["reward_at_week"] = {
            1: 6555697,
            2: 4916773,
            3: 3687580,
            4: 2765685,
            5: 2074263
        }
        res = self.farms.increaseReward(50_000_000).interpret(storage=init_storage, sender=admin, now=int(604800 * 2 + 604800/2))

        self.assertEqual(res.storage["total_reward"], 70000000 - 6555697 - 4916773)
        self.assertEqual(res.storage["weeks"], 3)
        reward_week_1 = int(res.storage["reward_at_week"][1])
        reward_week_2 = int(res.storage["reward_at_week"][2])
        reward_week_3 = int(res.storage["reward_at_week"][3])
        reward_week_4 = int(res.storage["reward_at_week"][4])
        reward_week_5 = int(res.storage["reward_at_week"][5])
        self.assertEqual(reward_week_1, 6555697)
        self.assertEqual(reward_week_2, 4916773)
        self.assertEqual(reward_week_3, 25309202)
        self.assertEqual(reward_week_4, 18981901)
        self.assertEqual(reward_week_5, 14236426)

    def test_increaseReward_reward_20k_on_week_2_should_work(self):
        init_storage = deepcopy(initial_storage)
        init_storage["total_reward"] = 10_000_000
        init_storage["weeks"] = 3
        init_storage["rate"] = 7500
        init_storage["reward_at_week"] = {
            1: 4324324,
            2: 3243243,
            3: 2432432,
        }
        res = self.farms.increaseReward(20_000_000).interpret(storage=init_storage, sender=admin, now=int(604800 + 604800/2))

        self.assertEqual(res.storage["total_reward"], 30000000 - 4324324)
        self.assertEqual(res.storage["weeks"], 2)
        reward_week_1 = int(res.storage["reward_at_week"][1])
        reward_week_2 = int(res.storage["reward_at_week"][2])
        reward_week_3 = int(res.storage["reward_at_week"][3])
        self.assertEqual(reward_week_1, 4324324)
        self.assertEqual(reward_week_2, 14671814)
        self.assertEqual(reward_week_3, 11003861)

    ######################
    # Tests for Staking #
    ######################

    def test_staking_user_stakes_one_time_on_second_week_should_work(self):
        init_storage = deepcopy(initial_storage)
        init_storage["user_stakes"] = {}
        init_storage["user_points"] = {}
        init_storage["farm_points"] = {}
        init_storage["creation_time"] = 0
        staking_time = int(604800 + 604800/2) 
        locked_amount = 20

        res = self.farms.stake(locked_amount).interpret(storage=init_storage, sender=bob, now=staking_time)
    
        self.assertEqual(admin, res.storage["admin"])
        transfer_tx = res.operations[0]
        transfer_tx_params = transfer_tx["parameters"]["value"]['args'][0]['args'][0]['args']
        self.assertEqual(bob, transfer_tx_params[0]['string'])
        # TODO retrieve address of THIS contract (instead of hard coded address)
        self.assertEqual("KT1BEqzn5Wx8uJrZNvuS9DVHmLvG9td3fDLi", transfer_tx_params[1]['string'])
        self.assertEqual(locked_amount, int(transfer_tx_params[2]['int']))

        user_stakes = res.storage["user_stakes"]
        self.assertEqual(locked_amount, user_stakes[bob])
        self.assertEqual(1, len(user_stakes.keys()))
    
        farm_points = res.storage["farm_points"]
        self.assertEqual(604800 * locked_amount / 2, farm_points[2])
        self.assertEqual(604800 * locked_amount, farm_points[3])
        self.assertEqual(604800 * locked_amount, farm_points[4])
        self.assertEqual(604800 * locked_amount, farm_points[5])

        user_points = res.storage["user_points"]
        user_points_keys = user_points.keys()
        self.assertEqual(1, len(user_points_keys))
        self.assertEqual(bob, list(user_points_keys)[0])
        self.assertEqual(604800 * locked_amount / 2, user_points[bob][2])
        self.assertEqual(604800 * locked_amount, user_points[bob][3])
        self.assertEqual(604800 * locked_amount, user_points[bob][4])
        self.assertEqual(604800 * locked_amount, user_points[bob][5])

    def test_staking_user_stakes_multiple_times_should_work(self):
        init_storage = deepcopy(initial_storage)
        init_storage["user_stakes"] = {}
        init_storage["user_points"] = {}
        init_storage["farm_points"] = {}
        init_storage["creation_time"] = 0
        staking_time_1 = int(2*604800 + 604800/2) 
        locked_amount_1 = 300

        res1 = self.farms.stake(locked_amount_1).interpret(storage=init_storage, sender=bob, now=staking_time_1)

        self.assertEqual(admin, res1.storage["admin"])
        transfer_tx = res1.operations[0]
        transfer_tx_params = transfer_tx["parameters"]["value"]['args'][0]['args'][0]['args']
        self.assertEqual(bob, transfer_tx_params[0]['string'])
        # TODO retrieve address of THIS contract (instead of hard coded address)
        self.assertEqual("KT1BEqzn5Wx8uJrZNvuS9DVHmLvG9td3fDLi", transfer_tx_params[1]['string'])
        self.assertEqual(locked_amount_1, int(transfer_tx_params[2]['int']))

        user_stakes = res1.storage["user_stakes"]
        self.assertEqual(locked_amount_1, user_stakes[bob])
        self.assertEqual(1, len(user_stakes.keys()))
    
        farm_points = res1.storage["farm_points"]
        self.assertEqual(604800 * locked_amount_1 / 2, farm_points[3])
        self.assertEqual(604800 * locked_amount_1, farm_points[4])
        self.assertEqual(604800 * locked_amount_1, farm_points[5])

        user_points = res1.storage["user_points"]
        user_points_keys = user_points.keys()
        self.assertEqual(1, len(user_points_keys))
        self.assertEqual(bob, list(user_points_keys)[0])
        self.assertEqual(604800 * locked_amount_1 / 2, user_points[bob][3])
        self.assertEqual(604800 * locked_amount_1, user_points[bob][4])
        self.assertEqual(604800 * locked_amount_1, user_points[bob][5])

        new_storage = deepcopy(initial_storage)
        new_storage["user_stakes"][bob] = 300
        new_storage["user_points"] = {
            bob: {
                1: 0,
                2: 0,
                3: int(300 * 604800 / 2),
                4: 300 * 604800,
                5: 300 * 604800
            }
        }
        new_storage["farm_points"] = {
            1: 0,
            2: 0,
            3: int(300 * 604800 / 2),
            4: 300 * 604800,
            5: 300 * 604800
        }
        new_storage["creation_time"] = 0
        staking_time_2 = int(3*604800 + 604800*2/3) 
        locked_amount_2 = 500

        res2 = self.farms.stake(locked_amount_2).interpret(storage=new_storage, sender=bob, now=staking_time_2)

        self.assertEqual(admin, res2.storage["admin"])
        transfer_tx = res2.operations[0]
        transfer_tx_params = transfer_tx["parameters"]["value"]['args'][0]['args'][0]['args']
        self.assertEqual(bob, transfer_tx_params[0]['string'])
        # TODO retrieve address of THIS contract (instead of hard coded address)
        self.assertEqual("KT1BEqzn5Wx8uJrZNvuS9DVHmLvG9td3fDLi", transfer_tx_params[1]['string'])
        self.assertEqual(locked_amount_2, int(transfer_tx_params[2]['int']))

        user_stakes = res2.storage["user_stakes"]
        self.assertEqual(locked_amount_1 + locked_amount_2, user_stakes[bob])
        self.assertEqual(1, len(user_stakes.keys()))
    
        farm_points = res2.storage["farm_points"]
        self.assertEqual(604800 * locked_amount_1 / 2, farm_points[3])
        self.assertEqual(604800 * locked_amount_1 + 604800 * locked_amount_2 / 3, farm_points[4])
        self.assertEqual(604800 * locked_amount_1 + 604800 * locked_amount_2 , farm_points[5])

        user_points = res2.storage["user_points"]
        user_points_keys = user_points.keys()
        self.assertEqual(1, len(user_points_keys))
        self.assertEqual(bob, list(user_points_keys)[0])
        self.assertEqual(604800 * locked_amount_1 / 2, user_points[bob][3])
        self.assertEqual(604800 * locked_amount_1 + 604800 * locked_amount_2 / 3, user_points[bob][4])
        self.assertEqual(604800 * locked_amount_1 + 604800 * locked_amount_2 , user_points[bob][5])

    def test_staking_user_stakes_both_should_work(self):
        new_storage = deepcopy(initial_storage)
        new_storage["user_stakes"][bob] = 300
        new_storage["user_points"] = {
            bob: {
                1: 0,
                2: 0,
                3: int(300 * 604800 / 2),
                4: 300 * 604800,
                5: 300 * 604800
            }
        }
        new_storage["farm_points"] = {
            1: 0,
            2: 0,
            3: int(300 * 604800 / 2),
            4: 300 * 604800,
            5: 300 * 604800
        }
        new_storage["creation_time"] = 0
        locked_amount_1 = 300
        staking_time_2 = int(2*604800 + 604800*2/3) 
        locked_amount_2 = 400

        res2 = self.farms.stake(locked_amount_2).interpret(storage=new_storage, sender=alice, now=staking_time_2)

        self.assertEqual(admin, res2.storage["admin"])
        transfer_tx = res2.operations[0]
        transfer_tx_params = transfer_tx["parameters"]["value"]['args'][0]['args'][0]['args']
        self.assertEqual(alice, transfer_tx_params[0]['string'])
        # TODO retrieve address of THIS contract (instead of hard coded address)
        self.assertEqual("KT1BEqzn5Wx8uJrZNvuS9DVHmLvG9td3fDLi", transfer_tx_params[1]['string'])
        self.assertEqual(locked_amount_2, int(transfer_tx_params[2]['int']))

        user_stakes = res2.storage["user_stakes"]
        self.assertEqual(locked_amount_2, user_stakes[alice])
        self.assertEqual(2, len(user_stakes.keys()))
    
        farm_points = res2.storage["farm_points"]
        self.assertEqual(604800 * locked_amount_1 / 2 + 604800 * locked_amount_2 / 3, farm_points[3])
        self.assertEqual(604800 * locked_amount_1 + 604800 * locked_amount_2, farm_points[4])
        self.assertEqual(604800 * locked_amount_1 + 604800 * locked_amount_2, farm_points[5])

        user_points = res2.storage["user_points"]
        user_points_keys = user_points.keys()
        self.assertEqual(2, len(user_points_keys))
        self.assertEqual(alice, list(user_points_keys)[1])
        self.assertEqual(604800 * locked_amount_2 / 3, user_points[alice][3])
        self.assertEqual(604800 * locked_amount_2, user_points[alice][4])
        self.assertEqual(604800 * locked_amount_2, user_points[alice][5])

    def test_staking_user_stakes_0_LP_should_fail(self):
        init_storage = deepcopy(initial_storage)
        init_storage["user_stakes"] = {}
        init_storage["user_points"] = {}
        init_storage["farm_points"] = {}
        init_storage["creation_time"] = 0
        locked_amount = 0

        with self.raisesMichelsonError(staking_amount_gt_0):
            res = self.farms.stake(locked_amount).interpret(storage=init_storage, sender=alice, now=int(604800 + 604800/2))



    ######################
    # Tests for Unstaking #
    ######################

    def test_unstaking_unstake_should_work(self):
        init_storage = deepcopy(initial_storage)
        init_storage["user_stakes"] = {
            alice: 500
        }
        init_storage["user_points"] = {
            alice: {
                1: int(500 * 604800/2),
                2: 500 * 604800,
                3: 500 * 604800,
                4: 500 * 604800,
                5: 500 * 604800
            }
        }
        init_storage["farm_points"] = {
            1: int(500 * 604800 / 2),
            2: 500 * 604800,
            3: 500 * 604800,
            4: 500 * 604800,
            5: 500 * 604800
        }

        final_userpoint = {
            alice: {
                1: int(500 * 604800/2),
                2: int((500+250) * 604800/2),
                3: 250 * 604800,
                4: 250 * 604800,
                5: 250 * 604800
            }
        }

        final_farmpoint = {
            1: int(500 * 604800 / 2),
            2: int((500+250) * 604800/2),
            3: 250 * 604800,
            4: 250 * 604800,
            5: 250 * 604800
        }
        res = self.farms.unstake(250).interpret(sender=alice, storage=init_storage, now=int(604800 + 604800/2))
        self.assertDictEqual(res.storage["user_points"], final_userpoint)
        self.assertDictEqual(res.storage["farm_points"], final_farmpoint)
        self.assertEqual(res.storage["user_stakes"][alice], 250)

    def test_unstaking_unstake_more_than_staked_should_fail(self):

        init_storage = deepcopy(initial_storage)
        init_storage["user_stakes"] = {
            alice: 500
        }
        init_storage["user_points"] = {
            alice: {
                1: int(500 * 604800/2),
                2: 500 * 604800,
                3: 500 * 604800,
                4: 500 * 604800,
                5: 500 * 604800
            }
        }
        init_storage["farm_points"] = {
            1: int(500 * 604800 / 2),
            2: 500 * 604800,
            3: 500 * 604800,
            4: 500 * 604800,
            5: 500 * 604800
        }

        final_userpoint = {
            alice: {
                1: int(500 * 604800/2),
                2: int((500+250) * 604800/2),
                3: 250 * 604800,
                4: 250 * 604800,
                5: 250 * 604800
            }
        }

        final_farmpoint = {
            1: int(500 * 604800 / 2),
            2: int((500+250) * 604800/2),
            3: 250 * 604800,
            4: 250 * 604800,
            5: 250 * 604800
        }

        with self.raisesMichelsonError("ERROR: Trying to unstake more than staked"):
            self.farms.unstake(501).interpret(sender=alice, storage=init_storage, now=int(604800 + 604800 / 2))

    def test_unstaking_unstake_with_0_staked_should_fail(self):

        init_storage = deepcopy(initial_storage)
        init_storage["user_stakes"] = {
            alice: 500
        }
        init_storage["user_points"] = {
            alice: {
                1: int(500 * 604800/2),
                2: 500 * 604800,
                3: 500 * 604800,
                4: 500 * 604800,
                5: 500 * 604800
            }
        }
        init_storage["farm_points"] = {
            1: int(500 * 604800 / 2),
            2: 500 * 604800,
            3: 500 * 604800,
            4: 500 * 604800,
            5: 500 * 604800
        }

        final_userpoint = {
            alice: {
                1: int(500 * 604800/2),
                2: int((500+250) * 604800/2),
                3: 250 * 604800,
                4: 250 * 604800,
                5: 250 * 604800
            }
        }

        final_farmpoint = {
            1: int(500 * 604800 / 2),
            2: int((500+250) * 604800/2),
            3: 250 * 604800,
            4: 250 * 604800,
            5: 250 * 604800
        }
        with self.raisesMichelsonError("ERROR: user did not stake any token"):
            self.farms.unstake(10).interpret(storage=init_storage, sender=bob)

    def test_unstaking_unstake_with_two_users_should_work(self):

        init_storage = deepcopy(initial_storage)
        init_storage["user_stakes"][bob] = 600
        init_storage["user_points"] = {
            bob: {
                1: 0,
                2: 0,
                3: int(600 * 604800 / 3),
                4: 600 * 604800,
                5: 600 * 604800
            },
            alice: {
                1: int(500 * 604800 / 2),
                2: 500 * 604800,
                3: 500 * 604800,
                4: 500 * 604800,
                5: 500 * 604800
            }
        }
        init_storage["farm_points"] = {
            1: int(500 * 604800 / 2),
            2: 500 * 604800,
            3: int(600 * 604800 / 3) + 500 * 604800,
            4: 600 * 604800 + 500 * 604800,
            5: 600 * 604800 + 500 * 604800
        }

        final_userpoint = {
            bob: {
                1: 0,
                2: 0,
                3: int(600 * 604800 / 3),
                4: int((600 * (6 / 7) + 500 / 7) * 604800),
                5: 500 * 604800
            },
            alice: {
                1: int(500 * 604800 / 2),
                2: 500 * 604800,
                3: 500 * 604800,
                4: 500 * 604800,
                5: 500 * 604800
            }
        }

        final_farmpoint = {
            1: int(500 * 604800 / 2),
            2: 500 * 604800,
            3: int(600 * 604800 / 3) + 500 * 604800,
            4: int(500 * 604800 + (600 * (6 / 7) + 500 / 7) * 604800),
            5: 500 * 604800 + 500 * 604800
        }
        res2 = self.farms.unstake(100).interpret(storage=init_storage, sender=bob, now=int(3 * 604800 + 604800 * 6 / 7))
        self.assertDictEqual(res2.storage["farm_points"], final_farmpoint)
        self.assertDictEqual(res2.storage["user_points"], final_userpoint)
        self.assertEqual(res2.storage["user_stakes"][bob], 500)

    ######################
    # Tests for ClaimAll #
    ######################

    def test_claimall_should_work(self):

        init_storage = deepcopy(initial_storage)
        init_storage["total_reward"] = 20_000_000
        init_storage["reward_at_week"] = {
            1: 6555697,
            2: 4916773,
            3: 3687580,
            4: 2765685,
            5: 2074263
        }
        init_storage["creation_time"] = 0
        init_storage["user_stakes"] = {
            alice: 500
        }
        init_storage["user_points"] = {
            alice: {
                1: int(500 * 604800/2),
                2: 500 * 604800,
                3: 500 * 604800,
                4: 500 * 604800,
                5: 500 * 604800
            }
        }
        init_storage["farm_points"] = {
            1: int(500 * 604800 / 2),
            2: 500 * 604800,
            3: 500 * 604800,
            4: 500 * 604800,
            5: 500 * 604800
        }
            
        ######################################################
        # Alice claims after one week of staking (works)     #
        ######################################################
        res = self.farms.claimAll().interpret(storage=init_storage, sender=alice, now=int(604800 + 604800/2))

        self.assertEqual(admin, res.storage["admin"])
        transfer_txs = res.operations
        #print("ClaimAll : resulting operations")
        #print(transfer_txs)

        self.assertEqual(1, len(transfer_txs))
        self.assertEqual('transaction', transfer_txs[0]["kind"])
        transfer_tx_params = transfer_txs[0]["parameters"]["value"]['args'][0]['args'][0]['args']
        self.assertEqual(initial_storage["reserve_address"], transfer_tx_params[0]['string']) 
        self.assertEqual(alice, transfer_tx_params[1]['string']) 
        self.assertEqual(str(init_storage["reward_at_week"][1]), transfer_tx_params[2]['int'])

        alice_points = res.storage["user_points"][alice]
        self.assertEqual(alice_points[1], 0)
        self.assertEqual(alice_points[2], 500 * 604800)
        self.assertEqual(alice_points[3], 500 * 604800)
        self.assertEqual(alice_points[4], 500 * 604800)
        self.assertEqual(alice_points[5], 500 * 604800)

        

    def test_claimall_3rd_week_should_work(self):

        init_storage = deepcopy(initial_storage)
        init_storage["total_reward"] = 20_000_000
        init_storage["reward_at_week"] = {
            1: 6555697,
            2: 4916773,
            3: 3687580,
            4: 2765685,
            5: 2074263
        }
        init_storage["creation_time"] = 0
        init_storage["user_stakes"] = {
            alice: 500
        }
        init_storage["user_points"] = {
            alice: {
                1: int(500 * 604800/2),
                2: 500 * 604800,
                3: 500 * 604800,
                4: 500 * 604800,
                5: 500 * 604800
            }
        }
        init_storage["farm_points"] = {
            1: int(500 * 604800 / 2),
            2: 500 * 604800,
            3: 500 * 604800,
            4: 500 * 604800,
            5: 500 * 604800
        }
            
        ######################################################
        # Alice claims after one week of staking (works)     #
        ######################################################
        res = self.farms.claimAll().interpret(storage=init_storage, sender=alice, now=int(604800 * 2 + 604800/2))

        self.assertEqual(admin, res.storage["admin"])
        transfer_txs = res.operations
        #print("ClaimAll : resulting operations")
        #print(transfer_txs)

        self.assertEqual(2, len(transfer_txs))

        self.assertEqual('transaction', transfer_txs[1]["kind"])
        transfer_tx_2_params = transfer_txs[1]["parameters"]["value"]['args'][0]['args'][0]['args']
        self.assertEqual(initial_storage["reserve_address"], transfer_tx_2_params[0]['string']) 
        self.assertEqual(alice, transfer_tx_2_params[1]['string']) 
        self.assertEqual(str(init_storage["reward_at_week"][1]), transfer_tx_2_params[2]['int'])

        self.assertEqual('transaction', transfer_txs[0]["kind"])
        transfer_tx_1_params = transfer_txs[0]["parameters"]["value"]['args'][0]['args'][0]['args']
        self.assertEqual(initial_storage["reserve_address"], transfer_tx_1_params[0]['string']) 
        self.assertEqual(alice, transfer_tx_1_params[1]['string']) 
        self.assertEqual(str(init_storage["reward_at_week"][2]), transfer_tx_1_params[2]['int'])

        alice_points = res.storage["user_points"][alice]
        self.assertEqual(alice_points[1], 0)
        self.assertEqual(alice_points[2], 0)
        self.assertEqual(alice_points[3], 500 * 604800)
        self.assertEqual(alice_points[4], 500 * 604800)
        self.assertEqual(alice_points[5], 500 * 604800)



    def test_claimall_with_2_stakers_should_work(self):

        init_storage = deepcopy(initial_storage)
        init_storage["total_reward"] = 20_000_000
        init_storage["reward_at_week"] = {
            1: 6555697,
            2: 4916773,
            3: 3687580,
            4: 2765685,
            5: 2074263
        }
        init_storage["creation_time"] = 0
        init_storage["user_stakes"] = {
            alice: 500,
            bob: 100
        }
        init_storage["user_points"] = {
            alice: {
                1: 0,
                2: int(500 * 604800 * (1 - 2/3)),
                3: 500 * 604800,
                4: 500 * 604800,
                5: 500 * 604800
            }, 
            bob : {
                1: 0,
                2: int(100 * 604800 * (1 - 1/2)),
                3: 100 * 604800,
                4: 100 * 604800,
                5: 100 * 604800
            }
        }
        init_storage["farm_points"] = {
            1: 0,
            2: int(500 * 604800 * (1 - 2/3) + 100 * 604800 * (1 - 1/2)),
            3: (500 + 100) * 604800,
            4: (500 + 100) * 604800,
            5: (500 + 100) * 604800
        }
            
        ######################################################
        # Alice claims after one week of staking (works)     #
        ######################################################
        #print("Claim : result")
        #print(init_storage)

        res = self.farms.claimAll().interpret(storage=init_storage, sender=alice, now=int(604800 * 3 + 604800 / 2))

        self.assertEqual(admin, res.storage["admin"])
        transfer_txs = res.operations
        self.assertEqual(2, len(transfer_txs))

        # week 3
        self.assertEqual('transaction', transfer_txs[0]["kind"])
        transfer_tx_3_params = transfer_txs[0]["parameters"]["value"]['args'][0]['args'][0]['args']
        self.assertEqual(initial_storage["reserve_address"], transfer_tx_3_params[0]['string']) 
        self.assertEqual(alice, transfer_tx_3_params[1]['string']) 
        expected_value_3 = int(init_storage["reward_at_week"][3] *  init_storage["user_points"][alice][3] / init_storage["farm_points"][3])
        self.assertEqual(str(expected_value_3), transfer_tx_3_params[2]['int'])

        # # week 2
        self.assertEqual('transaction', transfer_txs[1]["kind"])
        transfer_tx_2_params = transfer_txs[1]["parameters"]["value"]['args'][0]['args'][0]['args']
        self.assertEqual(initial_storage["reserve_address"], transfer_tx_2_params[0]['string']) 
        self.assertEqual(alice, transfer_tx_2_params[1]['string']) 
        expected_value_2 = int(init_storage["reward_at_week"][2] * (500 * 604800 * 1/3) / init_storage["farm_points"][2])
        self.assertEqual(str(expected_value_2), transfer_tx_2_params[2]['int'])

        alice_points = res.storage["user_points"][alice]
        self.assertEqual(alice_points[1], 0)
        self.assertEqual(alice_points[2], 0)
        self.assertEqual(alice_points[3], 0)
        self.assertEqual(alice_points[4], 500 * 604800)
        self.assertEqual(alice_points[5], 500 * 604800)