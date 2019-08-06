contract owned {
    function owned() {
        owner = msg.sender;
    }

    address public owner;

    modifier onlyowner { if (msg.sender != owner) throw; _; }

    event OwnershipTransfer(address indexed from, address indexed to);

    function transferOwnership(address to) public onlyowner {
        owner = to;
        OwnershipTransfer(msg.sender, to);
    }
}
 
 
contract ERC20 {
    function totalSupply() constant returns (uint supply);
    function balanceOf(address who) constant returns (uint value);
    function allowance(address owner, address spender) constant returns (uint _allowance);
    function transfer(address to, uint value) returns (bool ok);
    function transferFrom(address from, address to, uint value) returns (bool ok);
    function approve(address spender, uint value) returns (bool ok);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


contract Order is owned {
    ERC20 public token;
    uint public weiPerToken;
    uint public decimalPlaces;

    function Order(address _token, uint _weiPerToken, uint _decimalPlaces) {
        token = ERC20(_token);
        weiPerToken = _weiPerToken;
        decimalPlaces = _decimalPlaces;
    }

    function sendRobust(address to, uint value) internal {
        if (!to.send(value)) {
            if (!to.call.value(value)()) throw;
        }
    }

    function min(uint a, uint b) internal returns (uint) {
        if (a <= b) {
            return a;
        } else {
            return b;
        }
    }

    function getTransferableBalance(address who) internal returns (uint amount) {
        uint allowance = token.allowance(msg.sender, address(this));
        uint balance = token.balanceOf(msg.sender);

        amount = min(min(allowance, balance), numTokensAbleToPurchase());

        return amount;
    }

    function numTokensAbleToPurchase() constant returns (uint) {
        return (this.balance / weiPerToken) * decimalPlaces;
    }

    event OrderFilled(address _from, uint numTokens);

     
    function _fillOrder(address _from, uint numTokens) internal returns (bool) {
        if (numTokens == 0) throw;
        if (this.balance < numTokens * weiPerToken / decimalPlaces) throw;

        if (!token.transferFrom(_from, owner, numTokens)) return false;
        sendRobust(_from, numTokens * weiPerToken / decimalPlaces);
        OrderFilled(_from, numTokens);
        return true;
    }

    function fillOrder(address _from, uint numTokens) public returns (bool) {
        return _fillOrder(_from, numTokens);
    }

     
    function fillMyOrder(uint numTokens) public returns (bool) {
        return _fillOrder(msg.sender, numTokens);
    }

     
    function fillTheirOrder(address who) public returns (bool) {
        return _fillOrder(who, getTransferableBalance(who));
    }

     
     
    function fillOrderAuto() public returns (bool) {
        return _fillOrder(msg.sender, getTransferableBalance(msg.sender));
    }

     
    function () {
         
        if (msg.value > 0) {
            return;
        } else {
            fillOrderAuto();
        }
    }

     
    function cancel() onlyowner {
        selfdestruct(owner);
    }
}