pragma solidity ^0.4.18;
contract SimpleMultiSig {

  uint public nonce;                 
  uint public threshold;             
  mapping (address => bool) isOwner;  
  address[] public ownersArr;         

  function SimpleMultiSig(uint threshold_, address[] owners_) public {
    require(owners_.length <= 10 && threshold_ <= owners_.length && threshold_ != 0);

    address lastAdd = address(0);
    for (uint i=0; i<owners_.length; i++) {
      require(owners_[i] > lastAdd);
      isOwner[owners_[i]] = true;
      lastAdd = owners_[i];
    }
    ownersArr = owners_;
    threshold = threshold_;
  }

   
  function execute(uint8[] sigV, bytes32[] sigR, bytes32[] sigS, address destination, uint value, bytes data) public {
    require(sigR.length == threshold);
    require(sigR.length == sigS.length && sigR.length == sigV.length);

     
    bytes32 txHash = keccak256(byte(0x19), byte(0), address(this), destination, value, data, nonce);

    address lastAdd = address(0);  
    for (uint i = 0; i < threshold; i++) {
      address recovered = ecrecover(txHash, sigV[i], sigR[i], sigS[i]);
      require(recovered > lastAdd && isOwner[recovered]);
      lastAdd = recovered;
    }

    nonce = nonce + 1;
    require(destination.call.value(value)(data));
  }

  function () public payable {}
}