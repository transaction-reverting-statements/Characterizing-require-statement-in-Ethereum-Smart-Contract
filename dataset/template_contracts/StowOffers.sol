pragma solidity 0.4.24;

import "./StowDDEXHub.sol";

/**
 * @title Stow Offer Contract
 */


contract StowOffers {

    /** Struct of an offer being made
    * @prop hasOffered Used to check whether the offer exists *
    * @prop isFullfilled Whether or not the seller has excepted *
    * @prop amount the amount of LIN being offered *
    * @prop publicKey the public key to encrypt record data with if excepted *
    */
    struct Offer {
        bool hasOffered;
        bool isFulfilled;
        uint amount;
        bytes publicKey;
    }

    event StowOfferMade(
        bytes32 indexed dataHash, address indexed buyer, uint amount
    );

    event StowOfferFulfilled(
        bytes32 indexed dataHash, address indexed buyer
    );

    event StowOfferRevoked(
        bytes32 indexed dataHash, address indexed buyer
    );

    StowDDEXHub public ddexhub;

    /* All offers being made */
    /* dataHash => buyer address => offer */
    mapping(bytes32 => mapping(address => Offer)) public offers;

    /* Modifiers */

    modifier onlyUser() {
        require(ddexhub.hubContract().usersContract().isUser(msg.sender));
        _;
    }

    modifier hasBalance(uint amount) {
        require(ddexhub.tokenContract().balanceOf(msg.sender) >= amount);
        _;
    }

    modifier hasNotOffered(bytes32 dataHash) {
        require(!offers[dataHash][msg.sender].hasOffered);
        _;
    }

    modifier onlyOffered(bytes32 dataHash) {
        require(offers[dataHash][msg.sender].hasOffered);
        _;
    }

    modifier isNotFulfilled(bytes32 dataHash) {
        require(!offers[dataHash][msg.sender].isFulfilled);
        _;
    }

    modifier onlyStaked() {
        require(ddexhub.stakingContract().isUserStaked(msg.sender));
        _;
    }

    /* Constructor */
    constructor(StowDDEXHub _ddexhub) public {
        ddexhub = _ddexhub;
    }

    /* Fallback function */
    function () public { }

    /* @dev convenience function to see whether or not the sender has already offered for a record */
    /* @param dataHash the dataHash of the record thats being checked */
    function hasOffered(bytes32 dataHash) public view returns (bool) {
        return offers[dataHash][msg.sender].hasOffered;
    }

    /**
    * @dev abstracts out the offer logic into private method so it can be used by both public functions *
    * @param dataHash the hash of the record being offered for *
    * @param publicKey the key that the data will be encrypted with *
    * @param amount the amount off LIN being offered *
    */
    function _makeOffer(bytes32 dataHash, bytes publicKey, uint amount)
        internal
        hasBalance(amount)
        hasNotOffered(dataHash)
        returns (bool)
    {
        /* @dev Puts offer balance in escrow */
        ddexhub.tokenContract().transferFrom(msg.sender, address(this), amount);

        /* @dev Creates new unfulfilled offer from buyer */
        offers[dataHash][msg.sender] = Offer({
            hasOffered: true,
            isFulfilled: false,
            publicKey: publicKey,
            amount: amount
        });

        /* @dev Emit event for caching purposes */
        emit StowOfferMade(dataHash, msg.sender, amount);

        return true;
    }

    /**
    * @dev Freezes balance being offered in contract, creates offer and emits event
    * @param dataHash the hash of the record being offered for *
    * @param publicKey the key that the data will be encrypted with *
    * @param amount the amount off LIN being offered *
    */
    function makeOffer(bytes32 dataHash, bytes publicKey, uint amount)
        public
        onlyUser
        onlyStaked
        returns (bool)
    {
        require(_makeOffer(dataHash, publicKey, amount));

        return true;
    }

    /**
    * @dev Makes multiple offers based on the indexes of the arrays being passed in
    * @param dataHashes the hashes of the records being offered for *
    * @param publicKey the key that the data will be encrypted with *
    * @param amounts array of the amounts of lin being offered *
    */

    function makeOffers(bytes32[] dataHashes, bytes publicKey, uint[] amounts)
        public
        onlyUser
        onlyStaked
        returns (bool)
    {
        /* @dev must be matching amounts of hashes and amounts */
        require(dataHashes.length == amounts.length);

        /* @dev iterate through pairs, revert if one fails */
        for (uint i = 0; i < dataHashes.length; i++) {
            require(_makeOffer(dataHashes[i], publicKey, amounts[i]));
        }

        return true;
    }

    /**
    * @param dataHash The record revoking the offer from.
    * @dev Revoke offer, unfreezes balance and emit event
    */
    function revokeOffer(bytes32 dataHash)
        public
        onlyUser
        onlyOffered(dataHash)
        isNotFulfilled(dataHash)
        onlyStaked
        returns (bool)
    {

        /* @dev Set offer as not offered */
        offers[dataHash][msg.sender].hasOffered = false;

        /* @dev Send escrowed balance back */
        ddexhub.tokenContract().transfer(msg.sender, offers[dataHash][msg.sender].amount);

        /* @dev Emit event for caching purposes */
        emit StowOfferRevoked(dataHash, msg.sender);

        return true;
    }

    /**
    * @param dataHash The record being made an offer for.
    * @param buyer The address of the offerer
    * @dev Fulfills an offer and gives the seller the escrowed LIN if the permission has been created
    */
    function approveOffer(bytes32 dataHash, address buyer)
        public
        onlyStaked
        returns (bool)
    {
        /* @dev only record owner can approve */
        require(ddexhub.hubContract().recordsContract().recordOwnerOf(dataHash) == msg.sender);

        /* @dev pulls the offer from the contract state */
        Offer memory offer = offers[dataHash][buyer];

        /* @dev only approve made offers */
        require(offer.hasOffered);

        // /* @dev only approve unfulfilled offers */
        require(!offer.isFulfilled);

        // /* @dev make sure the permission has been created */
        require(ddexhub.hubContract().permissionsContract().checkAccess(dataHash, buyer));

        // /* @dev gives the escrowed balance to the seller/approver */
        require(ddexhub.tokenContract().transfer(msg.sender, offer.amount));

        offers[dataHash][msg.sender].isFulfilled = true;

        /* @dev Emit event for caching purposes */
        emit StowOfferFulfilled(dataHash, msg.sender);

        return true;
    }

}
