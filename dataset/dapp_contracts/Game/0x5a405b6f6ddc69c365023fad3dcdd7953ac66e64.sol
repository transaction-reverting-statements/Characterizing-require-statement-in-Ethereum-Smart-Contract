{"Contracts.sol":{"content":"pragma solidity ^0.4.25;\n\nimport \"./Ownalbe.sol\";\n\n\ncontract Contracts is Ownable {\n    uint private constant ETH_BASE_UINT = 1000000000000000000;\n\n    // can accept token\n    function() external payable {\n    }\n\n    //transfer token to owner\n    function withdrawToOwner(uint payout) external onlyOwner {\n        _owner.transfer(payout);\n    }\n\n    function kill() external onlyOwner {\n        selfdestruct(owner());\n    }\n\n}\n"},"Croupier.sol":{"content":"pragma solidity ^0.4.25;\n\nimport \"./Ownalbe.sol\";\n\ncontract Croupier is Ownable {\n    address internal _croupier;\n\n    event CroupiershipTransferred(address indexed previousCroupier, address indexed newCroupier);\n\n    constructor () internal {\n        _croupier = msg.sender;\n        emit CroupiershipTransferred(address(0), _croupier);\n    }\n\n    /**\n     * @return the address of the croupier.\n     */\n    function croupier() public view returns (address) {\n        return _croupier;\n    }\n\n    /**\n     * @dev Throws if called by any account other than the croupier.\n     */\n    modifier onlyCroupier() {\n        require(isOwner() || isCroupier());\n        _;\n    }\n\n    /**\n     * @return true if `msg.sender` is the croupier of the contract.\n     */\n    function isCroupier() public view returns (bool) {\n        return msg.sender == _croupier;\n    }\n\n    /**\n     * @dev Allows the current owner to transfer control of the contract to a newCroupier.\n     * @param newCroupier The address to transfer croupiership to.\n     */\n    function transferCroupiership(address newCroupier) public onlyOwner {\n        _transferCroupiership(newCroupier);\n    }\n\n    /**\n     * @dev Transfers control of the contract to a newCroupier.\n     * @param newCroupier The address to transfer croupiership to.\n     */\n    function _transferCroupiership(address newCroupier) internal {\n        require(newCroupier != address(0));\n        emit CroupiershipTransferred(_croupier, newCroupier);\n        _croupier = newCroupier;\n    }\n}\n"},"Ownalbe.sol":{"content":"pragma solidity ^0.4.25;\n\n\ncontract Ownable {\n    address internal _owner;\n\n    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);\n\n    constructor () internal {\n        _owner = msg.sender;\n        emit OwnershipTransferred(address(0), _owner);\n    }\n\n    /**\n     * @return the address of the owner.\n     */\n    function owner() public view returns (address) {\n        return _owner;\n    }\n\n    /**\n     * @dev Throws if called by any account other than the owner.\n     */\n    modifier onlyOwner() {\n        require(isOwner());\n        _;\n    }\n\n    /**\n     * @return true if `msg.sender` is the owner of the contract.\n     */\n    function isOwner() public view returns (bool) {\n        return msg.sender == _owner;\n    }\n\n    /**\n     * @dev Allows the current owner to transfer control of the contract to a newOwner.\n     * @param newOwner The address to transfer ownership to.\n     */\n    function transferOwnership(address newOwner) public onlyOwner {\n        _transferOwnership(newOwner);\n    }\n\n    /**\n     * @dev Transfers control of the contract to a newOwner.\n     * @param newOwner The address to transfer ownership to.\n     */\n    function _transferOwnership(address newOwner) internal {\n        require(newOwner != address(0));\n        emit OwnershipTransferred(_owner, newOwner);\n        _owner = newOwner;\n    }\n}\n"},"SafeMath.sol":{"content":"pragma solidity ^0.4.25;\n\n\n/**\n * @title SafeMath\n * @dev Unsigned math operations with safety checks that revert on error\n */\nlibrary SafeMath {\n    /**\n     * @dev Multiplies two unsigned integers, reverts on overflow.\n     */\n    function mul(uint256 a, uint256 b) internal pure returns (uint256) {\n        // Gas optimization: this is cheaper than requiring \u0027a\u0027 not being zero, but the\n        // benefit is lost if \u0027b\u0027 is also tested.\n        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522\n        if (a == 0) {\n            return 0;\n        }\n\n        uint256 c = a * b;\n        require(c / a == b);\n\n        return c;\n    }\n\n    /**\n     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.\n     */\n    function div(uint256 a, uint256 b) internal pure returns (uint256) {\n        // Solidity only automatically asserts when dividing by 0\n        require(b \u003e 0);\n        uint256 c = a / b;\n        // assert(a == b * c + a % b); // There is no case in which this doesn\u0027t hold\n\n        return c;\n    }\n\n    /**\n     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).\n     */\n    function sub(uint256 a, uint256 b) internal pure returns (uint256) {\n        require(b \u003c= a);\n        uint256 c = a - b;\n\n        return c;\n    }\n\n    /**\n     * @dev Adds two unsigned integers, reverts on overflow.\n     */\n    function add(uint256 a, uint256 b) internal pure returns (uint256) {\n        uint256 c = a + b;\n        require(c \u003e= a);\n\n        return c;\n    }\n\n    /**\n     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),\n     * reverts when dividing by zero.\n     */\n    function mod(uint256 a, uint256 b) internal pure returns (uint256) {\n        require(b != 0);\n        return a % b;\n    }\n}"},"Wallet.sol":{"content":"pragma solidity ^0.4.25;\n\nimport \"./Contracts.sol\";\nimport \"./SafeMath.sol\";\nimport \"./Croupier.sol\";\nimport \"./Ownalbe.sol\";\n\n\ncontract Wallet is Ownable, Croupier, Contracts {\n    using SafeMath for *;\n\n    uint64 private _depositId = 0;\n    uint64 private _withdrawId = 0;\n\n    //log\n    event DepositPlaced(uint64 id, address player, uint256 amount, string memo);\n    event WithdrawPlaced(uint64 id, address player, uint256 amount, string memo);\n\n    function deposit(string memo) external payable {\n        require(tx.origin == msg.sender, \"No contract bet accepted\");\n        require(msg.value \u003e 0, \"Invalid amount\");\n\n        emit DepositPlaced(_depositId, msg.sender, msg.value, memo);\n        _depositId++;\n    }\n\n    function withdraw(address player, uint256 amount, string memo) external onlyCroupier {\n        player.transfer(amount);\n        emit WithdrawPlaced(_withdrawId, player, amount, memo);\n        _withdrawId++;\n    }\n}\n\n"}}
