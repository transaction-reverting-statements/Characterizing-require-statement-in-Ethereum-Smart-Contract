pragma solidity ^0.5.0;
import "./libs/math/SafeMath.sol";

contract EIP20Storage {
    using SafeMath for uint256;
    uint256 constant private MAX_UINT256 = 2**256 - 1;

    address public functionsContract;

    modifier onlyFunctions {
        require(msg.sender == functionsContract);
        _;
    }

    uint256 public totalSupply;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;


    constructor(address _functions) public {
        functionsContract = _functions;
    }

    function setBalances(address _owner, uint256 _value) public onlyFunctions {
        balances[_owner] = _value;
    }
    function setAllowed(address _owner, address _spender, uint256 _value) public onlyFunctions {
        allowed[_owner][_spender] = _value;
    }
    function upgradeFunctions(address _newContract) public onlyFunctions {
        functionsContract = _newContract;
    }
    function increaseSupply(uint _value) public onlyFunctions {
        totalSupply = totalSupply.add(_value);
    }
    function decreaseSupply(uint _value) public onlyFunctions {
        totalSupply = totalSupply.sub(_value);
    }
    
    // Normal EIP20 functions

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        }
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}