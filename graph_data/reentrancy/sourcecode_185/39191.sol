 

 
 
library AccountingLib {
         
        struct Bank {
            mapping (address => uint) accountBalances;
        }

         
         
         
         
        function addFunds(Bank storage self, address accountAddress, uint value) public {
                if (self.accountBalances[accountAddress] + value < self.accountBalances[accountAddress]) {
                         
                        throw;
                }
                self.accountBalances[accountAddress] += value;
        }

        event _Deposit(address indexed _from, address indexed accountAddress, uint value);
         
         
         
         
        function Deposit(address _from, address accountAddress, uint value) public {
            _Deposit(_from, accountAddress, value);
        }


         
         
         
         
        function deposit(Bank storage self, address accountAddress, uint value) public returns (bool) {
                addFunds(self, accountAddress, value);
                return true;
        }

        event _Withdrawal(address indexed accountAddress, uint value);

         
         
         
        function Withdrawal(address accountAddress, uint value) public {
            _Withdrawal(accountAddress, value);
        }

        event _InsufficientFunds(address indexed accountAddress, uint value, uint balance);

         
         
         
         
        function InsufficientFunds(address accountAddress, uint value, uint balance) public {
            _InsufficientFunds(accountAddress, value, balance);
        }

         
         
         
         
        function deductFunds(Bank storage self, address accountAddress, uint value) public {
                 
                if (value > self.accountBalances[accountAddress]) {
                         
                        throw;
                }
                self.accountBalances[accountAddress] -= value;
        }

         
         
         
         
        function withdraw(Bank storage self, address accountAddress, uint value) public returns (bool) {
                 
                if (self.accountBalances[accountAddress] >= value) {
                        deductFunds(self, accountAddress, value);
                        if (!accountAddress.send(value)) {
                                if (!accountAddress.call.value(value)()) {  throw; }
                        }
                        return true;
                }
                return false;
        }

        uint constant DEFAULT_SEND_GAS = 100000;

        function sendRobust(address toAddress, uint value) public returns (bool) {
                if (msg.gas < DEFAULT_SEND_GAS) {
                    return sendRobust(toAddress, value, msg.gas);
                }
                return sendRobust(toAddress, value, DEFAULT_SEND_GAS);
        }

        function sendRobust(address toAddress, uint value, uint maxGas) public returns (bool) {
                if (value > 0 && !toAddress.send(value)) {
                         
                         
                         
                        if (!toAddress.call.gas(maxGas).value(value)()) {
                                return false;
                        }
                }
                return true;
        }
}