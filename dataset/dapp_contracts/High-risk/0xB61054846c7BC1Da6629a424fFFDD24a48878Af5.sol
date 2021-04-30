pragma solidity ^0.4.20;

contract Universe{
    // Universe contract
    // It is possible to buy planets or other universe-objects from other accounts.
    // If an object has an owner, fees will be paid to that owner until no owner has been found.
    
    struct Item{
        uint256 id;
        string name;
        uint256 price;
        uint256 id_owner;
        address owner;
    }
    
   // bool TESTMODE = true;
    
  //  event pushuint(uint256 push);
 //   event pushstr(string str);
  //  event pusha(address addr);
    
    uint256[4] LevelLimits = [0.05 ether, 0.5 ether, 2 ether, 5 ether];
    uint256[5] devFee = [5,4,3,2,2];
    uint256[5] shareFee = [12,6,4,3,2];
    uint256[5] raisePrice = [100, 35, 25, 17, 15];
    
    
    mapping (uint256 => Item) public ItemList;
    uint256 public current_item_index=1;
    
    address owner;
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    function Universe() public{
        owner=msg.sender;
        AddItem("Sun", 1 finney, 0);
        AddItem("Mercury", 1 finney, 1);
        AddItem("Venus", 1 finney, 1);
        AddItem("Earth", 1 finney, 1);
        AddItem("Mars", 1 finney, 1);
        AddItem("Jupiter", 1 finney, 1);
        AddItem("Saturn", 1 finney, 1);
        AddItem("Uranus", 1 finney, 1);
        AddItem("Neptune", 1  finney, 1);
        AddItem("Pluto", 1 finney, 1);
        AddItem("Moon", 1 finney, 4);
    }
    
    function CheckItemExists(uint256 _id) internal returns (bool boolean){
        if (ItemList[_id].price == 0){
            return false;
        }
        return true;
    }

    
 //   function AddItem(string _name, uint256 _price, uint256 _id_owner) public {
    function AddItem(string _name, uint256 _price, uint256 _id_owner) public onlyOwner {
//if (TESTMODE){
//if (_price < (1 finney)){
  //              _price = (1 finney);
    //        }
//}
        //require(_id != 0);
        //require(_id == current_item_index);
        uint256 _id = current_item_index;

        require(_id_owner != _id);
        require(_id_owner < _id);

        require(_price >= (1 finney));
        require(_id_owner == 0 || CheckItemExists(_id_owner));
        require(CheckItemExists(_id) != true);
        
     //   uint256 current_id_owner = _id_owner;
        
     //   uint256[] mem_owner;
        
        //pushuint(mem_owner.length);
        
        /*while (current_id_owner != 0){
           
            mem_owner[mem_owner.length-1] = current_id_owner;
            current_id_owner = ItemList[current_id_owner].id_owner;
            
          
            for(uint256 c=0; c 0 && _id < current_item_index);
        var TheItem = ItemList[_id];
        require(TheItem.owner != msg.sender);
        require(msg.value >= TheItem.price);
    
        uint256 index=0;
        
        for (uint256 c=0; c 0){
            msg.sender.transfer(totalBack);
        }
        
       // pushstr("owner transfer");
       // pushuint(totalToOwner);
        TheItem.owner.transfer(totalToOwner);
        
        TheItem.owner = msg.sender;
        TheItem.price = valueRaisePrice;
    }
    
   function mul(uint256 a, uint256 b) internal pure returns (uint256) {
      if (a == 0) {
         return 0;
      }
      uint256 c = a * b;
      assert(c / a == b);
      return c;
   }

   function div(uint256 a, uint256 b) internal pure returns (uint256) {
      // assert(b > 0); // Solidity automatically throws when dividing by 0
      uint256 c = a / b;
      // assert(a == b * c + a % b); // There is no case in which this doesn't hold
      return c;
   }

   function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
   }

   function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
   }
    
}
