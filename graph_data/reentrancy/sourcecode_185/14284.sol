pragma solidity ^0.4.21;

 


 
contract AcceptsHalo3D {
    Halo3D public tokenContract;

    function AcceptsHalo3D(address _tokenContract) public {
        tokenContract = Halo3D(_tokenContract);
    }

    modifier onlyTokenContract {
        require(msg.sender == address(tokenContract));
        _;
    }

     
    function tokenFallback(address _from, uint256 _value, bytes _data) external returns (bool);
}


contract Halo3D {
     
     
    modifier onlyBagholders() {
        require(myTokens() > 0);
        _;
    }

     
    modifier onlyStronghands() {
        require(myDividends(true) > 0);
        _;
    }

    modifier notContract() {
      require (msg.sender == tx.origin);
      _;
    }

     
     
     
     
     
     
     
     
     
    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress]);
        _;
    }


     
     
     
    modifier antiEarlyWhale(uint256 _amountOfEthereum){
        address _customerAddress = msg.sender;

         
         
        if( onlyAmbassadors && ((totalEthereumBalance() - _amountOfEthereum) <= ambassadorQuota_ )){
            require(
                 
                ambassadors_[_customerAddress] == true &&

                 
                (ambassadorAccumulatedQuota_[_customerAddress] + _amountOfEthereum) <= ambassadorMaxPurchase_

            );

             
            ambassadorAccumulatedQuota_[_customerAddress] = SafeMath.add(ambassadorAccumulatedQuota_[_customerAddress], _amountOfEthereum);

             
            _;
        } else {
             
            onlyAmbassadors = false;
            _;
        }

    }

     
    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address indexed referredBy
    );

    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 ethereumEarned
    );

    event onReinvestment(
        address indexed customerAddress,
        uint256 ethereumReinvested,
        uint256 tokensMinted
    );

    event onWithdraw(
        address indexed customerAddress,
        uint256 ethereumWithdrawn
    );

     
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );


     
    string public name = "Halo3D";
    string public symbol = "H3D";
    uint8 constant public decimals = 18;
    uint8 constant internal dividendFee_ = 20;  
    uint8 constant internal charityFee_ = 2;  
    uint256 constant internal tokenPriceInitial_ = 0.0000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;
    uint256 constant internal magnitude = 2**64;

     
     
     
    address constant public giveEthCharityAddress = 0x5ADF43DD006c6C36506e2b2DFA352E60002d22Dc;
    uint256 public totalEthCharityRecieved;  
    uint256 public totalEthCharityCollected;  

     
    uint256 public stakingRequirement = 100e18;

     
    mapping(address => bool) internal ambassadors_;
    uint256 constant internal ambassadorMaxPurchase_ = 0.4 ether;
    uint256 constant internal ambassadorQuota_ = 10 ether;



    
     
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) internal ambassadorAccumulatedQuota_;
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;

     
    mapping(address => bool) public administrators;

     
    bool public onlyAmbassadors = true;

     
    mapping(address => bool) public canAcceptTokens_;  



     
     
    function Halo3D()
        public
    {
         
        administrators[0xf4cFeD6A0f869548F73f05a364B329b86B6Bb157] = true;

         
        ambassadors_[0xf4cFeD6A0f869548F73f05a364B329b86B6Bb157] = true;
         
        ambassadors_[0xe436cbd3892c6dc3d6c8a3580153e6e0fa613cfc] = true;
         
        ambassadors_[0x922cFfa33A078B4Cc6077923e43447d8467F8B55] = true;
         
        ambassadors_[0x8Dd512843c24c382210a9CcC9C98B8b5eEED97e8] = true;
         
        ambassadors_[0x4ffe17a2a72bc7422cb176bc71c04ee6d87ce329] = true;
         
        ambassadors_[0x3747EaFE2Bc9cB5221879758ca24a0d15B47A9B6] = true;
         
        ambassadors_[0xB38094D492af4FfffF760707F36869713bFb2250] = true;
         
        ambassadors_[0xBa21d01125D6932ce8ABf3625977899Fd2C7fa30] = true;
         
        ambassadors_[0x2e6236591bfa37c683ce60d6cfde40396a114ff1] = true;
         
        ambassadors_[0xa683C1b815997a7Fa38f6178c84675FC4c79AC2B] = true;
         
        ambassadors_[0x84ECB387395a1be65E133c75Ff9e5FCC6F756DB3] = true;
         
        ambassadors_[0x05f2c11996d73288AbE8a31d8b593a693FF2E5D8] = true;
         
        ambassadors_[0x5632CA98e5788edDB2397757Aa82d1Ed6171e5aD] = true;
         
        ambassadors_[0xA790fa6422A15a3637885f6811e5428de3513169] = true;
         
        ambassadors_[0x008ca4F1bA79D1A265617c6206d7884ee8108a78] = true;
         
        ambassadors_[0x7c377B7bCe53a5CEF88458b2cBBe11C3babe16DA] = true;
         
        ambassadors_[0x183feBd8828a9ac6c70C0e27FbF441b93004fC05] = true;
         
        ambassadors_[0x29A9c76aD091c015C12081A1B201c3ea56884579] = true;
    }


     
    function buy(address _referredBy)
        public
        payable
        returns(uint256)
    {
        purchaseInternal(msg.value, _referredBy);
    }

     
    function()
        payable
        public
    {
        purchaseInternal(msg.value, 0x0);
    }

     
    function payCharity() payable public {
      uint256 ethToPay = SafeMath.sub(totalEthCharityCollected, totalEthCharityRecieved);
      require(ethToPay > 1);
      totalEthCharityRecieved = SafeMath.add(totalEthCharityRecieved, ethToPay);
      if(!giveEthCharityAddress.call.value(ethToPay).gas(400000)()) {
         totalEthCharityRecieved = SafeMath.sub(totalEthCharityRecieved, ethToPay);
      }
    }

     
    function reinvest()
        onlyStronghands()
        public
    {
         
        uint256 _dividends = myDividends(false);  

         
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);

         
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

         
        uint256 _tokens = purchaseTokens(_dividends, 0x0);

         
        onReinvestment(_customerAddress, _dividends, _tokens);
    }

     
    function exit()
        public
    {
         
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if(_tokens > 0) sell(_tokens);

         
        withdraw();
    }

     
    function withdraw()
        onlyStronghands()
        public
    {
         
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false);  

         
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);

         
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

         
        _customerAddress.transfer(_dividends);

         
        onWithdraw(_customerAddress, _dividends);
    }

     
    function sell(uint256 _amountOfTokens)
        onlyBagholders()
        public
    {
         
        address _customerAddress = msg.sender;
         
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);

        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_), 100);
        uint256 _charityPayout = SafeMath.div(SafeMath.mul(_ethereum, charityFee_), 100);

         
        uint256 _taxedEthereum =  SafeMath.sub(SafeMath.sub(_ethereum, _dividends), _charityPayout);

         
        totalEthCharityCollected = SafeMath.add(totalEthCharityCollected, _charityPayout);

         
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);

         
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedEthereum * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;

         
        if (tokenSupply_ > 0) {
             
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }

         
        onTokenSell(_customerAddress, _tokens, _taxedEthereum);
    }


     
    function transfer(address _toAddress, uint256 _amountOfTokens)
        onlyBagholders()
        public
        returns(bool)
    {
         
        address _customerAddress = msg.sender;

         
         
         
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

         
        if(myDividends(true) > 0) withdraw();

         
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);

         
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _amountOfTokens);


         
        Transfer(_customerAddress, _toAddress, _amountOfTokens);

         
        return true;
    }

     
    function transferAndCall(address _to, uint256 _value, bytes _data) external returns (bool) {
      require(_to != address(0));
      require(canAcceptTokens_[_to] == true);  
      require(transfer(_to, _value));  

      if (isContract(_to)) {
        AcceptsHalo3D receiver = AcceptsHalo3D(_to);
        require(receiver.tokenFallback(msg.sender, _value, _data));
      }

      return true;
    }

     
     function isContract(address _addr) private constant returns (bool is_contract) {
        
       uint length;
       assembly { length := extcodesize(_addr) }
       return length > 0;
     }

     
     
    function disableInitialStage()
        onlyAdministrator()
        public
    {
        onlyAmbassadors = false;
    }

     
    function setAdministrator(address _identifier, bool _status)
        onlyAdministrator()
        public
    {
        administrators[_identifier] = _status;
    }

     
    function setStakingRequirement(uint256 _amountOfTokens)
        onlyAdministrator()
        public
    {
        stakingRequirement = _amountOfTokens;
    }

     
    function setCanAcceptTokens(address _address, bool _value)
      onlyAdministrator()
      public
    {
      canAcceptTokens_[_address] = _value;
    }

     
    function setName(string _name)
        onlyAdministrator()
        public
    {
        name = _name;
    }

     
    function setSymbol(string _symbol)
        onlyAdministrator()
        public
    {
        symbol = _symbol;
    }


     
     
    function totalEthereumBalance()
        public
        view
        returns(uint)
    {
        return this.balance;
    }

     
    function totalSupply()
        public
        view
        returns(uint256)
    {
        return tokenSupply_;
    }

     
    function myTokens()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

     
    function myDividends(bool _includeReferralBonus)
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
    }

     
    function balanceOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return tokenBalanceLedger_[_customerAddress];
    }

     
    function dividendsOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return (uint256) ((int256)(profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }

     
    function sellPrice()
        public
        view
        returns(uint256)
    {
         
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_), 100);
            uint256 _charityPayout = SafeMath.div(SafeMath.mul(_ethereum, charityFee_), 100);
            uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_ethereum, _dividends), _charityPayout);
            return _taxedEthereum;
        }
    }

     
    function buyPrice()
        public
        view
        returns(uint256)
    {
         
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_), 100);
            uint256 _charityPayout = SafeMath.div(SafeMath.mul(_ethereum, charityFee_), 100);
            uint256 _taxedEthereum =  SafeMath.add(SafeMath.add(_ethereum, _dividends), _charityPayout);
            return _taxedEthereum;
        }
    }

     
    function calculateTokensReceived(uint256 _ethereumToSpend)
        public
        view
        returns(uint256)
    {
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereumToSpend, dividendFee_), 100);
        uint256 _charityPayout = SafeMath.div(SafeMath.mul(_ethereumToSpend, charityFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_ethereumToSpend, _dividends), _charityPayout);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        return _amountOfTokens;
    }

     
    function calculateEthereumReceived(uint256 _tokensToSell)
        public
        view
        returns(uint256)
    {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_), 100);
        uint256 _charityPayout = SafeMath.div(SafeMath.mul(_ethereum, charityFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_ethereum, _dividends), _charityPayout);
        return _taxedEthereum;
    }

     
    function etherToSendCharity()
        public
        view
        returns(uint256) {
        return SafeMath.sub(totalEthCharityCollected, totalEthCharityRecieved);
    }


     

     
    function purchaseInternal(uint256 _incomingEthereum, address _referredBy)
      notContract() 
      internal
      returns(uint256) {

      uint256 purchaseEthereum = _incomingEthereum;
      uint256 excess;
      if(purchaseEthereum > 5 ether) {  
          if (SafeMath.sub(address(this).balance, purchaseEthereum) <= 100 ether) {  
              purchaseEthereum = 5 ether;
              excess = SafeMath.sub(_incomingEthereum, purchaseEthereum);
          }
      }

      purchaseTokens(purchaseEthereum, _referredBy);

      if (excess > 0) {
        msg.sender.transfer(excess);
      }
    }


    function purchaseTokens(uint256 _incomingEthereum, address _referredBy)
        antiEarlyWhale(_incomingEthereum)
        internal
        returns(uint256)
    {
         
        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingEthereum, dividendFee_), 100);
        uint256 _referralBonus = SafeMath.div(_undividedDividends, 3);
        uint256 _charityPayout = SafeMath.div(SafeMath.mul(_incomingEthereum, charityFee_), 100);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_incomingEthereum, _undividedDividends), _charityPayout);

        totalEthCharityCollected = SafeMath.add(totalEthCharityCollected, _charityPayout);

        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        uint256 _fee = _dividends * magnitude;

         
         
         
         
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));

         
        if(
             
            _referredBy != 0x0000000000000000000000000000000000000000 &&

             
            _referredBy != msg.sender &&

             
             
            tokenBalanceLedger_[_referredBy] >= stakingRequirement
        ){
             
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
        } else {
             
             
            _dividends = SafeMath.add(_dividends, _referralBonus);
            _fee = _dividends * magnitude;
        }

         
        if(tokenSupply_ > 0){

             
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);

             
            profitPerShare_ += (_dividends * magnitude / (tokenSupply_));

             
            _fee = _fee - (_fee-(_amountOfTokens * (_dividends * magnitude / (tokenSupply_))));

        } else {
             
            tokenSupply_ = _amountOfTokens;
        }

         
        tokenBalanceLedger_[msg.sender] = SafeMath.add(tokenBalanceLedger_[msg.sender], _amountOfTokens);

         
         
        int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
        payoutsTo_[msg.sender] += _updatedPayouts;

         
        onTokenPurchase(msg.sender, _incomingEthereum, _amountOfTokens, _referredBy);

        return _amountOfTokens;
    }

     
    function ethereumToTokens_(uint256 _ethereum)
        internal
        view
        returns(uint256)
    {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
        uint256 _tokensReceived =
         (
            (
                 
                SafeMath.sub(
                    (sqrt
                        (
                            (_tokenPriceInitial**2)
                            +
                            (2*(tokenPriceIncremental_ * 1e18)*(_ethereum * 1e18))
                            +
                            (((tokenPriceIncremental_)**2)*(tokenSupply_**2))
                            +
                            (2*(tokenPriceIncremental_)*_tokenPriceInitial*tokenSupply_)
                        )
                    ), _tokenPriceInitial
                )
            )/(tokenPriceIncremental_)
        )-(tokenSupply_)
        ;

        return _tokensReceived;
    }

     
     function tokensToEthereum_(uint256 _tokens)
        internal
        view
        returns(uint256)
    {

        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (tokenSupply_ + 1e18);
        uint256 _etherReceived =
        (
             
            SafeMath.sub(
                (
                    (
                        (
                            tokenPriceInitial_ +(tokenPriceIncremental_ * (_tokenSupply/1e18))
                        )-tokenPriceIncremental_
                    )*(tokens_ - 1e18)
                ),(tokenPriceIncremental_*((tokens_**2-tokens_)/1e18))/2
            )
        /1e18);
        return _etherReceived;
    }


     
     
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}