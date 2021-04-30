{{
  "language": "Solidity",
  "sources": {
    "contracts/NTokenController.sol": {
      "content": "// SPDX-License-Identifier: GPL-3.0-or-later\n\npragma solidity ^0.6.12;\n\npragma experimental ABIEncoderV2;\n\nimport \"./lib/SafeMath.sol\";\nimport \"./lib/SafeERC20.sol\";\nimport './lib/TransferHelper.sol';\nimport \"./lib/ReentrancyGuard.sol\";\n\nimport \"./iface/INestPool.sol\";\nimport \"./iface/INTokenController.sol\";\nimport \"./iface/INToken.sol\";\nimport \"./NToken.sol\";\n\n// import \"./NestMining.sol\";\n// import \"./iface/INNRewardPool.sol\";\n\n/// @title NTokenController\n/// @author Inf Loop - \n/// @author Paradox  - \n\ncontract NTokenController is INTokenController, ReentrancyGuard {\n\n    using SafeMath for uint256;\n    using SafeERC20 for ERC20;\n\n    /* ========== STATE VARIABLES ============== */\n\n    /// @dev A number counter for generating ntoken name\n    uint32  public ntokenCounter;\n    uint8   public flag;         // 0: uninitialized | 1: active | 2: shutdown\n    uint216 private _reserved;\n\n    uint8   constant NTCTRL_FLAG_UNINITIALIZED    = 0;\n    uint8   constant NTCTRL_FLAG_ACTIVE           = 1;\n    uint8   constant NTCTRL_FLAG_PAUSED           = 2;\n\n    /// @dev A mapping for all auctions\n    ///     token(address) => NTokenTag\n    mapping(address => NTokenTag) private nTokenTagList;\n\n    /* ========== PARAMETERS ============== */\n\n    uint256 public openFeeNestAmount = 10_000; // default = 10_000\n\n    /* ========== ADDRESSES ============== */\n\n    /// @dev Contract address of NestPool\n    address public C_NestPool;\n    /// @dev Contract address of NestToken\n    address public C_NestToken;\n    /// @dev Contract address of NestDAO\n    address public C_NestDAO;\n\n    address private governance;\n\n    /* ========== EVENTS ============== */\n\n    /// @notice when the auction of a token gets started\n    /// @param token    The address of the (ERC20) token\n    /// @param ntoken   The address of the ntoken w.r.t. token for incentives\n    /// @param owner    The address of miner who opened the oracle\n    event NTokenOpened(address token, address ntoken, address owner);\n    event NTokenDisabled(address token);\n    event NTokenEnabled(address token);\n\n    /* ========== CONSTRUCTOR ========== */\n\n    constructor(address NestPool) public\n    {\n        governance = msg.sender;\n        flag = NTCTRL_FLAG_UNINITIALIZED;\n        C_NestPool = NestPool;\n    }\n\n    /// @dev The initialization function takes `_ntokenCounter` as argument, \n    ///     which shall be migrated from Nest v3.0\n    function start(uint32 _ntokenCounter) public onlyGovernance\n    {\n        require(flag == NTCTRL_FLAG_UNINITIALIZED, \"Nest:NTC:!flag\");\n        ntokenCounter = _ntokenCounter;\n        flag = NTCTRL_FLAG_ACTIVE;\n        emit FlagSet(address(msg.sender), uint256(NTCTRL_FLAG_ACTIVE));\n    }\n\n    modifier noContract()\n    {\n        require(address(msg.sender) == address(tx.origin), \"Nest:NTC:^(contract)\");\n        _;\n    }\n\n    modifier whenActive() \n    {\n        require(flag == NTCTRL_FLAG_ACTIVE, \"Nest:NTC:!flag\");\n        _;\n    }\n\n    modifier onlyGovOrBy(address _account)\n    {\n        if (msg.sender != governance) { \n            require(msg.sender == _account,\n                \"Nest:NTC:!Auth\");\n        }\n        _;\n    }\n\n    /* ========== GOVERNANCE ========== */\n\n    modifier onlyGovernance() \n    {\n        require(msg.sender == governance, \"Nest:NTC:!governance\");\n        _;\n    }\n\n    function loadGovernance() override external\n    {\n        governance = INestPool(C_NestPool).governance();\n    }\n\n    /// @dev  It should be called immediately after the depolyment\n    function loadContracts() override external onlyGovOrBy(C_NestPool) \n    {\n        C_NestToken = INestPool(C_NestPool).addrOfNestToken();\n        C_NestDAO = INestPool(C_NestPool).addrOfNestDAO();\n    }\n    \n    function setParams(uint256 _openFeeNestAmount) override external onlyGovernance\n    {\n        emit ParamsSetup(address(msg.sender), openFeeNestAmount, _openFeeNestAmount);\n        openFeeNestAmount = _openFeeNestAmount;\n    }\n\n    /// @dev  Bad tokens should be banned \n    function disable(address token) external onlyGovernance\n    {\n        NTokenTag storage _to = nTokenTagList[token];\n        _to.state = 1;\n        emit NTokenDisabled(token);\n    }\n\n    function enable(address token) external onlyGovernance\n    {\n        NTokenTag storage _to = nTokenTagList[token];\n        _to.state = 0;\n        emit NTokenEnabled(token);\n    }\n\n    /// @dev Stop service for emergency\n    function pause() external onlyGovernance\n    {\n        require(flag == NTCTRL_FLAG_ACTIVE, \"Nest:NTC:!flag\");\n        flag = NTCTRL_FLAG_PAUSED;\n        emit FlagSet(address(msg.sender), uint256(NTCTRL_FLAG_PAUSED));\n    }\n\n    /// @dev Resume service \n    function resume() external onlyGovernance\n    {\n        require(flag == NTCTRL_FLAG_PAUSED, \"Nest:NTC:!flag\");\n        flag = NTCTRL_FLAG_ACTIVE;\n        emit FlagSet(address(msg.sender), uint256(NTCTRL_FLAG_ACTIVE));\n    }\n\n    /* ========== OPEN ========== */\n\n    /// @notice  Open a NToken for a token by anyone (contracts aren't allowed)\n    /// @dev  Create and map the (Token, NToken) pair in NestPool\n    /// @param token  The address of token contract\n    function open(address token) override external noContract whenActive\n    {\n        require(INestPool(C_NestPool).getNTokenFromToken(token) == address(0x0),\n            \"Nest:NTC:EX(token)\");\n        require(nTokenTagList[token].state == 0,\n            \"Nest:NTC:DIS(token)\");\n\n        nTokenTagList[token] = NTokenTag(\n            address(msg.sender),                                // owner\n            uint128(0),                                         // nestFee\n            uint64(block.timestamp),                            // startTime\n            0,                                                  // state\n            0                                                   // _reserved\n        );\n        \n        //  create ntoken\n        NToken ntoken = new NToken(strConcat(\"NToken\",\n                getAddressStr(ntokenCounter)),\n                strConcat(\"N\", getAddressStr(ntokenCounter)),\n                address(governance),\n                // NOTE: here `bidder`, we use `C_NestPool` to separate new NTokens \n                //   from old ones, whose bidders are the miners creating NTokens\n                address(C_NestPool)\n        );\n\n        // increase the counter\n        ntokenCounter = ntokenCounter + 1;  // safe math\n        INestPool(C_NestPool).setNTokenToToken(token, address(ntoken));\n\n        // is token valid ?\n        ERC20 tokenERC20 = ERC20(token);\n        tokenERC20.safeTransferFrom(address(msg.sender), address(this), 1);\n        require(tokenERC20.balanceOf(address(this)) >= 1, \n            \"Nest:NTC:!TEST(token)\");\n        tokenERC20.safeTransfer(address(msg.sender), 1);\n\n        // charge nest\n        ERC20(C_NestToken).transferFrom(address(msg.sender), address(C_NestDAO), openFeeNestAmount);\n\n        // raise an event\n        emit NTokenOpened(token, address(ntoken), address(msg.sender));\n\n    }\n\n    /* ========== VIEWS ========== */\n\n    function NTokenTagOf(address token) override public view returns (NTokenTag memory) \n    {\n        return nTokenTagList[token];\n    }\n\n    /* ========== HELPERS ========== */\n\n    /// @dev from NESTv3.0\n    function strConcat(string memory _a, string memory _b) public pure returns (string memory)\n    {\n        bytes memory _ba = bytes(_a);\n        bytes memory _bb = bytes(_b);\n        string memory ret = new string(_ba.length + _bb.length);\n        bytes memory bret = bytes(ret);\n        uint k = 0;\n        for (uint i = 0; i < _ba.length; i++) {\n            bret[k++] = _ba[i];\n        } \n        for (uint i = 0; i < _bb.length; i++) {\n            bret[k++] = _bb[i];\n        } \n        return string(ret);\n    } \n    \n    /// @dev Convert a 4-digital number into a string, from NestV3.0\n    function getAddressStr(uint256 iv) public pure returns (string memory) \n    {\n        bytes memory buf = new bytes(64);\n        uint256 index = 0;\n        do {\n            buf[index++] = byte(uint8(iv % 10 + 48));\n            iv /= 10;\n        } while (iv > 0 || index < 4);\n        bytes memory str = new bytes(index);\n        for(uint256 i = 0; i < index; ++i) {\n            str[i] = buf[index - i - 1];\n        }\n        return string(str);\n    }\n\n}"
    },
    "contracts/lib/SafeMath.sol": {
      "content": "// SPDX-License-Identifier: GPL-3.0-or-later\n\npragma solidity ^0.6.12;\n\n// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)\n\nlibrary SafeMath {\n    function add(uint x, uint y) internal pure returns (uint z) {\n        require((z = x + y) >= x, 'ds-math-add-overflow');\n    }\n\n    function sub(uint x, uint y) internal pure returns (uint z) {\n        require((z = x - y) <= x, 'ds-math-sub-underflow');\n    }\n\n    function mul(uint x, uint y) internal pure returns (uint z) {\n        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');\n    }\n\n    function div(uint x, uint y) internal pure returns (uint z) {\n        require(y > 0, \"ds-math-div-zero\");\n        z = x / y;\n        // assert(a == b * c + a % b); // There is no case in which this doesn't hold\n    }\n}"
    },
    "contracts/lib/SafeERC20.sol": {
      "content": "// SPDX-License-Identifier: GPL-3.0-or-later\n\npragma solidity 0.6.12;\n\nimport \"./Address.sol\";\nimport \"./SafeMath.sol\";\n\nlibrary SafeERC20 {\n    using SafeMath for uint256;\n    using Address for address;\n\n    function safeTransfer(ERC20 token, address to, uint256 value) internal {\n        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));\n    }\n\n    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {\n        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));\n    }\n\n    function safeApprove(ERC20 token, address spender, uint256 value) internal {\n        require((value == 0) || (token.allowance(address(this), spender) == 0),\n            \"SafeERC20: approve from non-zero to non-zero allowance\"\n        );\n        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));\n    }\n\n    function safeIncreaseAllowance(ERC20 token, address spender, uint256 value) internal {\n        uint256 newAllowance = token.allowance(address(this), spender).add(value);\n        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));\n    }\n\n    function safeDecreaseAllowance(ERC20 token, address spender, uint256 value) internal {\n        uint256 newAllowance = token.allowance(address(this), spender).sub(value);\n        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));\n    }\n    function callOptionalReturn(ERC20 token, bytes memory data) private {\n        require(address(token).isContract(), \"SafeERC20: call to non-contract\");\n        (bool success, bytes memory returndata) = address(token).call(data);\n        require(success, \"SafeERC20: low-level call failed\");\n        if (returndata.length > 0) {\n            require(abi.decode(returndata, (bool)), \"SafeERC20: ERC20 operation did not succeed\");\n        }\n    }\n}\n\ninterface ERC20 {\n    function totalSupply() external view returns (uint256);\n    function balanceOf(address account) external view returns (uint256);\n    function transfer(address recipient, uint256 amount) external returns (bool);\n    function allowance(address owner, address spender) external view returns (uint256);\n    function approve(address spender, uint256 amount) external returns (bool);\n    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);\n    event Transfer(address indexed from, address indexed to, uint256 value);\n    event Approval(address indexed owner, address indexed spender, uint256 value);\n}"
    },
    "contracts/lib/TransferHelper.sol": {
      "content": "// SPDX-License-Identifier: GPL-3.0-or-later\n\npragma solidity ^0.6.12;\n\n// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false\nlibrary TransferHelper {\n    function safeApprove(address token, address to, uint value) internal {\n        // bytes4(keccak256(bytes('approve(address,uint256)')));\n        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));\n        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');\n    }\n\n    function safeTransfer(address token, address to, uint value) internal {\n        // bytes4(keccak256(bytes('transfer(address,uint256)')));\n        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));\n        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');\n    }\n\n    function safeTransferFrom(address token, address from, address to, uint value) internal {\n        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));\n        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));\n        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');\n    }\n\n    function safeTransferETH(address to, uint value) internal {\n        (bool success,) = to.call{value:value}(new bytes(0));\n        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');\n    }\n}"
    },
    "contracts/lib/ReentrancyGuard.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity ^0.6.0;\n\n/// @dev The non-empty constructor is conflict with upgrades-openzeppelin. \n\n/**\n * @dev Contract module that helps prevent reentrant calls to a function.\n *\n * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier\n * available, which can be applied to functions to make sure there are no nested\n * (reentrant) calls to them.\n *\n * Note that because there is a single `nonReentrant` guard, functions marked as\n * `nonReentrant` may not call one another. This can be worked around by making\n * those functions `private`, and then adding `external` `nonReentrant` entry\n * points to them.\n *\n * TIP: If you would like to learn more about reentrancy and alternative ways\n * to protect against it, check out our blog post\n * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].\n */\ncontract ReentrancyGuard {\n    // Booleans are more expensive than uint256 or any type that takes up a full\n    // word because each write operation emits an extra SLOAD to first read the\n    // slot's contents, replace the bits taken up by the boolean, and then write\n    // back. This is the compiler's defense against contract upgrades and\n    // pointer aliasing, and it cannot be disabled.\n\n    // The values being non-zero value makes deployment a bit more expensive,\n    // but in exchange the refund on every call to nonReentrant will be lower in\n    // amount. Since refunds are capped to a percentage of the total\n    // transaction's gas, it is best to keep them low in cases like this one, to\n    // increase the likelihood of the full refund coming into effect.\n\n    // NOTE: _NOT_ENTERED is set to ZERO such that it needn't constructor\n    uint256 private constant _NOT_ENTERED = 0;\n    uint256 private constant _ENTERED = 1;\n\n    uint256 private _status;\n\n    // constructor () internal {\n    //     _status = _NOT_ENTERED;\n    // }\n\n    /**\n     * @dev Prevents a contract from calling itself, directly or indirectly.\n     * Calling a `nonReentrant` function from another `nonReentrant`\n     * function is not supported. It is possible to prevent this from happening\n     * by making the `nonReentrant` function external, and make it call a\n     * `private` function that does the actual work.\n     */\n    modifier nonReentrant() {\n        // On the first call to nonReentrant, _notEntered will be true\n        require(_status != _ENTERED, \"ReentrancyGuard: reentrant call\");\n\n        // Any calls to nonReentrant after this point will fail\n        _status = _ENTERED;\n\n        _;\n\n        // By storing the original value once again, a refund is triggered (see\n        // https://eips.ethereum.org/EIPS/eip-2200)\n        _status = _NOT_ENTERED;\n    }\n}"
    },
    "contracts/iface/INestPool.sol": {
      "content": "// SPDX-License-Identifier: GPL-3.0-or-later\n\npragma solidity ^0.6.12;\n\nimport \"../lib/SafeERC20.sol\";\n\ninterface INestPool {\n\n    // function getNTokenFromToken(address token) view external returns (address);\n    // function setNTokenToToken(address token, address ntoken) external; \n\n    function addNest(address miner, uint256 amount) external;\n    function addNToken(address contributor, address ntoken, uint256 amount) external;\n\n    function depositEth(address miner) external payable;\n    function depositNToken(address miner,  address from, address ntoken, uint256 amount) external;\n\n    function freezeEth(address miner, uint256 ethAmount) external; \n    function unfreezeEth(address miner, uint256 ethAmount) external;\n\n    function freezeNest(address miner, uint256 nestAmount) external;\n    function unfreezeNest(address miner, uint256 nestAmount) external;\n\n    function freezeToken(address miner, address token, uint256 tokenAmount) external; \n    function unfreezeToken(address miner, address token, uint256 tokenAmount) external;\n\n    function freezeEthAndToken(address miner, uint256 ethAmount, address token, uint256 tokenAmount) external;\n    function unfreezeEthAndToken(address miner, uint256 ethAmount, address token, uint256 tokenAmount) external;\n\n    function getNTokenFromToken(address token) external view returns (address); \n    function setNTokenToToken(address token, address ntoken) external; \n\n    function withdrawEth(address miner, uint256 ethAmount) external;\n    function withdrawToken(address miner, address token, uint256 tokenAmount) external;\n\n    function withdrawNest(address miner, uint256 amount) external;\n    function withdrawEthAndToken(address miner, uint256 ethAmount, address token, uint256 tokenAmount) external;\n    // function withdrawNToken(address miner, address ntoken, uint256 amount) external;\n    function withdrawNTokenAndTransfer(address miner, address ntoken, uint256 amount, address to) external;\n\n\n    function balanceOfNestInPool(address miner) external view returns (uint256);\n    function balanceOfEthInPool(address miner) external view returns (uint256);\n    function balanceOfTokenInPool(address miner, address token)  external view returns (uint256);\n\n    function addrOfNestToken() external view returns (address);\n    function addrOfNestMining() external view returns (address);\n    function addrOfNTokenController() external view returns (address);\n    function addrOfNNRewardPool() external view returns (address);\n    function addrOfNNToken() external view returns (address);\n    function addrOfNestStaking() external view returns (address);\n    function addrOfNestQuery() external view returns (address);\n    function addrOfNestDAO() external view returns (address);\n\n    function addressOfBurnedNest() external view returns (address);\n\n    function setGovernance(address _gov) external; \n    function governance() external view returns(address);\n    function initNestLedger(uint256 amount) external;\n    function drainNest(address to, uint256 amount, address gov) external;\n\n}"
    },
    "contracts/iface/INTokenController.sol": {
      "content": "// SPDX-License-Identifier: GPL-3.0-or-later\n\npragma solidity ^0.6.12;\npragma experimental ABIEncoderV2;\n\ninterface INTokenController {\n\n    /// @dev A struct for an ntoken\n    ///     size: 2 x 256bit\n    struct NTokenTag {\n        address owner;          // the owner with the highest bid\n        uint128 nestFee;        // NEST amount staked for opening a NToken\n        uint64  startTime;      // the start time of service\n        uint8   state;          // =0: normal | =1 disabled\n        uint56  _reserved;      // padding space\n    }\n\n    function open(address token) external;\n    \n    function NTokenTagOf(address token) external view returns (NTokenTag memory);\n\n    /// @dev Only for governance\n    function loadContracts() external; \n\n    function loadGovernance() external;\n\n    function setParams(uint256 _openFeeNestAmount) external;\n\n    event ParamsSetup(address gov, uint256 oldParam, uint256 newParam);\n\n    event FlagSet(address gov, uint256 flag);\n\n}\n"
    },
    "contracts/iface/INToken.sol": {
      "content": "// SPDX-License-Identifier: GPL-3.0-or-later\n\npragma solidity ^0.6.12;\n\ninterface INToken {\n    // mint ntoken for value\n    function mint(uint256 amount, address account) external;\n\n    // the block height where the ntoken was created\n    function checkBlockInfo() external view returns(uint256 createBlock, uint256 recentlyUsedBlock);\n    // the owner (auction winner) of the ntoken\n    function checkBidder() external view returns(address);\n    function totalSupply() external view returns (uint256);\n    function balanceOf(address account) external view returns (uint256);\n    function transfer(address recipient, uint256 amount) external returns (bool);\n    function allowance(address owner, address spender) external view returns (uint256);\n    function approve(address spender, uint256 amount) external returns (bool);\n    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);\n    \n    event Transfer(address indexed from, address indexed to, uint256 value);\n    event Approval(address indexed owner, address indexed spender, uint256 value);\n\n}"
    },
    "contracts/NToken.sol": {
      "content": "// SPDX-License-Identifier: GPL-3.0-or-later\n\npragma solidity ^0.6.12;\n\nimport \"./lib/SafeMath.sol\";\nimport \"./iface/INToken.sol\";\nimport \"./iface/INestPool.sol\";\n\n\n/// @title NNRewardPool\n/// @author MLY0813 - \n/// @author Inf Loop - \n/// @author Paradox  - \n\n// The contract is based on Nest_NToken from Nest Protocol v3.0. Considering compatibility, the interface\n// keeps the same. \n\ncontract NToken is INToken {\n    using SafeMath for uint256;\n    \n    mapping (address => uint256) private _balances;\n    mapping (address => mapping (address => uint256)) private _allowed;\n    uint256 public _totalSupply = 0 ether;                                        \n    string public name;\n    string public symbol;\n    uint8 public decimals = 18;\n    uint256 public createdAtHeight;\n    uint256 public lastestMintAtHeight;\n    address public governance;\n\n    /// @dev The address of NestPool (Nest Protocol v3.5)\n    address C_NestPool;\n    address C_NestMining;\n    \n    /// @notice Constructor\n    /// @dev Given the address of NestPool, NToken can get other contracts by calling addrOfxxx()\n    /// @param _name The name of NToken\n    /// @param _symbol The symbol of NToken\n    /// @param gov The address of admin\n    /// @param NestPool The address of NestPool\n    constructor (string memory _name, string memory _symbol, address gov, address NestPool) public {\n    \tname = _name;                                                               \n    \tsymbol = _symbol;\n    \tcreatedAtHeight = block.number;\n    \tlastestMintAtHeight = block.number;\n    \tgovernance = gov;\n    \tC_NestPool = NestPool;\n        C_NestMining = INestPool(C_NestPool).addrOfNestMining();\n    }\n\n    modifier onlyGovernance() \n    {\n        require(msg.sender == governance, \"Nest:NTK:!gov\");\n        _;\n    }\n\n    /// @dev To ensure that all of governance-addresses be consist with each other\n    function loadGovernance() external \n    { \n        governance = INestPool(C_NestPool).governance();\n    }\n\n    function loadContracts() external onlyGovernance\n    {\n        C_NestMining = INestPool(C_NestPool).addrOfNestMining();\n    }\n\n    function resetNestPool(address _NestPool) external onlyGovernance\n    {\n        C_NestPool = _NestPool;\n    }\n\n    /// @dev Mint \n    /// @param amount The amount of NToken to add\n    /// @param account The account of NToken to add\n    function mint(uint256 amount, address account) override public {\n        require(address(msg.sender) == C_NestMining, \"Nest:NTK:!Auth\");\n        _balances[account] = _balances[account].add(amount);\n        _totalSupply = _totalSupply.add(amount);\n        lastestMintAtHeight = block.number;\n    }\n\n    /// @notice The view of totalSupply\n    /// @return The total supply of ntoken\n    function totalSupply() override public view returns (uint256) {\n        return _totalSupply;\n    }\n\n    /// @dev The view of balances\n    /// @param owner The address of an account\n    /// @return The balance of the account\n    function balanceOf(address owner) override public view returns (uint256) {\n        return _balances[owner];\n    }\n    \n    \n    /// @notice The view of variables about minting \n    /// @dev The naming follows Nestv3.0\n    /// @return createBlock The block number where the contract was created\n    /// @return recentlyUsedBlock The block number where the last minting went\n    function checkBlockInfo() \n        override public view \n        returns(uint256 createBlock, uint256 recentlyUsedBlock) \n    {\n        return (createdAtHeight, lastestMintAtHeight);\n    }\n\n    function allowance(address owner, address spender) override public view returns (uint256) \n    {\n        return _allowed[owner][spender];\n    }\n\n    function transfer(address to, uint256 value) override public returns (bool) \n    {\n        _transfer(msg.sender, to, value);\n        return true;\n    }\n\n    function approve(address spender, uint256 value) override public returns (bool) \n    {\n        require(spender != address(0));\n        _allowed[msg.sender][spender] = value;\n        emit Approval(msg.sender, spender, value);\n        return true;\n    }\n\n\n    function transferFrom(address from, address to, uint256 value) override public returns (bool) \n    {\n        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);\n        _transfer(from, to, value);\n        emit Approval(from, msg.sender, _allowed[from][msg.sender]);\n        return true;\n    }\n\n    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) \n    {\n        require(spender != address(0));\n\n        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);\n        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);\n        return true;\n    }\n\n    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) \n    {\n        require(spender != address(0));\n\n        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);\n        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);\n        return true;\n    }\n\n    function _transfer(address from, address to, uint256 value) internal {\n        _balances[from] = _balances[from].sub(value);\n        _balances[to] = _balances[to].add(value);\n        emit Transfer(from, to, value);\n    }\n    \n    /// @dev The ABI keeps unchanged with old NTokens, so as to support token-and-ntoken-mining\n    /// @return The address of bidder\n    function checkBidder() override public view returns(address) {\n        return C_NestPool;\n    }\n}"
    },
    "contracts/lib/Address.sol": {
      "content": "// SPDX-License-Identifier: GPL-3.0-or-later\n\npragma solidity 0.6.12;\n\nlibrary Address {\n    function isContract(address account) internal view returns (bool) {\n        bytes32 codehash;\n        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;\n        assembly { codehash := extcodehash(account) }\n        return (codehash != accountHash && codehash != 0x0);\n    }\n    function sendValue(address payable recipient, uint256 amount) internal {\n        require(address(this).balance >= amount, \"Address: insufficient balance\");\n        (bool success, ) = recipient.call{value:amount}(\"\");\n        require(success, \"Address: unable to send value, recipient may have reverted\");\n    }\n}"
    }
  },
  "settings": {
    "optimizer": {
      "enabled": true,
      "runs": 200
    },
    "outputSelection": {
      "*": {
        "*": [
          "evm.bytecode",
          "evm.deployedBytecode",
          "abi"
        ]
      }
    },
    "libraries": {}
  }
}}