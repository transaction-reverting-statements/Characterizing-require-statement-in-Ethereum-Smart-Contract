pragma solidity ^0.4.18; // solhint-disable-line



contract VerifyToken {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    bool public activated;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}
contract EthVerifyCore{
  mapping (address => bool) public verifiedUsers;
}
contract ShrimpFarmer is ApproveAndCallFallBack{
    using SafeMath for uint;
    address vrfAddress=0x5BD574410F3A2dA202bABBa1609330Db02aD64C2;//0x5BD574410F3A2dA202bABBa1609330Db02aD64C2;
    VerifyToken vrfcontract=VerifyToken(vrfAddress);

    //257977574257854071311765966
    //                10000000000
    //uint256 EGGS_PER_SHRIMP_PER_SECOND=1;
    uint256 public EGGS_TO_HATCH_1SHRIMP=86400;//86400
    uint public VRF_EGG_COST=(1000000000000000000*300)/EGGS_TO_HATCH_1SHRIMP;
    //uint256 public STARTING_SHRIMP=300;
    uint256 PSN=100000000000000;
    uint256 PSNH=50000000000000;
    uint public POT_DRAIN_TIME=12 hours;//24 hours;
    uint public HATCH_COOLDOWN=6 hours;//6 hours;
    bool public initialized=false;
    //bool public completed=false;

    address public ceoAddress;
    address public dev2;
    mapping (address => uint256) public hatcheryShrimp;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => bool) public hasClaimedFree;
    uint256 public marketEggs;
    EthVerifyCore public ethVerify=EthVerifyCore(0x1c307A39511C16F74783fCd0091a921ec29A0b51);//0x1c307A39511C16F74783fCd0091a921ec29A0b51);

    uint public lastBidTime;//last time someone bid for the pot
    address public currentWinner;
    //uint public potEth=0;
    uint public totalHatcheryShrimp=0;
    uint public prizeEth=0;//eth specifically set aside for the pot

    function ShrimpFarmer() public{
        ceoAddress=msg.sender;
        dev2=address(0x95096780Efd48FA66483Bc197677e89f37Ca0CB5);
        lastBidTime=now;
        currentWinner=msg.sender;
    }
    function finalizeIfNecessary() public{
      if(lastBidTime.add(POT_DRAIN_TIME) 0); // Solidity automatically throws when dividing by 0
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
