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
    
    function() external payable {}
    
    //************
    //Game payable
    //************
    function joinGameWithInviterID(uint256 _inviterID) public payable {
        require(msg.value >= 0.01 ether,"You need to pay 0.01 eth at least");
        require(now.sub(rInfoXrID[roundNumber].lastCalculateTime) < cycleTime,"Waiting for settlement");
        if(pIDXpAdd[msg.sender] < 1) {
            registerWithInviterID(_inviterID);
        }
        buyCore(pInfoXpAdd[msg.sender].inviterAddress,msg.value);
        emit newPlayerJoinGameEvent(msg.sender,msg.value,true,now);
    }
    
    //********************
    // Method need Gas
    //********************
    function joinGameWithBalance(uint256 _amount) public payable {
        require(_amount >= 0.01 ether,"You need to pay 0.01 eth at least");
        require(now.sub(rInfoXrID[roundNumber].lastCalculateTime) < cycleTime,"Waiting for settlement");
        uint256 balance = getUserBalance(msg.sender);
        require(balance >= _amount.mul(11).div(10),"balance is not enough");
        platformBalance = platformBalance.add(_amount.div(10));
        buyCore(pInfoXpAdd[msg.sender].inviterAddress,_amount);
        pInfoXpAdd[msg.sender].withDrawNumber = pInfoXpAdd[msg.sender].withDrawNumber.sub(_amount.mul(11).div(10));
        emit newPlayerJoinGameEvent(msg.sender,_amount,false,now);
    }
    
    function calculateTarget() public {
        require(now.sub(rInfoXrID[roundNumber].lastCalculateTime) >= cycleTime,"Less than cycle Time from last operation");
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
        if(increaseBalance >= targetBalance) {
            //buy p3d
            if(getIncreaseBalance(dayNumber,roundNumber) > 0) {
                p3dContract.buy.value(getIncreaseBalance(dayNumber,roundNumber).div(100))(p3dInviterAddress);
            }
            //continue
            dayNumber = dayNumber.add(1);
            rInfoXrID[roundNumber].totalDay = dayNumber;
            if(rInfoXrID[roundNumber].startTime == 0) {
                rInfoXrID[roundNumber].startTime = now;
                rInfoXrID[roundNumber].lastCalculateTime = now;
            } else {
                rInfoXrID[roundNumber].lastCalculateTime = rInfoXrID[roundNumber].startTime.add((cycleTime).mul(dayNumber.sub(1)));   
            }
            emit calculateTargetEvent(0);
        } else {
            //Game over, start new round
            bool haveWinner = false;
            if(dayNumber > 1) {
                sendBalanceForDevelop(roundNumber);
                haveWinner = true;
            }
            rInfoXrID[roundNumber].winnerDay = dayNumber.sub(1);
            roundNumber = roundNumber.add(1);
            dayNumber = 1;
            if(haveWinner) {
                rInfoXrID[roundNumber].bounsInitNumber = getBounsWithRoundID(roundNumber.sub(1)).div(10);
            } else {
                rInfoXrID[roundNumber].bounsInitNumber = getBounsWithRoundID(roundNumber.sub(1));
            }
            rInfoXrID[roundNumber].totalDay = 1;
            rInfoXrID[roundNumber].startTime = now;
            rInfoXrID[roundNumber].lastCalculateTime = now;
            emit calculateTargetEvent(roundNumber);
        }
    }

    function registerWithInviterID(uint256 _inviterID) private {
        totalPlayerNumber = totalPlayerNumber.add(1);
        pIDXpAdd[msg.sender] = totalPlayerNumber;
        pAddXpID[totalPlayerNumber] = msg.sender;
        pInfoXpAdd[msg.sender].inviterAddress = pAddXpID[_inviterID];
    }
    
    function buyCore(address _inviterAddress,uint256 _amount) private {
        //for inviter
        if(_inviterAddress == 0x0 || _inviterAddress == msg.sender) {
            platformBalance = platformBalance.add(_amount/10);
        } else {
            pInfoXpAdd[_inviterAddress].inviteEarnings = pInfoXpAdd[_inviterAddress].inviteEarnings.add(_amount/10);
        }
        uint256 playerIndex = rInfoXrID[roundNumber].dayInfoXDay[dayNumber].playerNumber.add(1);
        if(rInfoXrID[roundNumber].numberXaddress[msg.sender] == 0) {
            rInfoXrID[roundNumber].number = rInfoXrID[roundNumber].number.add(1);
            rInfoXrID[roundNumber].numberXaddress[msg.sender] = rInfoXrID[roundNumber].number;
            rInfoXrID[roundNumber].addressXnumber[rInfoXrID[roundNumber].number] = msg.sender;
        }
        rInfoXrID[roundNumber].dayInfoXDay[dayNumber].playerNumber = playerIndex;
        rInfoXrID[roundNumber].dayInfoXDay[dayNumber].addXIndex[playerIndex] = msg.sender;
        rInfoXrID[roundNumber].dayInfoXDay[dayNumber].indexXAddress[msg.sender] = playerIndex;
        rInfoXrID[roundNumber].dayInfoXDay[dayNumber].amountXIndex[playerIndex] = _amount;
    }
    
    function playerWithdraw(uint256 _amount) public {
        uint256 balance = getUserBalance(msg.sender);
        require(balance>=_amount,"amount out of limit");
        msg.sender.transfer(_amount);
        pInfoXpAdd[msg.sender].withDrawNumber = pInfoXpAdd[msg.sender].withDrawNumber.add(_amount);
    }
    
    function sendBalanceForDevelop(uint256 _roundID) private {
        uint256 bouns = getBounsWithRoundID(_roundID).div(5);
        sysDevelopAddress.transfer(bouns.div(2));
        sysInviterAddress.transfer(bouns.div(2));
    }
    
    //********************
    // Calculate Data
    //********************
    function getBounsWithRoundID(uint256 _roundID) private view returns(uint256 _bouns) {
        _bouns = _bouns.add(rInfoXrID[_roundID].bounsInitNumber);
        for(uint256 d=1;d<=rInfoXrID[_roundID].totalDay;d++){
            for(uint256 i=1;i<=rInfoXrID[_roundID].dayInfoXDay[d].playerNumber;i++) {
                uint256 amount = rInfoXrID[_roundID].dayInfoXDay[d].amountXIndex[i];
                _bouns = _bouns.add(amount.mul(891).div(1000));  
            }
            for(uint256 j=1;j<=rInfoXrID[_roundID].number;j++) {
                address address2 = rInfoXrID[_roundID].addressXnumber[j];
                if(d>=2) {
                    _bouns = _bouns.sub(getTransformMineInDay(address2,_roundID,d.sub(1)));
                } else {
                    _bouns = _bouns.sub(getTransformMineInDay(address2,_roundID,d));
                }
            }
        }
        return(_bouns);
    }
    
    function getIncreaseBalance(uint256 _dayID,uint256 _roundID) private view returns(uint256 _balance) {
        for(uint256 i=1;i<=rInfoXrID[_roundID].dayInfoXDay[_dayID].playerNumber;i++) {
            uint256 amount = rInfoXrID[_roundID].dayInfoXDay[_dayID].amountXIndex[i];
            _balance = _balance.add(amount);   
        }
        _balance = _balance.mul(9).div(10);
        return(_balance);
    }
    
    function getMineInfoInDay(address _userAddress,uint256 _roundID, uint256 _dayID) private view returns(uint256 _totalMine,uint256 _myMine,uint256 _additional) {
        for(uint256 i=1;i<=_dayID;i++) {
            for(uint256 j=1;j<=rInfoXrID[_roundID].dayInfoXDay[i].playerNumber;j++) {
                address userAddress = rInfoXrID[_roundID].dayInfoXDay[i].addXIndex[j];
                uint256 amount = rInfoXrID[_roundID].dayInfoXDay[i].amountXIndex[j];
                if(_totalMine == 0) {
                    _totalMine = _totalMine.add(amount.mul(5));
                    if(userAddress == _userAddress){
                        _myMine = _myMine.add(amount.mul(5));
                    }
                } else {
                    uint256 addPart = (amount.mul(5)/2).mul(_myMine)/_totalMine;
                    _totalMine = _totalMine.add(amount.mul(15).div(2));
                    if(userAddress == _userAddress){
                        _myMine = _myMine.add(amount.mul(5)).add(addPart);    
                    }else {
                        _myMine = _myMine.add(addPart);
                    }
                    _additional = _additional.add(addPart);
                }
            }
        }
        return(_totalMine,_myMine,_additional);
    }
    
    function getTransformRate(address _userAddress,uint256 _roundID,uint256 _dayID) private view returns(uint256 _rate) {
        (,uint256 userMine,) = getMineInfoInDay(_userAddress,_roundID,_dayID);
        if(userMine > 0) {
            uint256 rate = userMine.mul(4).div(1000000000000000000).add(40);
            if(rate >80)                              
                return(80);
            else
                return(rate);        
        } else {
            return(40);
        }
    }
    
    function getTransformMineInDay(address _userAddress,uint256 _roundID,uint256 _dayID) private view returns(uint256 _transformedMine) {
        (,uint256 userMine,) = getMineInfoInDay(_userAddress,_roundID,_dayID.sub(1));
        uint256 rate = getTransformRate(_userAddress,_roundID,_dayID.sub(1));
        _transformedMine = userMine.mul(rate).div(10000);
        return(_transformedMine);
    }
    
    function calculateTotalMinePay(uint256 _roundID,uint256 _dayID) private view returns(uint256 _needToPay) {
        (uint256 mine,,) = getMineInfoInDay(msg.sender,_roundID,_dayID.sub(1));
        _needToPay = mine.mul(8).div(1000);
        return(_needToPay);
    }
    
    function getDailyTarget(uint256 _roundID,uint256 _dayID) private view returns(uint256) {
        uint256 needToPay = calculateTotalMinePay(_roundID,_dayID);
        uint256 target = 0;
        if (_dayID > 20) {
            target = (SafeMath.pwr(((5).mul(_dayID).sub(100)),3).add(1000000)).mul(needToPay).div(1000000);
            return(target);
        } else {
            target = ((1000000).sub(SafeMath.pwr((100).sub((5).mul(_dayID)),3))).mul(needToPay).div(1000000);
            if(target == 0) target = 0.0063 ether;
            return(target);            
        }
    }
    
    function getUserBalance(address _userAddress) private view returns(uint256 _balance) {
        if(pIDXpAdd[_userAddress] == 0) {
            return(0);
        }
        uint256 withDrawNumber = pInfoXpAdd[_userAddress].withDrawNumber;
        uint256 totalTransformed = 0;
        for(uint256 i=1;i<=roundNumber;i++) {
            for(uint256 j=1;j=_amount,"Lack of balance");
        _toAddress.transfer(_amount);
        platformBalance = platformBalance.sub(_amount);
    }
    
    function p3dWithdrawForAdmin(address _toAddress,uint256 _amount) public {
        require(msg.sender==sysAdminAddress,"You are not the admin");
        uint256 p3dToken = p3dContract.balanceOf(address(this));
        require(_amount<=p3dToken,"You don't have so much P3DToken");
        p3dContract.transfer(_toAddress,_amount);
    }
    
    //************
    //
    //************
    function getDataOfGame() public view returns(uint256 _playerNumber,uint256 _dailyIncreased,uint256 _dailyTransform,uint256 _contractBalance,uint256 _userBalanceLeft,uint256 _platformBalance,uint256 _mineBalance,uint256 _balanceOfMine) {
        for(uint256 i=1;i<=totalPlayerNumber;i++) {
            address userAddress = pAddXpID[i];
            _userBalanceLeft = _userBalanceLeft.add(getUserBalance(userAddress));
        }
        return(
            totalPlayerNumber,
            getIncreaseBalance(dayNumber,roundNumber),
            calculateTotalMinePay(roundNumber,dayNumber),
            address(this).balance,
            _userBalanceLeft,
            platformBalance,
            getBounsWithRoundID(roundNumber),
            getBounsWithRoundID(roundNumber).mul(7).div(10)
            );
    }
    
    function getUserAddressList() public view returns(address[]) {
        address[] memory addressList = new address[](totalPlayerNumber);
        for(uint256 i=0;iaddress) addXIndex;
        mapping(uint256=>uint256) amountXIndex;
        mapping(address=>uint256) indexXAddress;
    }
    
    struct RoundInfo {
        uint256 startTime;
        uint256 lastCalculateTime;
        uint256 bounsInitNumber;
        uint256 totalDay;
        uint256 winnerDay;
        mapping(uint256=>DayInfo) dayInfoXDay;
        mapping(uint256=>address) addressXnumber;
        mapping(address=>uint256) numberXaddress;
        uint256 number;
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
