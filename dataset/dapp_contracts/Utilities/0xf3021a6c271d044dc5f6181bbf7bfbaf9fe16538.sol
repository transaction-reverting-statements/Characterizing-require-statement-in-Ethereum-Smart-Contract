pragma solidity ^0.4.24;

contract Factory {
  address developer = 0x0033F8dAcBc75F53549298100E85102be995CdBF59;

  event ContractCreated(address creator, address newcontract, uint timestamp, string contract_type);
    
  function setDeveloper (address _dev) public {
    if(developer==address(0) || developer==msg.sender){
       developer = _dev;
    }
  }
  
  function createContract (bool isbroker, string contract_type, bool _brokerrequired) 
  public {
    address newContract = new Broker(isbroker, developer, msg.sender, _brokerrequired);
    emit ContractCreated(msg.sender, newContract, block.timestamp, contract_type);
  } 
}

contract Broker {
  enum State { Created, Validated, Locked, Finished }
  State public state;

  enum FileState { 
    Created, 
    Invalidated
    // , Confirmed 
  }

  struct File{
    // The purpose of this file. Like, picture, license info., etc.
    // to save the space, we better use short name.
    // Dapps should match proper long name for this.
    bytes32 purpose;
    // name of the file
    string name;
    // ipfs id for this file
    string ipfshash;
    FileState state;
  }

  struct Item{
    string name;
    // At least 0.1 Finney, because it's the fee to the developer
    uint   price;
    // this could be a link to an Web page explaining about this item
    string detail;
    File[] documents;
  }
  
  struct BuyInfo{
    address buyer;
    bool completed;
  }

  Item public item;
  address public seller = address(0);
  address public broker = address(0);
  uint    public brokerFee;
  // Minimum 0.1 Finney (0.0001 eth ~ 25Cent) to 0.01% of the price.
  uint    public developerfee = 0.1 finney;
  uint    minimumdeveloperfee = 0.1 finney;
  address developer = 0x0033F8dAcBc75F53549298100E85102be995CdBF59;
  // bool public validated;
  address creator = 0x0;
  address factory = 0x0;
  
  bool bBrokerRequired = true;
  BuyInfo[] public buyinfo;


  modifier onlySeller() {
    require(msg.sender == seller);
    _;
  }

  modifier onlyCreator() {
    require(msg.sender == creator);
    _;
  }

  modifier onlyBroker() {
    require(msg.sender == broker);
    _;
  }

  modifier inState(State _state) {
      require(state == _state);
      _;
  }

  modifier condition(bool _condition) {
      require(_condition);
      _;
  }

  event AbortedBySeller();
  event AbortedByBroker();
  event PurchaseConfirmed(address buyer);
  event ItemReceived();
  event IndividualItemReceived(address buyer);
  event Validated();
  event ItemInfoChanged(string name, uint price, string detail, uint developerfee);
  event SellerChanged(address seller);
  event BrokerChanged(address broker);
  event BrokerFeeChanged(uint fee);

  // The constructor
  constructor(bool isbroker, address _dev, address _creator, bool _brokerrequired) 
    public 
  {
    bBrokerRequired = _brokerrequired;
    if(creator==address(0)){
      //storedData = initialValue;
      if(isbroker)
        broker = _creator;
      else
        seller = _creator;
      creator = _creator;
      // value = msg.value / 2;
      // require((2 * value) == msg.value);
      state = State.Created;

      // validated = false;
      brokerFee = 50;
    }
    if(developer==address(0) || developer==msg.sender){
       developer = _dev;
    }
    if(factory==address(0)){
       factory = msg.sender;
    }
  }

  function joinAsBroker() public {
    if(broker==address(0)){
      broker = msg.sender;
    }
  }

  function createOrSet(string name, uint price, string detail)
    public 
    inState(State.Created)
    onlyCreator
  {
    require(price > minimumdeveloperfee);
    item.name = name;
    item.price = price;
    item.detail = detail;
    developerfee = (price/1000)0){
          uint val = address(this).balance / buyinfo.length;
          for (uint256 x = 0; x < buyinfo.length; x++) {
              if(buyinfo[x].completed==false){
                buyinfo[x].buyer.transfer(val);
              }
          }
      }
      state = State.Finished;
  }

  /// Abort the purchase and reclaim the ether.
  /// Can only be called by the seller before
  /// the contract is locked.
  function abort()
    public 
    onlySeller
  {
    returnMoneyToBuyers();
    emit AbortedBySeller();
    // validated = false;
    seller.transfer(address(this).balance);
  }

  function abortByBroker()
    public 
    onlyBroker
  {
    if(!bBrokerRequired)
      return;
    returnMoneyToBuyers();
    emit AbortedByBroker();
  }

  /// Confirm the purchase as buyer.
  /// The ether will be locked until confirmReceived
  /// is called.
  function confirmPurchase()
    public 
    condition(msg.value == item.price)
    payable
  {
      if(bBrokerRequired){
        if(state != State.Validated && state != State.Locked){
          return;
        }
      }
      
      if(state == State.Finished){
        return;
      }
      
      state = State.Locked;
      emit PurchaseConfirmed(msg.sender);
      bool complete = false;
      if(!bBrokerRequired){
    // send money right away
        complete = true;
        seller.transfer(item.price-developerfee);
        developer.transfer(developerfee);
      }
      buyinfo.push(BuyInfo(msg.sender, complete));
  }

  /// Confirm that you (the buyer) received the item.
  /// This will release the locked ether.
  function confirmReceived()
    public 
    onlyBroker
    inState(State.Locked)
  {
      if(buyinfo.length>0){
          for (uint256 x = 0; x < buyinfo.length; x++) {
              confirmReceivedAt(x);
          }
      }
      
      // It is important to change the state first because
      // otherwise, the contracts called using `send` below
      // can call in again here.
      state = State.Finished;
  }
  
  //
  function confirmReceivedAt(uint index)
    public 
    onlyBroker
    inState(State.Locked)
  {
      // In this case the broker is confirming one by one,
      // the other purchase should go on. So we don't change the status.
      if(index>=buyinfo.length)
        return;
      if(buyinfo[index].completed)
        return;

      // NOTE: This actually allows both the buyer and the seller to
      // block the refund - the withdraw pattern should be used.
      seller.transfer(item.price-brokerFee-developerfee);
      broker.transfer(brokerFee);
      developer.transfer(developerfee);
      
      buyinfo[index].completed = true;

      emit IndividualItemReceived(buyinfo[index].buyer);
  }

  function getInfo() constant 
    public 
    returns (State, string, uint, string, uint, uint, address, address, bool)
  {
    return (state, item.name, item.price, item.detail, item.documents.length, 
        developerfee, seller, broker, bBrokerRequired);
  }
  
  function getBalance() constant
    public
    returns (uint256)
  {
    return address(this).balance;
  }

  function getFileAt(uint index) 
    public 
    constant returns(uint, bytes32, string, string, FileState)
  {
    return (index,
      item.documents[index].purpose,
      item.documents[index].name,
      item.documents[index].ipfshash,
      item.documents[index].state);
  }
}
