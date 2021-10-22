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
# Permet de charger le smart contract zvec Pytest de le simuler avec un faux storage
initial_storage = ContractInterface.from_file(compiled_contract_path).storage.dummy()
initial_storage["admin"] = admin
initial_storage["total_reward"] = 10_000_000
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

    def test_setAdmin(self):
        init_storage = deepcopy(initial_storage)

        print("Etat 1 : ")
        print(init_storage)
        
        ################################
        # Admin sets new admin (works) #
        ################################
        res = self.farms.setAdmin(bob).interpret(storage=init_storage, sender=admin)
        self.assertEqual(bob, res.storage["admin"])
        self.assertEqual([], res.operations)
        print("Etat 1 : resulting storage")
        print(res.storage)

        print("Etat 2 : ")
        print(init_storage)

        ######################################
        # random user sets new admin (fails) #
        ######################################
        with self.raisesMichelsonError(only_admin):
            self.farms.setAdmin(admin).interpret(storage=init_storage, sender=alice)

    ######################
    # Tests for Staking #
    ######################

    def test_staking_20_lp_should_work(self):
        #now = pytezos.now()
        #now = time.Time()
        now = 1634808274 

        init_storage = deepcopy(initial_storage)
        init_storage["user_stakes"] = {}
        init_storage["user_points"] = {}
        init_storage["farm_points"] = {}
        init_storage["creation_time"] = 0
        
        locked_amount = 20
        

        print("Staking initial storage : ")
        print(init_storage)
        
        ######################################################
        # Bob stakes 20 LP after one week and a half (works) #
        ######################################################
        res = self.farms.stake(locked_amount).interpret(storage=init_storage, sender=bob, now=int(604800 + 604800/2))

        print("Staking : resulting storage")
        print(res.storage)
    
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

        

        

    def test_staking_0_lp_should_fail(self):
        now = 1634808274 

        init_storage = deepcopy(initial_storage)
        init_storage["user_stakes"] = {}
        init_storage["user_points"] = {}
        init_storage["farm_points"] = {}
        init_storage["creation_time"] = 0
        
        locked_amount = 0
        
        print("Staking initial storage : ")
        print(init_storage)
        
        ######################################
        # Alice stakes 0 LP (fails) #
        ######################################
        with self.raisesMichelsonError(staking_amount_gt_0):
            res2 = self.farms.stake(locked_amount).interpret(storage=init_storage, sender=alice, now=int(604800 + 604800/2))
    def test_unstake(self):
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

        with self.raisesMichelsonError("ERROR: Trying to unstake more than staked"):
            self.farms.unstake(501).interpret(sender=alice, storage=init_storage, now=int(604800 + 604800 / 2))

        with self.raisesMichelsonError("ERROR: user did not stake any token"):
            self.farms.unstake(10).interpret(storage=init_storage, sender=bob)

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


    def test_increase_reward(self):
        init_storage = deepcopy(initial_storage)
        init_storage["total_reward"] = 20_000
        res = self.farms.increaseReward(0).interpret(storage=init_storage, sender=bob)

        print("Increase reward : result")
        print(res.storage["reward_at_week"])
        reward_week_1 = int(res.storage["reward_at_week"][1] / 10000)
        reward_week_2 = int(res.storage["reward_at_week"][2] / 10000)
        reward_week_3 = int(res.storage["reward_at_week"][3] / 10000)
        reward_week_4 = int(res.storage["reward_at_week"][4] / 10000)
        reward_week_5 = int(res.storage["reward_at_week"][5] / 10000)
        self.assertEqual(reward_week_1, 6556)
        self.assertEqual(reward_week_2, 4917)
        self.assertEqual(reward_week_3, 3688)
        self.assertEqual(reward_week_4, 2765)
        self.assertEqual(reward_week_5, 2074)