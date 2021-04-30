pragma solidity 0.4.24;

import "@stowprotocol/stow-token-contracts/contracts/STOWToken.sol";
import "@stowprotocol/stow-smart-contracts/contracts/StowHub.sol";
import "openzeppelin-solidity/contracts/lifecycle/Destructible.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./StowOffers.sol";
import "./StowStaking.sol";

/**
 * @title Stow DDEX Hub Contract
 */


contract StowDDEXHub is Ownable, Destructible {

    STOWToken public tokenContract;
    StowHub public hubContract;
    StowOffers public offersContract;
    StowStaking public stakingContract;

    event StowOffersContractSet(address from, address to);
    event StowStakingContractSet(address from, address to);
    event StowHubContractSet(address from, address to);
    event StowTokenContractSet(address from, address to);

    constructor(StowHub _hubContract, STOWToken _tokenContract) public {
        setHubContract(_hubContract);
        setTokenContract(_tokenContract);
    }

    function () public { }

    function setOffersContract(StowOffers _offersContract)
        external
        onlyOwner
        returns (bool)
    {
        address prev = address(offersContract);
        offersContract = _offersContract;
        emit StowOffersContractSet(prev, _offersContract);
        return true;
    }

    function setStakingContract(StowStaking _stakingContract)
        external
        onlyOwner
        returns (bool)
    {
        address prev = address(stakingContract);
        stakingContract = _stakingContract;
        emit StowStakingContractSet(prev, _stakingContract);
        return true;
    }

    function setHubContract(StowHub _hubContract)
        public
        onlyOwner
        returns (bool)
    {
        address prev = address(hubContract);
        hubContract = _hubContract;
        emit StowHubContractSet(prev, _hubContract);
        return true;
    }

    function setTokenContract(STOWToken _tokenContract)
        public
        onlyOwner
        returns (bool)
    {
        address prev = address(tokenContract);
        tokenContract = _tokenContract;
        emit StowTokenContractSet(prev, _tokenContract);
        return true;
    }


}
