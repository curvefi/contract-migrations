# Contract to migrate between old and new pools
from vyper.interfaces import ERC20

N_COINS = ___N_COINS___
ZERO256: constant(uint256) = 0  # This hack is really bad XXX
ZEROS: constant(uint256[N_COINS]) = ___N_ZEROS___  # <- change

max_timestamp: constant(timestamp) = 2 ** 255

contract Old:
    def remove_liquidity(_amount: uint256, deadline: timestamp,
                         min_amounts: uint256[N_COINS]): modifying

contract New:
    def add_liquidity(amounts: uint256[N_COINS],
                      min_mint_amount: uint256): modifying
    def calc_token_amount(
        amounts: uint256[N_COINS], deposit: bool) -> uint256: constant

old: Old
new: New
old_token: ERC20
new_token: ERC20

coins: public(address[N_COINS])


@public
def __init__(_old: address, _old_token: address,
             _new: address, _new_token: address,
             _coins: address[N_COINS]):
    self.old = Old(_old)
    self.new = New(_new)
    self.old_token = ERC20(_old_token)
    self.new_token = ERC20(_new_token)
    self.coins[N_COINS] = _coins


@public
@nonreentrant('lock')
def migrate():
    old_token_amount: uint256 = self.old_token.balanceOf(msg.sender)
    assert_modifiable(
        self.old_token.transferFrom(msg.sender, self, old_token_amount))
    self.old.remove_liquidity(old_token_amount, max_timestamp, ZEROS)

    balances: uint256[N_COINS] = ZEROS
    for i in range(N_COINS):
        balances[i] = self.coins[i].balanceOf(self)
    min_mint_amount: uint256 = self.new.calc_token_amount(balances, True)
    min_mint_amount = min_mint_amount * 999 / 1000

    self.new.add_liquidity(balances, min_mint_amount)

    new_mint_amount: uint256 = self.new_token.balanceOf(self)
    self.new_token.transfer(msg.sender, new_mint_amount)
