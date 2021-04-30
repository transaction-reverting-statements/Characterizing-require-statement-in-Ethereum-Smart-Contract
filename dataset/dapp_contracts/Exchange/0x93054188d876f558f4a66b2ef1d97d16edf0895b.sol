# (c) Curve.Fi, 2020
# Pools for renBTC/wBTC. Ren can potentially change amount of underlying bitcoins


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
    def exchangeRateCurrent() -> uint256: constant
    def supplyRatePerBlock() -> uint256: constant
    def accrualBlockNumber() -> uint256: constant


from vyper.interfaces import ERC20


# This can (and needs to) be changed at compile time
N_COINS: constant(int128) = 2  #  uint256:
    """
    Handle ramping A up or down
    """
    t1: timestamp = self.future_A_time
    A1: uint256 = self.future_A

    if block.timestamp < t1:
        A0: uint256 = self.initial_A
        t0: timestamp = self.initial_A_time
        # Expressions in uint256 cannot have negative numbers, thus "if"
        if A1 > A0:
            return A0 + (A1 - A0) * (block.timestamp - t0) / (t1 - t0)
        else:
            return A0 - (A0 - A1) * (block.timestamp - t0) / (t1 - t0)

    else:  # when t1 == 0 or block.timestamp >= t1
        return A1


@constant
@public
def A() -> uint256:
    return self._A()


@private
@constant
def _rates() -> uint256[N_COINS]:
    result: uint256[N_COINS] = PRECISION_MUL
    use_lending: bool[N_COINS] = USE_LENDING
    for i in range(N_COINS):
        rate: uint256 = LENDING_PRECISION  # Used with no lending
        if use_lending[i]:
            rate = cERC20(self.coins[i]).exchangeRateCurrent()
        result[i] *= rate
    return result


@private
@constant
def _xp(rates: uint256[N_COINS]) -> uint256[N_COINS]:
    result: uint256[N_COINS] = rates
    for i in range(N_COINS):
        result[i] = result[i] * self.balances[i] / LENDING_PRECISION
    return result


@private
@constant
def _xp_mem(rates: uint256[N_COINS], _balances: uint256[N_COINS]) -> uint256[N_COINS]:
    result: uint256[N_COINS] = rates
    for i in range(N_COINS):
        result[i] = result[i] * _balances[i] / PRECISION
    return result


@private
@constant
def get_D(xp: uint256[N_COINS], amp: uint256) -> uint256:
    S: uint256 = 0
    for _x in xp:
        S += _x
    if S == 0:
        return 0

    Dprev: uint256 = 0
    D: uint256 = S
    Ann: uint256 = amp * N_COINS
    for _i in range(255):
        D_P: uint256 = D
        for _x in xp:
            D_P = D_P * D / (_x * N_COINS)  # If division by 0, this will be borked: only withdrawal will work. And that is good
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


@private
@constant
def get_D_mem(rates: uint256[N_COINS], _balances: uint256[N_COINS], amp: uint256) -> uint256:
    return self.get_D(self._xp_mem(rates, _balances), amp)


@public
@constant
def get_virtual_price() -> uint256:
    """
    Returns portfolio virtual price (for calculating profit)
    scaled up by 1e18
    """
    D: uint256 = self.get_D(self._xp(self._rates()), self._A())
    # D is in the units similar to DAI (e.g. converted to precision 1e18)
    # When balanced, D = n * x_u - total virtual value of the portfolio
    token_supply: uint256 = self.token.totalSupply()
    return D * PRECISION / token_supply


@public
@constant
def calc_token_amount(amounts: uint256[N_COINS], deposit: bool) -> uint256:
    """
    Simplified method to calculate addition or reduction in token supply at
    deposit or withdrawal without taking fees into account (but looking at
    slippage).
    Needed to prevent front-running, not for precise calculations!
    """
    _balances: uint256[N_COINS] = self.balances
    rates: uint256[N_COINS] = self._rates()
    amp: uint256 = self._A()
    D0: uint256 = self.get_D_mem(rates, _balances, amp)
    for i in range(N_COINS):
        if deposit:
            _balances[i] += amounts[i]
        else:
            _balances[i] -= amounts[i]
    D1: uint256 = self.get_D_mem(rates, _balances, amp)
    token_amount: uint256 = self.token.totalSupply()
    diff: uint256 = 0
    if deposit:
        diff = D1 - D0
    else:
        diff = D0 - D1
    return diff * token_amount / D0


@public
@nonreentrant('lock')
def add_liquidity(amounts: uint256[N_COINS], min_mint_amount: uint256):
    # Amounts is amounts of c-tokens
    assert not self.is_killed

    use_lending: bool[N_COINS] = USE_LENDING
    fees: uint256[N_COINS] = ZEROS
    _fee: uint256 = self.fee * N_COINS / (4 * (N_COINS - 1))
    _admin_fee: uint256 = self.admin_fee
    amp: uint256 = self._A()

    token_supply: uint256 = self.token.totalSupply()
    rates: uint256[N_COINS] = self._rates()
    # Initial invariant
    D0: uint256 = 0
    old_balances: uint256[N_COINS] = self.balances
    if token_supply > 0:
        D0 = self.get_D_mem(rates, old_balances, amp)
    new_balances: uint256[N_COINS] = old_balances

    for i in range(N_COINS):
        if token_supply == 0:
            assert amounts[i] > 0
        # balances store amounts of c-tokens
        new_balances[i] = old_balances[i] + amounts[i]

    # Invariant after change
    D1: uint256 = self.get_D_mem(rates, new_balances, amp)
    assert D1 > D0

    # We need to recalculate the invariant accounting for fees
    # to calculate fair user's share
    D2: uint256 = D1
    if token_supply > 0:
        # Only account for fees if we are not the first to deposit
        for i in range(N_COINS):
            ideal_balance: uint256 = D1 * old_balances[i] / D0
            difference: uint256 = 0
            if ideal_balance > new_balances[i]:
                difference = ideal_balance - new_balances[i]
            else:
                difference = new_balances[i] - ideal_balance
            fees[i] = _fee * difference / FEE_DENOMINATOR
            self.balances[i] = new_balances[i] - (fees[i] * _admin_fee / FEE_DENOMINATOR)
            new_balances[i] -= fees[i]
        D2 = self.get_D_mem(rates, new_balances, amp)
    else:
        self.balances = new_balances

    # Calculate, how much pool tokens to mint
    mint_amount: uint256 = 0
    if token_supply == 0:
        mint_amount = D1  # Take the dust if there was any
    else:
        mint_amount = token_supply * (D2 - D0) / D0

    assert mint_amount >= min_mint_amount, "Slippage screwed you"

    # Take coins from the sender
    for i in range(N_COINS):
        if amounts[i] > 0:
            assert_modifiable(
                cERC20(self.coins[i]).transferFrom(msg.sender, self, amounts[i]))

    # Mint pool tokens
    self.token.mint(msg.sender, mint_amount)

    log.AddLiquidity(msg.sender, amounts, fees, D1, token_supply + mint_amount)


@private
@constant
def get_y(i: int128, j: int128, x: uint256, _xp: uint256[N_COINS]) -> uint256:
    # x in the input is converted to the same price/precision

    assert (i != j) and (i >= 0) and (j >= 0) and (i < N_COINS) and (j < N_COINS)

    amp: uint256 = self._A()
    D: uint256 = self.get_D(_xp, amp)
    c: uint256 = D
    S_: uint256 = 0
    Ann: uint256 = amp * N_COINS

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
    rates: uint256[N_COINS] = self._rates()
    xp: uint256[N_COINS] = self._xp(rates)

    x: uint256 = xp[i] + (dx * rates[i] / PRECISION)
    y: uint256 = self.get_y(i, j, x, xp)
    dy: uint256 = (xp[j] - y - 1) * PRECISION / rates[j]
    _fee: uint256 = self.fee * dy / FEE_DENOMINATOR
    return dy - _fee


@public
@constant
def get_dy_underlying(i: int128, j: int128, dx: uint256) -> uint256:
    # dx and dy in underlying units
    rates: uint256[N_COINS] = self._rates()
    xp: uint256[N_COINS] = self._xp(rates)
    precisions: uint256[N_COINS] = PRECISION_MUL

    x: uint256 = xp[i] + dx * precisions[i]
    y: uint256 = self.get_y(i, j, x, xp)
    dy: uint256 = (xp[j] - y - 1) / precisions[j]
    _fee: uint256 = self.fee * dy / FEE_DENOMINATOR
    return dy - _fee


@private
def _exchange(i: int128, j: int128, dx: uint256, rates: uint256[N_COINS]) -> uint256:
    assert not self.is_killed
    # dx and dy are in c-tokens

    old_balances: uint256[N_COINS] = self.balances
    xp: uint256[N_COINS] = self._xp_mem(rates, old_balances)

    x: uint256 = xp[i] + dx * rates[i] / PRECISION
    y: uint256 = self.get_y(i, j, x, xp)

    dy: uint256 = xp[j] - y - 1  # -1 just in case there were some rounding errors
    dy_fee: uint256 = dy * self.fee / FEE_DENOMINATOR
    dy_admin_fee: uint256 = dy_fee * self.admin_fee / FEE_DENOMINATOR

    # Convert all to real units
    dy = (dy - dy_fee) * PRECISION / rates[j]
    dy_admin_fee = dy_admin_fee * PRECISION / rates[j]

    # Change balances exactly in same way as we change actual ERC20 coin amounts
    self.balances[i] = old_balances[i] + dx
    # When rounding errors happen, we undercharge admin fee in favor of LP
    self.balances[j] = old_balances[j] - dy - dy_admin_fee

    return dy


@public
@nonreentrant('lock')
def exchange(i: int128, j: int128, dx: uint256, min_dy: uint256):
    rates: uint256[N_COINS] = self._rates()
    dy: uint256 = self._exchange(i, j, dx, rates)
    assert dy >= min_dy, "Exchange resulted in fewer coins than expected"
    use_lending: bool[N_COINS] = USE_LENDING

    assert_modifiable(cERC20(self.coins[i]).transferFrom(msg.sender, self, dx))
    assert_modifiable(cERC20(self.coins[j]).transfer(msg.sender, dy))

    log.TokenExchange(msg.sender, i, dx, j, dy)


@public
@nonreentrant('lock')
def remove_liquidity(_amount: uint256, min_amounts: uint256[N_COINS]):
    total_supply: uint256 = self.token.totalSupply()
    amounts: uint256[N_COINS] = ZEROS
    fees: uint256[N_COINS] = ZEROS  # Fees are unused but we've got them historically in event
    use_lending: bool[N_COINS] = USE_LENDING

    for i in range(N_COINS):
        value: uint256 = self.balances[i] * _amount / total_supply
        assert value >= min_amounts[i], "Withdrawal resulted in fewer coins than expected"
        self.balances[i] -= value
        amounts[i] = value
        assert_modifiable(cERC20(self.coins[i]).transfer(msg.sender, value))

    self.token.burnFrom(msg.sender, _amount)  # Will raise if not enough

    log.RemoveLiquidity(msg.sender, amounts, fees, total_supply - _amount)


@public
@nonreentrant('lock')
def remove_liquidity_imbalance(amounts: uint256[N_COINS], max_burn_amount: uint256):
    assert not self.is_killed
    use_lending: bool[N_COINS] = USE_LENDING

    token_supply: uint256 = self.token.totalSupply()
    assert token_supply > 0
    _fee: uint256 = self.fee * N_COINS / (4 * (N_COINS - 1))
    _admin_fee: uint256 = self.admin_fee
    rates: uint256[N_COINS] = self._rates()
    amp: uint256 = self._A()

    old_balances: uint256[N_COINS] = self.balances
    new_balances: uint256[N_COINS] = old_balances
    D0: uint256 = self.get_D_mem(rates, old_balances, amp)
    for i in range(N_COINS):
        new_balances[i] -= amounts[i]
    D1: uint256 = self.get_D_mem(rates, new_balances, amp)
    fees: uint256[N_COINS] = ZEROS
    for i in range(N_COINS):
        ideal_balance: uint256 = D1 * old_balances[i] / D0
        difference: uint256 = 0
        if ideal_balance > new_balances[i]:
            difference = ideal_balance - new_balances[i]
        else:
            difference = new_balances[i] - ideal_balance
        fees[i] = _fee * difference / FEE_DENOMINATOR
        self.balances[i] = new_balances[i] - (fees[i] * _admin_fee / FEE_DENOMINATOR)
        new_balances[i] -= fees[i]
    D2: uint256 = self.get_D_mem(rates, new_balances, amp)

    token_amount: uint256 = (D0 - D2) * token_supply / D0 + 1
    assert token_amount <= max_burn_amount, "Slippage screwed you"

    for i in range(N_COINS):
        if amounts[i] > 0:
            assert_modifiable(cERC20(self.coins[i]).transfer(msg.sender, amounts[i]))
    self.token.burnFrom(msg.sender, token_amount)  # Will raise if not enough

    log.RemoveLiquidityImbalance(msg.sender, amounts, fees, D1, token_supply - token_amount)


@private
@constant
def get_y_D(A: uint256, i: int128, xp: uint256[N_COINS], D: uint256) -> uint256:
    """
    Calculate x[i] if one reduces D from being calculated for xp to D

    Done by solving quadratic equation iteratively.
    x_1**2 + x1 * (sum' - (A*n**n - 1) * D / (A * n**n)) = D ** (n + 1) / (n ** (2 * n) * prod' * A)
    x_1**2 + b*x_1 = c

    x_1 = (x_1**2 + c) / (2*x_1 + b)
    """
    # x in the input is converted to the same price/precision

    assert (i >= 0) and (i < N_COINS)

    c: uint256 = D
    S_: uint256 = 0
    Ann: uint256 = A * N_COINS

    _x: uint256 = 0
    for _i in range(N_COINS):
        if _i != i:
            _x = xp[_i]
        else:
            continue
        S_ += _x
        c = c * D / (_x * N_COINS)
    c = c * D / (Ann * N_COINS)
    b: uint256 = S_ + D / Ann
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


@private
@constant
def _calc_withdraw_one_coin(_token_amount: uint256, i: int128, rates: uint256[N_COINS]) -> (uint256, uint256):
    # First, need to calculate
    # * Get current D
    # * Solve Eqn against y_i for D - _token_amount
    amp: uint256 = self._A()
    _fee: uint256 = self.fee * N_COINS / (4 * (N_COINS - 1))
    precisions: uint256[N_COINS] = PRECISION_MUL
    total_supply: uint256 = self.token.totalSupply()

    xp: uint256[N_COINS] = self._xp(rates)

    D0: uint256 = self.get_D(xp, amp)
    D1: uint256 = D0 - _token_amount * D0 / total_supply
    xp_reduced: uint256[N_COINS] = xp

    new_y: uint256 = self.get_y_D(amp, i, xp, D1)
    dy_0: uint256 = (xp[i] - new_y) / precisions[i]  # w/o fees

    for j in range(N_COINS):
        dx_expected: uint256 = 0
        if j == i:
            dx_expected = xp[j] * D1 / D0 - new_y
        else:
            dx_expected = xp[j] - xp[j] * D1 / D0
        xp_reduced[j] -= _fee * dx_expected / FEE_DENOMINATOR

    dy: uint256 = xp_reduced[i] - self.get_y_D(amp, i, xp_reduced, D1)
    dy = (dy - 1) / precisions[i]  # Withdraw less to account for rounding errors

    return dy, dy_0 - dy


@public
@constant
def calc_withdraw_one_coin(_token_amount: uint256, i: int128) -> uint256:
    rates: uint256[N_COINS] = self._rates()
    return self._calc_withdraw_one_coin(_token_amount, i, rates)[0]


@public
@nonreentrant('lock')
def remove_liquidity_one_coin(_token_amount: uint256, i: int128, min_amount: uint256):
    """
    Remove _amount of liquidity all in a form of coin i
    """
    dy: uint256 = 0
    dy_fee: uint256 = 0
    rates: uint256[N_COINS] = self._rates()
    dy, dy_fee = self._calc_withdraw_one_coin(_token_amount, i, rates)
    assert dy >= min_amount, "Not enough coins removed"

    self.balances[i] -= (dy + dy_fee * self.admin_fee / FEE_DENOMINATOR)
    self.token.burnFrom(msg.sender, _token_amount)
    assert_modifiable(ERC20(self.coins[i]).transfer(msg.sender, dy))

    log.RemoveLiquidityOne(msg.sender, _token_amount, dy)


### Admin functions ###
@public
def ramp_A(_future_A: uint256, _future_time: timestamp):
    assert msg.sender == self.owner
    assert block.timestamp >= self.initial_A_time + min_ramp_time
    assert _future_time >= block.timestamp + min_ramp_time

    _initial_A: uint256 = self._A()
    assert (_future_A > 0) and (_future_A < max_A)
    assert ((_future_A >= _initial_A) and (_future_A <= _initial_A * max_A_change)) or\
           ((_future_A < _initial_A) and (_future_A * max_A_change >= _initial_A))
    self.initial_A = _initial_A
    self.future_A = _future_A
    self.initial_A_time = block.timestamp
    self.future_A_time = _future_time

    log.RampA(_initial_A, _future_A, block.timestamp, _future_time)


@public
def stop_ramp_A():
    assert msg.sender == self.owner

    current_A: uint256 = self._A()
    self.initial_A = current_A
    self.future_A = current_A
    self.initial_A_time = block.timestamp
    self.future_A_time = block.timestamp
    # now (block.timestamp < t1) is always False, so we return saved A

    log.StopRampA(current_A, block.timestamp)


@public
def commit_new_fee(new_fee: uint256, new_admin_fee: uint256):
    assert msg.sender == self.owner
    assert self.admin_actions_deadline == 0
    assert new_admin_fee <= max_admin_fee
    assert new_fee <= max_fee

    _deadline: timestamp = block.timestamp + admin_actions_delay
    self.admin_actions_deadline = _deadline
    self.future_fee = new_fee
    self.future_admin_fee = new_admin_fee

    log.CommitNewFee(_deadline, new_fee, new_admin_fee)


@public
def apply_new_fee():
    assert msg.sender == self.owner
    assert self.admin_actions_deadline <= block.timestamp\
        and self.admin_actions_deadline > 0

    self.admin_actions_deadline = 0
    _fee: uint256 = self.future_fee
    _admin_fee: uint256 = self.future_admin_fee
    self.fee = _fee
    self.admin_fee = _admin_fee

    log.NewFee(_fee, _admin_fee)


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
