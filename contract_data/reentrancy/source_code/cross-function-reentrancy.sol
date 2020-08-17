pragma solidity ^0.4.18;

contract crossFunctionReentrancy{
    mapping (address => bool) private claimedBonus;
    mapping (address => uint) private rewardsForA;

    function WithdrawReward(address recipient) public {
        uint amountToWithdraw = rewardsForA[recipient];
        rewardsForA[recipient] = 0;
        require(recipient.call.value(amountToWithdraw)());
    }

    function GetFirstWithdrawalBonus(address recipient) public {
        if (claimedBonus[recipient] == false) {
            throw;
        }
        rewardsForA[recipient] += 100;
        WithdrawReward(recipient);
        claimedBonus[recipient] = false;
    }
}
