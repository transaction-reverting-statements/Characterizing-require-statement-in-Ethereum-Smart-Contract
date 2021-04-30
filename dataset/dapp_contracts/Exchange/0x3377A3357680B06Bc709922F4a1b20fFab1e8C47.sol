{{
  "language": "Solidity",
  "sources": {
    "@openzeppelin/contracts/GSN/Context.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity ^0.6.0;\n\n/*\n * @dev Provides information about the current execution context, including the\n * sender of the transaction and its data. While these are generally available\n * via msg.sender and msg.data, they should not be accessed in such a direct\n * manner, since when dealing with GSN meta-transactions the account sending and\n * paying for execution may not be the actual sender (as far as an application\n * is concerned).\n *\n * This contract is only required for intermediate, library-like contracts.\n */\nabstract contract Context {\n    function _msgSender() internal view virtual returns (address payable) {\n        return msg.sender;\n    }\n\n    function _msgData() internal view virtual returns (bytes memory) {\n        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691\n        return msg.data;\n    }\n}\n"
    },
    "@openzeppelin/contracts/access/Ownable.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity ^0.6.0;\n\nimport \"../GSN/Context.sol\";\n/**\n * @dev Contract module which provides a basic access control mechanism, where\n * there is an account (an owner) that can be granted exclusive access to\n * specific functions.\n *\n * By default, the owner account will be the one that deploys the contract. This\n * can later be changed with {transferOwnership}.\n *\n * This module is used through inheritance. It will make available the modifier\n * `onlyOwner`, which can be applied to your functions to restrict their use to\n * the owner.\n */\ncontract Ownable is Context {\n    address private _owner;\n\n    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);\n\n    /**\n     * @dev Initializes the contract setting the deployer as the initial owner.\n     */\n    constructor () internal {\n        address msgSender = _msgSender();\n        _owner = msgSender;\n        emit OwnershipTransferred(address(0), msgSender);\n    }\n\n    /**\n     * @dev Returns the address of the current owner.\n     */\n    function owner() public view returns (address) {\n        return _owner;\n    }\n\n    /**\n     * @dev Throws if called by any account other than the owner.\n     */\n    modifier onlyOwner() {\n        require(_owner == _msgSender(), \"Ownable: caller is not the owner\");\n        _;\n    }\n\n    /**\n     * @dev Leaves the contract without owner. It will not be possible to call\n     * `onlyOwner` functions anymore. Can only be called by the current owner.\n     *\n     * NOTE: Renouncing ownership will leave the contract without an owner,\n     * thereby removing any functionality that is only available to the owner.\n     */\n    function renounceOwnership() public virtual onlyOwner {\n        emit OwnershipTransferred(_owner, address(0));\n        _owner = address(0);\n    }\n\n    /**\n     * @dev Transfers ownership of the contract to a new account (`newOwner`).\n     * Can only be called by the current owner.\n     */\n    function transferOwnership(address newOwner) public virtual onlyOwner {\n        require(newOwner != address(0), \"Ownable: new owner is the zero address\");\n        emit OwnershipTransferred(_owner, newOwner);\n        _owner = newOwner;\n    }\n}\n"
    },
    "@openzeppelin/contracts/math/SafeMath.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity ^0.6.0;\n\n/**\n * @dev Wrappers over Solidity's arithmetic operations with added overflow\n * checks.\n *\n * Arithmetic operations in Solidity wrap on overflow. This can easily result\n * in bugs, because programmers usually assume that an overflow raises an\n * error, which is the standard behavior in high level programming languages.\n * `SafeMath` restores this intuition by reverting the transaction when an\n * operation overflows.\n *\n * Using this library instead of the unchecked operations eliminates an entire\n * class of bugs, so it's recommended to use it always.\n */\nlibrary SafeMath {\n    /**\n     * @dev Returns the addition of two unsigned integers, reverting on\n     * overflow.\n     *\n     * Counterpart to Solidity's `+` operator.\n     *\n     * Requirements:\n     *\n     * - Addition cannot overflow.\n     */\n    function add(uint256 a, uint256 b) internal pure returns (uint256) {\n        uint256 c = a + b;\n        require(c >= a, \"SafeMath: addition overflow\");\n\n        return c;\n    }\n\n    /**\n     * @dev Returns the subtraction of two unsigned integers, reverting on\n     * overflow (when the result is negative).\n     *\n     * Counterpart to Solidity's `-` operator.\n     *\n     * Requirements:\n     *\n     * - Subtraction cannot overflow.\n     */\n    function sub(uint256 a, uint256 b) internal pure returns (uint256) {\n        return sub(a, b, \"SafeMath: subtraction overflow\");\n    }\n\n    /**\n     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on\n     * overflow (when the result is negative).\n     *\n     * Counterpart to Solidity's `-` operator.\n     *\n     * Requirements:\n     *\n     * - Subtraction cannot overflow.\n     */\n    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {\n        require(b <= a, errorMessage);\n        uint256 c = a - b;\n\n        return c;\n    }\n\n    /**\n     * @dev Returns the multiplication of two unsigned integers, reverting on\n     * overflow.\n     *\n     * Counterpart to Solidity's `*` operator.\n     *\n     * Requirements:\n     *\n     * - Multiplication cannot overflow.\n     */\n    function mul(uint256 a, uint256 b) internal pure returns (uint256) {\n        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the\n        // benefit is lost if 'b' is also tested.\n        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522\n        if (a == 0) {\n            return 0;\n        }\n\n        uint256 c = a * b;\n        require(c / a == b, \"SafeMath: multiplication overflow\");\n\n        return c;\n    }\n\n    /**\n     * @dev Returns the integer division of two unsigned integers. Reverts on\n     * division by zero. The result is rounded towards zero.\n     *\n     * Counterpart to Solidity's `/` operator. Note: this function uses a\n     * `revert` opcode (which leaves remaining gas untouched) while Solidity\n     * uses an invalid opcode to revert (consuming all remaining gas).\n     *\n     * Requirements:\n     *\n     * - The divisor cannot be zero.\n     */\n    function div(uint256 a, uint256 b) internal pure returns (uint256) {\n        return div(a, b, \"SafeMath: division by zero\");\n    }\n\n    /**\n     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on\n     * division by zero. The result is rounded towards zero.\n     *\n     * Counterpart to Solidity's `/` operator. Note: this function uses a\n     * `revert` opcode (which leaves remaining gas untouched) while Solidity\n     * uses an invalid opcode to revert (consuming all remaining gas).\n     *\n     * Requirements:\n     *\n     * - The divisor cannot be zero.\n     */\n    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {\n        require(b > 0, errorMessage);\n        uint256 c = a / b;\n        // assert(a == b * c + a % b); // There is no case in which this doesn't hold\n\n        return c;\n    }\n\n    /**\n     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),\n     * Reverts when dividing by zero.\n     *\n     * Counterpart to Solidity's `%` operator. This function uses a `revert`\n     * opcode (which leaves remaining gas untouched) while Solidity uses an\n     * invalid opcode to revert (consuming all remaining gas).\n     *\n     * Requirements:\n     *\n     * - The divisor cannot be zero.\n     */\n    function mod(uint256 a, uint256 b) internal pure returns (uint256) {\n        return mod(a, b, \"SafeMath: modulo by zero\");\n    }\n\n    /**\n     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),\n     * Reverts with custom message when dividing by zero.\n     *\n     * Counterpart to Solidity's `%` operator. This function uses a `revert`\n     * opcode (which leaves remaining gas untouched) while Solidity uses an\n     * invalid opcode to revert (consuming all remaining gas).\n     *\n     * Requirements:\n     *\n     * - The divisor cannot be zero.\n     */\n    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {\n        require(b != 0, errorMessage);\n        return a % b;\n    }\n}\n"
    },
    "@openzeppelin/contracts/token/ERC20/IERC20.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity ^0.6.0;\n\n/**\n * @dev Interface of the ERC20 standard as defined in the EIP.\n */\ninterface IERC20 {\n    /**\n     * @dev Returns the amount of tokens in existence.\n     */\n    function totalSupply() external view returns (uint256);\n\n    /**\n     * @dev Returns the amount of tokens owned by `account`.\n     */\n    function balanceOf(address account) external view returns (uint256);\n\n    /**\n     * @dev Moves `amount` tokens from the caller's account to `recipient`.\n     *\n     * Returns a boolean value indicating whether the operation succeeded.\n     *\n     * Emits a {Transfer} event.\n     */\n    function transfer(address recipient, uint256 amount) external returns (bool);\n\n    /**\n     * @dev Returns the remaining number of tokens that `spender` will be\n     * allowed to spend on behalf of `owner` through {transferFrom}. This is\n     * zero by default.\n     *\n     * This value changes when {approve} or {transferFrom} are called.\n     */\n    function allowance(address owner, address spender) external view returns (uint256);\n\n    /**\n     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.\n     *\n     * Returns a boolean value indicating whether the operation succeeded.\n     *\n     * IMPORTANT: Beware that changing an allowance with this method brings the risk\n     * that someone may use both the old and the new allowance by unfortunate\n     * transaction ordering. One possible solution to mitigate this race\n     * condition is to first reduce the spender's allowance to 0 and set the\n     * desired value afterwards:\n     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729\n     *\n     * Emits an {Approval} event.\n     */\n    function approve(address spender, uint256 amount) external returns (bool);\n\n    /**\n     * @dev Moves `amount` tokens from `sender` to `recipient` using the\n     * allowance mechanism. `amount` is then deducted from the caller's\n     * allowance.\n     *\n     * Returns a boolean value indicating whether the operation succeeded.\n     *\n     * Emits a {Transfer} event.\n     */\n    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);\n\n    /**\n     * @dev Emitted when `value` tokens are moved from one account (`from`) to\n     * another (`to`).\n     *\n     * Note that `value` may be zero.\n     */\n    event Transfer(address indexed from, address indexed to, uint256 value);\n\n    /**\n     * @dev Emitted when the allowance of a `spender` for an `owner` is set by\n     * a call to {approve}. `value` is the new allowance.\n     */\n    event Approval(address indexed owner, address indexed spender, uint256 value);\n}\n"
    },
    "contracts/KingServant.sol": {
      "content": "pragma solidity 0.6.12;\n\nimport \"@openzeppelin/contracts/token/ERC20/IERC20.sol\";\nimport \"@openzeppelin/contracts/math/SafeMath.sol\";\nimport \"@openzeppelin/contracts/access/Ownable.sol\";\nimport \"./interfaces/IKingSwapERC20.sol\";\nimport \"./interfaces/IKingSwapPair.sol\";\nimport \"./interfaces/IKingSwapFactory.sol\";\n\ncontract KingServant is Ownable {\n    using SafeMath for uint256;\n\n    IKingSwapFactory public factory;\n    address public table;\n    address public king;\n    address public weth;\n    uint8 public burnRatio = 0;\n\n    constructor(IKingSwapFactory _factory, address _table, address _king, address _weth) public {\n        require(\n            address(_factory) != address(0) && _table != address(0) && _king != address(0) && _weth != address(0),\n            \"invalid address\"\n        );\n        factory = _factory;\n        king = _king;\n        table = _table;\n        weth = _weth;\n    }\n\n    function convert(address token0, address token1) public {\n        // At least we try to make front-running harder to do.\n        require(msg.sender == tx.origin, \"do not convert from contract\");\n        IKingSwapPair pair = IKingSwapPair(factory.getPair(token0, token1));\n        pair.transfer(address(pair), pair.balanceOf(address(this)));\n        pair.burn(address(this));\n        uint256 wethAmount = _toWETH(token0) + _toWETH(token1);\n        uint256 wethAmountToBurn = burnRatio == 0 ? 0 : wethAmount.mul(burnRatio).div(10);\n        uint256 wethAmountOnTable = wethAmount.sub(wethAmountToBurn);\n        IERC20(weth).transfer(factory.getPair(weth, king), wethAmountOnTable);\n        _toKING(wethAmountOnTable, table);\n        if (wethAmountToBurn != 0) {\n            IERC20(weth).transfer(factory.getPair(weth, king), wethAmountToBurn);\n            _toKING(wethAmountToBurn, address(1));\n        }\n    }\n\n    function _toWETH(address token) internal returns (uint256) {\n        if (token == king) {\n            uint amount = IERC20(token).balanceOf(address(this));\n            uint amountToBurn = amount.mul(burnRatio).div(10);\n            uint amountOnTable = amount.sub(amountToBurn);\n            IERC20(token).transfer(table, amountOnTable);\n            IERC20(token).transfer(address(1), amountToBurn);\n            return 0;\n        }\n        if (token == weth) {\n            uint amount = IERC20(token).balanceOf(address(this));\n            return amount;\n        }\n        IKingSwapPair pair = IKingSwapPair(factory.getPair(token, weth));\n        if (address(pair) == address(0)) {\n            return 0;\n        }\n        (uint reserve0, uint reserve1,) = pair.getReserves();\n        address token0 = pair.token0();\n        (uint reserveIn, uint reserveOut) = token0 == token ? (reserve0, reserve1) : (reserve1, reserve0);\n        uint amountIn = IERC20(token).balanceOf(address(this));\n        uint amountInWithFee = amountIn.mul(9975);\n        uint numerator = amountInWithFee.mul(reserveOut);\n        uint denominator = reserveIn.mul(10000).add(amountInWithFee);\n        uint amountOut = numerator / denominator;\n        (uint amount0Out, uint amount1Out) = token0 == token ? (uint(0), amountOut) : (amountOut, uint(0));\n        IERC20(token).transfer(address(pair), amountIn);\n        pair.swap(amount0Out, amount1Out, address(this), new bytes(0));\n        return amountOut;\n    }\n\n    function _toKING(uint256 amountIn, address to) internal {\n        IKingSwapPair pair = IKingSwapPair(factory.getPair(weth, king));\n        (uint reserve0, uint reserve1,) = pair.getReserves();\n        address token0 = pair.token0();\n        (uint reserveIn, uint reserveOut) = token0 == weth ? (reserve0, reserve1) : (reserve1, reserve0);\n        // avoid stack too deep error\n        uint amountOut;\n        {\n            uint amountInWithFee = amountIn.mul(9975);\n            uint numerator = amountInWithFee.mul(reserveOut);\n            uint denominator = reserveIn.mul(10000).add(amountInWithFee);\n            amountOut = numerator / denominator;\n        }\n        (uint amount0Out, uint amount1Out) = token0 == weth ? (uint(0), amountOut) : (amountOut, uint(0));\n        pair.swap(amount0Out, amount1Out, to, new bytes(0));\n    }\n\n    function setBurnRatio(uint8 newRatio) public onlyOwner {\n        require(newRatio >= 0 && newRatio <= 10, \"invalid burn ratio\");\n        burnRatio = newRatio;\n    }\n}\n"
    },
    "contracts/interfaces/IKingSwapERC20.sol": {
      "content": "// SPDX-License-Identifier: GPL-3.0\npragma solidity >=0.6.0;\n\ninterface IKingSwapERC20 {\n    event Approval(address indexed owner, address indexed spender, uint value);\n    event Transfer(address indexed from, address indexed to, uint value);\n\n    function name() external pure returns (string memory);\n    function symbol() external pure returns (string memory);\n    function decimals() external pure returns (uint8);\n    function totalSupply() external view returns (uint);\n    function balanceOf(address owner) external view returns (uint);\n    function allowance(address owner, address spender) external view returns (uint);\n\n    function approve(address spender, uint value) external returns (bool);\n    function transfer(address to, uint value) external returns (bool);\n    function transferFrom(address from, address to, uint value) external returns (bool);\n\n    function DOMAIN_SEPARATOR() external view returns (bytes32);\n    function PERMIT_TYPEHASH() external pure returns (bytes32);\n    function nonces(address owner) external view returns (uint);\n\n    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;\n}\n"
    },
    "contracts/interfaces/IKingSwapFactory.sol": {
      "content": "// SPDX-License-Identifier: GPL-3.0\npragma solidity >=0.6.0;\n\ninterface IKingSwapFactory {\n    event PairCreated(address indexed token0, address indexed token1, address pair, uint);\n\n    function feeTo() external view returns (address);\n    function feeToSetter() external view returns (address);\n    function migrator() external view returns (address);\n\n    function getPair(address tokenA, address tokenB) external view returns (address pair);\n    function allPairs(uint) external view returns (address pair);\n    function allPairsLength() external view returns (uint);\n\n    function createPair(address tokenA, address tokenB) external returns (address pair);\n\n    function setFeeTo(address) external;\n    function setFeeToSetter(address) external;\n    function setMigrator(address) external;\n}\n"
    },
    "contracts/interfaces/IKingSwapPair.sol": {
      "content": "// SPDX-License-Identifier: GPL-3.0\npragma solidity >=0.6.0;\n\ninterface IKingSwapPair {\n    event Approval(address indexed owner, address indexed spender, uint value);\n    event Transfer(address indexed from, address indexed to, uint value);\n\n    function name() external pure returns (string memory);\n    function symbol() external pure returns (string memory);\n    function decimals() external pure returns (uint8);\n    function totalSupply() external view returns (uint);\n    function balanceOf(address owner) external view returns (uint);\n    function allowance(address owner, address spender) external view returns (uint);\n\n    function approve(address spender, uint value) external returns (bool);\n    function transfer(address to, uint value) external returns (bool);\n    function transferFrom(address from, address to, uint value) external returns (bool);\n\n    function DOMAIN_SEPARATOR() external view returns (bytes32);\n    function PERMIT_TYPEHASH() external pure returns (bytes32);\n    function nonces(address owner) external view returns (uint);\n\n    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;\n\n    event Mint(address indexed sender, uint amount0, uint amount1);\n    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);\n    event Swap(\n        address indexed sender,\n        uint amount0In,\n        uint amount1In,\n        uint amount0Out,\n        uint amount1Out,\n        address indexed to\n    );\n    event Sync(uint112 reserve0, uint112 reserve1);\n\n    function MINIMUM_LIQUIDITY() external pure returns (uint);\n    function factory() external view returns (address);\n    function token0() external view returns (address);\n    function token1() external view returns (address);\n    function stoken() external view returns (address);\n    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);\n    function price0CumulativeLast() external view returns (uint);\n    function price1CumulativeLast() external view returns (uint);\n    function kLast() external view returns (uint);\n\n    function mint(address to) external returns (uint liquidity);\n    function burn(address to) external returns (uint amount0, uint amount1);\n    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;\n    function skim(address to) external;\n    function sync() external;\n\n    function initialize(address, address) external;\n    function dealSlippageWithIn(address[] calldata path, uint amountIn, address to, bool ifmint) external returns (uint amountOut);\n    function dealSlippageWithOut(address[] calldata path, uint amountOut, address to, bool ifmint) external returns (uint extra);\n    function getAmountOutMarket(address token, uint amountIn) external view returns (uint _out, uint t0Price);\n    function getAmountInMarket(address token, uint amountOut) external view returns (uint _in, uint t0Price);\n    function getAmountOutFinal(address token, uint256 amountIn) external view returns (uint256 amountOut, uint256 stokenAmount);\n    function getAmountInFinal(address token, uint256 amountOut) external view returns (uint256 amountIn, uint256 stokenAmount);\n    function getTokenMarketPrice(address token) external view returns (uint price);\n}\n"
    }
  },
  "settings": {
    "remappings": [],
    "optimizer": {
      "enabled": true,
      "runs": 200
    },
    "evmVersion": "istanbul",
    "libraries": {
      "": {}
    },
    "outputSelection": {
      "*": {
        "*": [
          "evm.bytecode",
          "evm.deployedBytecode",
          "abi"
        ]
      }
    }
  }
}}