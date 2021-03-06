pragma solidity ^0.4.24;

interface ConflictResolutionInterface {
    function minHouseStake(uint activeGames) external pure returns(uint);

    function maxBalance() external pure returns(int);

    function isValidBet(uint8 _gameType, uint _betNum, uint _betValue) external pure returns(bool);

    function endGameConflict(
        uint8 _gameType,
        uint _betNum,
        uint _betValue,
        int _balance,
        uint _stake,
        bytes32 _serverSeed,
        bytes32 _playerSeed
    )
        external
        view
        returns(int);

    function serverForceGameEnd(
        uint8 gameType,
        uint _betNum,
        uint _betValue,
        int _balance,
        uint _stake,
        uint _endInitiatedTime
    )
        external
        view
        returns(int);

    function playerForceGameEnd(
        uint8 _gameType,
        uint _betNum,
        uint _betValue,
        int _balance,
        uint _stake,
        uint _endInitiatedTime
    )
        external
        view
        returns(int);
}

library MathUtil {
    /**
     * @dev Returns the absolute value of _val.
     * @param _val value
     * @return The absolute value of _val.
     */
    function abs(int _val) internal pure returns(uint) {
        if (_val < 0) {
            return uint(-_val);
        } else {
            return uint(_val);
        }
    }

    /**
     * @dev Calculate maximum.
     */
    function max(uint _val1, uint _val2) internal pure returns(uint) {
        return _val1 >= _val2 ? _val1 : _val2;
    }

    /**
     * @dev Calculate minimum.
     */
    function min(uint _val1, uint _val2) internal pure returns(uint) {
        return _val1 <= _val2 ? _val1 : _val2;
    }
}

contract Ownable {
    address public owner;
    address public pendingOwner;

    event LogOwnerShipTransferred(address indexed previousOwner, address indexed newOwner);
    event LogOwnerShipTransferInitiated(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Modifier, which throws if called by other account than owner.
     */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    /**
     * @dev Set contract creator as initial owner
     */
    constructor() public {
        owner = msg.sender;
        pendingOwner = address(0);
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        pendingOwner = _newOwner;
        emit LogOwnerShipTransferInitiated(owner, _newOwner);
    }

    /**
     * @dev New owner can accpet ownership.
     */
    function claimOwnership() public onlyPendingOwner {
        emit LogOwnerShipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

contract ConflictResolutionManager is Ownable {
    /// @dev Conflict resolution contract.
    ConflictResolutionInterface public conflictRes;

    /// @dev New Conflict resolution contract.
    address public newConflictRes = 0;

    /// @dev Time update of new conflict resolution contract was initiated.
    uint public updateTime = 0;

    /// @dev Min time before new conflict res contract can be activated after initiating update.
    uint public constant MIN_TIMEOUT = 3 days;

    /// @dev Min time before new conflict res contract can be activated after initiating update.
    uint public constant MAX_TIMEOUT = 6 days;

    /// @dev Update of conflict resolution contract was initiated.
    event LogUpdatingConflictResolution(address newConflictResolutionAddress);

    /// @dev New conflict resolution contract is active.
    event LogUpdatedConflictResolution(address newConflictResolutionAddress);

    /**
     * @dev Constructor
     * @param _conflictResAddress conflict resolution contract address.
     */
    constructor(address _conflictResAddress) public {
        conflictRes = ConflictResolutionInterface(_conflictResAddress);
    }

    /**
     * @dev Initiate conflict resolution contract update.
     * @param _newConflictResAddress New conflict resolution contract address.
     */
    function updateConflictResolution(address _newConflictResAddress) public onlyOwner {
        newConflictRes = _newConflictResAddress;
        updateTime = block.timestamp;

        emit LogUpdatingConflictResolution(_newConflictResAddress);
    }

    /**
     * @dev Active new conflict resolution contract.
     */
    function activateConflictResolution() public onlyOwner {
        require(newConflictRes != 0);
        require(updateTime != 0);
        require(updateTime + MIN_TIMEOUT <= block.timestamp && block.timestamp <= updateTime + MAX_TIMEOUT);

        conflictRes = ConflictResolutionInterface(newConflictRes);
        newConflictRes = 0;
        updateTime = 0;

        emit LogUpdatedConflictResolution(newConflictRes);
    }
}

contract Pausable is Ownable {
    /// @dev Is contract paused.
    bool public paused = false;

    /// @dev Time pause was called
    uint public timePaused = 0;

    /// @dev Modifier, which only allows function execution if not paused.
    modifier onlyNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier, which only allows function execution if paused.
    modifier onlyPaused() {
        require(paused);
        _;
    }

    /// @dev Modifier, which only allows function execution if paused longer than timeSpan.
    modifier onlyPausedSince(uint timeSpan) {
        require(paused && timePaused + timeSpan <= block.timestamp);
        _;
    }

    /// @dev Event is fired if paused.
    event LogPause();

    /// @dev Event is fired if pause is ended.
    event LogUnpause();

    /**
     * @dev Pause contract. No new game sessions can be created.
     */
    function pause() public onlyOwner onlyNotPaused {
        paused = true;
        timePaused = block.timestamp;
        emit LogPause();
    }

    /**
     * @dev Unpause contract.
     */
    function unpause() public onlyOwner onlyPaused {
        paused = false;
        timePaused = 0;
        emit LogUnpause();
    }
}

contract Destroyable is Pausable {
    /// @dev After pausing the contract for 20 days owner can selfdestruct it.
    uint public constant TIMEOUT_DESTROY = 20 days;

    /**
     * @dev Destroy contract and transfer ether to address _targetAddress.
     */
    function destroy() public onlyOwner onlyPausedSince(TIMEOUT_DESTROY) {
        selfdestruct(owner);
    }
}

contract GameChannelBase is Destroyable, ConflictResolutionManager {
    /// @dev Different game session states.
    enum GameStatus {
        ENDED, ///< @dev Game session is ended.
        ACTIVE, ///< @dev Game session is active.
        PLAYER_INITIATED_END, ///< @dev Player initiated non regular end.
        SERVER_INITIATED_END ///< @dev Server initiated non regular end.
    }

    /// @dev Reason game session ended.
    enum ReasonEnded {
        REGULAR_ENDED, ///< @dev Game session is regularly ended.
        END_FORCED_BY_SERVER, ///< @dev Player did not respond. Server forced end.
        END_FORCED_BY_PLAYER ///< @dev Server did not respond. Player forced end.
    }

    struct Game {
        /// @dev Game session status.
        GameStatus status;

        /// @dev Player's stake.
        uint128 stake;

        /// @dev Last game round info if not regularly ended.
        /// If game session is ended normally this data is not used.
        uint8 gameType;
        uint32 roundId;
        uint16 betNum;
        uint betValue;
        int balance;
        bytes32 playerSeed;
        bytes32 serverSeed;
        uint endInitiatedTime;
    }

    /// @dev Minimal time span between profit transfer.
    uint public constant MIN_TRANSFER_TIMESPAN = 1 days;

    /// @dev Maximal time span between profit transfer.
    uint public constant MAX_TRANSFER_TIMSPAN = 6 * 30 days;

    bytes32 public constant TYPE_HASH = keccak256(abi.encodePacked(
        "uint32 Round Id",
        "uint8 Game Type",
        "uint16 Number",
        "uint Value (Wei)",
        "int Current Balance (Wei)",
        "bytes32 Server Hash",
        "bytes32 Player Hash",
        "uint Game Id",
        "address Contract Address"
     ));

    /// @dev Current active game sessions.
    uint public activeGames = 0;

    /// @dev Game session id counter. Points to next free game session slot. So gameIdCntr -1 is the
    // number of game sessions created.
    uint public gameIdCntr;

    /// @dev Only this address can accept and end games.
    address public serverAddress;

    /// @dev Address to transfer profit to.
    address public houseAddress;

    /// @dev Current house stake.
    uint public houseStake = 0;

    /// @dev House profit since last profit transfer.
    int public houseProfit = 0;

    /// @dev Min value player needs to deposit for creating game session.
    uint128 public minStake;

    /// @dev Max value player can deposit for creating game session.
    uint128 public maxStake;

    /// @dev Timeout until next profit transfer is allowed.
    uint public profitTransferTimeSpan = 14 days;

    /// @dev Last time profit transferred to house.
    uint public lastProfitTransferTimestamp;

    /// @dev Maps gameId to game struct.
    mapping (uint => Game) public gameIdGame;

    /// @dev Maps player address to current player game id.
    mapping (address => uint) public playerGameId;

    /// @dev Maps player address to pending returns.
    mapping (address => uint) public pendingReturns;

    /// @dev Modifier, which only allows to execute if house stake is high enough.
    modifier onlyValidHouseStake(uint _activeGames) {
        uint minHouseStake = conflictRes.minHouseStake(_activeGames);
        require(houseStake >= minHouseStake);
        _;
    }

    /// @dev Modifier to check if value send fulfills player stake requirements.
    modifier onlyValidValue() {
        require(minStake <= msg.value && msg.value <= maxStake);
        _;
    }

    /// @dev Modifier, which only allows server to call function.
    modifier onlyServer() {
        require(msg.sender == serverAddress);
        _;
    }

    /// @dev Modifier, which only allows to set valid transfer timeouts.
    modifier onlyValidTransferTimeSpan(uint transferTimeout) {
        require(transferTimeout >= MIN_TRANSFER_TIMESPAN
                && transferTimeout <= MAX_TRANSFER_TIMSPAN);
        _;
    }

    /// @dev This event is fired when player creates game session.
    event LogGameCreated(address indexed player, uint indexed gameId, uint128 stake, bytes32 indexed serverEndHash, bytes32 playerEndHash);

    /// @dev This event is fired when player requests conflict end.
    event LogPlayerRequestedEnd(address indexed player, uint indexed gameId);

    /// @dev This event is fired when server requests conflict end.
    event LogServerRequestedEnd(address indexed player, uint indexed gameId);

    /// @dev This event is fired when game session is ended.
    event LogGameEnded(address indexed player, uint indexed gameId, uint32 roundId, int balance, ReasonEnded reason);

    /// @dev this event is fired when owner modifies player's stake limits.
    event LogStakeLimitsModified(uint minStake, uint maxStake);

    /**
     * @dev Contract constructor.
     * @param _serverAddress Server address.
     * @param _minStake Min value player needs to deposit to create game session.
     * @param _maxStake Max value player can deposit to create game session.
     * @param _conflictResAddress Conflict resolution contract address.
     * @param _houseAddress House address to move profit to.
     */
    constructor(
        address _serverAddress,
        uint128 _minStake,
        uint128 _maxStake,
        address _conflictResAddress,
        address _houseAddress,
        uint _gameIdCntr
    )
        public
        ConflictResolutionManager(_conflictResAddress)
    {
        require(_minStake > 0 && _minStake <= _maxStake);
        require(_gameIdCntr > 0);

        gameIdCntr = _gameIdCntr;
        serverAddress = _serverAddress;
        houseAddress = _houseAddress;
        lastProfitTransferTimestamp = block.timestamp;
        minStake = _minStake;
        maxStake = _maxStake;
    }

    /**
     * @notice Withdraw pending returns.
     */
    function withdraw() public {
        uint toTransfer = pendingReturns[msg.sender];
        require(toTransfer > 0);

        pendingReturns[msg.sender] = 0;
        msg.sender.transfer(toTransfer);
    }

    /**
     * @notice Transfer house profit to houseAddress.
     */
    function transferProfitToHouse() public {
        require(lastProfitTransferTimestamp + profitTransferTimeSpan <= block.timestamp);

        // update last transfer timestamp
        lastProfitTransferTimestamp = block.timestamp;

        if (houseProfit <= 0) {
            // no profit to transfer
            return;
        }

        // houseProfit is gt 0 => safe to cast
        uint toTransfer = uint(houseProfit);
        assert(houseStake >= toTransfer);

        houseProfit = 0;
        houseStake = houseStake - toTransfer;

        houseAddress.transfer(toTransfer);
    }

    /**
     * @dev Set profit transfer time span.
     */
    function setProfitTransferTimeSpan(uint _profitTransferTimeSpan)
        public
        onlyOwner
        onlyValidTransferTimeSpan(_profitTransferTimeSpan)
    {
        profitTransferTimeSpan = _profitTransferTimeSpan;
    }

    /**
     * @dev Increase house stake by msg.value
     */
    function addHouseStake() public payable onlyOwner {
        houseStake += msg.value;
    }

    /**
     * @dev Withdraw house stake.
     */
    function withdrawHouseStake(uint value) public onlyOwner {
        uint minHouseStake = conflictRes.minHouseStake(activeGames);

        require(value <= houseStake && houseStake - value >= minHouseStake);
        require(houseProfit <= 0 || uint(houseProfit) <= houseStake - value);

        houseStake = houseStake - value;
        owner.transfer(value);
    }

    /**
     * @dev Withdraw house stake and profit.
     */
    function withdrawAll() public onlyOwner onlyPausedSince(3 days) {
        houseProfit = 0;
        uint toTransfer = houseStake;
        houseStake = 0;
        owner.transfer(toTransfer);
    }

    /**
     * @dev Set new house address.
     * @param _houseAddress New house address.
     */
    function setHouseAddress(address _houseAddress) public onlyOwner {
        houseAddress = _houseAddress;
    }

    /**
     * @dev Set stake min and max value.
     * @param _minStake Min stake.
     * @param _maxStake Max stake.
     */
    function setStakeRequirements(uint128 _minStake, uint128 _maxStake) public onlyOwner {
        require(_minStake > 0 && _minStake <= _maxStake);
        minStake = _minStake;
        maxStake = _maxStake;
        emit LogStakeLimitsModified(minStake, maxStake);
    }

    /**
     * @dev Close game session.
     * @param _game Game session data.
     * @param _gameId Id of game session.
     * @param _playerAddress Player's address of game session.
     * @param _reason Reason for closing game session.
     * @param _balance Game session balance.
     */
    function closeGame(
        Game storage _game,
        uint _gameId,
        uint32 _roundId,
        address _playerAddress,
        ReasonEnded _reason,
        int _balance
    )
        internal
    {
        _game.status = GameStatus.ENDED;

        assert(activeGames > 0);
        activeGames = activeGames - 1;

        payOut(_playerAddress, _game.stake, _balance);

        emit LogGameEnded(_playerAddress, _gameId, _roundId, _balance, _reason);
    }

    /**
     * @dev End game by paying out player and server.
     * @param _playerAddress Player's address.
     * @param _stake Player's stake.
     * @param _balance Player's balance.
     */
    function payOut(address _playerAddress, uint128 _stake, int _balance) internal {
        assert(_balance <= conflictRes.maxBalance());
        assert((int(_stake) + _balance) >= 0); // safe as _balance (see line above), _stake ranges are fixed.

        uint valuePlayer = uint(int(_stake) + _balance); // safe as _balance, _stake ranges are fixed.

        if (_balance > 0 && int(houseStake) < _balance) { // safe to cast houseStake is limited.
            // Should never happen!
            // House is bankrupt.
            // Payout left money.
            valuePlayer = houseStake;
        }

        houseProfit = houseProfit - _balance;

        int newHouseStake = int(houseStake) - _balance; // safe to cast and sub as houseStake, balance ranges are fixed
        assert(newHouseStake >= 0);
        houseStake = uint(newHouseStake);

        pendingReturns[_playerAddress] += valuePlayer;
        if (pendingReturns[_playerAddress] > 0) {
            safeSend(_playerAddress);
        }
    }

    /**
     * @dev Send value of pendingReturns[_address] to _address.
     * @param _address Address to send value to.
     */
    function safeSend(address _address) internal {
        uint valueToSend = pendingReturns[_address];
        assert(valueToSend > 0);

        pendingReturns[_address] = 0;
        if (_address.send(valueToSend) == false) {
            pendingReturns[_address] = valueToSend;
        }
    }

    /**
     * @dev Verify signature of given data. Throws on verification failure.
     * @param _sig Signature of given data in the form of rsv.
     * @param _address Address of signature signer.
     */
    function verifySig(
        uint32 _roundId,
        uint8 _gameType,
        uint16 _num,
        uint _value,
        int _balance,
        bytes32 _serverHash,
        bytes32 _playerHash,
        uint _gameId,
        address _contractAddress,
        bytes _sig,
        address _address
    )
        internal
        view
    {
        // check if this is the correct contract
        address contractAddress = this;
        require(_contractAddress == contractAddress);

        bytes32 roundHash = calcHash(
                _roundId,
                _gameType,
                _num,
                _value,
                _balance,
                _serverHash,
                _playerHash,
                _gameId,
                _contractAddress
        );

        verify(
                roundHash,
                _sig,
                _address
        );
    }

     /**
     * @dev Check if _sig is valid signature of _hash. Throws if invalid signature.
     * @param _hash Hash to check signature of.
     * @param _sig Signature of _hash.
     * @param _address Address of signer.
     */
    function verify(
        bytes32 _hash,
        bytes _sig,
        address _address
    )
        internal
        pure
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        (r, s, v) = signatureSplit(_sig);
        address addressRecover = ecrecover(_hash, v, r, s);
        require(addressRecover == _address);
    }

    /**
     * @dev Calculate typed hash of given data (compare eth_signTypedData).
     * @return Hash of given data.
     */
    function calcHash(
        uint32 _roundId,
        uint8 _gameType,
        uint16 _num,
        uint _value,
        int _balance,
        bytes32 _serverHash,
        bytes32 _playerHash,
        uint _gameId,
        address _contractAddress
    )
        private
        pure
        returns(bytes32)
    {
        bytes32 dataHash = keccak256(abi.encodePacked(
            _roundId,
            _gameType,
            _num,
            _value,
            _balance,
            _serverHash,
            _playerHash,
            _gameId,
            _contractAddress
        ));

        return keccak256(abi.encodePacked(
            TYPE_HASH,
            dataHash
        ));
    }

    /**
     * @dev Split the given signature of the form rsv in r s v. v is incremented with 27 if
     * it is below 2.
     * @param _signature Signature to split.
     * @return r s v
     */
    function signatureSplit(bytes _signature)
        private
        pure
        returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(_signature.length == 65);

        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := and(mload(add(_signature, 65)), 0xff)
        }
        if (v < 2) {
            v = v + 27;
        }
    }
}

contract GameChannelConflict is GameChannelBase {
    /**
     * @dev Contract constructor.
     * @param _serverAddress Server address.
     * @param _minStake Min value player needs to deposit to create game session.
     * @param _maxStake Max value player can deposit to create game session.
     * @param _conflictResAddress Conflict resolution contract address
     * @param _houseAddress House address to move profit to
     */
    constructor(
        address _serverAddress,
        uint128 _minStake,
        uint128 _maxStake,
        address _conflictResAddress,
        address _houseAddress,
        uint _gameIdCtr
    )
        public
        GameChannelBase(_serverAddress, _minStake, _maxStake, _conflictResAddress, _houseAddress, _gameIdCtr)
    {
        // nothing to do
    }

    /**
     * @dev Used by server if player does not end game session.
     * @param _roundId Round id of bet.
     * @param _gameType Game type of bet.
     * @param _num Number of bet.
     * @param _value Value of bet.
     * @param _balance Balance before this bet.
     * @param _serverHash Hash of server seed for this bet.
     * @param _playerHash Hash of player seed for this bet.
     * @param _gameId Game session id.
     * @param _contractAddress Address of this contract.
     * @param _playerSig Player signature of this bet.
     * @param _playerAddress Address of player.
     * @param _serverSeed Server seed for this bet.
     * @param _playerSeed Player seed for this bet.
     */
    function serverEndGameConflict(
        uint32 _roundId,
        uint8 _gameType,
        uint16 _num,
        uint _value,
        int _balance,
        bytes32 _serverHash,
        bytes32 _playerHash,
        uint _gameId,
        address _contractAddress,
        bytes _playerSig,
        address _playerAddress,
        bytes32 _serverSeed,
        bytes32 _playerSeed
    )
        public
        onlyServer
    {
        verifySig(
                _roundId,
                _gameType,
                _num,
                _value,
                _balance,
                _serverHash,
                _playerHash,
                _gameId,
                _contractAddress,
                _playerSig,
                _playerAddress
        );

        serverEndGameConflictImpl(
                _roundId,
                _gameType,
                _num,
                _value,
                _balance,
                _serverHash,
                _playerHash,
                _serverSeed,
                _playerSeed,
                _gameId,
                _playerAddress
        );
    }

    /**
     * @notice Can be used by player if server does not answer to the end game session request.
     * @param _roundId Round id of bet.
     * @param _gameType Game type of bet.
     * @param _num Number of bet.
     * @param _value Value of bet.
     * @param _balance Balance before this bet.
     * @param _serverHash Hash of server seed for this bet.
     * @param _playerHash Hash of player seed for this bet.
     * @param _gameId Game session id.
     * @param _contractAddress Address of this contract.
     * @param _serverSig Server signature of this bet.
     * @param _playerSeed Player seed for this bet.
     */
    function playerEndGameConflict(
        uint32 _roundId,
        uint8 _gameType,
        uint16 _num,
        uint _value,
        int _balance,
        bytes32 _serverHash,
        bytes32 _playerHash,
        uint _gameId,
        address _contractAddress,
        bytes _serverSig,
        bytes32 _playerSeed
    )
        public
    {
        verifySig(
            _roundId,
            _gameType,
            _num,
            _value,
            _balance,
            _serverHash,
            _playerHash,
            _gameId,
            _contractAddress,
            _serverSig,
            serverAddress
        );

        playerEndGameConflictImpl(
            _roundId,
            _gameType,
            _num,
            _value,
            _balance,
            _playerHash,
            _playerSeed,
            _gameId,
            msg.sender
        );
    }

    /**
     * @notice Cancel active game without playing. Useful if server stops responding before
     * one game is played.
     * @param _gameId Game session id.
     */
    function playerCancelActiveGame(uint _gameId) public {
        address playerAddress = msg.sender;
        uint gameId = playerGameId[playerAddress];
        Game storage game = gameIdGame[gameId];

        require(gameId == _gameId);

        if (game.status == GameStatus.ACTIVE) {
            game.endInitiatedTime = block.timestamp;
            game.status = GameStatus.PLAYER_INITIATED_END;

            emit LogPlayerRequestedEnd(msg.sender, gameId);
        } else if (game.status == GameStatus.SERVER_INITIATED_END && game.roundId == 0) {
            closeGame(game, gameId, 0, playerAddress, ReasonEnded.REGULAR_ENDED, 0);
        } else {
            revert();
        }
    }

    /**
     * @dev Cancel active game without playing. Useful if player starts game session and
     * does not play.
     * @param _playerAddress Players' address.
     * @param _gameId Game session id.
     */
    function serverCancelActiveGame(address _playerAddress, uint _gameId) public onlyServer {
        uint gameId = playerGameId[_playerAddress];
        Game storage game = gameIdGame[gameId];

        require(gameId == _gameId);

        if (game.status == GameStatus.ACTIVE) {
            game.endInitiatedTime = block.timestamp;
            game.status = GameStatus.SERVER_INITIATED_END;

            emit LogServerRequestedEnd(msg.sender, gameId);
        } else if (game.status == GameStatus.PLAYER_INITIATED_END && game.roundId == 0) {
            closeGame(game, gameId, 0, _playerAddress, ReasonEnded.REGULAR_ENDED, 0);
        } else {
            revert();
        }
    }

    /**
    * @dev Force end of game if player does not respond. Only possible after a certain period of time
    * to give the player a chance to respond.
    * @param _playerAddress Player's address.
    */
    function serverForceGameEnd(address _playerAddress, uint _gameId) public onlyServer {
        uint gameId = playerGameId[_playerAddress];
        Game storage game = gameIdGame[gameId];

        require(gameId == _gameId);
        require(game.status == GameStatus.SERVER_INITIATED_END);

        // theoretically we have enough data to calculate winner
        // but as player did not respond assume he has lost.
        int newBalance = conflictRes.serverForceGameEnd(
            game.gameType,
            game.betNum,
            game.betValue,
            game.balance,
            game.stake,
            game.endInitiatedTime
        );

        closeGame(game, gameId, game.roundId, _playerAddress, ReasonEnded.END_FORCED_BY_SERVER, newBalance);
    }

    /**
    * @notice Force end of game if server does not respond. Only possible after a certain period of time
    * to give the server a chance to respond.
    */
    function playerForceGameEnd(uint _gameId) public {
        address playerAddress = msg.sender;
        uint gameId = playerGameId[playerAddress];
        Game storage game = gameIdGame[gameId];

        require(gameId == _gameId);
        require(game.status == GameStatus.PLAYER_INITIATED_END);

        int newBalance = conflictRes.playerForceGameEnd(
            game.gameType,
            game.betNum,
            game.betValue,
            game.balance,
            game.stake,
            game.endInitiatedTime
        );

        closeGame(game, gameId, game.roundId, playerAddress, ReasonEnded.END_FORCED_BY_PLAYER, newBalance);
    }

    /**
     * @dev Conflict handling implementation. Stores game data and timestamp if game
     * is active. If server has already marked conflict for game session the conflict
     * resolution contract is used (compare conflictRes).
     * @param _roundId Round id of bet.
     * @param _gameType Game type of bet.
     * @param _num Number of bet.
     * @param _value Value of bet.
     * @param _balance Balance before this bet.
     * @param _playerHash Hash of player's seed for this bet.
     * @param _playerSeed Player's seed for this bet.
     * @param _gameId game Game session id.
     * @param _playerAddress Player's address.
     */
    function playerEndGameConflictImpl(
        uint32 _roundId,
        uint8 _gameType,
        uint16 _num,
        uint _value,
        int _balance,
        bytes32 _playerHash,
        bytes32 _playerSeed,
        uint _gameId,
        address _playerAddress
    )
        private
    {
        uint gameId = playerGameId[_playerAddress];
        Game storage game = gameIdGame[gameId];
        int maxBalance = conflictRes.maxBalance();

        require(gameId == _gameId);
        require(_roundId > 0);
        require(keccak256(abi.encodePacked(_playerSeed)) == _playerHash);
        require(-int(game.stake) <= _balance && _balance <= maxBalance); // save to cast as ranges are fixed
        require(conflictRes.isValidBet(_gameType, _num, _value));
        require(int(game.stake) + _balance - int(_value) >= 0); // save to cast as ranges are fixed

        if (game.status == GameStatus.SERVER_INITIATED_END && game.roundId == _roundId) {
            game.playerSeed = _playerSeed;
            endGameConflict(game, gameId, _playerAddress);
        } else if (game.status == GameStatus.ACTIVE
                || (game.status == GameStatus.SERVER_INITIATED_END && game.roundId < _roundId)) {
            game.status = GameStatus.PLAYER_INITIATED_END;
            game.endInitiatedTime = block.timestamp;
            game.roundId = _roundId;
            game.gameType = _gameType;
            game.betNum = _num;
            game.betValue = _value;
            game.balance = _balance;
            game.playerSeed = _playerSeed;
            game.serverSeed = bytes32(0);

            emit LogPlayerRequestedEnd(msg.sender, gameId);
        } else {
            revert();
        }
    }

    /**
     * @dev Conflict handling implementation. Stores game data and timestamp if game
     * is active. If player has already marked conflict for game session the conflict
     * resolution contract is used (compare conflictRes).
     * @param _roundId Round id of bet.
     * @param _gameType Game type of bet.
     * @param _num Number of bet.
     * @param _value Value of bet.
     * @param _balance Balance before this bet.
     * @param _serverHash Hash of server's seed for this bet.
     * @param _playerHash Hash of player's seed for this bet.
     * @param _serverSeed Server's seed for this bet.
     * @param _playerSeed Player's seed for this bet.
     * @param _playerAddress Player's address.
     */
    function serverEndGameConflictImpl(
        uint32 _roundId,
        uint8 _gameType,
        uint16 _num,
        uint _value,
        int _balance,
        bytes32 _serverHash,
        bytes32 _playerHash,
        bytes32 _serverSeed,
        bytes32 _playerSeed,
        uint _gameId,
        address _playerAddress
    )
        private
    {
        uint gameId = playerGameId[_playerAddress];
        Game storage game = gameIdGame[gameId];
        int maxBalance = conflictRes.maxBalance();

        require(gameId == _gameId);
        require(_roundId > 0);
        require(keccak256(abi.encodePacked(_serverSeed)) == _serverHash);
        require(keccak256(abi.encodePacked(_playerSeed)) == _playerHash);
        require(-int(game.stake) <= _balance && _balance <= maxBalance); // save to cast as ranges are fixed
        require(conflictRes.isValidBet(_gameType, _num, _value));
        require(int(game.stake) + _balance - int(_value) >= 0); // save to cast as ranges are fixed

        if (game.status == GameStatus.PLAYER_INITIATED_END && game.roundId == _roundId) {
            game.serverSeed = _serverSeed;
            endGameConflict(game, gameId, _playerAddress);
        } else if (game.status == GameStatus.ACTIVE
                || (game.status == GameStatus.PLAYER_INITIATED_END && game.roundId < _roundId)) {
            game.status = GameStatus.SERVER_INITIATED_END;
            game.endInitiatedTime = block.timestamp;
            game.roundId = _roundId;
            game.gameType = _gameType;
            game.betNum = _num;
            game.betValue = _value;
            game.balance = _balance;
            game.serverSeed = _serverSeed;
            game.playerSeed = _playerSeed;

            emit LogServerRequestedEnd(_playerAddress, gameId);
        } else {
            revert();
        }
    }

    /**
     * @dev End conflicting game.
     * @param _game Game session data.
     * @param _gameId Game session id.
     * @param _playerAddress Player's address.
     */
    function endGameConflict(Game storage _game, uint _gameId, address _playerAddress) private {
        int newBalance = conflictRes.endGameConflict(
            _game.gameType,
            _game.betNum,
            _game.betValue,
            _game.balance,
            _game.stake,
            _game.serverSeed,
            _game.playerSeed
        );

        closeGame(_game, _gameId, _game.roundId, _playerAddress, ReasonEnded.REGULAR_ENDED, newBalance);
    }
}

contract GameChannel is GameChannelConflict {
    /**
     * @dev contract constructor
     * @param _serverAddress Server address.
     * @param _minStake Min value player needs to deposit to create game session.
     * @param _maxStake Max value player can deposit to create game session.
     * @param _conflictResAddress Conflict resolution contract address.
     * @param _houseAddress House address to move profit to.
     */
    constructor(
        address _serverAddress,
        uint128 _minStake,
        uint128 _maxStake,
        address _conflictResAddress,
        address _houseAddress,
        uint _gameIdCntr
    )
        public
        GameChannelConflict(_serverAddress, _minStake, _maxStake, _conflictResAddress, _houseAddress, _gameIdCntr)
    {
        // nothing to do
    }

    /**
     * @notice Create games session request. msg.value needs to be valid stake value.
     * @param _playerEndHash last entry of players' hash chain.
     * @param _previousGameId player's previous game id, initial 0.
     * @param _createBefore game can be only created before this timestamp.
     * @param _serverEndHash last entry of server's hash chain.
     * @param _serverSig server signature. See verifyCreateSig
     */
    function createGame(
        bytes32 _playerEndHash,
        uint _previousGameId,
        uint _createBefore,
        bytes32 _serverEndHash,
        bytes _serverSig
    )
        public
        payable
        onlyValidValue
        onlyValidHouseStake(activeGames + 1)
        onlyNotPaused
    {
        uint previousGameId = playerGameId[msg.sender];
        Game storage game = gameIdGame[previousGameId];

        require(game.status == GameStatus.ENDED);
        require(previousGameId == _previousGameId);
        require(block.timestamp < _createBefore);

        verifyCreateSig(msg.sender, _previousGameId, _createBefore, _serverEndHash, _serverSig);

        uint gameId = gameIdCntr++;
        playerGameId[msg.sender] = gameId;
        Game storage newGame = gameIdGame[gameId];

        newGame.stake = uint128(msg.value); // It's safe to cast msg.value as it is limited, see onlyValidValue
        newGame.status = GameStatus.ACTIVE;

        activeGames = activeGames + 1;

        // It's safe to cast msg.value as it is limited, see onlyValidValue
        emit LogGameCreated(msg.sender, gameId, uint128(msg.value), _serverEndHash,  _playerEndHash);
    }


    /**
     * @dev Regular end game session. Used if player and house have both
     * accepted current game session state.
     * The game session with gameId _gameId is closed
     * and the player paid out. This functions is called by the server after
     * the player requested the termination of the current game session.
     * @param _roundId Round id of bet.
     * @param _gameType Game type of bet.
     * @param _num Number of bet.
     * @param _value Value of bet.
     * @param _balance Current balance.
     * @param _serverHash Hash of server's seed for this bet.
     * @param _playerHash Hash of player's seed for this bet.
     * @param _gameId Game session id.
     * @param _contractAddress Address of this contract.
     * @param _playerAddress Address of player.
     * @param _playerSig Player's signature of this bet.
     */
    function serverEndGame(
        uint32 _roundId,
        uint8 _gameType,
        uint16 _num,
        uint _value,
        int _balance,
        bytes32 _serverHash,
        bytes32 _playerHash,
        uint _gameId,
        address _contractAddress,
        address _playerAddress,
        bytes _playerSig
    )
        public
        onlyServer
    {
        verifySig(
                _roundId,
                _gameType,
                _num,
                _value,
                _balance,
                _serverHash,
                _playerHash,
                _gameId,
                _contractAddress,
                _playerSig,
                _playerAddress
        );

        regularEndGame(_playerAddress, _roundId, _gameType, _num, _value, _balance, _gameId, _contractAddress);
    }

    /**
     * @notice Regular end game session. Normally not needed as server ends game (@see serverEndGame).
     * Can be used by player if server does not end game session.
     * @param _roundId Round id of bet.
     * @param _gameType Game type of bet.
     * @param _num Number of bet.
     * @param _value Value of bet.
     * @param _balance Current balance.
     * @param _serverHash Hash of server's seed for this bet.
     * @param _playerHash Hash of player's seed for this bet.
     * @param _gameId Game session id.
     * @param _contractAddress Address of this contract.
     * @param _serverSig Server's signature of this bet.
     */
    function playerEndGame(
        uint32 _roundId,
        uint8 _gameType,
        uint16 _num,
        uint _value,
        int _balance,
        bytes32 _serverHash,
        bytes32 _playerHash,
        uint _gameId,
        address _contractAddress,
        bytes _serverSig
    )
        public
    {
        verifySig(
                _roundId,
                _gameType,
                _num,
                _value,
                _balance,
                _serverHash,
                _playerHash,
                _gameId,
                _contractAddress,
                _serverSig,
                serverAddress
        );

        regularEndGame(msg.sender, _roundId, _gameType, _num, _value, _balance, _gameId, _contractAddress);
    }

    /**
     * @dev Verify server signature.
     * @param _playerAddress player's address.
     * @param _previousGameId player's previous game id, initial 0.
     * @param _createBefore game can be only created before this timestamp.
     * @param _serverEndHash last entry of server's hash chain.
     * @param _serverSig server signature.
     */
    function verifyCreateSig(
        address _playerAddress,
        uint _previousGameId,
        uint _createBefore,
        bytes32 _serverEndHash,
        bytes _serverSig
    )
        private view
    {
        address contractAddress = this;
        bytes32 hash = keccak256(abi.encodePacked(
            contractAddress, _playerAddress, _previousGameId, _createBefore, _serverEndHash
        ));

        verify(hash, _serverSig, serverAddress);
    }

    /**
     * @dev Regular end game session implementation. Used if player and house have both
     * accepted current game session state. The game session with gameId _gameId is closed
     * and the player paid out.
     * @param _playerAddress Address of player.
     * @param _gameType Game type of bet.
     * @param _num Number of bet.
     * @param _value Value of bet.
     * @param _balance Current balance.
     * @param _gameId Game session id.
     * @param _contractAddress Address of this contract.
     */
    function regularEndGame(
        address _playerAddress,
        uint32 _roundId,
        uint8 _gameType,
        uint16 _num,
        uint _value,
        int _balance,
        uint _gameId,
        address _contractAddress
    )
        private
    {
        uint gameId = playerGameId[_playerAddress];
        Game storage game = gameIdGame[gameId];
        address contractAddress = this;
        int maxBalance = conflictRes.maxBalance();

        require(_gameId == gameId);
        require(_roundId > 0);
        // save to cast as game.stake hash fixed range
        require(-int(game.stake) <= _balance && _balance <= maxBalance);
        require((_gameType == 0) && (_num == 0) && (_value == 0));
        require(game.status == GameStatus.ACTIVE);

        assert(_contractAddress == contractAddress);

        closeGame(game, gameId, _roundId, _playerAddress, ReasonEnded.REGULAR_ENDED, _balance);
    }
}
