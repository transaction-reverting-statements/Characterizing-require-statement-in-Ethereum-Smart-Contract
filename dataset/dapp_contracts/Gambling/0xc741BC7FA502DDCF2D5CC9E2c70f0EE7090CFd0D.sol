pragma solidity ^0.4.3;
contract Game{
    //创建者
    address founder;

    uint betPhase=6;

    uint commitPhase=6;

    uint openPhase=6;

    uint minValue=0.1 ether;



    uint refund=90;

    bool finished=true;

    uint startBlock;

    uint id=0;

    struct Participant{
        bytes32 hash;
        bytes32 origin;
        uint value;
        bool committed;
        bool returned;
    }




    struct Bet{
        uint betPhase;
        uint commitPhase;
        uint openPhase;
        uint minValue;

        mapping(address=>Participant) participants;
        address[] keys;
        uint totalValue;
        uint valiadValue;
        uint validUsers;
        bytes32 luckNumber;
        address lucky;
        bool prized;
        uint refund;
    }

    mapping(uint=>Bet) games;


    modifier checkGameFinish(){
        if(finished){
            throw;
        }
        _;
    }

    modifier checkFounder(){
        if(msg.sender!=founder){
            throw;
        }
        _;
    }

    modifier checkPrized(uint id){
        if(games[id].prized){
            throw;
        }
        _;
    }

    modifier checkFihished(){
        if(!finished){
            throw;
        }
        _;
    }

    modifier checkId(uint i){
        if(id!=i){
            throw;
        }
        _;
    }

    modifier checkValue(uint value){
        if(valuestartBlock+betPhase){
            throw;
        }
        _;
    }

    modifier checkCommitPhase(){
        if(block.number>startBlock+betPhase+commitPhase){
            throw;
        }
        _;
    }

    modifier checkOpen(){
        if(block.numbermax){
                    max=distance;
                    tmp=key;
                }
            }else{
                if(p.returned==false){
                    if(key.send(p.value*8/10)){
                        p.returned=true;
                    }

                }
            }

        }
        bet.lucky=tmp;
        bet.luckNumber=random;
        uint prize=bet.valiadValue*refund/100;

        founder.send((bet.valiadValue-prize));
        if(tmp.send(prize)){
            bet.prized=true;
            Open(tmp,random,prize,id);
        }

        finished=true;
    }

    function getContractBalance() constant returns(uint){
        return this.balance;
    }

    function withdraw(address user,uint value)
    checkFounder
    {
        user.send(value);
    }

    function getPlayerCommitted(uint period,address player) constant returns(bool){
        Participant memory p=games[period].participants[player];
        return p.committed;
    }

    function getPlayerReturned(uint period,address player) constant returns(bool){
        Participant memory p=games[period].participants[player];
        return p.returned;
    }

    function getPlayerNum(uint period) constant
    returns(uint){
        Bet bet=games[period];
        return bet.keys.length;
    }

    function getPlayerAddress(uint period,uint offset) constant
    returns(address){
        Bet bet=games[period];
        return bet.keys[offset];
    }

    function getPlayerOrigin(uint period,uint offset) constant
    returns(bytes32){
        Bet bet=games[period];
        address user=bet.keys[offset];
        return bet.participants[user].origin;
    }

    function getPlayerHash(uint period,uint offset) constant
    returns(bytes32){
        Bet bet=games[period];
        address user=bet.keys[offset];
        return bet.participants[user].hash;
    }

    function getPlayerValue(uint period,uint offset) constant
    returns(uint){
        Bet bet=games[period];
        address user=bet.keys[offset];
        return bet.participants[user].value;
    }

    // public getRandom(uint id) constant{

    // }
    function getId() constant returns(uint){
        return id;
    }

    function getRandom(uint id) constant
    checkId(id)
    returns(bytes32){
        return games[id].luckNumber;
    }

    function getLuckUser(uint id) constant
    checkId(id)
    returns(address){
        return games[id].lucky;
    }

    function getPrizeAmount(uint id) constant
    checkId(id)
    returns(uint){
        return games[id].totalValue;
    }

    function getMinAmount(uint id) constant
    checkId(id)
    returns(uint)
    {
        return minValue;
    }

    function getsha3(bytes32 x) constant
    returns(bytes32){
        return sha3(x);
    }

    function getGamePeriod() constant
    returns(uint){
        return id;
    }


    function getStartBlock() constant
    returns(uint){
        return startBlock;
    }

    function getBetPhase() constant
    returns(uint){
        return betPhase;
    }

    function getCommitPhase() constant
    returns(uint){
        return commitPhase;
    }

    function getFinished() constant
    returns(bool){
        return finished;
    }

}
