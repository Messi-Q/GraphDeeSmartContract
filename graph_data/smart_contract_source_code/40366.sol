contract TriWallet {
   
  bool public thisIsFork;

   
  address public etcWallet;

   
  address public ethWallet;

   
  event ETCWalletCreated(address etcWalletAddress);

   
  event ETHWalletCreated(address ethWalletAddress);

   
  function TriWallet () {
     
    thisIsFork = BranchSender (0x23141df767233776f7cbbec497800ddedaa4c684).isRightBranch ();
    
     
    etcWallet = new BranchWallet (msg.sender, !thisIsFork);
    
     
    ethWallet = new BranchWallet (msg.sender, thisIsFork);
  
     
    ETCWalletCreated (etcWallet);

     
    ETHWalletCreated (ethWallet);
  }

   
  function distribute () {
    if (thisIsFork) {
       
      if (!ethWallet.send (this.balance)) throw;
    } else {
       
      if (!etcWallet.send (this.balance)) throw;
    }
  }
}

 
contract BranchWallet {
   
  address public owner;
    
   
   
  bool public isRightBranch;

   
   
   
   
  function BranchWallet (address _owner, bool _isRightBranch) {
    owner = _owner;
    isRightBranch = _isRightBranch;
  }

   
  function () {
    if (!isRightBranch) throw;
  }

   
   
   
   
   
  function send (address _to, uint _value) {
    if (!isRightBranch) throw;
    if (msg.sender != owner) throw;
    if (!_to.send (_value)) throw;
  }


  function execute(address _to, uint _value, bytes _data) {
    if (!isRightBranch) throw;
    if (msg.sender != owner) throw;
    if (!_to.call.value (_value)(_data)) throw;
  }
}

 
 
contract BranchSender {
   
   
  bool public isRightBranch;
}