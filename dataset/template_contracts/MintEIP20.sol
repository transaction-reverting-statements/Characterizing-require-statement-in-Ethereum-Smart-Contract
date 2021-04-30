pragma solidity ^0.5.0;
import "./UpgradableEIP20.sol";
import "./EIP20Storage.sol";

import "./libs/math/SafeMath.sol";
import "./libs/ownership/owned.sol";

contract MintEIP20 is UpgradableEIP20 {

    address public oldFunctionsContract;

    constructor (
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol,
        address _storageAddress
    ) UpgradableEIP20(0, _tokenName, _decimalUnits, _tokenSymbol)
    public {
        eipStorage = EIP20Storage(_storageAddress);
        oldFunctionsContract = address(eipStorage.functionsContract);
    }


    /**
   * @dev Function to mint tokens
   * @param _account The address that will receive the minted tokens.
   * @param _value The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
    function mint(address _account, uint256 _value) public onlyOwner returns (bool)
    {
        return _mint(_account, _value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param _account The account that will receive the created tokens.
     * @param _value The amount that will be created.
     */
    function _mint(address _account, uint256 _value) internal returns (bool) {
        require(_account != address(0));
        eipStorage.increaseSupply(_value);
        eipStorage.setBalances(_account, balanceOf(_account).add(_value));
        return true;
    }

}