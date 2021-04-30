{"DeliverFunds.sol":{"content":"pragma solidity 0.5.10;\r\n\r\ncontract DeliverFunds {\r\n    constructor(address payable target) public payable {\r\n        selfdestruct(target);\r\n    }\r\n}"},"EthexHouse.sol":{"content":"pragma solidity ^0.5.0;\r\n\r\n/**\r\n * (E)t)h)e)x) House Contract \r\n *  This smart-contract is the part of Ethex Lottery fair game.\r\n *  See latest version at https://github.com/ethex-bet/ethex-lottery \r\n *  http://ethex.bet\r\n */\r\n \r\n contract EthexHouse {\r\n     address payable private owner;\r\n     \r\n     constructor() public {\r\n         owner = msg.sender;\r\n     }\r\n     \r\n     modifier onlyOwner {\r\n        require(msg.sender == owner);\r\n        _;\r\n    }\r\n    \r\n    function payIn() external payable {\r\n    }\r\n    \r\n    function withdraw() external onlyOwner {\r\n        owner.transfer(address(this).balance);\r\n    }\r\n }"},"EthexJackpot.sol":{"content":"pragma solidity ^0.5.0;\r\n\r\n/**\r\n * (E)t)h)e)x) Jackpot Contract \r\n *  This smart-contract is the part of Ethex Lottery fair game.\r\n *  See latest version at https://github.com/ethex-bet/ethex-contracts \r\n *  http://ethex.bet\r\n */\r\n\r\ncontract EthexJackpot {\r\n    mapping(uint256 =\u003e address payable) public tickets;\r\n    uint256 public numberEnd;\r\n    uint256 public firstNumber;\r\n    uint256 public dailyAmount;\r\n    uint256 public weeklyAmount;\r\n    uint256 public monthlyAmount;\r\n    uint256 public seasonalAmount;\r\n    bool public dailyProcessed;\r\n    bool public weeklyProcessed;\r\n    bool public monthlyProcessed;\r\n    bool public seasonalProcessed;\r\n    address payable private owner;\r\n    address public lotoAddress;\r\n    address payable public newVersionAddress;\r\n    EthexJackpot previousContract;\r\n    uint256 public dailyNumberStartPrev;\r\n    uint256 public weeklyNumberStartPrev;\r\n    uint256 public monthlyNumberStartPrev;\r\n    uint256 public seasonalNumberStartPrev;\r\n    uint256 public dailyStart;\r\n    uint256 public weeklyStart;\r\n    uint256 public monthlyStart;\r\n    uint256 public seasonalStart;\r\n    uint256 public dailyEnd;\r\n    uint256 public weeklyEnd;\r\n    uint256 public monthlyEnd;\r\n    uint256 public seasonalEnd;\r\n    uint256 public dailyNumberStart;\r\n    uint256 public weeklyNumberStart;\r\n    uint256 public monthlyNumberStart;\r\n    uint256 public seasonalNumberStart;\r\n    uint256 public dailyNumberEndPrev;\r\n    uint256 public weeklyNumberEndPrev;\r\n    uint256 public monthlyNumberEndPrev;\r\n    uint256 public seasonalNumberEndPrev;\r\n    \r\n    event Jackpot (\r\n        uint256 number,\r\n        uint256 count,\r\n        uint256 amount,\r\n        byte jackpotType\r\n    );\r\n    \r\n    event Ticket (\r\n        bytes16 indexed id,\r\n        uint256 number\r\n    );\r\n    \r\n    event SuperPrize (\r\n        uint256 amount,\r\n        address winner\r\n    );\r\n    \r\n    uint256 constant DAILY = 5000;\r\n    uint256 constant WEEKLY = 35000;\r\n    uint256 constant MONTHLY = 150000;\r\n    uint256 constant SEASONAL = 450000;\r\n    uint256 constant PRECISION = 1 ether;\r\n    uint256 constant DAILY_PART = 84;\r\n    uint256 constant WEEKLY_PART = 12;\r\n    uint256 constant MONTHLY_PART = 3;\r\n    \r\n    constructor() public payable {\r\n        owner = msg.sender;\r\n    }\r\n    \r\n    function() external payable { }\r\n\r\n    modifier onlyOwner {\r\n        require(msg.sender == owner);\r\n        _;\r\n    }\r\n    \r\n    modifier onlyOwnerOrNewVersion {\r\n        require(msg.sender == owner || msg.sender == newVersionAddress);\r\n        _;\r\n    }\r\n    \r\n    modifier onlyLoto {\r\n        require(msg.sender == lotoAddress, \"Loto only\");\r\n        _;\r\n    }\r\n    \r\n    function migrate() external onlyOwnerOrNewVersion {\r\n        newVersionAddress.transfer(address(this).balance);\r\n    }\r\n\r\n    function registerTicket(bytes16 id, address payable gamer) external onlyLoto {\r\n        uint256 number = numberEnd + 1;\r\n        if (block.number \u003e= dailyEnd) {\r\n            setDaily();\r\n            dailyNumberStart = number;\r\n        }\r\n        else\r\n            if (dailyNumberStart == dailyNumberStartPrev)\r\n                dailyNumberStart = number;\r\n        if (block.number \u003e= weeklyEnd) {\r\n            setWeekly();\r\n            weeklyNumberStart = number;\r\n        }\r\n        else\r\n            if (weeklyNumberStart == weeklyNumberStartPrev)\r\n                weeklyNumberStart = number;\r\n        if (block.number \u003e= monthlyEnd) {\r\n            setMonthly();\r\n            monthlyNumberStart = number;\r\n        }\r\n        else\r\n            if (monthlyNumberStart == monthlyNumberStartPrev)\r\n                monthlyNumberStart = number;\r\n        if (block.number \u003e= seasonalEnd) {\r\n            setSeasonal();\r\n            seasonalNumberStart = number;\r\n        }\r\n        else\r\n            if (seasonalNumberStart == seasonalNumberStartPrev)\r\n                seasonalNumberStart = number;\r\n        numberEnd = number;\r\n        tickets[number] = gamer;\r\n        emit Ticket(id, number);\r\n    }\r\n    \r\n    function setLoto(address loto) external onlyOwner {\r\n        lotoAddress = loto;\r\n    }\r\n    \r\n    function setNewVersion(address payable newVersion) external onlyOwner {\r\n        newVersionAddress = newVersion;\r\n    }\r\n    \r\n    function payIn() external payable {\r\n        uint256 distributedAmount = dailyAmount + weeklyAmount + monthlyAmount + seasonalAmount;\r\n        if (distributedAmount \u003c address(this).balance) {\r\n            uint256 amount = (address(this).balance - distributedAmount) / 4;\r\n            dailyAmount += amount;\r\n            weeklyAmount += amount;\r\n            monthlyAmount += amount;\r\n            seasonalAmount += amount;\r\n        }\r\n    }\r\n    \r\n    function settleJackpot() external {\r\n        if (block.number \u003e= dailyEnd)\r\n            setDaily();\r\n        if (block.number \u003e= weeklyEnd)\r\n            setWeekly();\r\n        if (block.number \u003e= monthlyEnd)\r\n            setMonthly();\r\n        if (block.number \u003e= seasonalEnd)\r\n            setSeasonal();\r\n        \r\n        if (block.number == dailyStart || (dailyStart \u003c block.number - 256))\r\n            return;\r\n        \r\n        uint48 modulo = uint48(bytes6(blockhash(dailyStart) \u003c\u003c 29));\r\n        \r\n        uint256 dailyPayAmount;\r\n        uint256 weeklyPayAmount;\r\n        uint256 monthlyPayAmount;\r\n        uint256 seasonalPayAmount;\r\n        uint256 dailyWin;\r\n        uint256 weeklyWin;\r\n        uint256 monthlyWin;\r\n        uint256 seasonalWin;\r\n        if (dailyProcessed == false) {\r\n            dailyPayAmount = dailyAmount * PRECISION / DAILY_PART / PRECISION;\r\n            dailyAmount -= dailyPayAmount;\r\n            dailyProcessed = true;\r\n            dailyWin = getNumber(dailyNumberStartPrev, dailyNumberEndPrev, modulo);\r\n            emit Jackpot(dailyWin, dailyNumberEndPrev - dailyNumberStartPrev + 1, dailyPayAmount, 0x01);\r\n        }\r\n        if (weeklyProcessed == false) {\r\n            weeklyPayAmount = weeklyAmount * PRECISION / WEEKLY_PART / PRECISION;\r\n            weeklyAmount -= weeklyPayAmount;\r\n            weeklyProcessed = true;\r\n            weeklyWin = getNumber(weeklyNumberStartPrev, weeklyNumberEndPrev, modulo);\r\n            emit Jackpot(weeklyWin, weeklyNumberEndPrev - weeklyNumberStartPrev + 1, weeklyPayAmount, 0x02);\r\n        }\r\n        if (monthlyProcessed == false) {\r\n            monthlyPayAmount = monthlyAmount * PRECISION / MONTHLY_PART / PRECISION;\r\n            monthlyAmount -= monthlyPayAmount;\r\n            monthlyProcessed = true;\r\n            monthlyWin = getNumber(monthlyNumberStartPrev, monthlyNumberEndPrev, modulo);\r\n            emit Jackpot(monthlyWin, monthlyNumberEndPrev - monthlyNumberStartPrev + 1, monthlyPayAmount, 0x04);\r\n        }\r\n        if (seasonalProcessed == false) {\r\n            seasonalPayAmount = seasonalAmount;\r\n            seasonalAmount -= seasonalPayAmount;\r\n            seasonalProcessed = true;\r\n            seasonalWin = getNumber(seasonalNumberStartPrev, seasonalNumberEndPrev, modulo);\r\n            emit Jackpot(seasonalWin, seasonalNumberEndPrev - seasonalNumberStartPrev + 1, seasonalPayAmount, 0x08);\r\n        }\r\n        if (dailyPayAmount \u003e 0)\r\n            getAddress(dailyWin).transfer(dailyPayAmount);\r\n        if (weeklyPayAmount \u003e 0)\r\n            getAddress(weeklyWin).transfer(weeklyPayAmount);\r\n        if (monthlyPayAmount \u003e 0)\r\n            getAddress(monthlyWin).transfer(monthlyPayAmount);\r\n        if (seasonalPayAmount \u003e 0)\r\n            getAddress(seasonalWin).transfer(seasonalPayAmount);\r\n    }\r\n\r\n    function paySuperPrize(address payable winner) external onlyLoto {\r\n        uint256 superPrizeAmount = dailyAmount + weeklyAmount + monthlyAmount + seasonalAmount;\r\n        dailyAmount = 0;\r\n        weeklyAmount = 0;\r\n        monthlyAmount = 0;\r\n        seasonalAmount = 0;\r\n        emit SuperPrize(superPrizeAmount, winner);\r\n        winner.transfer(superPrizeAmount);\r\n    }\r\n    \r\n    function setOldVersion(address payable oldAddress) external onlyOwner {\r\n        previousContract = EthexJackpot(oldAddress);\r\n        dailyStart = previousContract.dailyStart();\r\n        dailyEnd = previousContract.dailyEnd();\r\n        dailyProcessed = previousContract.dailyProcessed();\r\n        weeklyStart = previousContract.weeklyStart();\r\n        weeklyEnd = previousContract.weeklyEnd();\r\n        weeklyProcessed = previousContract.weeklyProcessed();\r\n        monthlyStart = previousContract.monthlyStart();\r\n        monthlyEnd = previousContract.monthlyEnd();\r\n        monthlyProcessed = previousContract.monthlyProcessed();\r\n        seasonalStart = previousContract.seasonalStart();\r\n        seasonalEnd = previousContract.seasonalEnd();\r\n        seasonalProcessed = previousContract.seasonalProcessed();\r\n        dailyNumberStartPrev = previousContract.dailyNumberStartPrev();\r\n        weeklyNumberStartPrev = previousContract.weeklyNumberStartPrev();\r\n        monthlyNumberStartPrev = previousContract.monthlyNumberStartPrev();\r\n        seasonalNumberStartPrev = previousContract.seasonalNumberStartPrev();\r\n        dailyNumberStart = previousContract.dailyNumberStart();\r\n        weeklyNumberStart = previousContract.weeklyNumberStart();\r\n        monthlyNumberStart = previousContract.monthlyNumberStart();\r\n        seasonalNumberStart = previousContract.seasonalNumberStart();\r\n        dailyNumberEndPrev = previousContract.dailyNumberEndPrev();\r\n        weeklyNumberEndPrev = previousContract.weeklyNumberEndPrev();\r\n        monthlyNumberEndPrev = previousContract.monthlyNumberEndPrev();\r\n        seasonalNumberEndPrev = previousContract.seasonalNumberEndPrev();\r\n        numberEnd = previousContract.numberEnd();\r\n        dailyAmount = previousContract.dailyAmount();\r\n        weeklyAmount = previousContract.weeklyAmount();\r\n        monthlyAmount = previousContract.monthlyAmount();\r\n        seasonalAmount = previousContract.seasonalAmount();\r\n        firstNumber = weeklyNumberStart;\r\n        for (uint256 i = firstNumber; i \u003c= numberEnd; i++)\r\n            tickets[i] = previousContract.getAddress(i);\r\n        previousContract.migrate();\r\n    }\r\n    \r\n    function getAddress(uint256 number) public returns (address payable) {\r\n        if (number \u003c= firstNumber)\r\n            return previousContract.getAddress(number);\r\n        return tickets[number];\r\n    }\r\n    \r\n    function setDaily() private {\r\n        dailyProcessed = dailyNumberEndPrev == numberEnd;\r\n        dailyStart = dailyEnd;\r\n        dailyEnd = dailyStart + DAILY;\r\n        dailyNumberStartPrev = dailyNumberStart;\r\n        dailyNumberEndPrev = numberEnd;\r\n    }\r\n    \r\n    function setWeekly() private {\r\n        weeklyProcessed = weeklyNumberEndPrev == numberEnd;\r\n        weeklyStart = weeklyEnd;\r\n        weeklyEnd = weeklyStart + WEEKLY;\r\n        weeklyNumberStartPrev = weeklyNumberStart;\r\n        weeklyNumberEndPrev = numberEnd;\r\n    }\r\n    \r\n    function setMonthly() private {\r\n        monthlyProcessed = monthlyNumberEndPrev == numberEnd;\r\n        monthlyStart = monthlyEnd;\r\n        monthlyEnd = monthlyStart + MONTHLY;\r\n        monthlyNumberStartPrev = monthlyNumberStart;\r\n        monthlyNumberEndPrev = numberEnd;\r\n    }\r\n    \r\n    function setSeasonal() private {\r\n        seasonalProcessed = seasonalNumberEndPrev == numberEnd;\r\n        seasonalStart = seasonalEnd;\r\n        seasonalEnd = seasonalStart + SEASONAL;\r\n        seasonalNumberStartPrev = seasonalNumberStart;\r\n        seasonalNumberEndPrev = numberEnd;\r\n    }\r\n    \r\n    function getNumber(uint256 startNumber, uint256 endNumber, uint48 modulo) pure private returns (uint256) {\r\n        return startNumber + modulo % (endNumber - startNumber + 1);\r\n    }\r\n}"},"EthexLoto.sol":{"content":"pragma solidity 0.5.10;\r\n\r\n/**\r\n * (E)t)h)e)x) Loto Contract \r\n *  This smart-contract is the part of Ethex Lottery fair game.\r\n *  See latest version at https://github.com/ethex-bet/ethex-contacts \r\n *  http://ethex.bet\r\n */\r\n\r\nimport \"./EthexJackpot.sol\";\r\nimport \"./EthexHouse.sol\";\r\nimport \"./EthexSuperprize.sol\";\r\nimport \"./DeliverFunds.sol\";\r\n\r\ncontract EthexLoto {\r\n    struct Bet {\r\n        uint256 blockNumber;\r\n        uint256 amount;\r\n        bytes16 id;\r\n        bytes6 bet;\r\n        address payable gamer;\r\n    }\r\n    \r\n    struct Transaction {\r\n        uint256 amount;\r\n        address payable gamer;\r\n    }\r\n    \r\n    struct Superprize {\r\n        uint256 amount;\r\n        bytes16 id;\r\n    }\r\n    \r\n    mapping(uint256 =\u003e uint256) public blockNumberQueue;\r\n    mapping(uint256 =\u003e uint256) public amountQueue;\r\n    mapping(uint256 =\u003e bytes16) public idQueue;\r\n    mapping(uint256 =\u003e bytes6) public betQueue;\r\n    mapping(uint256 =\u003e address payable) public gamerQueue;\r\n    uint256 public first = 2;\r\n    uint256 public last = 1;\r\n    uint256 public holdBalance;\r\n    \r\n    address payable public jackpotAddress;\r\n    address payable public houseAddress;\r\n    address payable public superprizeAddress;\r\n    address payable private owner;\r\n\r\n    event PayoutBet (\r\n        uint256 amount,\r\n        bytes16 id,\r\n        address gamer\r\n    );\r\n    \r\n    event RefundBet (\r\n        uint256 amount,\r\n        bytes16 id,\r\n        address gamer\r\n    );\r\n    \r\n    uint256 constant MIN_BET = 0.01 ether;\r\n    uint256 constant PRECISION = 1 ether;\r\n    uint256 constant JACKPOT_PERCENT = 10;\r\n    uint256 constant HOUSE_EDGE = 10;\r\n    \r\n    constructor(address payable jackpot, address payable house, address payable superprize) public payable {\r\n        owner = msg.sender;\r\n        jackpotAddress = jackpot;\r\n        houseAddress = house;\r\n        superprizeAddress = superprize;\r\n    }\r\n    \r\n    function() external payable { }\r\n    \r\n    modifier onlyOwner {\r\n        require(msg.sender == owner);\r\n        _;\r\n    }\r\n    \r\n    function placeBet(bytes22 params) external payable {\r\n        require(tx.origin == msg.sender);\r\n        require(msg.value \u003e= MIN_BET, \"Bet amount should be greater or equal than minimal amount\");\r\n        require(bytes16(params) != 0, \"Id should not be 0\");\r\n        \r\n        bytes16 id = bytes16(params);\r\n        bytes6 bet = bytes6(params \u003c\u003c 128);\r\n        \r\n        uint256 coefficient;\r\n        uint8 markedCount;\r\n        uint256 holdAmount;\r\n        uint256 jackpotFee = msg.value * JACKPOT_PERCENT * PRECISION / 100 / PRECISION;\r\n        uint256 houseEdgeFee = msg.value * HOUSE_EDGE * PRECISION / 100 / PRECISION;\r\n        uint256 betAmount = msg.value - jackpotFee - houseEdgeFee;\r\n        \r\n        (coefficient, markedCount, holdAmount) = getHold(betAmount, bet);\r\n        \r\n        require(msg.value * (100 - JACKPOT_PERCENT - HOUSE_EDGE) * (coefficient * 8 - 15 * markedCount) \u003c= 9000 ether * markedCount);\r\n        \r\n        require(\r\n            msg.value * (800 * coefficient - (JACKPOT_PERCENT + HOUSE_EDGE) * (coefficient * 8 + 15 * markedCount)) \u003c= 1500 * markedCount * (address(this).balance - holdBalance));\r\n        \r\n        holdBalance += holdAmount;\r\n        \r\n        enqueue(block.number, betAmount, id, bet, msg.sender);\r\n        \r\n        if (markedCount \u003e 1)\r\n            EthexJackpot(jackpotAddress).registerTicket(id, msg.sender);\r\n        \r\n        EthexHouse(houseAddress).payIn.value(houseEdgeFee)();\r\n        EthexJackpot(jackpotAddress).payIn.value(jackpotFee)();\r\n    }\r\n    \r\n    function settleBets() external {\r\n        if (first \u003e last)\r\n            return;\r\n        uint256 i = 0;\r\n        uint256 length = last - first + 1;\r\n        length = length \u003e 10 ? 10 : length;\r\n        Transaction[] memory transactions = new Transaction[](length);\r\n        Superprize[] memory superprizes = new Superprize[](length);\r\n        uint256 balance = address(this).balance - holdBalance;\r\n        \r\n        for(; i \u003c length; i++) {\r\n            if (blockNumberQueue[first] \u003e= block.number) {\r\n                length = i;\r\n                break;\r\n            }\r\n            else {\r\n                Bet memory bet = dequeue();\r\n                uint256 coefficient = 0;\r\n                uint8 markedCount = 0;\r\n                uint256 holdAmount = 0;\r\n                (coefficient, markedCount, holdAmount) = getHold(bet.amount, bet.bet);\r\n                holdBalance -= holdAmount;\r\n                balance += holdAmount;\r\n                if (bet.blockNumber \u003c block.number - 256) {\r\n                    transactions[i] = Transaction(bet.amount, bet.gamer);\r\n                    emit RefundBet(bet.amount, bet.id, bet.gamer);\r\n                    balance -= bet.amount;\r\n                }\r\n                else {\r\n                    bytes32 blockHash = blockhash(bet.blockNumber);\r\n                    coefficient = 0;\r\n                    uint8 matchesCount;\r\n                    bool isSuperPrize = true;\r\n                    for (uint8 j = 0; j \u003c bet.bet.length; j++) {\r\n                        if (bet.bet[j] \u003e 0x13) {\r\n                            isSuperPrize = false;\r\n                            continue;\r\n                        }\r\n                        byte field;\r\n                        if (j % 2 == 0)\r\n                            field = blockHash[29 + j / 2] \u003e\u003e 4;\r\n                        else\r\n                            field = blockHash[29 + j / 2] \u0026 0x0F;\r\n                        if (bet.bet[j] \u003c 0x10) {\r\n                            if (field == bet.bet[j]) {\r\n                                matchesCount++;\r\n                                coefficient += 30;\r\n                            }\r\n                            else\r\n                                isSuperPrize = false;\r\n                            continue;\r\n                        }\r\n                        else\r\n                            isSuperPrize = false;\r\n                        if (bet.bet[j] == 0x10) {\r\n                            if (field \u003e 0x09 \u0026\u0026 field \u003c 0x10) {\r\n                                matchesCount++;\r\n                                coefficient += 5;\r\n                            }\r\n                            continue;\r\n                        }\r\n                        if (bet.bet[j] == 0x11) {\r\n                            if (field \u003c 0x0A) {\r\n                                matchesCount++;\r\n                                coefficient += 3;\r\n                            }\r\n                            continue;\r\n                        }\r\n                        if (bet.bet[j] == 0x12) {\r\n                            if (field \u003c 0x0A \u0026\u0026 field \u0026 0x01 == 0x01) {\r\n                                matchesCount++;\r\n                                coefficient += 6;\r\n                            }\r\n                            continue;\r\n                        }\r\n                        if (bet.bet[j] == 0x13) {\r\n                            if (field \u003c 0x0A \u0026\u0026 field \u0026 0x01 == 0x0) {\r\n                                matchesCount++;\r\n                                coefficient += 6;\r\n                            }\r\n                            continue;\r\n                        }\r\n                    }\r\n                \r\n                    coefficient *= PRECISION * 8;\r\n                        \r\n                    uint256 payoutAmount = bet.amount * coefficient / (PRECISION * 15 * markedCount);\r\n                    transactions[i] = Transaction(payoutAmount, bet.gamer);\r\n                    emit PayoutBet(payoutAmount, bet.id, bet.gamer);\r\n                    balance -= payoutAmount;\r\n                    \r\n                    if (isSuperPrize == true) {\r\n                        superprizes[i].amount = balance;\r\n                        superprizes[i].id = bet.id;\r\n                        balance = 0;\r\n                    }\r\n                }\r\n            }\r\n        }\r\n        \r\n        for (i = 0; i \u003c length; i++) {\r\n            if (transactions[i].amount \u003e 0 \u0026\u0026 !transactions[i].gamer.send(transactions[i].amount))\r\n                (new DeliverFunds).value(transactions[i].amount)(transactions[i].gamer);\r\n            if (superprizes[i].id != 0) {\r\n                EthexSuperprize(superprizeAddress).initSuperprize(transactions[i].gamer, superprizes[i].id);\r\n                EthexJackpot(jackpotAddress).paySuperPrize(transactions[i].gamer);\r\n                if (superprizes[i].amount \u003e 0 \u0026\u0026 !transactions[i].gamer.send(superprizes[i].amount))\r\n                    (new DeliverFunds).value(superprizes[i].amount)(transactions[i].gamer);\r\n            }\r\n        }\r\n    }\r\n    \r\n    function migrate(address payable newContract) external onlyOwner {\r\n        newContract.transfer(address(this).balance);\r\n    }\r\n\r\n    function setJackpot(address payable jackpot) external onlyOwner {\r\n        jackpotAddress = jackpot;\r\n    }\r\n    \r\n    function setSuperprize(address payable superprize) external onlyOwner {\r\n        superprizeAddress = superprize;\r\n    }\r\n    \r\n    function length() public view returns (uint256) {\r\n        return 1 + last - first;\r\n    }\r\n    \r\n    function enqueue(uint256 blockNumber, uint256 amount, bytes16 id, bytes6 bet, address payable gamer) internal {\r\n        last += 1;\r\n        blockNumberQueue[last] = blockNumber;\r\n        amountQueue[last] = amount;\r\n        idQueue[last] = id;\r\n        betQueue[last] = bet;\r\n        gamerQueue[last] = gamer;\r\n    }\r\n\r\n    function dequeue() internal returns (Bet memory bet) {\r\n        require(last \u003e= first);\r\n\r\n        bet = Bet(blockNumberQueue[first], amountQueue[first], idQueue[first], betQueue[first], gamerQueue[first]);\r\n\r\n        delete blockNumberQueue[first];\r\n        delete amountQueue[first];\r\n        delete idQueue[first];\r\n        delete betQueue[first];\r\n        delete gamerQueue[first];\r\n        \r\n        if (first == last) {\r\n            first = 2;\r\n            last = 1;\r\n        }\r\n        else\r\n            first += 1;\r\n    }\r\n    \r\n    function getHold(uint256 amount, bytes6 bet) internal pure returns (uint256 coefficient, uint8 markedCount, uint256 holdAmount) {\r\n        for (uint8 i = 0; i \u003c bet.length; i++) {\r\n            if (bet[i] \u003e 0x13)\r\n                continue;\r\n            markedCount++;\r\n            if (bet[i] \u003c 0x10) {\r\n                coefficient += 30;\r\n                continue;\r\n            }\r\n            if (bet[i] == 0x10) {\r\n                coefficient += 5;\r\n                continue;\r\n            }\r\n            if (bet[i] == 0x11) {\r\n                coefficient += 3;\r\n                continue;\r\n            }\r\n            if (bet[i] == 0x12) {\r\n                coefficient += 6;\r\n                continue;\r\n            }\r\n            if (bet[i] == 0x13) {\r\n                coefficient += 6;\r\n                continue;\r\n            }\r\n        }\r\n        holdAmount = amount * coefficient * 2 / 375 / markedCount;\r\n    }\r\n}\r\n"},"EthexSuperprize.sol":{"content":"pragma solidity ^0.5.0;\r\n\r\n/**\r\n * (E)t)h)e)x) Superprize Contract \r\n *  This smart-contract is the part of Ethex Lottery fair game.\r\n *  See latest version at https://github.com/ethex-bet/ethex-lottery \r\n *  http://ethex.bet\r\n */\r\n \r\n contract EthexSuperprize {\r\n    struct Payout {\r\n        uint256 index;\r\n        uint256 amount;\r\n        uint256 block;\r\n        address payable winnerAddress;\r\n        bytes16 betId;\r\n    }\r\n     \r\n    Payout[] public payouts;\r\n     \r\n    address payable private owner;\r\n    address public lotoAddress;\r\n    address payable public newVersionAddress;\r\n    EthexSuperprize previousContract;\r\n    uint256 public hold;\r\n    \r\n    event Superprize (\r\n        uint256 index,\r\n        uint256 amount,\r\n        address winner,\r\n        bytes16 betId,\r\n        byte state\r\n    );\r\n    \r\n    uint8 constant PARTS = 6;\r\n    uint256 constant PRECISION = 1 ether;\r\n    uint256 constant MONTHLY = 150000;\r\n     \r\n    constructor() public {\r\n        owner = msg.sender;\r\n    }\r\n     \r\n     modifier onlyOwner {\r\n        require(msg.sender == owner);\r\n        _;\r\n    }\r\n    \r\n    function() external payable { }\r\n    \r\n    function initSuperprize(address payable winner, bytes16 betId) external {\r\n        require(msg.sender == lotoAddress);\r\n        uint256 amount = address(this).balance - hold;\r\n        hold = address(this).balance;\r\n        uint256 sum;\r\n        uint256 temp;\r\n        for (uint256 i = 1; i \u003c PARTS; i++) {\r\n            temp = amount * PRECISION * (i - 1 + 10) / 75 / PRECISION;\r\n            sum += temp;\r\n            payouts.push(Payout(i, temp, block.number + i * MONTHLY, winner, betId));\r\n        }\r\n        payouts.push(Payout(PARTS, amount - sum, block.number + PARTS * MONTHLY, winner, betId));\r\n        emit Superprize(0, amount, winner, betId, 0);\r\n    }\r\n    \r\n    function paySuperprize() external onlyOwner {\r\n        if (payouts.length == 0)\r\n            return;\r\n        Payout[] memory payoutArray = new Payout[](payouts.length);\r\n        uint i = payouts.length;\r\n        while (i \u003e 0) {\r\n            i--;\r\n            if (payouts[i].block \u003c= block.number) {\r\n                emit Superprize(payouts[i].index, payouts[i].amount, payouts[i].winnerAddress, payouts[i].betId, 0x01);\r\n                hold -= payouts[i].amount;\r\n            }\r\n            payoutArray[i] = payouts[i];\r\n            payouts.pop();\r\n        }\r\n        for (i = 0; i \u003c payoutArray.length; i++)\r\n            if (payoutArray[i].block \u003e block.number)\r\n                payouts.push(payoutArray[i]);\r\n        for (i = 0; i \u003c payoutArray.length; i++)\r\n            if (payoutArray[i].block \u003c= block.number)\r\n                payoutArray[i].winnerAddress.transfer(payoutArray[i].amount);\r\n    }\r\n     \r\n    function setOldVersion(address payable oldAddress) external onlyOwner {\r\n        previousContract = EthexSuperprize(oldAddress);\r\n        lotoAddress = previousContract.lotoAddress();\r\n        hold = previousContract.hold();\r\n        uint256 index;\r\n        uint256 amount;\r\n        uint256 betBlock;\r\n        address payable winner;\r\n        bytes16 betId;\r\n        for (uint i = 0; i \u003c previousContract.getPayoutsCount(); i++) {\r\n            (index, amount, betBlock, winner, betId) = previousContract.payouts(i);\r\n            payouts.push(Payout(index, amount, betBlock, winner, betId));\r\n        }\r\n        previousContract.migrate();\r\n    }\r\n    \r\n    function setNewVersion(address payable newVersion) external onlyOwner {\r\n        newVersionAddress = newVersion;\r\n    }\r\n    \r\n    function setLoto(address loto) external onlyOwner {\r\n        lotoAddress = loto;\r\n    }\r\n    \r\n    function migrate() external {\r\n        require(msg.sender == owner || msg.sender == newVersionAddress);\r\n        require(newVersionAddress != address(0));\r\n        newVersionAddress.transfer(address(this).balance);\r\n    }   \r\n\r\n    function getPayoutsCount() view public returns (uint256) {\r\n        return payouts.length;\r\n    }\r\n}"}}
