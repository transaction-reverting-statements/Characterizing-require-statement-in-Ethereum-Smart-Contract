{"erc-otc.sol":{"content":"// erc-otc.sol\r\n//\r\n// This program is free software: you can redistribute it and/or modify it\r\n//\r\n// This program is distributed in the hope that it will be useful,\r\n// but WITHOUT ANY WARRANTY; without even the implied warranty of\r\n// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.\r\n//\r\n\r\npragma solidity ^0.4.18;\r\n\r\nimport \"./math.sol\";\r\n\r\ncontract ERC20Events {\r\n    event Approval(address indexed src, address indexed guy, uint wad);\r\n    event Transfer(address indexed src, address indexed dst, uint wad);\r\n}\r\n\r\ncontract ERC20 is ERC20Events {\r\n    function totalSupply() public view returns (uint);\r\n    function balanceOf(address guy) public view returns (uint);\r\n    function allowance(address src, address guy) public view returns (uint);\r\n\r\n    function approve(address guy, uint wad) public returns (bool);\r\n    function transfer(address dst, uint wad) public returns (bool);\r\n    function transferFrom(address src, address dst, uint wad) public returns (bool);\r\n}\r\n\r\ncontract EventfulMarket {\r\n\r\n    event LogMake(\r\n        bytes32  indexed  id,\r\n        address  indexed  maker,\r\n        uint           pay_amt,\r\n        uint           buy_amt,\r\n        address     erc20Address,\r\n        uint64            timestamp,\r\n        uint              escrowType\r\n    );\r\n\r\n    event LogTake(\r\n        bytes32           id,\r\n        address  indexed  maker,\r\n        address  indexed  taker,\r\n        uint          take_amt,\r\n        uint           give_amt,\r\n        address     erc20Address,\r\n        uint64            timestamp,\r\n        uint              escrowType\r\n    );\r\n\r\n    event LogKill(\r\n        bytes32  indexed  id,\r\n        address  indexed  maker,\r\n        uint           pay_amt,\r\n        uint           buy_amt,\r\n        address     erc20Address,\r\n        uint64            timestamp,\r\n        uint              escrowType\r\n    );\r\n}\r\n\r\ncontract ERCOTC is EventfulMarket, DSMath {\r\n\r\n    address devAddress;\r\n    uint constant devFee = 500; //500 for 0.2%;\r\n    \r\n    uint public last_offer_id;\r\n    uint public last_token_id;\r\n    mapping (uint =\u003e OfferInfo) public offers;\r\n    mapping (uint =\u003e address) public tokens;\r\n    mapping (address =\u003e bool) public validToken;\r\n    \r\n    bool locked;\r\n\r\n    struct OfferInfo {\r\n        uint     pay_amt;\r\n        uint     buy_amt;\r\n        address  owner;\r\n        uint64   timestamp;\r\n        bytes32  offerId;\r\n        address  erc20Address;\r\n        uint     escrowType; //0 ERC - 1 ETH\r\n    }\r\n\r\n    modifier can_buy(uint id) {\r\n        require(isActive(id), \"cannot buy, offer ID not active\");\r\n        _;\r\n    }\r\n\r\n    modifier can_cancel(uint id) {\r\n        require(isActive(id), \"cannot cancel, offer ID not active\");\r\n        require(getOwner(id) == msg.sender, \"cannot cancel, msg.sender not the same as offer maker\");\r\n        _;\r\n    }\r\n\r\n    modifier can_offer {\r\n        _;\r\n    }\r\n\r\n    modifier synchronized {\r\n        require(!locked, \"Sync lock\");\r\n        locked = true;\r\n        _;\r\n        locked = false;\r\n    }\r\n\r\n    constructor() public{\r\n        devAddress = msg.sender;\r\n    }\r\n\r\n    function isActive(uint id) public view returns (bool active) {\r\n        return offers[id].timestamp \u003e 0;\r\n    }\r\n\r\n    function getOwner(uint id) public view returns (address owner) {\r\n        return offers[id].owner;\r\n    }\r\n\r\n    function getOffer(uint id) public view returns (uint, uint, address, bytes32) {\r\n      var offer = offers[id];\r\n      return (offer.pay_amt, offer.buy_amt, offer.erc20Address, offer.offerId);\r\n    }\r\n\r\n    // ---- Public entrypoints ---- //\r\n\r\n    function addERC(address erc20Address)\r\n        public\r\n    {\r\n        require(erc20Address != address(0));\r\n        require(isContract(erc20Address));\r\n        require(validToken[erc20Address] == false);\r\n        tokens[_next_token_id()] = erc20Address;\r\n        validToken[erc20Address] = true;\r\n    }\r\n        \r\n    // Transfers funds from caller to\r\n    // offer maker, and from market to caller.\r\n    function buyERC(uint id, address ref)\r\n        public\r\n        payable\r\n        can_buy(id)\r\n        synchronized\r\n        returns (bool)\r\n    {\r\n        OfferInfo memory offer = offers[id];\r\n        ERC20 erc20Interface = ERC20(offers[id].erc20Address);\r\n        require(offer.escrowType == 0, \"Incorrect escrow type\");\r\n        require(msg.value \u003e 0 \u0026\u0026 msg.value == offer.buy_amt, \"msg.value error\");\r\n        require(offer.buy_amt \u003e 0 \u0026\u0026 offer.pay_amt \u003e 0);\r\n\r\n        //calc amounts\r\n        uint ethValue = sub(offer.buy_amt, (offer.buy_amt / devFee));\r\n        uint erc20Value = sub(offer.pay_amt, (offer.pay_amt / devFee));\r\n        uint ethFee;\r\n        uint erc20Fee;\r\n        if(ref == address(0)){//no ref\r\n            ethFee = offer.buy_amt / devFee;//0.2%\r\n            erc20Fee = offer.pay_amt / devFee;//0.2%\r\n            //send\r\n            offer.owner.transfer(ethValue);//send eth to offer maker (seller)\r\n            devAddress.transfer(ethFee);//send eth devfee\r\n            require(erc20Interface.transfer(msg.sender, erc20Value), \"Transfer failed\"); //send escrowed token from contract to offer taker (buyer)\r\n            require(erc20Interface.transfer(devAddress, erc20Fee), \"Dev Transfer failed\"); //send token devfee\r\n        }\r\n        else{//ref (50% of devfee)\r\n            ethFee = offer.buy_amt / mul(devFee, 2);//0.1% (send twice)\r\n            erc20Fee = offer.pay_amt / mul(devFee, 2);//0.1% (send twice)\r\n            //send\r\n            offer.owner.transfer(ethValue);//send eth to offer maker (seller)\r\n            devAddress.transfer(ethFee);//send eth devfee\r\n            ref.transfer(ethFee);//send eth to refferer\r\n            require(erc20Interface.transfer(msg.sender, erc20Value), \"Transfer failed\"); //send escrowed token from contract to offer taker (buyer)\r\n            require(erc20Interface.transfer(devAddress, erc20Fee), \"Dev Transfer failed\"); //send token devfee\r\n            require(erc20Interface.transfer(ref, erc20Fee), \"Ref Transfer failed\"); //send token devfee\r\n        }\r\n\r\n        //events\r\n        emit LogTake(\r\n            bytes32(id),\r\n            offer.owner,\r\n            msg.sender,\r\n            uint(erc20Value),\r\n            uint(ethValue),\r\n            offer.erc20Address,\r\n            uint64(now),\r\n            offer.escrowType\r\n        );\r\n\r\n        //delete offer\r\n        offers[id].pay_amt = 0;\r\n        offers[id].buy_amt = 0;\r\n        delete offers[id];\r\n        \r\n        return true;\r\n    }\r\n\r\n    // Transfers funds from caller to\r\n    // offer maker, and from market to caller.\r\n    function buyETH(uint id, address ref)\r\n        public\r\n        can_buy(id)\r\n        synchronized\r\n        returns (bool)\r\n    {\r\n        OfferInfo memory offer = offers[id];\r\n        ERC20 erc20Interface = ERC20(offers[id].erc20Address);\r\n        require(offer.escrowType == 1, \"Incorrect escrow type\");\r\n        require(erc20Interface.balanceOf(msg.sender) \u003e=  offer.buy_amt, \"Balance is less than requested spend amount\");\r\n        require(offer.pay_amt \u003e 0 \u0026\u0026 offer.buy_amt \u003e 0);\r\n        //calc amounts\r\n        uint ethValue = sub(offer.pay_amt, (offer.pay_amt/ devFee));\r\n        uint erc20Value = sub(offer.buy_amt, (offer.buy_amt / devFee));\r\n        uint ethFee;\r\n        uint erc20Fee;\r\n        if(ref == address(0)){//no ref\r\n            ethFee = offer.pay_amt / devFee;//0.2%\r\n            erc20Fee = erc20Fee / devFee;//0.2%\r\n            //send\r\n            require(erc20Interface.transferFrom(msg.sender, offer.owner, erc20Value), \"Transfer failed\");//send token to offer maker (seller)\r\n            require(erc20Interface.transferFrom(msg.sender, devAddress, erc20Fee), \"Dev transfer failed\");//send token devfee\r\n            msg.sender.transfer(ethValue);//send ETH to offer taker (buyer)\r\n            devAddress.transfer(ethFee);//send eth devfee\r\n        }\r\n         else{//ref\r\n            ethFee =  offer.pay_amt / mul(devFee, 2);//0.1% (send twice)\r\n            erc20Fee = erc20Fee / mul(devFee, 2);//0.1% (send twice)\r\n            //send\r\n            require(erc20Interface.transferFrom(msg.sender, offer.owner, erc20Value), \"Transfer failed\");//send token to offer maker (seller)\r\n            require(erc20Interface.transferFrom(msg.sender, devAddress, erc20Fee), \"Dev Transfer failed\");//send token devfee\r\n            require(erc20Interface.transferFrom(msg.sender, ref, erc20Fee), \"Ref transfer failed\");//send token devfee\r\n            msg.sender.transfer(ethValue);//send ETH to offer taker (buyer)\r\n            devAddress.transfer(ethFee);//send eth devfee\r\n            ref.transfer(ethFee);//send eth to ref\r\n         }\r\n\r\n        //events\r\n        emit LogTake(\r\n            bytes32(id),\r\n            offer.owner,\r\n            msg.sender,\r\n            uint(offer.buy_amt),\r\n            uint(offer.pay_amt),\r\n            offer.erc20Address,\r\n            uint64(now),\r\n            offer.escrowType\r\n        );\r\n        \r\n        //delete offer\r\n        offers[id].pay_amt = 0;\r\n        offers[id].buy_amt = 0;\r\n        delete offers[id];\r\n\r\n        return true;\r\n    }\r\n\r\n    // cancel an offer, refunds offer maker.\r\n    function cancel(uint id)\r\n        public\r\n        can_cancel(id)\r\n        synchronized\r\n        returns (bool success)\r\n    {\r\n        // read-only offer. Modify an offer by directly accessing offers[id]\r\n        OfferInfo memory offer = offers[id];\r\n        delete offers[id];\r\n        ERC20 erc20Interface = ERC20(offer.erc20Address);\r\n        if(offer.escrowType == 0){ // erc\r\n            require(erc20Interface.transfer(offer.owner, offer.pay_amt), \"Transfer failed\");\r\n        }\r\n        else{ //eth\r\n            offer.owner.transfer(offer.pay_amt);\r\n        }\r\n        emit LogKill(\r\n            bytes32(id),\r\n            offer.owner,\r\n            uint(offer.pay_amt),\r\n            uint(offer.buy_amt),\r\n            offer.erc20Address,\r\n            uint64(now),\r\n            offer.escrowType\r\n        );\r\n\r\n        success = true;\r\n    }\r\n\r\n    //cancel\r\n    function kill(bytes32 id)\r\n        public\r\n    {\r\n        require(cancel(uint256(id)), \"Error on cancel order.\");\r\n    }\r\n\r\n    //make\r\n    function make(\r\n        uint  pay_amt,\r\n        uint  buy_amt,\r\n        address erc20Address\r\n    )\r\n        public\r\n        payable\r\n        returns (bytes32 id)\r\n    {\r\n        if(msg.value \u003e 0){\r\n            return bytes32(offerETH(pay_amt, buy_amt, erc20Address));\r\n        }\r\n        else{\r\n            return bytes32(offerERC(pay_amt, buy_amt, erc20Address));\r\n        }\r\n    }\r\n\r\n    // make a new offer to sell ETH. Takes ETH funds from the caller into market escrow.\r\n    function offerETH(uint pay_amt, uint buy_amt, address erc20Address) //amounts in wei / token\r\n        public\r\n        payable\r\n        can_offer\r\n        synchronized\r\n        returns (uint id)\r\n    {\r\n        //check amounts\r\n        require(pay_amt \u003e 0, \"pay_amt is 0\");\r\n        require(buy_amt \u003e 0, \"buy_amt is 0\");\r\n        require(pay_amt == msg.value, \"pay_amt not equal to msg.value\");\r\n        //check address\r\n        require(erc20Address != address(0));\r\n        require(isContract(erc20Address));\r\n        require(validToken[erc20Address]);\r\n        //create new offer, no need to call transfer msg.value is escrowed\r\n        newOffer(id, pay_amt, buy_amt, erc20Address, 1);\r\n        emit LogMake(\r\n            bytes32(id),\r\n            msg.sender,\r\n            uint(pay_amt),\r\n            uint(buy_amt),\r\n            erc20Address,\r\n            uint64(now),\r\n            1\r\n        );\r\n    }\r\n\r\n    // make a new offer to sell token. Takes token funds from the caller into market escrow.\r\n    function offerERC(uint pay_amt, uint buy_amt, address erc20Address) //amounts in token / wei\r\n        public\r\n        can_offer\r\n        synchronized\r\n        returns (uint id)\r\n    {\r\n        //check amounts\r\n        require(pay_amt \u003e 0, \"pay_amt is 0\");\r\n        require(buy_amt \u003e 0,  \"buy_amt is 0\");\r\n        //check address\r\n        require(erc20Address != address(0));\r\n        require(isContract(erc20Address));\r\n        require(validToken[erc20Address]);\r\n        //check erc balance\r\n        ERC20 erc20Interface = ERC20(erc20Address);\r\n        require(erc20Interface.balanceOf(msg.sender) \u003e= pay_amt, \"Insufficient balanceOf token\");\r\n        //create new offer\r\n        newOffer(id, pay_amt, buy_amt, erc20Address, 0);\r\n        //make transfer to escrow\r\n        require(erc20Interface.transferFrom(msg.sender, address(this), pay_amt), \"Transfer failed\");\r\n\r\n        emit LogMake(\r\n            bytes32(id),\r\n            msg.sender,\r\n            uint(pay_amt),\r\n            uint(buy_amt),\r\n            erc20Address,\r\n            uint64(now),\r\n            0\r\n        );\r\n    }\r\n\r\n    //formulate new offer\r\n    function newOffer(uint id, uint pay_amt, uint buy_amt, address erc20Address, uint escrowType)\r\n        internal\r\n    {\r\n        OfferInfo memory info;\r\n        info.pay_amt = pay_amt;\r\n        info.buy_amt = buy_amt;\r\n        info.owner = msg.sender;\r\n        info.timestamp = uint64(now);\r\n        info.erc20Address = erc20Address;\r\n        info.escrowType = escrowType;\r\n        id = _next_id();\r\n        info.offerId = bytes32(id);\r\n        offers[id] = info;\r\n    }\r\n\r\n    //take\r\n    function take(bytes32 id, address ref)\r\n        public\r\n        payable\r\n    {\r\n        if(msg.value \u003e 0){\r\n            require(buyERC(uint256(id), ref), \"Buy ERC failed\");\r\n        }\r\n        else{\r\n            require(buyETH(uint256(id), ref), \"Sell ERC failed\");\r\n        }\r\n\r\n    }\r\n\r\n    //is contract? subject to reentrancy attack yet not applicable with currect require checks, just extra security\r\n    function isContract(address addr) internal view returns (bool) {\r\n        uint size;\r\n        assembly { size := extcodesize(addr) }\r\n        return size \u003e 0;\r\n    }\r\n    \r\n    //get next id\r\n    function _next_id()\r\n        internal\r\n        returns (uint)\r\n    {\r\n        last_offer_id++;\r\n        return last_offer_id;\r\n    }\r\n\r\n        //get next id\r\n    function _next_token_id()\r\n        internal\r\n        returns (uint)\r\n    {\r\n        last_token_id++;\r\n        return last_token_id;\r\n    }\r\n}"},"math.sol":{"content":"/// math.sol -- mixin for inline numerical wizardry\r\n\r\n// This program is free software: you can redistribute it and/or modify\r\n// it under the terms of the GNU General Public License as published by\r\n// the Free Software Foundation, either version 3 of the License, or\r\n// (at your option) any later version.\r\n\r\n// This program is distributed in the hope that it will be useful,\r\n// but WITHOUT ANY WARRANTY; without even the implied warranty of\r\n// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\r\n// GNU General Public License for more details.\r\n\r\n// You should have received a copy of the GNU General Public License\r\n// along with this program.  If not, see \u003chttp://www.gnu.org/licenses/\u003e.\r\n\r\npragma solidity ^0.4.13;\r\n\r\ncontract DSMath {\r\n    function add(uint x, uint y) internal pure returns (uint z) {\r\n        require((z = x + y) \u003e= x);\r\n    }\r\n    function sub(uint x, uint y) internal pure returns (uint z) {\r\n        require((z = x - y) \u003c= x);\r\n    }\r\n    function mul(uint x, uint y) internal pure returns (uint z) {\r\n        require(y == 0 || (z = x * y) / y == x);\r\n    }\r\n\r\n    function min(uint x, uint y) internal pure returns (uint z) {\r\n        return x \u003c= y ? x : y;\r\n    }\r\n    function max(uint x, uint y) internal pure returns (uint z) {\r\n        return x \u003e= y ? x : y;\r\n    }\r\n    function imin(int x, int y) internal pure returns (int z) {\r\n        return x \u003c= y ? x : y;\r\n    }\r\n    function imax(int x, int y) internal pure returns (int z) {\r\n        return x \u003e= y ? x : y;\r\n    }\r\n\r\n    uint constant WAD = 10 ** 18;\r\n    uint constant RAY = 10 ** 27;\r\n\r\n    function wmul(uint x, uint y) internal pure returns (uint z) {\r\n        z = add(mul(x, y), WAD / 2) / WAD;\r\n    }\r\n    function rmul(uint x, uint y) internal pure returns (uint z) {\r\n        z = add(mul(x, y), RAY / 2) / RAY;\r\n    }\r\n    function wdiv(uint x, uint y) internal pure returns (uint z) {\r\n        z = add(mul(x, WAD), y / 2) / y;\r\n    }\r\n    function rdiv(uint x, uint y) internal pure returns (uint z) {\r\n        z = add(mul(x, RAY), y / 2) / y;\r\n    }\r\n\r\n    // This famous algorithm is called \"exponentiation by squaring\"\r\n    // and calculates x^n with x as fixed-point and n as regular unsigned.\r\n    //\r\n    // It\u0027s O(log n), instead of O(n) for naive repeated multiplication.\r\n    //\r\n    // These facts are why it works:\r\n    //\r\n    //  If n is even, then x^n = (x^2)^(n/2).\r\n    //  If n is odd,  then x^n = x * x^(n-1),\r\n    //   and applying the equation for even x gives\r\n    //    x^n = x * (x^2)^((n-1) / 2).\r\n    //\r\n    //  Also, EVM division is flooring and\r\n    //    floor[(n-1) / 2] = floor[n / 2].\r\n    //\r\n    function rpow(uint x, uint n) internal pure returns (uint z) {\r\n        z = n % 2 != 0 ? x : RAY;\r\n\r\n        for (n /= 2; n != 0; n /= 2) {\r\n            x = rmul(x, x);\r\n\r\n            if (n % 2 != 0) {\r\n                z = rmul(z, x);\r\n            }\r\n        }\r\n    }\r\n}"}}
