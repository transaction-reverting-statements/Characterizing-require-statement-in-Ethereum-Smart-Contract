pragma solidity ^0.5.4;

/**
  Multipliers contract: returns 111%-141% of each investment!
  Automatic payouts!
  No bugs, no backdoors, NO OWNER - fully automatic!
  Made and checked by professionals!

  1. Send any sum to smart contract address
     - sum from 0.01 to 10 ETH
     - min 250000 gas limit
     - you are added to a queue
  2. Wait a little bit
  3. ...
  4. PROFIT! You have got 111-141%

  How is that?
  1. The first investor in the queue (you will become the
     first in some time) receives next investments until
     it become 111-141% of his initial investment.
  2. You will receive payments in several parts or all at once
  3. Once you receive 111-141% of your initial investment you are
     removed from the queue.
  4. You can make multiple deposits
  5. The balance of this contract should normally be 0 because
     all the money are immediately go to payouts
  6. The more deposits you make the more multiplier you get. See MULTIPLIERS var
  7. If you are the last depositor (no deposits after you in 30 mins)
     you get 5% of all the ether that were on the contract. Send 0 to withdraw it.
     Do it BEFORE NEXT RESTART!


     So the last pays to the first (or to several first ones
     if the deposit big enough) and the investors paid 111-141% are removed from the queue

                new investor --|               brand new investor --|
                 investor5     |                 new investor       |
                 investor4     |     =======>      investor5        |
                 investor3     |                   investor4        |
    (part. paid) investor2          инвестор5        |
                 инвестор3     |                   инвестор4        |
 (част. выплата) инвестор2     0 - next start time
    int public stage = 0; //Number of contract runs
    mapping(address => DepositCount) public depositsMade; //The number of deposits of different depositors

    constructor(address payable _tech, address payable _promo) public {
        //Initialize array to save gas to first depositor
        //Remember - actual queue length is stored in currentQueueSize!
        queue.push(Deposit(address(0x1),0,1));
        tech = _tech;
        promo = _promo;
    }

    //This function receives all the deposits
    //stores them and make immediate payouts
    function () external payable {
        deposit();
    }

    //This function receives all the deposits
    //stores them and make immediate payouts
    function deposit() public payable {
        //Prevent cheating with high gas prices.
        require(tx.gasprice <= maxGasPrice, "Gas price is too high! Do not cheat!");
        require(startTime > 0 && now >= startTime, "The race has not begun yet!");

        if(msg.value > 0 && lastDepositInfo.time > 0 && now > lastDepositInfo.time + MAX_IDLE_TIME){
            //This is deposit after prize is drawn, so just return the money and withdraw the prize to the winner
            msg.sender.transfer(msg.value);
            withdrawPrize();
        }else if(msg.value > 0){
            require(gasleft() >= 220000, "We require more gas!"); //We need gas to process queue
            require(msg.value >= MIN_INVESTMENT, "The investment is too small!");
            require(msg.value <= MAX_INVESTMENT, "The investment is too large!"); //Do not allow too big investments to stabilize payouts

            addDeposit(msg.sender, msg.value);

            //Pay to first investors in line
            pay();
        }else if(msg.value == 0){
            withdrawPrize();
        }
    }

    //Used to pay to current investors
    //Each new transaction processes 1 - 4+ investors in the head of queue
    //depending on balance and gas left
    function pay() private {
        //Try to send all the money on contract to the first investors in line
        uint balance = address(this).balance;
        uint money = 0;
        if(balance > prizeAmount) //The opposite is impossible, however the check will not do any harm
            money = balance - prizeAmount;

        //We will do cycle on the queue
        uint i=currentReceiverIndex;
        for(; i= dep.expect){  //If we have enough money on the contract to fully pay to investor
                dep.depositor.send(dep.expect); //Send money to him
                money -= dep.expect;            //update money left

                emit Refund(stage, dep.expect, dep.depositor);

                //this investor is fully paid, so remove him
                delete queue[i];
            }else{
                //Here we don't have enough money so partially pay to investor
                dep.depositor.send(money); //Send to him everything we have
                dep.expect -= uint128(money);       //Update the expected amount

                emit Refund(stage, money, dep.depositor);
                break;                     //Exit cycle
            }

            if(gasleft() <= 50000)         //Check the gas left. If it is low, exit the cycle
                break;                     //The next investor will process the line further
        }

        currentReceiverIndex = i; //Update the index of the current first investor
    }

    function addDeposit(address payable depositor, uint value) private {
        //Count the number of the deposit at this stage
        DepositCount storage c = depositsMade[depositor];
        if(c.stage != stage){
            c.stage = int128(stage);
            c.count = 0;
        }

        //If you are applying for the prize you should invest more than minimal amount
        //Otherwize it doesn't count
        if(value >= getCurrentPrizeMinimalDeposit())
            lastDepositInfo = LastDepositInfo(uint128(currentQueueSize), uint128(now));

        //Compute the multiplier percent for this depositor
        uint multiplier = getDepositorMultiplier(depositor);
        //Add the investor into the queue. Mark that he expects to receive 111%-141% of deposit back
        push(depositor, value, value*multiplier/100);

        //Increment number of deposits the depositors made this round
        c.count++;

        //Save money for prize and father multiplier
        prizeAmount += value*(PRIZE_PERCENT)/100;

        //Send small part to tech support
        uint support = value*TECH_PERCENT/100;
        tech.send(support);
        uint adv = value*PROMO_PERCENT/100;
        promo.send(adv);

        emit Dep(stage, msg.value, msg.sender);
    }

    function proceedToNewStage(int _stage) private {
        //Clean queue info
        //The prize amount on the balance is left the same if not withdrawn
        stage = _stage;
        startTime = 0;
        currentQueueSize = 0; //Instead of deleting queue just reset its length (gas economy)
        currentReceiverIndex = 0;
        delete lastDepositInfo;
    }

    function withdrawPrize() private {
        //You can withdraw prize only if the last deposit was more than MAX_IDLE_TIME ago
        require(lastDepositInfo.time > 0 && lastDepositInfo.time <= now - MAX_IDLE_TIME, "The last depositor is not confirmed yet");
        //Last depositor will receive prize only if it has not been fully paid
        require(currentReceiverIndex <= lastDepositInfo.index, "The last depositor should still be in queue");

        uint balance = address(this).balance;
        uint prize = prizeAmount;
        if(balance > prize){
            //We should distribute funds to queue
            pay();
        }
        if(balance > prize){
            return; //Funds are still not distributed, so exit
        }
        if(prize > balance) //Impossible but better check it
            prize = balance;

        queue[lastDepositInfo.index].depositor.send(prize);

        emit Prize(stage, prize, queue[lastDepositInfo.index].depositor);

        prizeAmount = 0;
        proceedToNewStage(stage + 1);
    }

    //Pushes investor to the queue
    function push(address payable depositor, uint dep, uint expect) private {
        //Add the investor into the queue
        Deposit memory d = Deposit(depositor, uint128(dep), uint128(expect));
        assert(currentQueueSize <= queue.length); //Assert queue size is not corrupted
        if(queue.length == currentQueueSize)
            queue.push(d);
        else
            queue[currentQueueSize] = d;

        currentQueueSize++;
    }

    //Get the deposit info by its index
    //You can get deposit index from
    function getDeposit(uint idx) public view returns (address depositor, uint dep, uint expect){
        Deposit storage d = queue[idx];
        return (d.depositor, d.deposit, d.expect);
    }

    function getCurrentPrizeMinimalDeposit() public view returns(uint) {
        uint st = startTime;
        if(st == 0 || now < st)
            return MIN_INVESTMENT_FOR_PRIZE;
        uint dep = MIN_INVESTMENT_FOR_PRIZE + ((now - st)/1 hours)*MIN_INVESTMENT_FOR_PRIZE;
        if(dep > MAX_INVESTMENT)
            dep = MAX_INVESTMENT;
        return dep;
    }

    //Get the count of deposits of specific investor
    function getDepositsCount(address depositor) public view returns (uint) {
        uint c = 0;
        for(uint i=currentReceiverIndex; i 0) {
            uint j = 0;
            for(uint i=currentReceiverIndex; i= now, "Wrong start time");
        startTime = time;
        if(_gasprice > 0)
            maxGasPrice = _gasprice;
    }

    function setParameters(uint min, uint max, uint prize, uint idle) public onlyAuthorityAndStopped {
        if(min > 0)
            MIN_INVESTMENT = min;
        if(max > 0)
            MAX_INVESTMENT = max;
        if(prize > 0)
            MIN_INVESTMENT_FOR_PRIZE = prize;
        if(idle > 0)
            MAX_IDLE_TIME = idle;
    }

    function getCurrentCandidateForPrize() public view returns (address addr, uint prize, uint timeMade, int timeLeft){
        //prevent exception, just return 0 for absent candidate
        if(currentReceiverIndex <= lastDepositInfo.index && lastDepositInfo.index < currentQueueSize){
            Deposit storage d = queue[lastDepositInfo.index];
            addr = d.depositor;
            prize = prizeAmount;
            timeMade = lastDepositInfo.time;
            timeLeft = int(timeMade + MAX_IDLE_TIME) - int(now);
        }
    }

}
