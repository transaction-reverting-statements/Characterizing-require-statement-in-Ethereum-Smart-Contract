pragma solidity ^0.4.24;


library Player{

    using CommUtils for string;

    address public constant AUTHOR =  0x001C9b3392f473f8f13e9Eaf0619c405AF22FC26a7;
    
    struct Map{
        mapping(address=>uint256) map;
        mapping(address=>address) referrerMap;
        mapping(address=>bytes32) addrNameMap;
        mapping(bytes32=>address) nameAddrMap;
    }
    
    function deposit(Map storage  ps,address adr,uint256 v) internal returns(uint256) {
       ps.map[adr]+=v;
        return v;
    }
    
    function depositAuthor(Map storage  ps,uint256 v) public returns(uint256) {
        return deposit(ps,AUTHOR,v);
    }

    function withdrawal(Map storage  ps,address adr,uint256 num) public returns(uint256) {
        uint256 sum = ps.map[adr];
        if(sum==num){
            withdrawalAll(ps,adr);
        }
        require(sum > num);
        ps.map[adr] = (sum-num);
        return sum;
    }
    
    function withdrawalAll(Map storage  ps,address adr) public returns(uint256) {
        uint256 sum = ps.map[adr];
        require(sum >= 0);
        delete ps.map[adr];
        return sum;
    }
    
    function getAmmount(Map storage ps,address adr) public view returns(uint256) {
        return ps.map[adr];
    }
    
    function registerName(Map storage ps,bytes32 _name)internal  {
        require(ps.nameAddrMap[_name] == address(0) );
        ps.nameAddrMap[_name] = msg.sender;
        ps.addrNameMap[msg.sender] = _name;
        depositAuthor(ps,msg.value);
    }
    
    function isEmptyName(Map storage ps,bytes32 _name) public view returns(bool) {
        return ps.nameAddrMap[_name] == address(0);
    }
    
    function getByName(Map storage ps,bytes32 _name)public view returns(address) {
        return ps.nameAddrMap[_name] ;
    }
    
    function getName(Map storage ps) public view returns(bytes32){
        return ps.addrNameMap[msg.sender];
    }
    
    function getNameByAddr(Map storage ps,address adr) public view returns(bytes32){
        return ps.addrNameMap[adr];
    }    
    
    function getReferrer(Map storage ps,address adr)public view returns(address){
        return ps.referrerMap[adr];
    }
    
    function getReferrerName(Map storage ps,address adr)public view returns(bytes32){
        return getNameByAddr(ps,getReferrer(ps,adr));
    }
    
    function setReferrer(Map storage ps,address self,address referrer)internal {
         ps.referrerMap[self] = referrer;
    }
    
    function applyReferrer(Map storage ps,string referrer)internal {
        require(getReferrer(ps,msg.sender) == address(0));
        bytes32 rbs = referrer.nameFilter();
        address referrerAdr = getByName(ps,rbs);
        if(referrerAdr != msg.sender){
            setReferrer(ps,msg.sender,referrerAdr);
        }
    }    
    
    function withdrawalFee(Map storage ps,uint256 fee) public returns (uint256){
        if(msg.value > 0){
            require(msg.value >= fee,"msg.value < fee");
            return fee;
        }
        require(getAmmount(ps,msg.sender)>=fee ,"players.getAmmount(msg.sender) array.length? array.length : len;
        for(uint256 i =0;i 0, "string must be between 1 and 32 characters");
        // make sure it doesnt start with or end with space
        require(_temp[0] != 0x20 && _temp[_length-1] != 0x20, "string cannot start or end with space");
        // make sure first two characters are not 0x
        if (_temp[0] == 0x30)
        {
            require(_temp[1] != 0x78, "string cannot start with 0x");
            require(_temp[1] != 0x58, "string cannot start with 0X");
        }
        
        // create a bool to track if we have a non number character
        bool _hasNonNumber;
        
        // convert & check
        for (uint256 i = 0; i < _length; i++)
        {
            // if its uppercase A-Z
            if (_temp[i] > 0x40 && _temp[i] < 0x5b)
            {
                // convert to lower case a-z
                _temp[i] = byte(uint(_temp[i]) + 32);
                
                // we have a non number
                if (_hasNonNumber == false)
                    _hasNonNumber = true;
            } else {
                require
                (
                    // require character is a space
                    _temp[i] == 0x20 || 
                    // OR lowercase a-z
                    (_temp[i] > 0x60 && _temp[i] < 0x7b) ||
                    // or 0-9
                    (_temp[i] > 0x2f && _temp[i] < 0x3a),
                    "string contains invalid characters"
                );
                // make sure theres not 2x spaces in a row
                if (_temp[i] == 0x20)
                    require( _temp[i+1] != 0x20, "string cannot contain consecutive spaces");
                
                // see if we have a character other than a number
                if (_hasNonNumber == false && (_temp[i] < 0x30 || _temp[i] > 0x39))
                    _hasNonNumber = true;    
            }
        }
        
        require(_hasNonNumber == true, "string cannot be only numbers");
        
        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
    }    
    
    
}



library PlayerReply{
    
    using CommUtils for address[];
    using CommUtils for uint256[];
    
    uint256 constant VISABLE_NONE = 0;
    uint256 constant VISABLE_FINAL = 1;
    uint256 constant VISABLE_ALL = 2;
    uint256 constant VISABLE_OWNER = 3;
    uint256 constant VISABLE_BUYED = 4;
    
    uint256 constant HIDE_TIME = 5*60;
    
    uint256 constant GRAND_TOTAL_TIME = 10*60;
    
    
    struct Data{
        address[] ownerIds;
        uint256 aCount;
        uint256 bCount;
        uint256[] answer;
        uint replyAt;
    }
    
    struct List{
        uint256 size;
        mapping (uint256 => uint256) hashIds;
        mapping (uint256 => Data) map;
        mapping (uint256=>uint256) sellPriceMap;
        mapping (uint256=>address) seller;
        mapping (uint256=>address[]) buyer;
    }
    
    
    function init(Data storage d,uint256 ac,uint256 bc,address own) internal{
          d.ownerIds.push(own)  ;
          d.aCount = ac;
          d.bCount = bc;
          d.replyAt = now;
    }
    
    function clear(List storage ds) internal{
        for(uint256 i =0;i0 && d.answer.length>0 && d.ownerIds.contains(msg.sender);
    }
    
    function isWined(Data storage d) internal view returns(bool){
        return d.replyAt>0 && d.answer.length>0 && d.aCount == d.answer.length ;
    }
    
    function getWin(List storage ds) internal view returns(Data storage lastAns){
        for(uint256 i=0;i HIDE_TIME && ds.sellPriceMap[ansHash] == 0){
            return VISABLE_ALL;
        }
        return VISABLE_NONE;
    }
    
    function getReplay(List storage ds,uint256 idx) internal view returns(
        uint256 ,//aCount;
        uint256,// bCount;
        uint256[],// answer;
        uint,// Timeline;
        uint256, // VisibleType
        uint256, //sellPrice
        uint256 //ansHash
        ) {
            uint256 ansHash = ds.hashIds[idx];
            uint256 sellPrice = ds.sellPriceMap[ansHash];
            Data storage d= ds.map[ansHash];
            uint256 vt = getVisibleType(ds,ansHash);
        return (
            d.aCount,
            d.bCount,
            vt!=VISABLE_NONE ?  d.answer : new uint256[](0),
            now-d.replyAt,
            vt,
            sellPrice,
            vt!=VISABLE_NONE ? ansHash : 0
        );
    } 
    
    function listBestScore(List storage ds) internal view returns(
        uint256 aCount , //aCount    
        uint256 bCount , //bCount
        uint256 bestCount // Count
        ){
        uint256 sorce = 0;
        for(uint256 i=0;i sorce){
                aCount = d.aCount;
                bCount = d.bCount;
                sorce = curSore;
                bestCount = 1;
            }else if(curSore == sorce){
                bestCount++;
            }
        }
    }
    
    
    function getOrGenByAnwser(List storage ds,uint256[] ans) internal  returns(Data storage ){
        uint256 ansHash = ans.getHash();
        Data storage d = ds.map[ansHash];
        if(d.answer.length>0) return d;
        d.answer = ans;
        ds.hashIds[ds.size] = ansHash;
        ds.size ++;
        return d;
    }
    
    
    function get(List storage ds,uint256 idx) public view returns(Data storage){
        return ds.map[ ds.hashIds[idx]];
    }
    
    function getByHash(List storage ds ,uint256 ansHash)public view returns(Data storage){
        return ds.map[ansHash];
    }
    
    
    function getLastReplyAt(List storage list) internal view returns(uint256){
        return list.size>0 ? (now- get(list,list.size-1).replyAt) : 0;
    }
    
    function getLastReply(List storage ds) internal view returns(Data storage d){
        if( ds.size>0){
            return get(ds,ds.size-1);
        }
        return d;
    }    
    
    function countByGrand(List storage ds) internal view returns(uint256) {
        if(ds.size == 0 ) return 0;
        uint256 count = 0;
        uint256 _lastAt = now;
        uint256 lastIdx = ds.size-1;
        Data memory d = get(ds,lastIdx-count);
        while((_lastAt - d.replyAt)<= GRAND_TOTAL_TIME ){
            count++;
            _lastAt = d.replyAt;
            if(count>lastIdx) return count;
            d = get(ds,lastIdx-count);
        }
        return count;       
    }
    
}


library RoomInfo{
    
    using PlayerReply for PlayerReply.Data;
    using PlayerReply for PlayerReply.List;
    using Player for Player.Map;
    using CommUtils for uint256[];
    uint256 constant DIVIDEND_AUTH = 5;
    uint256 constant DIVIDEND_INVITE = 2;
    uint256 constant DIVIDEND_INVITE_REFOUND = 3;
    uint256 constant DECIMAL_PLACE = 100;

    uint256 constant GRAND_RATE = 110;
    
    
    
    struct Data{
        address ownerId;
        uint256 charsLength;
        uint256[] answer;
        PlayerReply.List replys;
        bytes32 name;
        uint256 prize;
        uint256 minReplyFee;
        uint256 replayCount;
        uint256 firstReplayAt;
        uint256 rateCode;
        uint256 round;
        uint256 maxReplyFeeRate;
        uint256 toAnswerRate;
        uint256 toOwner;
        uint256 nextRoundRate;
        uint256 increaseRate_1000;
        uint256 initAwardTime ;
        uint256 plusAwardTime ;
    }
    
    struct List{
        mapping(uint256 => Data)  map;
        uint256  size ;
    }
    
    
    
    function genOrGetReplay(Data storage d,uint256[] ans) internal returns(PlayerReply.Data storage ) {
        (PlayerReply.Data storage replayData)  = d.replys.getOrGenByAnwser(ans);
        d.replayCount++;
        if(d.firstReplayAt == 0) d.firstReplayAt = now;
        return (replayData);
    }
    
    function tryAnswer(Data storage d ,uint256[] _t ) internal view returns(uint256,uint256){
        require(d.answer.length == _t.length);
        uint256 aCount;
        uint256 bCount;
        for(uint256 i=0;i 5 );
        require(minReplyFee<= msg.value *maxReplyFeeRate /DECIMAL_PLACE && minReplyFee>= 0.000005 ether);
        require(digits>=2 && digits <= 9 );
        require((toAnswerRate+toOwner)<=90);
        require(msg.value >= 0.001 ether);
        require(nextRoundRate <= 70);
        require(templateLen >= 10);
        require(initAwardTime < 60*60*24*90);
        require(plusAwardTime < 60*60*24*20);
        require(CommUtils.mulRate(msg.value,100-nextRoundRate) >= minReplyFee);
        
        d.charsLength = templateLen;
        d.answer = CommUtils.genRandomArray(digits,templateLen,0);       
        d.ownerId = msg.sender;
        d.name = n;
        d.prize = msg.value;
        d.minReplyFee = minReplyFee;
        d.round = 1;
        d.maxReplyFeeRate = maxReplyFeeRate;
        d.toAnswerRate = toAnswerRate;
        d.toOwner = toOwner;
        d.nextRoundRate = nextRoundRate;
        d.increaseRate_1000 = increaseRate_1000;
        d.initAwardTime = initAwardTime;
        d.plusAwardTime = plusAwardTime;
        
    }
    
    function replayAnser(Data storage r,Player.Map storage ps,uint256 fee,uint256[] tryA) internal returns(
            uint256, // aCount
            uint256 // bCount
        )  {
        (uint256 a, uint256 b) = tryAnswer(r,tryA);
        saveReplyFee(r,ps,fee);
        (PlayerReply.Data storage pr) = genOrGetReplay(r,tryA);
        pr.init(a,b,msg.sender); 
        return (a,b);
    }
    
    function saveReplyFee(Data storage d,Player.Map storage ps,uint256 replayFee) internal  {
        uint256 lessFee = replayFee;
        //uint256 toAnswerRate= rates[IdxToAnswerRate];
        //uint256 toOwner = rates[IdxToOwnerRate];
        
        lessFee -=sendReplayDividend(d,ps,replayFee*d.toAnswerRate/DECIMAL_PLACE);
        address refer = ps.getReferrer(msg.sender);
        if(refer == address(0)){
            lessFee -=ps.depositAuthor(replayFee*(DIVIDEND_AUTH+DIVIDEND_INVITE+DIVIDEND_INVITE_REFOUND)/DECIMAL_PLACE);            
        }else{
            lessFee -=ps.deposit(msg.sender,replayFee*DIVIDEND_INVITE_REFOUND/DECIMAL_PLACE);
            lessFee -=ps.deposit(refer,replayFee*DIVIDEND_INVITE/DECIMAL_PLACE);
            lessFee -=ps.depositAuthor(replayFee*DIVIDEND_AUTH/DECIMAL_PLACE);
        }
        lessFee -=ps.deposit(d.ownerId,replayFee*d.toOwner/DECIMAL_PLACE);
        
        d.prize += lessFee;
    }
    
    function sendReplayDividend(Data storage d,Player.Map storage ps,uint256 ammount) private returns(uint256) {
        if(d.replayCount <=0) return 0;
        uint256 oneD = ammount /  d.replayCount;
        for(uint256 i=0;i d.minReplyFee  );
    }    
    
    function clearAndNextRound(Data storage d,uint256 prize) internal {
        d.prize = prize;
        d.replys.clear();
        d.replayCount  = 0;
        d.firstReplayAt = 0;
        d.round++;
        d.answer = CommUtils.genRandomArray(d.answer.length,d.charsLength,0); 
    }
    
    function getReplyFee(Data storage d) internal view returns(uint256){
        uint256 prizeMax = (d.prize *  d.maxReplyFeeRate ) /DECIMAL_PLACE;
        uint256 ans = CommUtils.pwrFloat(d.minReplyFee, d.increaseRate_1000 +1000,1000,d.replys.size);
        ans = ans > prizeMax ? prizeMax : ans;
        uint256 count = d.replys.countByGrand();
        if(count>0){
            ans = CommUtils.pwrFloat(ans,GRAND_RATE,DECIMAL_PLACE,count);       
        }
        ans = ans < d.minReplyFee ? d.minReplyFee : ans;
        return ans;
    }
    
    function sellReply(Data storage d,Player.Map storage ps,uint256 ansHash,uint256 price,uint256 fee) internal{
        d.replys.setSellPrice(ansHash,price);
        saveReplyFee(d,ps,fee);
    }
    
    function buyReply(Data storage d,Player.Map storage ps,uint256 replyIdx,uint256 buyFee) internal{
        uint256 ansHash = d.replys.hashIds[replyIdx];
        require(buyFee >= d.replys.getSellPrice(replyIdx) ,"buyFee to less");
        require(d.replys.seller[ansHash]!=address(0),"d.replys.seller[ansHash]!=address(0)");
        d.replys.buyer[ansHash].push(msg.sender);
        uint256 lessFee = buyFee;
        address refer = ps.referrerMap[msg.sender];
        if(refer == address(0)){
            lessFee -=ps.depositAuthor(buyFee*(DIVIDEND_AUTH+DIVIDEND_INVITE+DIVIDEND_INVITE_REFOUND)/100);            
        }else{
            lessFee -=ps.deposit(msg.sender,buyFee*DIVIDEND_INVITE_REFOUND/100);
            lessFee -=ps.deposit(refer,buyFee*DIVIDEND_INVITE/100);
            lessFee -=ps.depositAuthor(buyFee*DIVIDEND_AUTH/100);
        }        
        lessFee -=ps.deposit(d.ownerId,buyFee*    d.toOwner  /100);
        ps.deposit(d.replys.seller[ansHash],lessFee);
    }
    
    
    function getGameItem(Data storage d) public view returns(
        bytes32, //name
        uint256, //bestACount 
        uint256, //bestBCount
        uint256, //answer count
        uint256, //totalPrize
        uint256, // reply Fee
        uint256 //OverTimeLeft
        ){
             (uint256 aCount,uint256 bCount,uint256 bestCount) = d.replys.listBestScore();
             bestCount = bestCount;
             uint256 fee = getReplyFee(d);
             uint256 overTimeLeft = getOverTimeLeft(d);
             uint256 replySize = d.replys.size;
        return(
            d.name,
            d.prize,
            aCount,
            bCount,
            replySize,
            fee,
            overTimeLeft
        );  
        
    }    
    
    function getByPrizeLeast(List storage ds) internal view returns (Data storage){
        Data storage ans = ds.map[0];
        uint256 _cp = ans.prize;
        for(uint256 i=0;i ds.map[i].prize){
                ans= ds.map[i];
                _cp = ans.prize;
            }
        }
        return ans;
    }
    
    function getByPrizeLargestIdx(List storage ds) internal view returns (uint256 ){
        uint256 ans = 0;
        uint256 _cp = 0;
        for(uint256 i=0;i(r.prize-nextRound)){
            revert("sum>(r.prize-nextRound)");
        }
    }    
    
    function getOverTimeLeft(Data storage d) internal view returns(uint256){
        if(d.replayCount == 0) return 0;
        //uint256 time = (d.replayCount * 5 * 60 )+ (3*24*60*60) ;
        uint256 time = (d.replayCount *d.plusAwardTime )+ d.initAwardTime ;
        uint256 spendT = (now-d.firstReplayAt);
        if(time 0 && getOverTimeLeft(d)==0 ) return d.replys.getLastReply();
        return pr;
    }
    
    function getRoomExReplyInfo(Data storage r) internal view returns(uint256 time,uint256 count) {
        time = r.replys.getLastReplyAt();
        count = r.replys.countByGrand();
    }
    
    function get(List storage ds,uint256 idx) internal view returns(Data storage){
        return ds.map[idx];
    }
    
    
}


contract BullsAndCows {

    using Player for Player.Map;
    //using PlayerReply for PlayerReply.Data;
    //using PlayerReply for PlayerReply.List;
    using RoomInfo for RoomInfo.Data;
    using RoomInfo for RoomInfo.List;
    using CommUtils for string;
    


    uint256 public constant DIGIT_MIN = 4;    
    uint256 public constant SELL_PRICE_RATE = 200;
    uint256 public constant SELL_MIN_RATE = 50;

   // RoomInfo.Data[] private roomInfos ;
    RoomInfo.List roomInfos;
    Player.Map private players;
    
    //constructor() public   {    }
    
    // function createRoomQuick() public payable {
    //     createRoom(4,10,"AAA",35,10,20,0.05 ether,20,20,60*60,60*60);
    // }
        
    // function getBalance() public view returns (uint){
    //     return address(this).balance;
    // }    
    
    // function testNow() public  view returns(uint256[]) {
    //     RoomInfo.Data storage r = roomInfos[0]    ; 
    //     return r.answer;
    // }
    
    // function TestreplayAnser(uint256 roomIdx) public payable   {
    //     RoomInfo.Data storage r = roomInfos.map[roomIdx];
    //     for(uint256 i=0;i<4;i++){
    //         uint256[] memory aa = CommUtils.genRandomArray(r.answer.length,r.charsLength,i);
    //         r.replayAnser(players,0.5 ether,aa);
    //     }
    // }    
    
    
    function getInitInfo() public view returns(
        uint256,//roomSize
        bytes32 //refert
        ){
        return (
            roomInfos.size,
            players.getReferrerName(msg.sender)
        );
    }
    
    function getRoomIdxByNameElseLargest(string _roomName) public view returns(uint256 ){
        return roomInfos.getIdxByNameElseLargest(_roomName.nameFilter());
    }    
    
    function getRoomInfo(uint256 roomIdx) public view returns(
        address, //ownerId
        bytes32, //roomName,
        uint256, // replay visible idx type
        uint256, // prize
        uint256, // replyFee
        uint256, // reply combo count
        uint256, // lastReplyAt
        uint256, // get over time
        uint256,  // round
        bool // winner
        ){
        RoomInfo.Data storage r = roomInfos.get(roomIdx)    ;
        (uint256 time,uint256 count) = r.getRoomExReplyInfo();
        (PlayerReply.Data storage pr) = r.getWinReply();
        return (
            r.ownerId,
            r.name,
            r.replys.size,
            r.prize,
            r.getReplyFee(),
            count,
            time,
            r.getOverTimeLeft(),
            r.round,
            PlayerReply.isOwner(pr)
        );
    }
    
    function getRoom(uint256 roomIdx) public view returns(
        uint256, //digits,
        uint256, //templateLen,
        uint256, //toAnswerRate,
        uint256, //toOwner,
        uint256, //nextRoundRate,
        uint256, //minReplyFee,
        uint256, //maxReplyFeeRate           
        uint256  //IdxIncreaseRate
        ){
        RoomInfo.Data storage r = roomInfos.map[roomIdx]    ;
        return(
        r.answer.length,
        r.charsLength,
        r.toAnswerRate ,  //r.toAnswerRate 
        r.toOwner , //r.toOwner,
        r.nextRoundRate ,  //r.nextRoundRate,
        r.minReplyFee, 
        r.maxReplyFeeRate,     //r.maxReplyFeeRate  
        r.increaseRate_1000     //IdxIncreaseRate
        );
        
    }
    
    function getGameItem(uint256 idx) public view returns(
        bytes32 ,// name
        uint256, //totalPrize
        uint256, //bestACount 
        uint256 , //bestBCount
        uint256 , //answer count
        uint256, //replyFee
        uint256 //OverTimeLeft
        ){
        return roomInfos.map[idx].getGameItem();
    }
    
    function getReplyFee(uint256 roomIdx) public view returns(uint256){
        return roomInfos.map[roomIdx].getReplyFee();
    }
    
    function getReplay(uint256 roomIdx,uint256 replayIdx) public view returns(
        uint256 ,//aCount;
        uint256,// bCount;
        uint256[],// answer;
        uint,// replyAt;
        uint256, // VisibleType
        uint256 ,//sellPrice
        uint256 //ansHash
        ) {
        RoomInfo.Data storage r = roomInfos.map[roomIdx];
        return r.getReplay(replayIdx);
    }
    
    function replayAnserWithReferrer(uint256 roomIdx,uint256[] tryA,string referrer)public payable {
        players.applyReferrer(referrer);
        replayAnser(roomIdx,tryA);
    }

    function replayAnser(uint256 roomIdx,uint256[] tryA) public payable   {
        RoomInfo.Data storage r = roomInfos.map[roomIdx];
        (uint256 a, uint256 b)= r.replayAnser(players,players.withdrawalFee(r.getReplyFee()),tryA);
        emit ReplayAnserResult (a,b,roomIdx);
    }
    
    
    function sellReply(uint256 roomIdx,uint256 ansHash,uint256 price) public payable {
        RoomInfo.Data storage r = roomInfos.map[roomIdx];
        require(price >= r.prize * SELL_MIN_RATE / 100,"price too low");
        r.sellReply(players,ansHash,price,players.withdrawalFee(price * SELL_PRICE_RATE /100));
    }
    
    function buyReply(uint256 roomIdx,uint256 replyIdx) public payable{
        roomInfos.map[roomIdx].buyReply(players,replyIdx,msg.value);
    }
    
    

    function isEmptyName(string _n) public view returns(bool){
        return players.isEmptyName(_n.nameFilter());
    }
    
    function award(uint256 roomIdx) public  {
        RoomInfo.Data storage r = roomInfos.map[roomIdx];
        (
            address[] memory winners,
            uint256[] memory rewords,
            uint256 nextRound
        )=r.award(players);
        emit Wined(winners , rewords,roomIdx);
        //(nextRound >= CREATE_INIT_PRIZE && SafeMath.mulRate(nextRound,maxReplyFeeRate) > r.minReplyFee  ) || roomInfos.length == 1
        if(r.isAbleNextRound(nextRound)){
            r.clearAndNextRound(nextRound);   
        }else if(roomInfos.size>1){
            for(uint256 i = roomIdx; i= 0.1 ether);
        require(players.getName()=="");
        players.registerName(name.nameFilter());
    }
    
    function getPlayerName() public view returns(bytes32){
        return players.getName();
    }
    
    event ReplayAnserResult(
        uint256 aCount,
        uint256 bCount,
        uint256 roomIdx
    );
    
    event Wined(
        address[]  winners,
        uint256[]  rewords,
        uint256 roomIdx
    );    
    
}
