// File: @ensdomains/ens/contracts/ENS.sol

pragma solidity >=0.4.24;

interface ENS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external returns(bytes32);
    function setResolver(bytes32 node, address resolver) external;
    function setOwner(bytes32 node, address owner) external;
    function setTTL(bytes32 node, uint64 ttl) external;
    function setApprovalForAll(address operator, bool approved) external;
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
    function ttl(bytes32 node) external view returns (uint64);
    function recordExists(bytes32 node) external view returns (bool);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: openzeppelin-solidity/contracts/introspection/IERC165.sol

pragma solidity ^0.5.0;

/**
 * @title IERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface IERC165 {
    /**
     * @notice Query if a contract implements an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: openzeppelin-solidity/contracts/token/ERC721/IERC721.sol

pragma solidity ^0.5.0;


/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);

    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId) public;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @ensdomains/ethregistrar/contracts/BaseRegistrar.sol

pragma solidity >=0.4.24;




contract BaseRegistrar is IERC721, Ownable {
    uint constant public GRACE_PERIOD = 90 days;

    event ControllerAdded(address indexed controller);
    event ControllerRemoved(address indexed controller);
    event NameMigrated(uint256 indexed id, address indexed owner, uint expires);
    event NameRegistered(uint256 indexed id, address indexed owner, uint expires);
    event NameRenewed(uint256 indexed id, uint expires);

    // The ENS registry
    ENS public ens;

    // The namehash of the TLD this registrar owns (eg, .eth)
    bytes32 public baseNode;

    // A map of addresses that are authorised to register and renew names.
    mapping(address=>bool) public controllers;

    // Authorises a controller, who can register and renew domains.
    function addController(address controller) external;

    // Revoke controller permission for an address.
    function removeController(address controller) external;

    // Set the resolver for the TLD this registrar manages.
    function setResolver(address resolver) external;

    // Returns the expiration timestamp of the specified label hash.
    function nameExpires(uint256 id) external view returns(uint);

    // Returns true iff the specified name is available for registration.
    function available(uint256 id) public view returns(bool);

    /**
     * @dev Register a name.
     */
    function register(uint256 id, address owner, uint duration) external returns(uint);

    function renew(uint256 id, uint duration) external returns(uint);

    /**
     * @dev Reclaim ownership of a name in ENS, if you own it in the registrar.
     */
    function reclaim(uint256 id, address owner) external;
}

// File: @ensdomains/subdomain-registrar/contracts/Resolver.sol

pragma solidity ^0.5.0;


/**
 * @dev A basic interface for ENS resolvers.
 */
contract Resolver {
    function supportsInterface(bytes4 interfaceID) public pure returns (bool);
    function addr(bytes32 node) public view returns (address);
    function setAddr(bytes32 node, address addr) public;
}

// File: @ensdomains/subdomain-registrar/contracts/RegistrarInterface.sol

pragma solidity ^0.5.0;

contract RegistrarInterface {
    event OwnerChanged(bytes32 indexed label, address indexed oldOwner, address indexed newOwner);
    event DomainConfigured(bytes32 indexed label);
    event DomainUnlisted(bytes32 indexed label);
    event NewRegistration(bytes32 indexed label, string subdomain, address indexed owner, address indexed referrer, uint price);
    event RentPaid(bytes32 indexed label, string subdomain, uint amount, uint expirationDate);

    // InterfaceID of these four methods is 0xc1b15f5a
    function query(bytes32 label, string calldata subdomain) external view returns (string memory domain, uint signupFee, uint rent, uint referralFeePPM);
    function register(bytes32 label, string calldata subdomain, address owner, address payable referrer, address resolver) external payable;

    function rentDue(bytes32 label, string calldata subdomain) external view returns (uint timestamp);
    function payRent(bytes32 label, string calldata subdomain) external payable;
}

// File: @ensdomains/subdomain-registrar/contracts/AbstractSubdomainRegistrar.sol

pragma solidity ^0.5.0;




contract AbstractSubdomainRegistrar is RegistrarInterface {

    // namehash('eth')
    bytes32 constant public TLD_NODE = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

    bool public stopped = false;
    address public registrarOwner;
    address public migration;

    address public registrar;

    ENS public ens;

    modifier owner_only(bytes32 label) {
        require(owner(label) == msg.sender);
        _;
    }

    modifier not_stopped() {
        require(!stopped);
        _;
    }

    modifier registrar_owner_only() {
        require(msg.sender == registrarOwner);
        _;
    }

    event DomainTransferred(bytes32 indexed label, string name);

    constructor(ENS _ens) public {
        ens = _ens;
        registrar = ens.owner(TLD_NODE);
        registrarOwner = msg.sender;
    }

    function doRegistration(bytes32 node, bytes32 label, address subdomainOwner, Resolver resolver) internal {
        // Get the subdomain so we can configure it
        ens.setSubnodeOwner(node, label, address(this));

        bytes32 subnode = keccak256(abi.encodePacked(node, label));
        // Set the subdomain's resolver
        ens.setResolver(subnode, address(resolver));

        // Set the address record on the resolver
        resolver.setAddr(subnode, subdomainOwner);

        // Pass ownership of the new subdomain to the registrant
        ens.setOwner(subnode, subdomainOwner);
    }

    function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
        return (
            (interfaceID == 0x01ffc9a7) // supportsInterface(bytes4)
            || (interfaceID == 0xc1b15f5a) // RegistrarInterface
        );
    }

    function rentDue(bytes32 label, string calldata subdomain) external view returns (uint timestamp) {
        return 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    }

    /**
     * @dev Sets the resolver record for a name in ENS.
     * @param name The name to set the resolver for.
     * @param resolver The address of the resolver
     */
    function setResolver(string memory name, address resolver) public owner_only(keccak256(bytes(name))) {
        bytes32 label = keccak256(bytes(name));
        bytes32 node = keccak256(abi.encodePacked(TLD_NODE, label));
        ens.setResolver(node, resolver);
    }

    /**
     * @dev Configures a domain for sale.
     * @param name The name to configure.
     * @param price The price in wei to charge for subdomain registrations
     * @param referralFeePPM The referral fee to offer, in parts per million
     */
    function configureDomain(string memory name, uint price, uint referralFeePPM) public {
        configureDomainFor(name, price, referralFeePPM, msg.sender, address(0x0));
    }

    /**
     * @dev Stops the registrar, disabling configuring of new domains.
     */
    function stop() public not_stopped registrar_owner_only {
        stopped = true;
    }

    /**
     * @dev Sets the address where domains are migrated to.
     * @param _migration Address of the new registrar.
     */
    function setMigrationAddress(address _migration) public registrar_owner_only {
        require(stopped);
        migration = _migration;
    }

    function transferOwnership(address newOwner) public registrar_owner_only {
        registrarOwner = newOwner;
    }

    /**
     * @dev Returns information about a subdomain.
     * @param label The label hash for the domain.
     * @param subdomain The label for the subdomain.
     * @return domain The name of the domain, or an empty string if the subdomain
     *                is unavailable.
     * @return price The price to register a subdomain, in wei.
     * @return rent The rent to retain a subdomain, in wei per second.
     * @return referralFeePPM The referral fee for the dapp, in ppm.
     */
    function query(bytes32 label, string calldata subdomain) external view returns (string memory domain, uint price, uint rent, uint referralFeePPM);

    function owner(bytes32 label) public view returns (address);
    function configureDomainFor(string memory name, uint price, uint referralFeePPM, address payable _owner, address _transfer) public;
}

// File: @ensdomains/subdomain-registrar/contracts/EthRegistrarSubdomainRegistrar.sol

pragma solidity ^0.5.0;



/**
 * @dev Implements an ENS registrar that sells subdomains on behalf of their owners.
 *
 * Users may register a subdomain by calling `register` with the name of the domain
 * they wish to register under, and the label hash of the subdomain they want to
 * register. They must also specify the new owner of the domain, and the referrer,
 * who is paid an optional finder's fee. The registrar then configures a simple
 * default resolver, which resolves `addr` lookups to the new owner, and sets
 * the `owner` account as the owner of the subdomain in ENS.
 *
 * New domains may be added by calling `configureDomain`, then transferring
 * ownership in the ENS registry to this contract. Ownership in the contract
 * may be transferred using `transfer`, and a domain may be unlisted for sale
 * using `unlistDomain`. There is (deliberately) no way to recover ownership
 * in ENS once the name is transferred to this registrar.
 *
 * Critically, this contract does not check one key property of a listed domain:
 *
 * - Is the name UTS46 normalised?
 *
 * User applications MUST check these two elements for each domain before
 * offering them to users for registration.
 *
 * Applications should additionally check that the domains they are offering to
 * register are controlled by this registrar, since calls to `register` will
 * fail if this is not the case.
 */
contract EthRegistrarSubdomainRegistrar is AbstractSubdomainRegistrar {

    struct Domain {
        string name;
        address payable owner;
        uint price;
        uint referralFeePPM;
    }

    mapping (bytes32 => Domain) domains;

    constructor(ENS ens) AbstractSubdomainRegistrar(ens) public { }

    /**
     * @dev owner returns the address of the account that controls a domain.
     *      Initially this is a null address. If the name has been
     *      transferred to this contract, then the internal mapping is consulted
     *      to determine who controls it. If the owner is not set,
     *      the owner of the domain in the Registrar is returned.
     * @param label The label hash of the deed to check.
     * @return The address owning the deed.
     */
    function owner(bytes32 label) public view returns (address) {
        if (domains[label].owner != address(0x0)) {
            return domains[label].owner;
        }

        return BaseRegistrar(registrar).ownerOf(uint256(label));
    }

    /**
     * @dev Transfers internal control of a name to a new account. Does not update
     *      ENS.
     * @param name The name to transfer.
     * @param newOwner The address of the new owner.
     */
    function transfer(string memory name, address payable newOwner) public owner_only(keccak256(bytes(name))) {
        bytes32 label = keccak256(bytes(name));
        emit OwnerChanged(label, domains[label].owner, newOwner);
        domains[label].owner = newOwner;
    }

    /**
     * @dev Configures a domain, optionally transferring it to a new owner.
     * @param name The name to configure.
     * @param price The price in wei to charge for subdomain registrations.
     * @param referralFeePPM The referral fee to offer, in parts per million.
     * @param _owner The address to assign ownership of this domain to.
     * @param _transfer The address to set as the transfer address for the name
     *        when the permanent registrar is replaced. Can only be set to a non-zero
     *        value once.
     */
    function configureDomainFor(string memory name, uint price, uint referralFeePPM, address payable _owner, address _transfer) public owner_only(keccak256(bytes(name))) {
        bytes32 label = keccak256(bytes(name));
        Domain storage domain = domains[label];

        if (BaseRegistrar(registrar).ownerOf(uint256(label)) != address(this)) {
            BaseRegistrar(registrar).transferFrom(msg.sender, address(this), uint256(label));
            BaseRegistrar(registrar).reclaim(uint256(label), address(this));
        }

        if (domain.owner != _owner) {
            domain.owner = _owner;
        }

        if (keccak256(bytes(domain.name)) != label) {
            // New listing
            domain.name = name;
        }

        domain.price = price;
        domain.referralFeePPM = referralFeePPM;

        emit DomainConfigured(label);
    }

    /**
     * @dev Unlists a domain
     * May only be called by the owner.
     * @param name The name of the domain to unlist.
     */
    function unlistDomain(string memory name) public owner_only(keccak256(bytes(name))) {
        bytes32 label = keccak256(bytes(name));
        Domain storage domain = domains[label];
        emit DomainUnlisted(label);

        domain.name = '';
        domain.price = 0;
        domain.referralFeePPM = 0;
    }

    /**
     * @dev Returns information about a subdomain.
     * @param label The label hash for the domain.
     * @param subdomain The label for the subdomain.
     * @return domain The name of the domain, or an empty string if the subdomain
     *                is unavailable.
     * @return price The price to register a subdomain, in wei.
     * @return rent The rent to retain a subdomain, in wei per second.
     * @return referralFeePPM The referral fee for the dapp, in ppm.
     */
    function query(bytes32 label, string calldata subdomain) external view returns (string memory domain, uint price, uint rent, uint referralFeePPM) {
        bytes32 node = keccak256(abi.encodePacked(TLD_NODE, label));
        bytes32 subnode = keccak256(abi.encodePacked(node, keccak256(bytes(subdomain))));

        if (ens.owner(subnode) != address(0x0)) {
            return ('', 0, 0, 0);
        }

        Domain storage data = domains[label];
        return (data.name, data.price, 0, data.referralFeePPM);
    }

    /**
     * @dev Registers a subdomain.
     * @param label The label hash of the domain to register a subdomain of.
     * @param subdomain The desired subdomain label.
     * @param _subdomainOwner The account that should own the newly configured subdomain.
     * @param referrer The address of the account to receive the referral fee.
     */
    function register(bytes32 label, string calldata subdomain, address _subdomainOwner, address payable referrer, address resolver) external not_stopped payable {
        address subdomainOwner = _subdomainOwner;
        bytes32 domainNode = keccak256(abi.encodePacked(TLD_NODE, label));
        bytes32 subdomainLabel = keccak256(bytes(subdomain));

        // Subdomain must not be registered already.
        require(ens.owner(keccak256(abi.encodePacked(domainNode, subdomainLabel))) == address(0));

        Domain storage domain = domains[label];

        // Domain must be available for registration
        require(keccak256(bytes(domain.name)) == label);

        // User must have paid enough
        require(msg.value >= domain.price);

        // Send any extra back
        if (msg.value > domain.price) {
            msg.sender.transfer(msg.value - domain.price);
        }

        // Send any referral fee
        uint256 total = domain.price;
        if (domain.referralFeePPM > 0 && referrer != address(0x0) && referrer != domain.owner) {
            uint256 referralFee = (domain.price * domain.referralFeePPM) / 1000000;
            referrer.transfer(referralFee);
            total -= referralFee;
        }

        // Send the registration fee
        if (total > 0) {
            domain.owner.transfer(total);
        }

        // Register the domain
        if (subdomainOwner == address(0x0)) {
            subdomainOwner = msg.sender;
        }
        doRegistration(domainNode, subdomainLabel, subdomainOwner, Resolver(resolver));

        emit NewRegistration(label, subdomain, subdomainOwner, referrer, domain.price);
    }

    function rentDue(bytes32 label, string calldata subdomain) external view returns (uint timestamp) {
        return 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    }

    /**
     * @dev Migrates the domain to a new registrar.
     * @param name The name of the domain to migrate.
     */
    function migrate(string memory name) public owner_only(keccak256(bytes(name))) {
        require(stopped);
        require(migration != address(0x0));

        bytes32 label = keccak256(bytes(name));
        Domain storage domain = domains[label];

        BaseRegistrar(registrar).approve(migration, uint256(label));

        EthRegistrarSubdomainRegistrar(migration).configureDomainFor(
            domain.name,
            domain.price,
            domain.referralFeePPM,
            domain.owner,
            address(0x0)
        );

        delete domains[label];

        emit DomainTransferred(label, name);
    }

    function payRent(bytes32 label, string calldata subdomain) external payable {
        revert();
    }
}

// File: @ensdomains/subdomain-registrar/contracts/ENSMigrationSubdomainRegistrar.sol

pragma solidity ^0.5.0;



/**
 * @dev Implements an ENS registrar that sells subdomains on behalf of their owners.
 *
 * Users may register a subdomain by calling `register` with the name of the domain
 * they wish to register under, and the label hash of the subdomain they want to
 * register. They must also specify the new owner of the domain, and the referrer,
 * who is paid an optional finder's fee. The registrar then configures a simple
 * default resolver, which resolves `addr` lookups to the new owner, and sets
 * the `owner` account as the owner of the subdomain in ENS.
 *
 * New domains may be added by calling `configureDomain`, then transferring
 * ownership in the ENS registry to this contract. Ownership in the contract
 * may be transferred using `transfer`, and a domain may be unlisted for sale
 * using `unlistDomain`. There is (deliberately) no way to recover ownership
 * in ENS once the name is transferred to this registrar.
 *
 * Critically, this contract does not check one key property of a listed domain:
 *
 * - Is the name UTS46 normalised?
 *
 * User applications MUST check these two elements for each domain before
 * offering them to users for registration.
 *
 * Applications should additionally check that the domains they are offering to
 * register are controlled by this registrar, since calls to `register` will
 * fail if this is not the case.
 */
contract ENSMigrationSubdomainRegistrar is EthRegistrarSubdomainRegistrar {

    constructor(ENS ens) EthRegistrarSubdomainRegistrar(ens) public { }

    function migrateSubdomain(bytes32 node, bytes32 label) external {
        bytes32 subnode = keccak256(abi.encodePacked(node, label));
        address previous = ens.owner(subnode);

        // only allow a contract to run their own migration
        require(!isContract(previous) || msg.sender == previous);

        ens.setSubnodeRecord(node, label, previous, ens.resolver(subnode), ens.ttl(subnode));
    }

    function isContract(address addr) private returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}
