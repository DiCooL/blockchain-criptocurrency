#    - Block → chain → checking hashes
#    - Adding primitive tx 
# they’re chained together using hashes!!!

import hashlib
import time

def sha256(data: str) -> str:
    return hashlib.sha256(data.encode()).hexdigest()

class Block:
    def __init__(self, previous_hash, transactions, nonce, timestamp):
        self.previous_hash = previous_hash
        self.transactions = transactions
        self.merkle_root = self.compute_merkle_root(transactions)
        self.nonce = nonce
        self.timestamp = timestamp
        self.hash = self.compute_hash()

    @staticmethod
    def compute_merkle_root(transactions):

        if not transactions:
            return "0"

        hashes = [sha256(tx) for tx in transactions]

        while len(hashes) > 1:
            if len(hashes) % 2 == 1:
                hashes.append(hashes[-1])
            
            new_hashes = []
            for i in range(0, len(hashes), 2):
                new_hashes.append(sha256(hashes[i] + hashes[i+1]))
            hashes = new_hashes

        return hashes[0]    

    def compute_hash(self):
        block_string = f"{self.previous_hash}{self.merkle_root}{self.nonce}{self.timestamp}" 
        return sha256(block_string)


class Blockchain:
    def __init__(self):

        genesis_block = Block("0", ["Decentralized ecosystem"], 0, 0) 
        self.chain = [genesis_block]

    def is_chain_valid(self, current_block, previous_block):

        if current_block.hash != current_block.compute_hash():
            return False
    
        if current_block.previous_hash != previous_block.hash:
            return False
    
        return True
    
    def add_block(self, new_block):

        previous_block=self.chain[-1]

        if self.is_chain_valid(new_block, previous_block):
            self.chain.append(new_block)

    
bc = Blockchain()
tx=["a->b", "a->c", "b!=c"]

block1 = Block(bc.chain[-1].hash, tx, 1, timestamp=int(time.time()))
bc.add_block(block1)

for i, b in enumerate(bc.chain):
    print(f"Block {i}: hash = {b.hash}, prev = {b.previous_hash}, merkle_root = {b.merkle_root}, time = {b.timestamp}")




