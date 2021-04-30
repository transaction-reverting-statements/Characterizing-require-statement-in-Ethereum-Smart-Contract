// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Roles.sol

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// File: @openzeppelin/contracts/access/roles/PauserRole.sol

pragma solidity ^0.5.0;



contract PauserRole is Context {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(_msgSender());
    }

    modifier onlyPauser() {
        require(isPauser(_msgSender()), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(_msgSender());
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

// File: @openzeppelin/contracts/lifecycle/Pausable.sol

pragma solidity ^0.5.0;



/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context, PauserRole {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @animocabrands/contracts-inventory/contracts/token/ERC1155/ERC1155PausableCollections.sol

pragma solidity =0.5.16;


contract ERC1155PausableCollections is Pausable {
    event CollectionsPaused(uint256[] collectionIds, address pauser);
    event CollectionsUnpaused(uint256[] collectionIds, address pauser);

    mapping(uint256 => bool) internal _pausedCollections;

    /**
     * @dev Called by an admin to pause a list of collections.
     */
    function pauseCollections(uint256[] memory collectionIds) public;

    /**
     * @dev Called by an admin to unpause a list of collection.
     */
    function unpauseCollections(uint256[] memory collectionIds) public;
}

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following 
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts/introspection/IERC165.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol

pragma solidity ^0.5.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

// File: @animocabrands/contracts-inventory/contracts/token/ERC721/IERC721.sol

pragma solidity = 0.5.16;

 /**
    @title ERC721 Non-Fungible Token Standard, basic interface
    @dev See https://eips.ethereum.org/EIPS/eip-721
    Note: The ERC-165 identifier for this interface is 0x80ac58cd.
 */
contract IERC721 {
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );

    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );

    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    /**
     * @dev Gets the balance of the specified address
     * @param owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Gets the owner of the specified ID
     * @param tokenId uint256 ID to query the owner of
     * @return owner address currently marked as the owner of the given ID
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);

    /**
     * @dev Approves another address to transfer the given token ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per token at a given time.
     * Can only be called by the token owner or an approved operator.
     * @param to address to be approved for the given token ID
     * @param tokenId uint256 ID of the token to be approved
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Gets the approved address for a token ID, or zero if no address set
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to query the approval of
     * @return address currently approved for the given token ID
     */
    function getApproved(uint256 tokenId) public view returns (address operator);

    /**
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf
     * @param operator operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Tells whether an operator is approved by a given owner
     * @param owner owner address which you want to query the approval of
     * @param operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address owner,address operator) external view returns (bool);

    /**
     * @dev Transfers the ownership of a given token ID to another address
     * Usage of this method is discouraged, use `safeTransferFrom` whenever possible
     * Requires the msg sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
    */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     *
     * Requires the msg sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
    */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// File: @animocabrands/contracts-inventory/contracts/token/ERC721/IERC721Metadata.sol

pragma solidity = 0.5.16;

 /**
    @title ERC721 Non-Fungible Token Standard, optional metadata extension
    @dev See https://eips.ethereum.org/EIPS/eip-721
    Note: The ERC-165 identifier for this interface is 0x5b5e139f.
 */
interface IERC721Metadata {

    /**
     * @dev Gets the token name
     * @return string representing the token name
     */
    function name() external view returns (string memory);

    /**
     * @dev Gets the token symbol
     * @return string representing the token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns an URI for a given token ID
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     * @return string URI of given token ID
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @animocabrands/contracts-inventory/contracts/token/ERC1155/IERC1155.sol

pragma solidity = 0.5.16;

/**
    @title ERC-1155 Multi Token Standard, basic interface
    @dev See https://eips.ethereum.org/EIPS/eip-1155
    Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
contract IERC1155 {

    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _value
    );

    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _values
    );

    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    event URI(
        string _value,
        uint256 indexed _id
    );

    /**
        @notice Transfers `value` amount of an `id` from  `from` to `to`  (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `from` account (see "Approval" section of the standard).
        MUST revert if `to` is the zero address.
        MUST revert if balance of holder for token `id` is lower than the `value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param from    Source address
        @param to      Target address
        @param id      ID of the token type
        @param value   Transfer amount
        @param data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `to`
    */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) public;

    /**
        @notice Transfers `values` amount(s) of `ids` from the `from` address to the `to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `from` account (see "Approval" section of the standard).
        MUST revert if `to` is the zero address.
        MUST revert if length of `ids` is not the same as length of `values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `ids` is lower than the respective amount(s) in `values` sent to the recipient.
        MUST revert on any other error.
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param from    Source address
        @param to      Target address
        @param ids     IDs of each token type (order and length must match _values array)
        @param values  Transfer amounts per token type (order and length must match _ids array)
        @param data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `to`
    */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) public;

    /**
        @notice Get the balance of an account's tokens.
        @param owner  The address of the token holder
        @param id     ID of the token
        @return        The _owner's balance of the token type requested
     */
    function balanceOf(address owner, uint256 id) public view returns (uint256);

    /**
        @notice Get the balance of multiple account/token pairs
        @param owners The addresses of the token holders
        @param ids    ID of the tokens
        @return        The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(
        address[] memory owners,
        uint256[] memory ids
    ) public view returns (uint256[] memory);

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param operator  Address to add to the set of authorized operators
        @param approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address operator, bool approved) public;

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param owner     The owner of the tokens
        @param operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address owner, address operator) public view returns (bool);
}

// File: @animocabrands/contracts-inventory/contracts/token/ERC1155/IERC1155MetadataURI.sol

pragma solidity = 0.5.16;

/**
    @title ERC-1155 Multi Token Standard, optional metadata URI extension
    @dev See https://eips.ethereum.org/EIPS/eip-1155
    Note: The ERC-165 identifier for this interface is 0x0e89341c.
 */
interface IERC1155MetadataURI {
    /**
        @notice A distinct Uniform Resource Identifier (URI) for a given token.
        @dev URIs are defined in RFC 3986.
        The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema". 
        The uri function SHOULD be used to retrieve values if no event was emitted.
        The uri function MUST return the same value as the latest event for an _id if it was emitted.
        The uri function MUST NOT be used to check for the existence of a token as it is possible for an implementation to return a valid string even if the token does not exist.       
        @return URI string
    */
    function uri(uint256 id) external view returns (string memory);
}

// File: @animocabrands/contracts-inventory/contracts/token/ERC1155/IERC1155AssetCollections.sol

pragma solidity = 0.5.16;



/**
    @title ERC-1155 Multi Token Standard, optional Asset Collections extension
    @dev See https://eips.ethereum.org/EIPS/eip-xxxx
    Interface for fungible/non-fungible collections management on a 1155-compliant contract.
    This proposal attempts to rationalize the co-existence of fungible and non-fungible tokens
    within the same contract. We consider that there can be up to several:
    (a) Fungible Collections, each representing a supply of fungible token,
    (b) Non-Fungible Collections, each representing a set of non-fungible tokens,
    (c) Non-Fungible Tokens.

    `balanceOf` and `balanceOfBatch`:
    - when applied to a Non-Fungible Collection, MAY return the balance of Non-Fungible Tokens for this collection,
    - when applied to a Non-Fungible Token, SHOULD return 1.

    Note: The ERC-165 identifier for this interface is 0x09ce5c46.
 */
contract IERC1155AssetCollections {

    /**
        @dev Returns the parent collection ID of a Non-Fungible Token ID.
        This function returns either a Fungible Collection ID or a Non-Fungible Collection ID.
        This function SHOULD NOT be used to check the existence of a Non-Fungible Token.
        This function MAY return a value for a non-existing Non-Fungible Token.
        @param id The ID to query. id must represent an existing/non-existing Non-Fungible Token, else it throws.
        @return uint256 the parent collection ID.
     */
    function collectionOf(uint256 id) public view returns (uint256);

    /**
        @dev Returns whether or not an ID represents a Fungible Collection.
        @param id The ID to query.
        @return bool true if id represents a Fungible Collection, false otherwise.
    */
    function isFungible(uint256 id) public view returns (bool);

    /**
       @dev Returns the owner of a Non-Fungible Token.
       @param tokenId The ID to query. MUST represent an existing Non-Fungible Token, else it throws.
       @return owner address currently marked as the owner of the Non-Fungible Token.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);
}

// File: @animocabrands/contracts-inventory/contracts/token/ERC1155/IERC1155TokenReceiver.sol

pragma solidity = 0.5.16;

/**
    @title ERC-1155 Multi Token Standard, token receiver
    @dev See https://eips.ethereum.org/EIPS/eip-1155
    Note: The ERC-165 identifier for this interface is 0x4e2312e0.
 */
interface IERC1155TokenReceiver {
    /**
        @notice Handle the receipt of a single ERC1155 token type.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.
        This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param operator  The address which initiated the transfer (i.e. msg.sender)
        @param from      The address which previously owned the token
        @param id        The ID of the token being transferred
        @param value     The amount of tokens being transferred
        @param data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @notice Handle the receipt of multiple ERC1155 token types.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.
        This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
        This function MUST revert if it rejects the transfer(s).
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param operator  The address which initiated the batch transfer (i.e. msg.sender)
        @param from      The address which previously owned the token
        @param ids       An array containing ids of each token being transferred (order and length must match _values array)
        @param values    An array containing amounts of each token being transferred (order and length must match _ids array)
        @param data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @animocabrands/contracts-inventory/contracts/token/ERC1155721/AssetsInventory.sol

pragma solidity = 0.5.16;












/**
    @title AssetsInventory, a contract which manages up to multiple collections of fungible and non-fungible tokens
    @dev In this implementation, with N representing the non-fungible bitmask length, IDs are composed as follow:
    (a) Fungible Collection IDs:
        - most significant bit == 0
    (b) Non-Fungible Collection IDs:
        - most significant bit == 1
        - (256-N) least significant bits == 0
    (c) Non-Fungible Token IDs:
        - most significant bit == 1
        - (256-N) least significant bits != 0

    If non-fungible bitmask length == 0, all the IDs represent a Fungible Collection.
    If non-fungible bitmask length == 1, there is one Non-Fungible Collection represented by the most significant bit set to 1 and other bits set to 0.
    If non-fungible bitmask length > 1, there are multiple Non-Fungible Collections.
 */
contract AssetsInventory is IERC165, IERC721, IERC1155, IERC1155AssetCollections, IERC721Metadata, IERC1155MetadataURI, Context
{
    // id (collection) => owner => balance
    mapping(uint256 => mapping(address => uint256)) internal _balances;

    // owner => operator => approved
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    // id (nft) => operator
    mapping(uint256 => address) internal _tokenApprovals;

    // id (collection or nft) => owner
    mapping(uint256 => address) internal _owners;

    // owner => nb nfts owned
    mapping(address => uint256) internal _nftBalances;

    // Mask for the non-fungible flag in ids
    uint256 internal constant NF_BIT_MASK = 1 << 255;

    // Mask for non-fungible collection in ids (it includes the nf bit)
    uint256 internal NF_COLLECTION_MASK;

    /**
     * @dev Constructor function
     * @param nfMaskLength number of bits in the Non-Fungible Collection mask
     * if nfMaskLength == 0, the contract doesn't support non-fungible tokens
     * if nfMaskLength == 1, the single non-fungible collection which is represented by only the non-fungible bit set to 1
     * if nfMaskLength > 1, there are several 
     */
    constructor(uint256 nfMaskLength) public {
        require(nfMaskLength < 256);
        if (nfMaskLength == 0) {
            NF_COLLECTION_MASK = 0;
        } else {
            uint256 mask = (1 << nfMaskLength) - 1;
            mask = mask << (256 - nfMaskLength);
            NF_COLLECTION_MASK = mask;
        }
    }

/////////////////////////////////////////// ERC165 /////////////////////////////////////////////

    /**
     * @dev Check if support an interface id
     * @param interfaceId interface id to query
     * @return bool if support the given interface id
     */
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return (
            // ERC165 interface id
            interfaceId == 0x01ffc9a7 ||
            // ERC721 interface id
            interfaceId == 0x80ac58cd ||
            // ERC721Metadata interface id
            interfaceId == 0x5b5e139f ||
            // ERC721Exists interface id
            interfaceId == 0x4f558e79 ||
            // ERC1155 interface id
            interfaceId == 0xd9b67a26 ||
            // ERC1155AssetCollections interface id
            interfaceId == 0x09ce5c46 ||
            // ERC1155MetadataURI interface id
            interfaceId == 0x0e89341c
        );
    }
/////////////////////////////////////////// ERC721 /////////////////////////////////////////////

    function balanceOf(address tokenOwner) public view returns (uint256) {
        require(tokenOwner != address(0x0));
        return _nftBalances[tokenOwner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        require(isNFT(tokenId));
        address tokenOwner = _owners[tokenId];
        require(tokenOwner != address(0x0));
        return tokenOwner;
    }

    function approve(address to, uint256 tokenId) public {
        address tokenOwner = ownerOf(tokenId);
        require(to != tokenOwner); // solium-disable-line error-reason

        address sender = _msgSender();
        require(sender == tokenOwner || _operatorApprovals[tokenOwner][sender]); // solium-disable-line error-reason

        _tokenApprovals[tokenId] = to;
        emit Approval(tokenOwner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(isNFT(tokenId) && exists(tokenId));
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address to, bool approved) public {
        address sender = _msgSender();
        require(to != sender);
        _setApprovalForAll(sender, to, approved);
    }

    function _setApprovalForAll(address sender, address operator, bool approved) internal {
        _operatorApprovals[sender][operator] = approved;
        emit ApprovalForAll(sender, operator, approved);
    }

    function isApprovedForAll(address tokenOwner, address operator) public view returns (bool) {
        return _operatorApprovals[tokenOwner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        _transferFrom(from, to, tokenId, "", false);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        _transferFrom(from, to, tokenId, "", true);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        _transferFrom(from, to, tokenId, data, true);
    }



/////////////////////////////////////////// ERC1155 /////////////////////////////////////////////

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) public
    {
        require(to != address(0x0));

        address sender = _msgSender();
        bool operatable = (from == sender || _operatorApprovals[from][sender] == true);

        if (isFungible(id) && value > 0) {
            require(operatable);
            _transferFungible(from, to, id, value);
        } else if (isNFT(id) && value == 1) {
            _transferNonFungible(from, to, id, operatable);
            emit Transfer(from, to, id);
        } else {
            revert();
        }

        emit TransferSingle(sender, from, to, id, value);
        require(_checkERC1155AndCallSafeTransfer(sender, from, to, id, value, data, false, false));
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) public
    {
        require(to != address(0x0));
        require(ids.length == values.length);

        // Only supporting a global operator approval allows to do a single check and not to touch storage to handle allowances.
        address sender = _msgSender();
        require(from == sender || _operatorApprovals[from][sender] == true);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 value = values[i];

            if (isFungible(id) && value > 0) {
                _transferFungible(from, to, id, value);
            } else if (isNFT(id) && value == 1) {
                _transferNonFungible(from, to, id, true);
                emit Transfer(from, to, id);
            } else {
                revert();
            }
        }

        emit TransferBatch(sender, from, to, ids, values);
        require(_checkERC1155AndCallSafeBatchTransfer(sender, from, to, ids, values, data));
    }

    function balanceOf(address tokenOwner, uint256 id) public view returns (uint256) {
        require(tokenOwner != address(0x0));

        if (isNFT(id)) {
            return _owners[id] == tokenOwner ? 1 : 0;
        }
    
        return _balances[id][tokenOwner];
    }

    function balanceOfBatch(
        address[] memory tokenOwners,
        uint256[] memory ids
    ) public view returns (uint256[] memory)
    {
        require(tokenOwners.length == ids.length);

        uint256[] memory balances = new uint256[](tokenOwners.length);

        for (uint256 i = 0; i < tokenOwners.length; ++i) {
            require(tokenOwners[i] != address(0x0));

            uint256 id = ids[i];

            if (isNFT(id)) {
                balances[i] = _owners[id] == tokenOwners[i] ? 1 : 0;
            } else {
                balances[i] = _balances[id][tokenOwners[i]];
            }
        }

        return balances;
    }

/////////////////////////////////////////// ERC1155AssetCollections /////////////////////////////////////////////

    function collectionOf(uint256 id) public view returns (uint256) {
        require(isNFT(id));
        return id & NF_COLLECTION_MASK;
    }

    /**
        @dev Tells whether an id represents a fungible collection
        @param id The ID to query
        @return bool whether the given id is fungible
     */
    function isFungible(uint256 id) public view returns (bool) {
        return id & (NF_BIT_MASK) == 0;
    }

    /**
        @dev Tells whether an id represents a non-fungible token
        @param id The ID to query
        @return bool whether the given id is non-fungible token
     */
    function isNFT(uint256 id) internal view returns (bool) {
        // A base type has the NF bit and an index
        return (id & (NF_BIT_MASK) != 0) && (id & (~NF_COLLECTION_MASK) != 0);
    }

    /**
     * @dev Returns whether the NFT belongs to someone
     * @param id uint256 ID of the NFT
     * @return whether the NFT belongs to someone
     */
    function exists(uint256 id) public view returns (bool) {
        address tokenOwner = _owners[id];
        return tokenOwner != address(0x0);
    }

/////////////////////////////////////////// Transfer Internal Functions ///////////////////////////////////////

    /**
     * @dev Internal function to transfer the ownership of a given NFT to another address
     * Emits Transfer and TransferSingle events
     * Requires the msg sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param safe bool to indicate whether the transfer is safe
    */
    function _transferFrom(address from, address to, uint256 tokenId, bytes memory data, bool safe) internal {
        require(to != address(0x0));
        require(isNFT(tokenId));

        address sender = _msgSender();
        bool operatable = (from == sender || _operatorApprovals[from][sender] == true);

        _transferNonFungible(from, to, tokenId, operatable);

        emit Transfer(from, to, tokenId);
        emit TransferSingle(sender, from, to, tokenId, 1);

        require(_checkERC1155AndCallSafeTransfer(sender, from, to, tokenId, 1, data, true, safe));
    }

    /**
     * @dev Internal function to transfer the ownership of a given token ID to another address
     * Requires the msg sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param id uint256 ID of the token to be transferred
     * @param operatable bool to indicate whether the msg sender is operator
    */
    function _transferNonFungible(address from, address to, uint256 id, bool operatable) internal {
        require(from == _owners[id]);

        address sender = _msgSender();
        require(operatable || ownerOf(id) == sender || getApproved(id) == sender);

        // clear approval
        if (_tokenApprovals[id] != address(0x0)) {
            _tokenApprovals[id] = address(0x0);
        }

        uint256 nfCollection = id & NF_COLLECTION_MASK;
        _balances[nfCollection][from] = SafeMath.sub(_balances[nfCollection][from], 1);
        _balances[nfCollection][to] = SafeMath.add(_balances[nfCollection][to], 1);
    
        _nftBalances[from] = SafeMath.sub(_nftBalances[from], 1);
        _nftBalances[to] = SafeMath.add(_nftBalances[to], 1);
    
        _owners[id] = to;
    }

    /**
     * @dev Internal function to move `collectionId` fungible tokens `value` from `from` to `to`.
     * @param from current owner of the `collectionId` fungible token
     * @param to address to receive the ownership of the given `collectionId` fungible token
     * @param collectionId uint256 ID of the fungible token to be transferred
     * @param value uint256 transfer amount
     */
    function _transferFungible(address from, address to, uint256 collectionId, uint256 value) internal {
        _balances[collectionId][from] = SafeMath.sub(_balances[collectionId][from], value);
        _balances[collectionId][to] = SafeMath.add(_balances[collectionId][to], value);
    }

/////////////////////////////////////////// Receiver Internal Functions ///////////////////////////////////////

    /**
     * @dev public function to invoke `onERC721Received` on a target address
     * The call is not executed if the target address is not a contract
     * @param operator transfer msg sender
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the token
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return whether the call correctly returned the expected magic value
     */
    function _checkERC721AndCallSafeTransfer(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal returns(bool)
    {
        if (!Address.isContract(to)) {
            return true;
        }
        return (IERC721Receiver(to).onERC721Received(operator, from, tokenId, data) == 0x150b7a02); // 0x150b7a02: ERC721 receive magic value
    }

    /**
     * @dev public function to invoke `onERC1155Received` on a target address
     * The call is not executed if the target address is not a contract
     * @param operator transfer msg sender
     * @param from address representing the previous owner of the given ID
     * @param to target address that will receive the token
     * @param id uint256 ID of the `non-fungible token / non-fungible collection / fungible collection` to be transferred
     * @param data bytes optional data to send along with the call
     * @param erc721 bool whether transfer to ERC721 contract
     * @param erc721Safe bool whether transfer to ERC721 contract safely
     * @return whether the call correctly returned the expected magic value
     */
    function _checkERC1155AndCallSafeTransfer(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data,
        bool erc721,
        bool erc721Safe
    ) internal returns (bool)
    {
        if (!Address.isContract(to)) {
            return true;
        }
        if (erc721) {
            if (!_checkIsERC1155Receiver(to)) {
                if (erc721Safe) {
                    return _checkERC721AndCallSafeTransfer(operator, from, to, id, data);
                } else {
                    return true;
                }
            }
        }
        return IERC1155TokenReceiver(to).onERC1155Received(operator, from, id, value, data) == 0xf23a6e61; // 0xf23a6e61: ERC1155 receive magic value
    }

    /**
     * @dev public function to invoke `onERC1155BatchReceived` on a target address
     * The call is not executed if the target address is not a contract
     * @param operator transfer msg sender
     * @param from address representing the previous owner of the given IDs
     * @param to target address that will receive the tokens
     * @param ids uint256 ID of the `non-fungible token / non-fungible collection / fungible collection` to be transferred
     * @param values uint256 transfer amounts of the `non-fungible token / non-fungible collection / fungible collection`
     * @param data bytes optional data to send along with the call
     * @return whether the call correctly returned the expected magic value
     */
    function _checkERC1155AndCallSafeBatchTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal returns (bool)
    {
        if (!Address.isContract(to)) {
            return true;
        }
        bytes4 retval = IERC1155TokenReceiver(to).onERC1155BatchReceived(operator, from, ids, values, data);
        return (retval == 0xbc197c81); // 0xbc197c81: ERC1155 batch receive magic value
    }

    /**
     * @dev public function to tell wheter a contract is ERC1155 Receiver contract
     * @param _contract address query contract addrss
     * @return wheter the given contract is ERC1155 Receiver contract
     */
    function _checkIsERC1155Receiver(address _contract) internal view returns(bool) {
        bytes4 erc1155ReceiverID = 0x4e2312e0;
        bytes4 INTERFACE_ID_ERC165 = 0x01ffc9a7;
        bool success;
        uint256 result;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let x:= mload(0x40)               // Find empty storage location using "free memory pointer"
            mstore(x, INTERFACE_ID_ERC165)                // Place signature at beginning of empty storage
            mstore(add(x, 0x04), erc1155ReceiverID) // Place first argument directly next to signature

            success:= staticcall(
                10000,          // 10k gas
                _contract,     // To addr
                x,             // Inputs are stored at location x
                0x24,          // Inputs are 36 bytes long
                x,             // Store output over input (saves space)
                0x20)          // Outputs are 32 bytes long

            result:= mload(x)                 // Load the result
        }
        // (10000 / 63) "not enough for supportsInterface(...)" // consume all gas, so caller can potentially know that there was not enough gas
        assert(gasleft() > 158);
        return success && result == 1;
    }
}

// File: @animocabrands/contracts-inventory/contracts/token/ERC1155721/PausableInventory.sol

pragma solidity = 0.5.16;



/**
    @title PausableInventory,an inventory contract with pausable collections
    @dev See https://
    Note: .
 */
contract PausableInventory is AssetsInventory, ERC1155PausableCollections
{

    constructor(uint256 nfMaskLength) public AssetsInventory(nfMaskLength)  {}

/////////////////////////////////////////// ERC1155PausableCollections /////////////////////////////////////////////

    modifier whenIdPaused(uint256 id) {
        require(idPaused(id));
        _;
    }

    modifier whenIdNotPaused(uint256 id) {
        require(!idPaused(id)                                                                                            );
        _;
    }

    function idPaused(uint256 id) public view returns (bool) {
        if (isNFT(id)) {
            return _pausedCollections[collectionOf(id)];
        } else {
            return _pausedCollections[id];
        }
    }

    function pauseCollections(uint256[] memory collectionIds) public onlyPauser {
        for (uint256 i=0; i 0) {
            bstr[--k] = base32Alphabet[_i % 32];
            _i /= 32;
        }
        return string(bstr);
    }

    /**
     * @dev public function to convert uint256 to string
     * @param num uint256 integer to convert
     * @return string string convert from given uint256
     */
    function uint2str(uint256 num) public pure returns(string memory _uintAsString) {
        if (num == 0) {
            return "0";
        }

        uint256 j = num;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }

        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (num != 0) {
            bstr[k--] = bytes1(uint8(48 + (num % 10)));
            num /= 10;
        }

        return string(bstr);
    }

    function uint2hexstr(uint i) public pure returns(string memory) {
        uint length = 64;
        uint mask = 15;
        bytes memory bstr = new bytes(length);
        int k = int(length - 1);
        while (i != 0) {
            uint curr = (i & mask);
            bstr[uint(k--)] = curr > 9 ? byte(uint8(87 + curr)) : byte(uint8(48 + curr)); // 87 = 97 - 10
            i = i >> 4;
        }
        while (k >= 0) {
            bstr[uint(k--)] = byte(uint8(48));
        }
        return string(bstr);
    }
}

// File: contracts/token/ERC1155721/DeltaTimeInventory.sol

pragma solidity = 0.5.16;






/**
 * @title F1 Delta Time Inventory Contract
 */
contract DeltaTimeInventory is PausableInventory, ERC20Fees, MinterRole {

    event FungibleCollection(address indexed id);
    event NonFungibleCollection(address indexed id);

    bool private _ipfsMigrated;

    string private _uriPrefix = "https://nft.f1deltatime.com/json/";
    string private _ipfsUriPrefix = "/ipfs/bafkrei";

    // Mapping Mapping from ID to URI
    mapping(uint256 => bytes32) private _uris;

    /**
     * @dev Constructor
     * @dev 32 DeltaTimeInventory collection type length
     */
    constructor(address gasTokenAddress, address payoutWallet
    ) public PausableInventory(32) ERC20Fees(gasTokenAddress, payoutWallet)  {
        _ipfsMigrated = false;
    }

    /**
     * @dev This function creates the collection id.
     * @param collectionId collection without fungible/non-fungible identifier
     * @return uint256 collectionId to create
     */
    function createCollection(uint256 collectionId, bytes32 byteUri) onlyMinter external {
        require(_ipfsMigrated? uint256(byteUri) > 0: uint256(byteUri) == 0);
        require(!isNFT(collectionId));
        _setURI(collectionId, byteUri);
    }

/////////////////////////////////////////// Mint ///////////////////////////////////////
    /**
     * @dev Public function to mint a batch of new tokens
     * Reverts if some the given token IDs already exist
     * @param to address[] List of addresses that will own the minted tokens
     * @param ids uint256[] List of ids of the tokens to be minted
     * @param uris bytes32[] Concatenated metadata URIs of nfts to be minted
     * @param values uint256[] List of quantities of ft to be minted
     */
    function batchMint(address[] memory to, uint256[] memory ids, bytes32[] memory uris, uint256[] memory values, bool safe) public onlyMinter {
        require(ids.length == to.length &&
            ids.length == uris.length &&
            ids.length == values.length);

        for (uint i = 0; i < ids.length; i++) {
            if (isNFT(ids[i]) && values[i] == 1) {
                _mintNonFungible(to[i], ids[i], uris[i], safe);
            } else if (isFungible(ids[i]) && uint256(uris[i]) == 0) {
                _mintFungible(to[i], ids[i], values[i]);
            } else {
                revert();
            }
        }
    }

    /**
     * @dev Public function to mint one non fungible token id
     * Reverts if the given token ID is not non fungible token id
     * @param to address recipient that will own the minted tokens
     * @param tokenId uint256 ID of the token to be minted
     * @param byteUri bytes32 Concatenated metadata URI of nft to be minted
     */
    function mintNonFungible(address to, uint256 tokenId, bytes32 byteUri, bool safe) external onlyMinter {
        require(isNFT(tokenId)); // solium-disable-line error-reason
        _mintNonFungible(to, tokenId, byteUri, safe);
    }

    /**
     * @dev Internal function to mint one non fungible token
     * Reverts if the given token ID already exist
     * @param to address recipient that will own the minted tokens
     * @param id uint256 ID of the token to be minted
     * @param byteUri bytes32 Concatenated metadata URI of nft to be minted
     */
    function _mintNonFungible(address to, uint256 id, bytes32 byteUri, bool safe) internal {
        require(to != address(0x0));
        require(!exists(id));

        uint256 collection = id & NF_COLLECTION_MASK;

        _owners[id] = to;
        _nftBalances[to] = SafeMath.add(_nftBalances[to], 1);
        _balances[collection][to] = SafeMath.add(_balances[collection][to], 1);

        emit Transfer(address(0x0), to, id);
        emit TransferSingle(_msgSender(), address(0x0), to, id, 1);

        _setURI(id, byteUri);

        if (safe) {
            require( // solium-disable-line error-reason
                _checkERC1155AndCallSafeTransfer(_msgSender(), address(0x0), to, id, 1, "", false, false), "failCheck"
            );
        }
    }

    /**
     * @dev Public function to mint fungible token
     * Reverts if the given ID is not fungible collection ID
     * @param to address recipient that will own the minted tokens
     * @param collection uint256 ID of the fungible collection to be minted
     * @param value uint256 amount to mint
     */
    function mintFungible(address to, uint256 collection, uint256 value) external onlyMinter {
        require(isFungible(collection));
        _mintFungible(to, collection, value);
    }

    /**
     * @dev Internal function to mint fungible token
     * Reverts if the given ID is not exsit
     * @param to address recipient that will own the minted tokens
     * @param collection uint256 ID of the fungible collection to be minted
     * @param value uint256 amount to mint
     */
    function _mintFungible(address to, uint256 collection, uint256 value) internal {
        require(to != address(0x0));
        require(value > 0);

        _balances[collection][to] = SafeMath.add(_balances[collection][to], value);

        emit TransferSingle(_msgSender(), address(0x0), to, collection, value);

        require( // solium-disable-line error-reason
            _checkERC1155AndCallSafeTransfer(_msgSender(), address(0x0), to, collection, value, "", false, false), "failCheck"
        );
    }

/////////////////////////////////////////// TokenURI////////////////////////////////////

    /**
     * @dev Public function to update the metadata URI prefix
     * @param uriPrefix string the new URI prefix
     */
    function setUriPrefix(string calldata uriPrefix) external onlyOwner {
        _uriPrefix = uriPrefix;
    }

    /**
     * @dev Public function to update the metadata IPFS URI prefix
     * @param ipfsUriPrefix string the new IPFS URI prefix
     */
    function setIPFSUriPrefix(string calldata ipfsUriPrefix) external onlyOwner {
        _ipfsUriPrefix = ipfsUriPrefix;
    }

    /**
     * @dev Public function to set the URI for a given ID
     * Reverts if the ID does not exist or metadata has migrated to IPFS
     * @param id uint256 ID to set its URI
     * @param byteUri bytes32 URI to assign
     */
    function setURI(uint256 id, bytes32 byteUri) external onlyMinter {
        require(!_ipfsMigrated && uint256(byteUri) > 0);
        require(exists(id));

        _setURI(id, byteUri);
    }

    /**
     * @dev Internal function to set the URI for a given ID
     * Reverts if the ID does not exist
     * @param id uint256 ID to set its URI
     * @param byteUri bytes32 URI to assign
     */
    function _setURI(uint256 id, bytes32 byteUri) internal {
        if (uint256(byteUri) > 0) {
            _uris[id] = byteUri;
            emit URI(_fullUriFromHash(byteUri), id);
        } else {
            emit URI(_fullUriFromId(id), id);
        }
    }

    /**
     * @dev Internal function to convert bytes32 hash to full uri string
     * @param byteUri bytes32 URI to convert
     * @return string URI convert from given hash
     */
    function _fullUriFromHash(bytes32 byteUri) private view returns(string memory) {
        return string(abi.encodePacked(_ipfsUriPrefix, Bytes.hash2base32(byteUri)));
    }

    /**
     * @dev Internal function to convert id to full uri string
     * @param id uint256 ID to convert
     * @return string URI convert from given ID
     */
    function _fullUriFromId(uint256 id) private view returns(string memory) {
        return string(abi.encodePacked(abi.encodePacked(_uriPrefix, Bytes.uint2str(id))));
    }

/////////////////////////////////////////// IPFS migration ///////////////////////////////////

    /**
     * @dev Sets IPFS migration flag true
     */
    function migrateToIPFS() public onlyMinter {
        _ipfsMigrated = true;
    }

/////////////////////////////////////////// ERC1155MetadataURI ///////////////////////////////////

    /**
     * @dev Returns an URI for a given ID
     * @param id uint256 ID of the tokenId / collectionId to query
     * @return string URI of given ID
     */
    function uri(uint256 id) public view returns(string memory) {
        if (uint256(_uris[id]) == 0) {
            return _fullUriFromId(id);
        }

        return _fullUriFromHash(_uris[id]);
    }

/////////////////////////////////////////// ERC721Metadata ///////////////////////////////////

    /**
     * @dev Gets the token name
     * @return string representing the token name
     */
    function name() external view returns(string memory) {
        return "F1® Delta Time Inventory";
    }

    /**
     * @dev Gets the token symbol
     * @return string representing the token symbol
     */
    function symbol() external view returns(string memory) {
        return "F1DTI";
    }

    /**
     * @dev Returns an URI for a given token ID
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     * @return string URI of given token ID
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(exists(tokenId));
        return uri(tokenId);
    }
}
