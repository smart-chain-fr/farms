from unittest import TestCase
from contextlib import contextmanager
from copy import deepcopy
from pytezos import ContractInterface, MichelsonRuntimeError, pytezos
from pytezos.operation.result import OperationResult
from pytezos.michelson.types.big_map import big_map_diff_to_lazy_diff
from pytezos.sandbox.node import SandboxedNodeTestCase
import time
import json


alice = 'tz1hNVs94TTjZh6BZ1PM5HL83A7aiZXkQ8ur'
bob = 'tz1c6PPijJnZYjKiSQND4pMtGMg6csGeAiiF'
oscar = 'tz1Phy92c2n817D17dUGzxNgw1qCkNSTWZY2'
fox = 'tz1XH5UyhRCUmCdUUbqD4tZaaqRTgGaFXt7q'

admin = 'tz1fABJ97CJMSP2DKrQx2HAFazh6GgahQ7ZK'

reserve_address = 'tz1RyejUffjfnHzWoRp1vYyZwGnfPuHsD5F5'
burn_address = 'tz1burnburnburnburnburnburnburjAYjjX'
 
another_contract = 'KT1FN2uavvys9LsEFh2rBBck6iKLXifyfJmc'

compiled_contract_path = "compiled/fa12.tz"

initial_storage = ContractInterface.from_file(compiled_contract_path).storage.dummy()
initial_storage["admin"] = admin
initial_storage["reserve"] = reserve_address
initial_storage["tokens"] = {}
initial_storage["allowances"] = {}
initial_storage["total_supply"] = 0
initial_storage["metadata"] = {}
initial_storage["token_metadata"] = {}



class Fa12ContractTest(TestCase):
    @classmethod
    def setUpClass(cls):
        cls.Fa12 = ContractInterface.from_file(compiled_contract_path)
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

    ##################
    # Tests for mint #
    ##################

    def test_mintorburnt_should_work(self):
        # Init
        init_storage = deepcopy(initial_storage)
        # Execute entrypoint
        res = self.Fa12.mintOrBurn(200,admin).interpret(storage=init_storage, sender=admin)
        self.assertEqual(admin, res.storage["admin"])
        self.assertEqual([], res.operations)
        self.assertEqual(res.storage["tokens"][admin], 200)


    def test_transfer_fee_with_implicit_account_should_work(self):
        # Init
        init_storage = deepcopy(initial_storage)
        init_storage["tokens"][admin] = 200
        # Execute entrypoint
        res = self.Fa12.transfer(admin, alice, 100).interpret(storage=init_storage, sender=admin)
        self.assertEqual(admin, res.storage["admin"])
        self.assertEqual([], res.operations)
        self.assertEqual(res.storage["tokens"][admin], 100)
        print(res.storage["tokens"])
        self.assertEqual(res.storage["tokens"][burn_address], 1)
        self.assertEqual(res.storage["tokens"][reserve_address], 4)
        self.assertEqual(res.storage["tokens"][alice], 95)

    def test_transfer_fee_with_contract_account_should_work(self):
        # Init
        init_storage = deepcopy(initial_storage)
        init_storage["tokens"][admin] = 200
        # Execute entrypoint
        res = self.Fa12.transfer(admin, another_contract, 100).interpret(storage=init_storage, sender=admin)
        self.assertEqual(admin, res.storage["admin"])
        self.assertEqual([], res.operations)
        self.assertEqual(res.storage["tokens"][admin], 100)
        self.assertEqual(res.storage["tokens"][burn_address], 1)
        self.assertEqual(res.storage["tokens"][reserve_address], 4)
        # self.assertEqual(res.storage["tokens"][alice], 95)