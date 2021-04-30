pragma solidity ^0.4.25; 



contract EtherGarden{

	mapping (uint256 => uint256) public VegetablesTradeBalance;
 	mapping (address => mapping (uint256 => uint256)) public OwnerVegetableStartGrowing;
 	mapping (address => mapping (uint256 => uint256)) public OwnerVegetableFieldSize;
	mapping (address => address) public Referrals;

	uint256 VegetableCount=4;
	uint256 minimum=0.0001 ether;
	uint256 growingSpeed=86400; //1 day
	uint256 public FreeFieldSize=50;

	bool public initialized=false;
	address public coOwner;
	
	
    /**
     * @dev Сonstructor Sets the original roles of the contract 
     */
     
    constructor() public {
        coOwner=msg.sender;
    }
	
    /**
     * @dev Modifiers
     */	
	 
    modifier onlyOwner() {
        require(msg.sender == coOwner);
        _;
    }
    modifier isInitialized() {
        require(initialized);
        _;
    }	

    /**
     * @dev Market functions
     */		

    function sellVegetables(uint256 _VegetableId) public isInitialized {
        require(_VegetableId < VegetableCount);
		
		uint256 value=vegetablesValue(_VegetableId);
        if (value>0) {
			uint256 price=SafeMath.mul(vegetablePrice(_VegetableId),value);
			uint256 fee=devFee(price);
			
			OwnerVegetableStartGrowing[msg.sender][_VegetableId]=now;
			VegetablesTradeBalance[_VegetableId]=SafeMath.add(VegetablesTradeBalance[_VegetableId],value);
			
			coOwner.transfer(fee);
			msg.sender.transfer(SafeMath.sub(price,fee));
		}
    }	 
	
    function buyField(uint256 _VegetableId, address _referral) public payable isInitialized {
        require(_VegetableId < VegetableCount);
		require(msg.value > minimum);
		
		uint256 acres=SafeMath.div(msg.value,fieldPrice(msg.value));
        
		if (OwnerVegetableStartGrowing[msg.sender][_VegetableId]>0)
			sellVegetables(_VegetableId);
		
		OwnerVegetableStartGrowing[msg.sender][_VegetableId]=now;
		OwnerVegetableFieldSize[msg.sender][_VegetableId]=SafeMath.add(OwnerVegetableFieldSize[msg.sender][_VegetableId],acres);
		VegetablesTradeBalance[_VegetableId]=SafeMath.add(VegetablesTradeBalance[_VegetableId],acres);
		
        uint256 fee=devFee(msg.value);
		coOwner.transfer(fee);
		
		if (address(_referral)>0 && address(_referral)!=msg.sender && Referrals[msg.sender]==address(0)) {
			Referrals[msg.sender]=_referral;
		}
		if (Referrals[msg.sender]!=address(0)) {
		    address refAddr=Referrals[msg.sender];
			refAddr.transfer(fee);
		}
		
    }
	 
	function reInvest(uint256 _VegetableId) public isInitialized {
		require(_VegetableId < VegetableCount);
		uint256 value=vegetablesValue(_VegetableId);
		require(value>0);
		
		OwnerVegetableFieldSize[msg.sender][_VegetableId]=SafeMath.add(OwnerVegetableFieldSize[msg.sender][_VegetableId],value);
		OwnerVegetableStartGrowing[msg.sender][_VegetableId]=now;
	}
	
    function getFreeField(uint256 _VegetableId) public isInitialized {
		require(OwnerVegetableFieldSize[msg.sender][_VegetableId]==0);
		OwnerVegetableFieldSize[msg.sender][_VegetableId]=FreeFieldSize;
		OwnerVegetableStartGrowing[msg.sender][_VegetableId]=now;
		
    }
	
    function initMarket(uint256 _init_value) public payable onlyOwner{
        require(!initialized);
        initialized=true;

		for (uint256 vegetableId=0; vegetableId 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
