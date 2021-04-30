pragma solidity ^0.5.0;
import "./EIP20Functions.sol";
import "./EIP20Storage.sol";

import "./libs/math/SafeMath.sol";
import "./libs/ownership/owned.sol";

contract UpgradableEIP20 is EIP20Functions, owned {

    constructor (
        uint256 _initialAmount,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol
    ) EIP20Functions(_initialAmount, _tokenName, _decimalUnits, _tokenSymbol)
    public {

    }

    function upgradeFunctions(address _a) public onlyOwner {
        eipStorage.upgradeFunctions(_a);
    }
}