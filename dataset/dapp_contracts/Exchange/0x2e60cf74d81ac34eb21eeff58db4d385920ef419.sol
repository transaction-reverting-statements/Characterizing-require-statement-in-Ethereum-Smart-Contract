# (c) Curve.Fi, 2020


# External Contracts
contract ERC20m:
    def totalSupply() -> uint256: constant
    def allowance(_owner: address, _spender: address) -> uint256: constant
    def transfer(_to: address, _value: uint256) -> bool: modifying
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: modifying
    def approve(_spender: address, _value: uint256) -> bool: modifying
    def mint(_to: address, _value: uint256): modifying
    def burn(_value: uint256): modifying
    def burnFrom(_to: address, _value: uint256): modifying
    def name() -> string[64]: constant
    def symbol() -> string[32]: constant
    def decimals() -> uint256: constant
    def balanceOf(arg0: address) -> uint256: constant
    def set_minter(_minter: address): modifying



# External Contracts
contract cERC20:
    def totalSupply() -> uint256: constant
    def allowance(_owner: address, _spender: address) -> uint256: constant
    def transfer(_to: address, _value: uint256) -> bool: modifying
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: modifying
    def approve(_spender: address, _value: uint256) -> bool: modifying
    def burn(_value: uint256): modifying
    def burnFrom(_to: address, _value: uint256): modifying
    def name() -> string[64]: constant
    def symbol() -> string[32]: constant
    def decimals() -> uint256: constant
    def balanceOf(arg0: address) -> uint256: constant
    def mint(mintAmount: uint256) -> uint256: modifying
    def redeem(redeemTokens: uint256) -> uint256: modifying
    def redeemUnderlying(redeemAmount: uint256) -> uint256: modifying
    def exchangeRateStored() -> uint256: constant
    def exchangeRateCurrent() -> uint256: modifying
    def supplyRatePerBlock() -> uint256: constant
    def accrualBlockNumber() -> uint256: constant


from vyper.interfaces import ERC20

# This can (and needs to) be changed at compile time
N_COINS: constant(int128) = 2  #  uint256[N_COINS]:
    # exchangeRateStored * (1 + supplyRatePerBlock * (getBlockNumber - accrualBlockNumber) / 1e18)
    result: uint256[N_COINS] = PRECISION_MUL
    for i in range(N_COINS):
        rate: uint256 = cERC20(self.coins[i]).exchangeRateStored()
        supply_rate: uint256 = cERC20(self.coins[i]).supplyRatePerBlock()
        old_block: uint256 = cERC20(self.coins[i]).accrualBlockNumber()
        rate += rate * supply_rate * (block.number - old_block) / 10 ** 18
        result[i] = rate * result[i]
    return result


@private
def _current_rates() -> uint256[N_COINS]:
    result: uint256[N_COINS] = PRECISION_MUL
    for i in range(N_COINS):
        rate: uint256 = cERC20(self.coins[i]).exchangeRateCurrent()
        result[i] = rate * result[i]
    return result


@private
@constant
def _xp(rates: uint256[N_COINS]) -> uint256[N_COINS]:
    result: uint256[N_COINS] = rates
    for i in range(N_COINS):
        result[i] = result[i] * self.balances[i] / 10 ** 18
    return result


@private
@constant
def get_D(xp: uint256[N_COINS]) -> uint256:
    S: uint256 = 0
    for _x in xp:
        S += _x
    if S == 0:
        return 0

    Dprev: uint256 = 0
    D: uint256 = S
    Ann: uint256 = convert(self.A, uint256) * N_COINS
    for _i in range(255):
        D_P: uint256 = D
        for _x in xp:
            D_P = D_P * D / (_x * N_COINS + 1)  # +1 is to prevent /0
        Dprev = D
        D = (Ann * S + D_P * N_COINS) * D / ((Ann - 1) * D + (N_COINS + 1) * D_P)
        # Equality with the precision of 1
        if D > Dprev:
            if D - Dprev <= 1:
                break
        else:
            if Dprev - D <= 1:
                break
    return D


@public
@constant
def get_virtual_price() -> uint256:
    """
    Returns portfolio virtual price (for calculating profit)
    scaled up by 1e18
    """
    D: uint256 = self.get_D(self._xp(self._stored_rates()))
    # D is in the units similar to DAI (e.g. converted to precision 1e18)
    # When balanced, D = n * x_u - total virtual value of the portfolio
    token_supply: uint256 = self.token.totalSupply()
    return D * 10 ** 18 / token_supply


@public
@nonreentrant('lock')
def add_liquidity(amounts: uint256[N_COINS], deadline: timestamp):
    # Amounts is amounts of c-tokens
    assert block.timestamp <= deadline, "Transaction expired"
    assert not self.is_killed

    token_supply: uint256 = self.token.totalSupply()
    rates: uint256[N_COINS] = self._current_rates()
    # Initial invariant
    D0: uint256 = 0
    if token_supply > 0:
        D0 = self.get_D(self._xp(rates))

    for i in range(N_COINS):
        if token_supply == 0:
            assert amounts[i] > 0
        # balances store amounts of c-tokens
        self.balances[i] += amounts[i]

    # Invariant after change
    D1: uint256 = self.get_D(self._xp(rates))
    assert D1 > D0

    # Calculate, how much pool tokens to mint
    mint_amount: uint256 = 0
    if token_supply == 0:
        mint_amount = D1  # Take the dust if there was any
    else:
        mint_amount = token_supply * (D1 - D0) / D0

    # Take coins from the sender
    for i in range(N_COINS):
        assert_modifiable(
            cERC20(self.coins[i]).transferFrom(msg.sender, self, amounts[i]))

    # Mint pool tokens
    self.token.mint(msg.sender, mint_amount)

    log.AddLiquidity(msg.sender, amounts, D1, token_supply + mint_amount)


@private
@constant
def get_y(i: int128, j: int128, x: uint256, _xp: uint256[N_COINS]) -> uint256:
    # x in the input is converted to the same price/precision

    assert i != j

    D: uint256 = self.get_D(_xp)
    c: uint256 = D
    S_: uint256 = 0
    Ann: uint256 = convert(self.A, uint256) * N_COINS

    _x: uint256 = 0
    for _i in range(N_COINS):
        if _i == i:
            _x = x
        elif _i != j:
            _x = _xp[_i]
        else:
            continue
        S_ += _x
        c = c * D / (_x * N_COINS)
    c = c * D / (Ann * N_COINS)
    b: uint256 = S_ + D / Ann  # - D
    y_prev: uint256 = 0
    y: uint256 = D
    for _i in range(255):
        y_prev = y
        y = (y*y + c) / (2 * y + b - D)
        # Equality with the precision of 1
        if y > y_prev:
            if y - y_prev <= 1:
                break
        else:
            if y_prev - y <= 1:
                break
    return y


@public
@constant
def get_dy(i: int128, j: int128, dx: uint256) -> uint256:
    # dx and dy in c-units
    rates: uint256[N_COINS] = self._stored_rates()
    xp: uint256[N_COINS] = self._xp(rates)

    x: uint256 = xp[i] + dx * rates[i] / 10 ** 18
    y: uint256 = self.get_y(i, j, x, xp)
    dy: uint256 = (xp[j] - y) * 10 ** 18 / rates[j]
    _fee: uint256 = convert(self.fee, uint256) * dy / 10 ** 10
    return dy - _fee


@public
@constant
def get_dy_underlying(i: int128, j: int128, dx: uint256) -> uint256:
    # dx and dy in underlying units
    rates: uint256[N_COINS] = self._stored_rates()
    xp: uint256[N_COINS] = self._xp(rates)
    precisions: uint256[N_COINS] = PRECISION_MUL

    x: uint256 = xp[i] + dx * precisions[i]
    y: uint256 = self.get_y(i, j, x, xp)
    dy: uint256 = (xp[j] - y) / precisions[j]
    _fee: uint256 = convert(self.fee, uint256) * dy / 10 ** 10
    return dy - _fee


@private
def _exchange(i: int128, j: int128, dx: uint256,
             min_dy: uint256, deadline: timestamp,
             rates: uint256[N_COINS]) -> uint256:
    assert block.timestamp <= deadline, "Transaction expired"
    assert i < N_COINS and j < N_COINS, "Coin number out of range"
    assert not self.is_killed
    # dx and dy are in c-tokens

    xp: uint256[N_COINS] = self._xp(rates)

    x: uint256 = xp[i] + dx * rates[i] / 10 ** 18
    y: uint256 = self.get_y(i, j, x, xp)
    dy: uint256 = xp[j] - y
    dy_fee: uint256 = dy * convert(self.fee, uint256) / 10 ** 10
    dy_admin_fee: uint256 = dy_fee * convert(self.admin_fee, uint256) / 10 ** 10
    self.balances[i] = x * 10 ** 18 / rates[i]
    self.balances[j] = (y + (dy_fee - dy_admin_fee)) * 10 ** 18 / rates[j]

    _dy: uint256 = (dy - dy_fee) * 10 ** 18 / rates[j]
    assert _dy >= min_dy

    return _dy


@public
@nonreentrant('lock')
def exchange(i: int128, j: int128, dx: uint256,
             min_dy: uint256, deadline: timestamp):
    rates: uint256[N_COINS] = self._current_rates()
    dy: uint256 = self._exchange(i, j, dx, min_dy, deadline, rates)
    assert_modifiable(cERC20(self.coins[i]).transferFrom(msg.sender, self, dx))
    assert_modifiable(cERC20(self.coins[j]).transfer(msg.sender, dy))
    log.TokenExchange(msg.sender, i, dx, j, dy)


@public
@nonreentrant('lock')
def exchange_underlying(i: int128, j: int128, dx: uint256,
                        min_dy: uint256, deadline: timestamp):
    rates: uint256[N_COINS] = self._current_rates()
    precisions: uint256[N_COINS] = PRECISION_MUL
    rate_i: uint256 = rates[i] / precisions[i]
    rate_j: uint256 = rates[j] / precisions[j]
    dx_: uint256 = dx * 10 ** 18 / rate_i
    min_dy_: uint256 = min_dy * 10 ** 18 / rate_j

    dy_: uint256 = self._exchange(i, j, dx_, min_dy_, deadline, rates)
    dy: uint256 = dy_ * rate_j / 10 ** 18

    ok: uint256 = 0
    assert_modifiable(ERC20(self.underlying_coins[i])\
        .transferFrom(msg.sender, self, dx))
    ERC20(self.underlying_coins[i]).approve(self.coins[i], dx)
    ok = cERC20(self.coins[i]).mint(dx)
    if ok > 0:
        raise "Could not mint coin"
    ok = cERC20(self.coins[j]).redeem(dy_)
    if ok > 0:
        raise "Could not redeem coin"
    assert_modifiable(ERC20(self.underlying_coins[j])\
        .transfer(msg.sender, dy))

    log.TokenExchangeUnderlying(msg.sender, i, dx, j, dy)


@public
@nonreentrant('lock')
def remove_liquidity(_amount: uint256, deadline: timestamp,
                     min_amounts: uint256[N_COINS]):
    assert block.timestamp <= deadline, "Transaction expired"
    assert self.token.balanceOf(msg.sender) >= _amount
    total_supply: uint256 = self.token.totalSupply()
    amounts: uint256[N_COINS] = ZEROS
    fees: uint256[N_COINS] = ZEROS

    for i in range(N_COINS):
        value: uint256 = self.balances[i] * _amount / total_supply
        assert value >= min_amounts[i]
        self.balances[i] -= value
        amounts[i] = value
        assert_modifiable(cERC20(self.coins[i]).transfer(
            msg.sender, value))

    self.token.burnFrom(msg.sender, _amount)

    D: uint256 = self.get_D(self._xp(self._current_rates()))
    log.RemoveLiquidity(msg.sender, amounts, fees, D, total_supply - _amount)


@public
@nonreentrant('lock')
def remove_liquidity_imbalance(amounts: uint256[N_COINS], deadline: timestamp):
    assert block.timestamp <= deadline, "Transaction expired"
    assert not self.is_killed

    token_supply: uint256 = self.token.totalSupply()
    assert token_supply > 0
    fees: uint256[N_COINS] = ZEROS
    _fee: uint256 = convert(self.fee, uint256)
    _admin_fee: uint256 = convert(self.admin_fee, uint256)
    rates: uint256[N_COINS] = self._current_rates()

    D0: uint256 = self.get_D(self._xp(rates))
    for i in range(N_COINS):
        fees[i] = amounts[i] * _fee / 10 ** 10
        self.balances[i] -= amounts[i] + fees[i]  # Charge all fees
    D1: uint256 = self.get_D(self._xp(rates))

    token_amount: uint256 = (D0 - D1) * token_supply / D0
    assert self.token.balanceOf(msg.sender) >= token_amount
    for i in range(N_COINS):
        assert_modifiable(cERC20(self.coins[i]).transfer(msg.sender, amounts[i]))
    self.token.burnFrom(msg.sender, token_amount)

    # Now "charge" fees
    # In fact, we "refund" fees to the liquidity providers but w/o admin fees
    # They got paid by burning a higher amount of liquidity token from sender
    for i in range(N_COINS):
        self.balances[i] += fees[i] - _admin_fee * fees[i] / 10 ** 10

    # D1 doesn't include the fee we've charged here, so not super precise
    log.RemoveLiquidity(msg.sender, amounts, fees, D1, token_supply - token_amount)


### Admin functions ###
@public
def commit_new_parameters(amplification: int128,
                          new_fee: int128,
                          new_admin_fee: int128):
    assert msg.sender == self.owner
    assert self.admin_actions_deadline == 0
    assert new_admin_fee <= max_admin_fee

    _deadline: timestamp = block.timestamp + admin_actions_delay
    self.admin_actions_deadline = _deadline
    self.future_A = amplification
    self.future_fee = new_fee
    self.future_admin_fee = new_admin_fee

    log.CommitNewParameters(_deadline, amplification, new_fee, new_admin_fee)


@public
def apply_new_parameters():
    assert msg.sender == self.owner
    assert self.admin_actions_deadline <= block.timestamp\
        and self.admin_actions_deadline > 0

    self.admin_actions_deadline = 0
    _A: int128 = self.future_A
    _fee: int128 = self.future_fee
    _admin_fee: int128 = self.future_admin_fee
    self.A = _A
    self.fee = _fee
    self.admin_fee = _admin_fee

    log.NewParameters(_A, _fee, _admin_fee)


@public
def revert_new_parameters():
    assert msg.sender == self.owner

    self.admin_actions_deadline = 0


@public
def commit_transfer_ownership(_owner: address):
    assert msg.sender == self.owner
    assert self.transfer_ownership_deadline == 0

    _deadline: timestamp = block.timestamp + admin_actions_delay
    self.transfer_ownership_deadline = _deadline
    self.future_owner = _owner

    log.CommitNewAdmin(_deadline, _owner)


@public
def apply_transfer_ownership():
    assert msg.sender == self.owner
    assert block.timestamp >= self.transfer_ownership_deadline\
        and self.transfer_ownership_deadline > 0

    self.transfer_ownership_deadline = 0
    _owner: address = self.future_owner
    self.owner = _owner

    log.NewAdmin(_owner)


@public
def revert_transfer_ownership():
    assert msg.sender == self.owner

    self.transfer_ownership_deadline = 0


@public
def withdraw_admin_fees():
    assert msg.sender == self.owner
    _precisions: uint256[N_COINS] = PRECISION_MUL

    for i in range(N_COINS):
        c: address = self.coins[i]
        value: uint256 = cERC20(c).balanceOf(self) - self.balances[i]
        if value > 0:
            assert_modifiable(cERC20(c).transfer(msg.sender, value))


@public
def kill_me():
    assert msg.sender == self.owner
    assert self.kill_deadline > block.timestamp
    self.is_killed = True


@public
def unkill_me():
    assert msg.sender == self.owner
    self.is_killed = False
