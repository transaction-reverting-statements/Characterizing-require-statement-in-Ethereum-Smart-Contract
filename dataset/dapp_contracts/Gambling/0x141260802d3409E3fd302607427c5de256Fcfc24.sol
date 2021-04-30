pragma solidity ^0.4.25;





  

contract owned {
    address public master_address;
    address public mayor;
    address public contract_owner; 
    
 
    constructor() public{
        
        master_address = 0x0ac10bf0342fa2724e93d250751186ba5b659303; 
        mayor = msg.sender;
        contract_owner = msg.sender;
    }  
    modifier onlyMaster{ 
        require(msg.sender == master_address);
        _;
    }  
 
    modifier onlyowner{
        require(msg.sender == contract_owner);
        _;
    }

    function transferMastership(address new_master) public onlyowner {
        master_address = new_master;
    }

    function transferMayorship(address new_mayor) public onlyMaster {
        mayor = new_mayor;
    } 
    
    
    
    
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface IERC721Receiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
}

contract ERC165 is IERC165 {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff);
        _supportedInterfaces[interfaceId] = true;
    }
}

 

interface ERC20_interface {
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns(bool);
}

 interface treasure{
     function callTreasureMin(uint8 index, address target, uint mintedAmount) external;
     function callTreasureBurn(uint8 index, address target, uint burnedAmount) external;
 }



contract ERC20 {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns(bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
}

library Address {

    function isContract(address account) internal view returns (bool) { 
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

library SafeMath{

     function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

     function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

 }
 
 library SafeMath8{
     function add(uint8 a, uint8 b) internal pure returns (uint8) {
        uint8 c = a + b;
        require(c >= a);

        return c;
    }

    function sub(uint8 a, uint8 b) internal pure returns (uint8) {
        require(b <= a);
        uint8 c = a - b;
        return c;
    }

 }
 
 library SafeMath16{
     function add(uint16 a, uint16 b) internal pure returns (uint16) {
        uint16 c = a + b;
        require(c >= a);

        return c;
    }

    function sub(uint16 a, uint16 b) internal pure returns (uint16) {
        require(b <= a);
        uint16 c = a - b;
        return c;
    }

     function mul(uint16 a, uint16 b) internal pure returns (uint16) {
        if (a == 0) {
            return 0;
        }
        uint16 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint16 a, uint16 b) internal pure returns (uint16) {
        require(b > 0);
        uint16 c = a / b;
        return c;
    }
 }


contract ERC721{

     event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
     event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
     event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

     function balanceOf(address _owner) public view returns (uint256);
     function ownerOf(uint256 _tokenId) public view returns (address);
     function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) public payable;
     function safeTransferFrom(address _from, address _to, uint256 _tokenId) public payable;
     function transferFrom(address _from, address _to, uint256 _tokenId) public payable;
     function approve(address _approved, uint256 _tokenId) external payable;
     function setApprovalForAll(address _operator, bool _approved) external;
     function getApproved(uint256 _tokenId) public view returns (address);
     function isApprovedForAll(address _owner, address _operator) public view returns (bool);
 }

contract external_function{
    function inquire_totdomains_amount() public view returns(uint16);
    
    

    function inquire_domain_level_star(uint16 _id) public view returns(uint8, uint8);
    function inquire_domain_building(uint16 _id, uint8 _index) public view returns(uint8);
    function inquire_domain_attribute(uint16 _id, uint8 _index) public view returns(uint8);
    function inquire_tot_domain_attribute(uint16 _id) public view returns(uint8[5]);
    function inquire_domain_cooltime(uint16 _id) public view returns(uint);
    function inquire_mayor_cooltime() public view returns(uint);
    function inquire_mayor_address() public view returns(address);
    function inquire_own_domain(address _sender) public view returns(uint16[]);
    
    function inquire_land_info(uint16  _city_number, uint16 _id) public pure returns(uint8,uint8,uint8,uint8,uint8,uint8,uint8,uint8,uint8,uint8);
    function inquire_building_limit(uint8 _building) public view returns(uint8);
  
    function domain_build(uint16 _id,  uint8 _building) external;
    function reconstruction(uint16 _id, uint8 _index, uint8 _building)external;
    function set_domian_attribute(uint16 _id, uint8 _index) external;
    function domain_all_reward(uint8 _class, address _user) external;
    function mayor_reward(address _user)external;
    

    function domain_reward(uint8 _class, address _user, uint16 _id) external;
    function transfer_master(address _to, uint16 _id) public;
    function retrieve_domain(uint16 _id) external;
    function set_domain_cooltime(uint cooltime) external;
}

interface master{
    function inquire_location(address _address) external view returns(uint16, uint16);
}

interface trade{
    function set_city_box_amount(uint16 _city, uint8 _index, uint _amount ) external;
}



contract slave is ERC165, ERC721, external_function, owned{
    
    event openBoxAmount(address indexed target, uint8 boxIndex, uint boxAmount); 

    constructor() public{
        
        _registerInterface(_InterfaceId_ERC721);
        
        random_seed = uint((keccak256(abi.encodePacked(now))));
     
    }    
            
    
      
    address public treasure_contract = 0x1570158e0ad7c5b95c69abe0ce4536f522a1cde6; 
    address public arina_contract = 0xe6987cd613dfda0995a95b3e6acbabececd41376;
    address trade_address = 0x167ee8dDfd7045090CDf8FF38864c6744Ef952d9;
    
       
    uint8 public area_number = 9;  
    uint8 public building_number = 20;
    uint16 public city_number = 9; 
                 
    uint random_seed;         
    uint mayorCooltime;    
                         
              
    string name = "land9";   
    string symbol = "land9"; 
   
    using SafeMath for uint256; 
    using SafeMath16 for uint16;
    using SafeMath8 for uint8; 
    using Address for address;

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    bytes4 private constant _InterfaceId_ERC721 = 0x80ac58cd;


    
    mapping (address => uint256) private owned_domain_amount;

    mapping (address => uint16[]) public owned_domain_id;

    
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    mapping (uint8 => uint8) same_building_limit;

    struct domain{
        address owner; 
        address backup; 
 
        uint8 star; 
        uint8 level; 
        uint8[] building; 
        uint cooltime; 
        
        address approvals; 
        
        uint8[5] attribute; 
        
    }

 
    uint public every_cooltime = 86400;

 
    uint8 public building_amount = 4; 
    uint8 public building_type_amount = 20; 
    
 

    uint8 level_limit = 100; 
    uint8 star_limit = 5; 

    uint8 public domains_amount = 100; 

    domain[100] public citys; 


    function set_treasure_contract(address _treasure_contract) public onlyowner{
        treasure_contract = _treasure_contract;
    }

    function set_arina_contract(address _arina_contract) public onlyowner{
        arina_contract = _arina_contract;
    }

    function set_building_amount(uint8 _building_amount) public onlyowner{
        building_amount = _building_amount;
    }

    function set_building_type_amount(uint8 _building_type_amount) public onlyowner{
        building_type_amount = _building_type_amount;
    }

    function set_level_limit(uint8 _level_limit) public onlyowner{
        level_limit = _level_limit;
    }

    function set_star_limit(uint8 _star_limit) public onlyowner{
        star_limit = _star_limit;
    }

    function set_city_number(uint8 _city_number) public onlyowner{
        city_number = _city_number;
    }

    function set_area_number(uint8 _area_number) public onlyowner{
        area_number = _area_number;
    }
     
    function set_trade_address(address _trade_address) public onlyowner{ 
       trade_address = _trade_address;
    } 
    

    function withdraw_all_ETH() public onlyowner{
        contract_owner.transfer(address(this).balance);
    }

    
    
    
    

    function withdraw_ETH(uint _eth_wei) public onlyowner{
        contract_owner.transfer(_eth_wei);
    }

    
    
    



    
    function inquire_own_domain(address _sender) public view returns(uint16[]){
        uint16[] memory _own_domains = new uint16[](citys.length);

        uint16 counter = 0;
        for (uint16 i = 0; i < citys.length; i++) {

            if (citys[i].owner == _sender) {
                _own_domains[counter] = i;
                counter = counter.add(1);
            }
        }

        uint16[] memory own_domains = new uint16[](counter);

        for (uint16 j = 0; j < counter; j++) {
            own_domains[j] = _own_domains[j];
        }

        return own_domains;
    }

    function inquire_domain_level(uint16 _id) public view returns(uint8){
        if(citys[_id].level <= level_limit){
            return citys[_id].level;
        }
        else
            return 0;
    }

    function inquire_domain_star(uint16 _id) public view returns(uint8){
        return citys[_id].star;
    }
    

    function inquire_domain_level_star(uint16 _id) public view returns(uint8, uint8){
        uint8 _level;
        if(citys[_id].level <= level_limit){
            _level = citys[_id].level;
        }
        else {
            _level = 0 ;
        }
        return (_level, citys[_id].star);
    }

    function inquire_domain_building(uint16 _id, uint8 _index) public view returns(uint8){
        return citys[_id].building[_index];
    }


    function inquire_tot_domain_building(uint16 _id) public view returns(uint8[]){
        return citys[_id].building;
    }

    function inquire_domain_cooltime(uint16 _id) public view returns(uint){
        return citys[_id].cooltime;
    } 
    
    function inquire_mayor_address() public view returns(address){
        return mayor;
    }
    
    function inquire_mayor_cooltime() public view returns(uint){
        return mayorCooltime;
    }
 

    function inquire_totdomains_amount() public view returns(uint16){
      return uint16(citys.length);
    }
    
    function inquire_domain_attribute(uint16 _id, uint8 _index) public view returns(uint8){
        return citys[_id].attribute[_index];
    }
    
    function inquire_tot_domain_attribute(uint16 _id) public view returns(uint8[5]){
        return citys[_id].attribute;
    }
    
    function inquire_building_limit(uint8 _building) public view returns(uint8){
        return same_building_limit[_building];
    }
    
  



    function() payable public{
    }

    function domain_build(uint16 _id,  uint8 _building) external onlyMaster{
        require(citys[_id].building.length < building_amount,"不能超出可建設區塊數");
        
        require(_building != 0, "不能蓋空地");
        require(_building <= building_type_amount,"不能超出可建設種類"); 
        
        if(isBuilded(_id,_building)){
 
            if(_building == 14){
                require(same_building_limit[14] < building_number);
                same_building_limit[14] = same_building_limit[14].add(1);
            }else if(_building == 15){
                require(same_building_limit[15] < building_number);
                same_building_limit[15] = same_building_limit[15].add(1);
            }else if(_building == 17){
                require(same_building_limit[17] < building_number);
                same_building_limit[17] = same_building_limit[17].add(1);
            }   
                
            citys[_id].building.push(_building);
        }

        if(citys[_id].star < star_limit){ 
            citys[_id].star = citys[_id].star.add(1);
        }
    }

    function reconstruction(uint16 _id, uint8 _index, uint8 _building)
    external onlyMaster{

        require(_index < building_amount); 
        require(_building != 0); 
        require(_building <= building_type_amount); 

        require(citys[_id].building[_index] != 0); 
        uint8 old_building = citys[_id].building[_index];
        if(isBuilded(_id,_building)){
            
             
             
            if(_building == 14){
                require(same_building_limit[14] < building_number);
                same_building_limit[14] = same_building_limit[14].add(1);
            }else if(_building == 15){
                require(same_building_limit[15] < building_number);
                same_building_limit[15] = same_building_limit[15].add(1);
            }else if(_building == 17){
                require(same_building_limit[17] < building_number);
                same_building_limit[17] = same_building_limit[17].add(1);
            } 
            
            citys[_id].building[_index] = _building;
            
            if(old_building == 14){
                same_building_limit[14] = same_building_limit[14].sub(1);
            }else if(old_building == 15){
                same_building_limit[15] = same_building_limit[15].sub(1);
            }else if(old_building == 17){
                same_building_limit[17] = same_building_limit[17].sub(1);
            }
         
        }
 
    }
    
    function set_domian_attribute(uint16 _id, uint8 _index) external onlyMaster{  
         
        uint8 produce;
         
        if(_index == 0){
            (produce,,,,,,,,,) =inquire_land_info(city_number,_id);
             
        }else if(_index == 1){ 
            (,produce,,,,,,,,) =inquire_land_info(city_number,_id);
        }else if(_index == 2){
            (,,produce,,,,,,,) =inquire_land_info(city_number,_id);
        }else if(_index == 3){
            (,,,produce,,,,,,) =inquire_land_info(city_number,_id);
        }else{
            (,,,,produce,,,,,) =inquire_land_info(city_number,_id);
        } 
        
        require((citys[_id].attribute[_index] + produce) < 10);
         
          
        citys[_id].attribute[_index] = citys[_id].attribute[_index].add(1);
    }
    
    function isBuilded(uint16 _id,  uint8 _building) public view returns(bool){ 
        
        uint8 produce01;
        uint8 produce02;
        uint8 produce03; 
        uint8 produce04;
        uint8 produce05;
        uint8 produce07;
        uint8 produce08;
        uint8 produce09;
        
        (produce01,produce02,produce03,produce04,produce05,,produce07,produce08,produce09,) = inquire_land_info(city_number,_id);
        
        produce01 = produce01.add(citys[_id].attribute[0]); 
        produce02 = produce02.add(citys[_id].attribute[1]);
        produce03 = produce03.add(citys[_id].attribute[2]);
        produce04 = produce04.add(citys[_id].attribute[3]);
        produce05 = produce05.add(citys[_id].attribute[4]);

  
        if(_building == 1){
            require(produce01 > 6 && produce09 > 4 && checkBuild(_id,_building),"土地特性需求不滿足條件");
            return true;
        }else if(_building == 2){
            require(produce02 > 6 && checkBuild(_id,_building),"土地特性需求不滿足條件");
            return true;
        }else if(_building == 3 ){
           require(produce05 > 6 && checkBuild(_id,_building),"土地特性需求不滿足條件");
           return true;
        }else if(_building == 4 ){
            require(produce07 > 7 && checkBuild(_id,_building),"土地特性需求不滿足條件");
            return true;
        }else if(_building == 5 || _building == 7){
            require(produce08 < 3 && checkBuild(_id,_building),"土地特性需求不滿足條件");
            return true; 
        }else if(_building == 6 ){
            require(produce07 > 3 && checkBuild(_id,_building),"土地特性需求不滿足條件");
            return true;
        }else if(_building == 8 ){
            require(produce08 > 7 && produce09 > 4 && checkBuild(_id,_building),"土地特性需求不滿足條件");
            return true;
        }else if(_building == 9 ){
            require(produce01 > 4 && produce09 > 4 && checkBuild(_id,_building),"土地特性需求不滿足條件");
            return true;
        }else if(_building == 10 ){
            require(produce03 > 6 && produce07 < 3 && checkBuild(_id,_building),"土地特性需求不滿足條件");
            return true;
        }else if(_building == 11 ){
            require(produce04 > 6 && produce03 < 3 && checkBuild(_id,_building),"土地特性需求不滿足條件");
            return true;
        }else if(_building == 15 || _building == 16 || _building == 18){
            require(produce07 > 7 && produce08 > 7 && checkBuild(_id,_building),"土地特性需求不滿足條件");
            return true;
        }else{
            require(checkBuild(_id,_building),"土地特性需求不滿足條件");
            return true;
        }
    }
    
    function checkBuild(uint16 _id,  uint8 _building) public view returns(bool){     
        bool same = true;                                                            
         for(uint m=0;m= ItemLv5_Random){
            return 5;
        }
        else if(Item_numerator >= ItemLv4_Random){
            return 4;
        }
        else if(Item_numerator >= ItemLv3_Random){
            return 3;
        }
        else if(Item_numerator >= ItemLv2_Random){
            return 2;
        }
        else {
            return 1;
        }
    }

    
    function transfer_master(address _to, uint16 _id) public onlyMaster{
        require(_to != address(0));

        address domain_owner = citys[_id].owner;

        if (domain_owner != 0x0){
            owned_domain_amount[domain_owner] = owned_domain_amount[domain_owner].sub(1);
        }

        if(citys[_id].star == 0){
            citys[_id].star = citys[_id].star.add(1); 
        }

        owned_domain_amount[_to] = owned_domain_amount[_to].add(1);
        owned_domain_id[_to].push(_id);
        citys[_id].owner = _to;
        if(citys[_id].level < level_limit){
            citys[_id].level = citys[_id].level.add(1);
        }

        
    }

    function retrieve_domain(uint16 _id) external onlyMaster{
        require(msg.sender == citys[_id].backup);
        transfer_master(contract_owner, _id);
        emit Transfer(citys[_id].owner, contract_owner, _id);
    }
    
    function set_domain_cooltime(uint _cooltime) external onlyMaster{
        every_cooltime = _cooltime;
    }
     
    function set_building_number(uint8 _building_number) public onlyMaster{
        building_number = _building_number;
    }



    function balanceOf(address _owner) public view returns (uint256){
        require(_owner != address(0));
        return owned_domain_amount[_owner];
    }
    function ownerOf(uint256 _tokenId) public view returns (address){
        address owner = citys[_tokenId].owner;
        return owner;
    }
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) public payable{
        transferFrom(_from, _to, _tokenId);
        require(_checkOnERC721Received(_from, _to, _tokenId, _data));
    }
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public payable{
        safeTransferFrom(_from, _to, _tokenId, "");
    }
    function transferFrom(address _from, address _to, uint256 _tokenId) public payable{
        require(_isApprovedOrOwner(msg.sender, _tokenId));
        _transferFrom(_from, _to, _tokenId);
    }
    function approve(address _approved, uint256 _tokenId) external payable{
        address owner = ownerOf(_tokenId);
        require(_approved != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

        citys[_tokenId].approvals = _approved;
        emit Approval(owner, _approved, _tokenId);
    }
    function setApprovalForAll(address _operator, bool _approved) external{
        require(_operator != msg.sender);
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    function getApproved(uint256 _tokenId) public view returns (address){
        require(_exists(_tokenId));
        return citys[_tokenId].approvals;
    }
    function isApprovedForAll(address _owner, address _operator) public view returns (bool){
        return _operatorApprovals[_owner][_operator];
    }

    function _exists(uint256 _tokenId) internal view returns (bool) {
        address owner = citys[_tokenId].owner;
        return owner != address(0);
    }

    function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        address owner = ownerOf(_tokenId);
        return (_spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender));
    }

    function _transferFrom(address _from, address _to, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _from);
        require(_to != address(0));

        _clearApproval(_tokenId);

        owned_domain_amount[_from] = owned_domain_amount[_from].sub(1);
        owned_domain_amount[_to] = owned_domain_amount[_to].add(1);

        citys[_tokenId].owner = _to;

        emit Transfer(_from, _to, _tokenId);
    }

    function _checkOnERC721Received(address _from, address _to, uint256 _tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!_to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    function _clearApproval(uint256 _tokenId) private {
        if (citys[_tokenId].approvals != address(0)) {
            citys[_tokenId].approvals = address(0);
        }
    }


}
