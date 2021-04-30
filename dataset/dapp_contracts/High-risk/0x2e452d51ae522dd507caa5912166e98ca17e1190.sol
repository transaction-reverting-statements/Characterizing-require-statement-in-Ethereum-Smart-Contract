pragma solidity ^0.4.25;

contract Richer3D {
    using SafeMath for *;
    
    //************
    //Game Setting
    //************
    string constant public name = "Richer3D";
    string constant public symbol = "R3D";
    address constant private sysAdminAddress = 0x4A3913ce9e8882b418a0Be5A43d2C319c3F0a7Bd;
    address constant private sysInviterAddress = 0xC5E41EC7fa56C0656Bc6d7371a8706Eb9dfcBF61;
    address constant private sysDevelopAddress = 0xCf3A25b73A493F96C15c8198319F0218aE8cAA4A;
    address constant private p3dInviterAddress = 0x82Fc4514968b0c5FdDfA97ed005A01843d0E117d;
    uint256 constant cycleTime = 24 hours;
    bool calculating_target = false;
    //************
    //Game Data
    //************
    uint256 private roundNumber;
    uint256 private dayNumber;
    uint256 private totalPlayerNumber;
    uint256 private platformBalance;
    //*************
    //Game DataBase
    //*************
    mapping(uint256=>DataModal.RoundInfo) private rInfoXrID;
    mapping(address=>DataModal.PlayerInfo) private pInfoXpAdd;
    mapping(address=>uint256) private pIDXpAdd;
    mapping(uint256=>address) private pAddXpID;
    
    //*************
    // P3D Data
    //*************
    HourglassInterface constant p3dContract = HourglassInterface(0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe);

    mapping(uint256=>uint256) private p3dDividesXroundID;

    //*************
    //Game Events
    //*************
    event newPlayerJoinGameEvent(address indexed _address,uint256 indexed _amount,bool indexed _JoinWithEth,uint256 _timestamp);
    event calculateTargetEvent(uint256 indexed _roundID);
    
    constructor() public {
        dayNumber = 1;
    }
    
    function() external payable {
        joinGameWithInviterID(0);
    }
    
    //************
    //Game payable
    //************
    function joinGameWithInviterID(uint256 _inviterID) public payable {
        uint256 _timestamp = now;
        address _senderAddress = msg.sender;
        uint256 _eth = msg.value;
        require(_timestamp.sub(rInfoXrID[roundNumber].lastCalculateTime) < cycleTime,"Waiting for settlement");
        if(pIDXpAdd[_senderAddress] < 1) {
            registerWithInviterID(_inviterID);
        }
        buyCore(_senderAddress,pInfoXpAdd[_senderAddress].inviterAddress,_eth);
        emit newPlayerJoinGameEvent(msg.sender,msg.value,true,_timestamp);
    }
    
    //********************
    // Method need Gas
    //********************
    function joinGameWithBalance(uint256 _amount) public {
        uint256 _timestamp = now;
        address _senderAddress = msg.sender;
        require(_timestamp.sub(rInfoXrID[roundNumber].lastCalculateTime) < cycleTime,"Waiting for settlement");
        uint256 balance = getUserBalance(_senderAddress);
        require(balance >= _amount,"balance is not enough");
        buyCore(_senderAddress,pInfoXpAdd[_senderAddress].inviterAddress,_amount);
        pInfoXpAdd[_senderAddress].withDrawNumber = pInfoXpAdd[_senderAddress].withDrawNumber.sub(_amount);
        emit newPlayerJoinGameEvent(_senderAddress,_amount,false,_timestamp);
    }
    
    function calculateTarget() public {
        require(calculating_target == false,"Waiting....");
        calculating_target = true;
        uint256 _timestamp = now;
        require(_timestamp.sub(rInfoXrID[roundNumber].lastCalculateTime) >= cycleTime,"Less than cycle Time from last operation");
        //allocate p3d dividends to contract 
        uint256 dividends = p3dContract.myDividends(true);
        if(dividends > 0) {
            if(rInfoXrID[roundNumber].dayInfoXDay[dayNumber].playerNumber > 0) {
                p3dDividesXroundID[roundNumber] = p3dDividesXroundID[roundNumber].add(dividends);
                p3dContract.withdraw();    
            } else {
                platformBalance = platformBalance.add(dividends);
                p3dContract.withdraw();    
            }
        }
        uint256 increaseBalance = getIncreaseBalance(dayNumber,roundNumber);
        uint256 targetBalance = getDailyTarget(roundNumber,dayNumber);
        uint256 ethForP3D = increaseBalance.div(100);
        if(increaseBalance >= targetBalance) {
            //buy p3d
            if(getIncreaseBalance(dayNumber,roundNumber) > 0) {
                p3dContract.buy.value(getIncreaseBalance(dayNumber,roundNumber).div(100))(p3dInviterAddress);
            }
            //continue
            dayNumber++;
            rInfoXrID[roundNumber].totalDay = dayNumber;
            if(rInfoXrID[roundNumber].startTime == 0) {
                rInfoXrID[roundNumber].startTime = _timestamp;
                rInfoXrID[roundNumber].lastCalculateTime = _timestamp;
            } else {
                rInfoXrID[roundNumber].lastCalculateTime = _timestamp;   
            }
             //dividends for mine holder
            rInfoXrID[roundNumber].increaseETH = rInfoXrID[roundNumber].increaseETH.sub(getETHNeedPay(roundNumber,dayNumber.sub(1))).sub(ethForP3D);
            emit calculateTargetEvent(0);
        } else {
            //Game over, start new round
            bool haveWinner = false;
            if(dayNumber > 1) {
                sendBalanceForDevelop(roundNumber);
                if(platformBalance > 0) {
                    uint256 platformBalanceAmount = platformBalance;
                    platformBalance = 0;
                    sysAdminAddress.transfer(platformBalanceAmount);
                } 
                haveWinner = true;
            }
            rInfoXrID[roundNumber].winnerDay = dayNumber.sub(1);
            roundNumber++;
            dayNumber = 1;
            if(haveWinner) {
                rInfoXrID[roundNumber].bounsInitNumber = getBounsWithRoundID(roundNumber.sub(1)).div(10);
            } else {
                rInfoXrID[roundNumber].bounsInitNumber = getBounsWithRoundID(roundNumber.sub(1));
            }
            rInfoXrID[roundNumber].totalDay = 1;
            rInfoXrID[roundNumber].startTime = _timestamp;
            rInfoXrID[roundNumber].lastCalculateTime = _timestamp;
            emit calculateTargetEvent(roundNumber);
        }
        calculating_target = false;
    }

    function registerWithInviterID(uint256 _inviterID) private {
        address _senderAddress = msg.sender;
        totalPlayerNumber++;
        pIDXpAdd[_senderAddress] = totalPlayerNumber;
        pAddXpID[totalPlayerNumber] = _senderAddress;
        pInfoXpAdd[_senderAddress].inviterAddress = pAddXpID[_inviterID];
    }
    
    function buyCore(address _playerAddress,address _inviterAddress,uint256 _amount) private {
        require(_amount >= 0.01 ether,"You need to pay 0.01 ether at lesat");
        //10 percent of the investment amount belongs to the inviter
        address _senderAddress = _playerAddress;
        if(_inviterAddress == address(0) || _inviterAddress == _senderAddress) {
            platformBalance = platformBalance.add(_amount/10);
        } else {
            pInfoXpAdd[_inviterAddress].inviteEarnings = pInfoXpAdd[_inviterAddress].inviteEarnings.add(_amount/10);
        }
        //Record the order of purchase for each user
        uint256 playerIndex = rInfoXrID[roundNumber].dayInfoXDay[dayNumber].playerNumber.add(1);
        rInfoXrID[roundNumber].dayInfoXDay[dayNumber].playerNumber = playerIndex;
        rInfoXrID[roundNumber].dayInfoXDay[dayNumber].addXIndex[playerIndex] = _senderAddress;
        //After the user purchases, they can add 50% more, except for the first user
        if(rInfoXrID[roundNumber].increaseETH > 0) {
            rInfoXrID[roundNumber].dayInfoXDay[dayNumber].increaseMine = rInfoXrID[roundNumber].dayInfoXDay[dayNumber].increaseMine.add(_amount*5/2);
            rInfoXrID[roundNumber].totalMine = rInfoXrID[roundNumber].totalMine.add(_amount*15/2);
        } else {
            rInfoXrID[roundNumber].totalMine = rInfoXrID[roundNumber].totalMine.add(_amount*5);
        }
        //Record the accumulated ETH in the prize pool, the newly added ETH each day, the ore and the ore actually purchased by each user
        rInfoXrID[roundNumber].increaseETH = rInfoXrID[roundNumber].increaseETH.add(_amount).sub(_amount/10);
        rInfoXrID[roundNumber].dayInfoXDay[dayNumber].increaseETH = rInfoXrID[roundNumber].dayInfoXDay[dayNumber].increaseETH.add(_amount).sub(_amount/10);
        rInfoXrID[roundNumber].dayInfoXDay[dayNumber].actualMine = rInfoXrID[roundNumber].dayInfoXDay[dayNumber].actualMine.add(_amount*5);
        rInfoXrID[roundNumber].dayInfoXDay[dayNumber].mineAmountXAddress[_senderAddress] = rInfoXrID[roundNumber].dayInfoXDay[dayNumber].mineAmountXAddress[_senderAddress].add(_amount*5);
        rInfoXrID[roundNumber].dayInfoXDay[dayNumber].ethPayAmountXAddress[_senderAddress] = rInfoXrID[roundNumber].dayInfoXDay[dayNumber].ethPayAmountXAddress[_senderAddress].add(_amount);
    }
    
    function playerWithdraw(uint256 _amount) public {
        address _senderAddress = msg.sender;
        uint256 balance = getUserBalance(_senderAddress);
        require(balance>=_amount,"Lack of balance");
        //The platform charges users 1% of the commission fee, and the rest is withdrawn to the user account
        platformBalance = platformBalance.add(_amount.div(100));
        pInfoXpAdd[_senderAddress].withDrawNumber = pInfoXpAdd[_senderAddress].withDrawNumber.add(_amount);
        _senderAddress.transfer(_amount.sub(_amount.div(100)));
    }
    
    function sendBalanceForDevelop(uint256 _roundID) private {
        uint256 bouns = getBounsWithRoundID(_roundID).div(5);
        sysDevelopAddress.transfer(bouns.div(2));
        sysInviterAddress.transfer(bouns.sub(bouns.div(2)));
    }

    //********************
    // Calculate Data
    //********************
    function getBounsWithRoundID(uint256 _roundID) private view returns(uint256 _bouns) {
        _bouns = _bouns.add(rInfoXrID[_roundID].bounsInitNumber).add(rInfoXrID[_roundID].increaseETH);
        return(_bouns);
    }
    
    function getETHNeedPay(uint256 _roundID,uint256 _dayID) private view returns(uint256 _amount) {
        if(_dayID >=2) {
            uint256 mineTotal = rInfoXrID[_roundID].totalMine.sub(rInfoXrID[_roundID].dayInfoXDay[_dayID].actualMine).sub(rInfoXrID[_roundID].dayInfoXDay[_dayID].increaseMine);
            _amount = mineTotal.mul(getTransformRate()).div(10000);
        } else {
            _amount = 0;
        }
        return(_amount);
    }
    
    function getIncreaseBalance(uint256 _dayID,uint256 _roundID) private view returns(uint256 _balance) {
        _balance = rInfoXrID[_roundID].dayInfoXDay[_dayID].increaseETH;
        return(_balance);
    }
    
    function getMineInfoInDay(address _userAddress,uint256 _roundID, uint256 _dayID) private view returns(uint256 _totalMine,uint256 _myMine,uint256 _additional) {
        //Through traversal, the total amount of ore by the end of the day, the amount of ore held by users, and the amount of additional additional secondary ore
        for(uint256 i=1;i<=_dayID;i++) {
            if(rInfoXrID[_roundID].increaseETH == 0) return(0,0,0);
            uint256 userActualMine = rInfoXrID[_roundID].dayInfoXDay[i].mineAmountXAddress[_userAddress];
            uint256 increaseMineInDay = rInfoXrID[_roundID].dayInfoXDay[i].increaseMine;
            _myMine = _myMine.add(userActualMine);
            _totalMine = _totalMine.add(rInfoXrID[_roundID].dayInfoXDay[i].increaseETH*50/9);
            uint256 dividendsMine = _myMine.mul(increaseMineInDay).div(_totalMine);
            _totalMine = _totalMine.add(increaseMineInDay);
            _myMine = _myMine.add(dividendsMine);
            _additional = dividendsMine;
        }
        return(_totalMine,_myMine,_additional);
    }
    
    //Ore ->eth conversion rate
    function getTransformRate() private pure returns(uint256 _rate) {
        return(60);
    }
    
    //Calculate the amount of eth to be paid in x day for user
    function getTransformMineInDay(address _userAddress,uint256 _roundID,uint256 _dayID) private view returns(uint256 _transformedMine) {
        (,uint256 userMine,) = getMineInfoInDay(_userAddress,_roundID,_dayID.sub(1));
        uint256 rate = getTransformRate();
        _transformedMine = userMine.mul(rate).div(10000);
        return(_transformedMine);
    }
    
    //Calculate the amount of eth to be paid in x day for all people
    function calculateTotalMinePay(uint256 _roundID,uint256 _dayID) private view returns(uint256 _needToPay) {
        uint256 mine = rInfoXrID[_roundID].totalMine.sub(rInfoXrID[_roundID].dayInfoXDay[_dayID].actualMine).sub(rInfoXrID[_roundID].dayInfoXDay[_dayID].increaseMine);
        _needToPay = mine.mul(getTransformRate()).div(10000);
        return(_needToPay);
    }

    //Calculate daily target values
    function getDailyTarget(uint256 _roundID,uint256 _dayID) private view returns(uint256) {
        uint256 needToPay = calculateTotalMinePay(_roundID,_dayID);
        uint256 target = 0;
        if (_dayID > 33) {
            target = (SafeMath.pwr(((3).mul(_dayID).sub(100)),3).mul(50).add(1000000)).mul(needToPay).div(1000000);
            return(target);
        } else {
            target = ((1000000).sub(SafeMath.pwr((100).sub((3).mul(_dayID)),3))).mul(needToPay).div(1000000);
            if(target == 0) target = 0.0063 ether;
            return(target);            
        }
    }
    
    //Query user income balance
    function getUserBalance(address _userAddress) private view returns(uint256 _balance) {
        if(pIDXpAdd[_userAddress] == 0) {
            return(0);
        }
        //Amount of user withdrawal
        uint256 withDrawNumber = pInfoXpAdd[_userAddress].withDrawNumber;
        uint256 totalTransformed = 0;
        //Calculate the number of ETH users get through the daily conversion
        for(uint256 i=1;i<=roundNumber;i++) {
            for(uint256 j=1;j 100) {
            number == 100;
        }
        address[] memory playerList = new address[](number);
        for(uint256 i=0;i 100) {
            number == 100;
        }
        address[] memory playerList = new address[](number);
        for(uint256 i=0;iaddress) addXIndex;
        mapping(address=>uint256) ethPayAmountXAddress;
        mapping(address=>uint256) mineAmountXAddress;
    }
    
    struct RoundInfo {
        uint256 startTime;
        uint256 lastCalculateTime;
        uint256 bounsInitNumber;
        uint256 increaseETH;
        uint256 totalDay;
        uint256 winnerDay;
        uint256 totalMine;
        mapping(uint256=>DayInfo) dayInfoXDay;
    }
}

library SafeMath {
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath div failed");
        uint256 c = a / b;
        return c;
    } 

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
    
    /**
     * @dev gives square root of given x.
     */
    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y) 
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y) 
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }
    
    /**
     * @dev gives square. multiplies x by x
     */
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }
    
    /**
     * @dev x to the power of y 
     */
    function pwr(uint256 x, uint256 y)
        internal 
        pure 
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else 
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }
}
