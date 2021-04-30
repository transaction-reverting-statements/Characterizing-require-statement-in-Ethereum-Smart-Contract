pragma solidity ^0.4.0;

/*

                                  # #  ( )
                                  ___#_#___|__
                              _  |____________|  _
                       _=====| | |            | | |==== _
                 =====| |.---------------------------. | |====
   = 0); //just in case
        require (_amount == uint256(uint128(_amount))); // Just some magic stuff
        require (this.balance >= _amount); // Checking if this contract has enought money to pay
        require (balances[msg.sender] >= _amount); // Checking if player has enough funds on his balance
        if (_amount == 0){
            _amount = balances[msg.sender];
            // If the requested amount is 0, it means that player wants to cashout the whole amount of balance
        }

        balances[msg.sender] -= _amount; // Changing the amount of funds on the player's in-game balance

        if (!msg.sender.send(_amount)){ // Sending funds and if the transaction is failed
            balances[msg.sender] += _amount; // Returning the amount of funds on the player's in-game balance
        }

        EventCashOut (msg.sender, _amount);
        return;
    }

    function cashOutShip (uint32 _shipID) public payable {

        require (_shipID > 0 && _shipID < newIdShip); // Checking if the ship exists
        require (ships[_shipID].owner == msg.sender); // Checking if sender owns this ship
        uint256 _amount = shipProducts[ships[_shipID].productID].earning*(shipProducts[ships[_shipID].productID].amountOfShips-ships[_shipID].lastCashoutIndex);
        require (this.balance >= _amount); // Checking if this contract has enought money to pay
        require (_amount > 0);

        uint32 lastIndex = ships[_shipID].lastCashoutIndex;

        ships[_shipID].lastCashoutIndex = shipProducts[ships[_shipID].productID].amountOfShips; // Changing the amount of funds on the ships's in-game balance

        if (!ships[_shipID].owner.send(_amount)){ // Sending funds and if the transaction is failed
            ships[_shipID].lastCashoutIndex = lastIndex; // Changing the amount of funds on the ships's in-game balance
        }

        EventCashOut (msg.sender, _amount);
        return;
    }

    function login (string _hash) public {
        EventLogin (msg.sender, _hash);
        return;
    }

    //upgrade ship
    // @_upgradeChoice: 0 is for armor, 1 is for damage, 2 is for speed, 3 is for attack speed
    function upgradeShip (uint32 _shipID, uint8 _upgradeChoice) public payable {
        require (_shipID > 0 && _shipID < newIdShip); // Checking if the ship exists
        require (ships[_shipID].owner == msg.sender); // Checking if sender owns this ship
        require (_upgradeChoice >= 0 && _upgradeChoice < 4); // Has to be between 0 and 3
        require (ships[_shipID].upgrades[_upgradeChoice] < 5); // Only 5 upgrades are allowed for each type of ship's parametres
        require (msg.value >= upgradePrice); // Checking if there is enough amount of money for the upgrade
        ships[_shipID].upgrades[_upgradeChoice]++; // Upgrading
        balances[msg.sender] += msg.value-upgradePrice; // Returning the rest amount of money back to the ship owner
        balances[UpgradeMaster] += upgradePrice; // Sending the amount of money spent on the upgrade to the contract creator

        EventUpgradeShip (msg.sender, _shipID, _upgradeChoice);
        return;
    }


    // Transfer. Using for sending ships to another players
    function _transfer (uint32 _shipID, address _receiver) public {
        require (_shipID > 0 && _shipID < newIdShip); // Checking if the ship exists
        require (ships[_shipID].owner == msg.sender); //Checking if sender owns this ship
        require (msg.sender != _receiver); // Checking that the owner is not sending the ship to himself
        require (ships[_shipID].selling == false); //Making sure that the ship is not on the auction now
        ships[_shipID].owner = _receiver; // Changing the ship's owner
        ships[_shipID].earner = _receiver; // Changing the ship's earner address

        EventTransfer (msg.sender, _receiver, _shipID);
        return;
    }

    // Transfer Action. Using for sending ships to EtherArmy's contracts. For example, the battle-area contract.
    function _transferAction (uint32 _shipID, address _receiver, uint8 _ActionType) public {
        require (_shipID > 0 && _shipID < newIdShip); // Checking if the ship exists
        require (ships[_shipID].owner == msg.sender); // Checking if sender owns this ship
        require (msg.sender != _receiver); // Checking that the owner is not sending the ship to himself
        require (ships[_shipID].selling == false); // Making sure that the ship is not on the auction now
        ships[_shipID].owner = _receiver; // Changing the ship's owner

        // As you can see, we do not change the earner here.
        // It means that technically speaking, the ship's owner is still getting his earnings.
        // It's logically that this method (transferAction) will be used for sending ships to the battle area contract or some other contracts which will be interacting with ships
        // Be careful with this method! Do not call it to transfer ships to another player!
        // The reason you should not do this is that the method called "transfer" changes the owner and earner, so it is possible to change the earner address to the current owner address any time.
        // However, for our special contracts like battle area, you are able to read this contract and make sure that your ship will not be sent to anyone else, only back to you.
        // So, please, do not use this method to send your ships to other players. Use it just for interacting with Etherships' contracts, which will be listed on Etherships.com

        EventTransferAction (msg.sender, _receiver, _shipID, _ActionType);
        return;
    }

    //selling
    function sellShip (uint32 _shipID, uint256 _startPrice, uint256 _finishPrice, uint256 _duration) public {
        require (_shipID > 0 && _shipID < newIdShip);
        require (ships[_shipID].owner == msg.sender);
        require (ships[_shipID].selling == false); // Making sure that the ship is not on the auction already
        require (_startPrice >= _finishPrice);
        require (_startPrice > 0 && _finishPrice >= 0);
        require (_duration > 0);
        require (_startPrice == uint256(uint128(_startPrice))); // Just some magic stuff
        require (_finishPrice == uint256(uint128(_finishPrice))); // Just some magic stuff

        auctions[newIdAuctionEntity] = AuctionEntity(_shipID, _startPrice, _finishPrice, now, _duration);
        ships[_shipID].selling = true;
        ships[_shipID].auctionEntity = newIdAuctionEntity++;

        EventAuction (msg.sender, _shipID, _startPrice, _finishPrice, _duration, now);
    }

    //bidding function, people use this to buy ships
    function bid (uint32 _shipID) public payable {
        require (_shipID > 0 && _shipID < newIdShip); // Checking if the ship exists
        require (ships[_shipID].selling == true); // Checking if this ships is on the auction now
        AuctionEntity memory currentAuction = auctions[ships[_shipID].auctionEntity]; // The auction entity for this ship. Just to make the line below easier to read
        uint256 currentPrice = currentAuction.startPrice-(((currentAuction.startPrice-currentAuction.finishPrice)/(currentAuction.duration))*(now-currentAuction.startTime));
        // The line above calculates the current price using the formula StartPrice-(((StartPrice-FinishPrice)/Duration)*(CurrentTime-StartTime)
        if (currentPrice < currentAuction.finishPrice){ // If the auction duration time has been expired
            currentPrice = currentAuction.finishPrice;  // Setting the current price as finishPrice
        }
        require (currentPrice >= 0); // Who knows :)
        require (msg.value >= currentPrice); // Checking if the buyer sent the amount of money which is more or equal the current price

        // All is fine, changing balances and changing ship's owner
        uint256 marketFee = (currentPrice/100)*3; // Calculating 3% of the current price as a fee
        balances[ships[_shipID].owner] += currentPrice-marketFee; // Giving [current price]-[fee] amount to seller
        balances[AuctionMaster] += marketFee; // Sending the fee amount to the contract creator's balance
        balances[msg.sender] += msg.value-currentPrice; //Return the rest amount to buyer
        ships[_shipID].owner = msg.sender; // Changing the owner of the ship
        ships[_shipID].selling = false; // Change the ship status to "not selling now"
        delete auctions[ships[_shipID].auctionEntity]; // Deleting the auction entity from the storage for auctions -- we don't need it anymore
        ships[_shipID].auctionEntity = 0; // Not necessary, but deleting the ID of auction entity which was deleted in the operation above

        EventBid (_shipID);
    }

    //cancel auction
    function cancelAuction (uint32 _shipID) public {
        require (_shipID > 0 && _shipID < newIdShip); // Checking if the ship exists
        require (ships[_shipID].selling == true); // Checking if this ships is on the auction now
        require (ships[_shipID].owner == msg.sender); // Checking if sender owns this ship
        ships[_shipID].selling = false; // Change the ship status to "not selling now"
        delete auctions[ships[_shipID].auctionEntity]; // Deleting the auction entity from the storage for auctions -- we don't need it anymore
        ships[_shipID].auctionEntity = 0; // Not necessary, but deleting the ID of auction entity which was deleted in the operation above

        EventCancelAuction (_shipID);
    }


    function newShipProduct (string _name, uint32 _armor, uint32 _speed, uint32 _minDamage, uint32 _maxDamage, uint32 _attackSpeed, uint8 _league, uint256 _price, uint256 _earning, uint256 _releaseTime) private {
        shipProducts[newIdShipProduct++] = ShipProduct(_name, _armor, _speed, _minDamage, _maxDamage, _attackSpeed, _league, _price, _price, _earning, _releaseTime, 0);
    }

    function buyShip (uint32 _shipproductID) public payable {
        require (shipProducts[_shipproductID].currentPrice > 0 && msg.value > 0); //value is more than 0, price is more than 0
        require (msg.value >= shipProducts[_shipproductID].currentPrice); //value is higher than price
        require (shipProducts[_shipproductID].releaseTime <= now); //checking if this ship was released.
        // Basically, the releaseTime was implemented just to give a chance to get the new ship for as many players as possible.
        // It prevents the using of bots.

        if (msg.value > shipProducts[_shipproductID].currentPrice){
            // If player payed more, put the rest amount of money on his balance
            balances[msg.sender] += msg.value-shipProducts[_shipproductID].currentPrice;
        }

        shipProducts[_shipproductID].currentPrice += shipProducts[_shipproductID].earning;

        ships[newIdShip++] = ShipEntity (_shipproductID, [0, 0, 0, 0], msg.sender, msg.sender, false, 0, 0, 0, ++shipProducts[_shipproductID].amountOfShips);

        // After all owners of the same type of ship got their earnings, admins get the amount which remains and no one need it
        // Basically, it is the start price of the ship.
        balances[ShipSellMaster] += shipProducts[_shipproductID].startPrice;

        EventBuyShip (msg.sender, _shipproductID, newIdShip-1);
        return;
    }

    // Our storage, keys are listed first, then mappings.
    // Of course, instead of some mappings we could use arrays, but why not

    uint32 public newIdShip = 1; // The next ID for the new ship
    uint32 public newIdShipProduct = 1; // The next ID for the new ship type
    uint256 public newIdAuctionEntity = 1; // The next ID for the new auction entity

    mapping (uint32 => ShipEntity) ships; // The storage
    mapping (uint32 => ShipProduct) shipProducts;
    mapping (uint256 => AuctionEntity) auctions;
    mapping (address => uint) balances;

    uint256 public constant upgradePrice = 5000000000000000; // The fee which the UgradeMaster earns for upgrading ships. Fee: 0.005 Eth

    function getShipName (uint32 _ID) public constant returns (string){
        return shipProducts[_ID].name;
    }

    function getShipProduct (uint32 _ID) public constant returns (uint32[7]){
        return [shipProducts[_ID].armor, shipProducts[_ID].speed, shipProducts[_ID].minDamage, shipProducts[_ID].maxDamage, shipProducts[_ID].attackSpeed, uint32(shipProducts[_ID].releaseTime), uint32(shipProducts[_ID].league)];
    }

    function getShipDetails (uint32 _ID) public constant returns (uint32[6]){
        return [ships[_ID].productID, uint32(ships[_ID].upgrades[0]), uint32(ships[_ID].upgrades[1]), uint32(ships[_ID].upgrades[2]), uint32(ships[_ID].upgrades[3]), uint32(ships[_ID].exp)];
    }

    function getShipOwner(uint32 _ID) public constant returns (address){
        return ships[_ID].owner;
    }

    function getShipSell(uint32 _ID) public constant returns (bool){
        return ships[_ID].selling;
    }

    function getShipTotalEarned(uint32 _ID) public constant returns (uint256){
        return ships[_ID].earned;
    }

    function getShipAuctionEntity (uint32 _ID) public constant returns (uint256){
        return ships[_ID].auctionEntity;
    }

    function getCurrentPrice (uint32 _ID) public constant returns (uint256){
        return shipProducts[_ID].currentPrice;
    }

    function getProductEarning (uint32 _ID) public constant returns (uint256){
        return shipProducts[_ID].earning;
    }

    function getShipEarning (uint32 _ID) public constant returns (uint256){
        return shipProducts[ships[_ID].productID].earning*(shipProducts[ships[_ID].productID].amountOfShips-ships[_ID].lastCashoutIndex);
    }

    function getCurrentPriceAuction (uint32 _ID) public constant returns (uint256){
        require (getShipSell(_ID));
        AuctionEntity memory currentAuction = auctions[ships[_ID].auctionEntity]; // The auction entity for this ship. Just to make the line below easier to read
        uint256 currentPrice = currentAuction.startPrice-(((currentAuction.startPrice-currentAuction.finishPrice)/(currentAuction.duration))*(now-currentAuction.startTime));
        if (currentPrice < currentAuction.finishPrice){ // If the auction duration time has been expired
            currentPrice = currentAuction.finishPrice;  // Setting the current price as finishPrice
        }
        return currentPrice;
    }

    function getPlayerBalance(address _player) public constant returns (uint256){
        return balances[_player];
    }

    function getContractBalance() public constant returns (uint256){
        return this.balance;
    }

    function howManyShips() public constant returns (uint32){
        return newIdShipProduct;
    }

}

/*
    EtherArmy.com
    Ethertanks.com
    Etheretanks.com
*/
