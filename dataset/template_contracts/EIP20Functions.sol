pragma solidity ^0.5.0;
import "./EIP20Storage.sol";
import "./libs/math/SafeMath.sol";

contract EIP20Functions {
    using SafeMath for uint256;
    uint256 constant private MAX_UINT256 = 2**256 - 1;

    EIP20Storage public eipStorage;

    string public name;
    uint8 public decimals;
    string public symbol;

    constructor (
        uint256 _initialAmount,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol
    ) public {
        eipStorage = new EIP20Storage(address(this));
        eipStorage.setBalances(msg.sender,_initialAmount);
        eipStorage.increaseSupply(_initialAmount);
        name = _tokenName;
        decimals = _decimalUnits;
        symbol = _tokenSymbol;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(eipStorage.balanceOf(msg.sender) >= _value);

        //balances[msg.sender] -= _value;
        uint256 fromValue = eipStorage.balanceOf(msg.sender).sub(_value);
        eipStorage.setBalances(msg.sender,fromValue);
        
        //balances[_to] += _value;
        uint256 toValue = eipStorage.balanceOf(_to).add(_value);
        eipStorage.setBalances(_to,toValue);

        emit Transfer(msg.sender, _to, _value); 
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // uint256 allowance = allowed[_from][msg.sender];
        uint256 allowance = eipStorage.allowance(_from,msg.sender);

        //require(balances[_from] >= _value && allowance >= _value);
        require(eipStorage.balanceOf(_from) >= _value && allowance >= _value);

        // balances[_from] -= _value;
        uint256 fromValue = eipStorage.balanceOf(_from).sub(_value);
        eipStorage.setBalances(_from,fromValue);

        // balances[_to] += _value;
        uint256 toValue = eipStorage.balanceOf(_to).add(_value);
        eipStorage.setBalances(_to,toValue);

        if (allowance < MAX_UINT256) {
            // allowed[_from][msg.sender] -= _value;
            uint256 allowedValue = allowance.sub(_value);
            eipStorage.setAllowed(_from,msg.sender, allowedValue);
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        //allowed[msg.sender][_spender] = _value;
        eipStorage.setAllowed(msg.sender, _spender, _value);
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function totalSupply() public view returns (uint256) {
        return eipStorage.totalSupply();
    }
    function balances(address _owner) public view returns (uint256) {
        return eipStorage.balanceOf(_owner);
    }
    function balanceOf(address _owner) public view returns (uint256) {
        return eipStorage.balanceOf(_owner);
    }

    function allowed(address _owner, address _spender) public view returns (uint256) {
        return eipStorage.allowance(_owner, _spender);
    }
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return eipStorage.allowance(_owner, _spender);
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}