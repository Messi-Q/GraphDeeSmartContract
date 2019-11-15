pragma solidity ^0.4.13;

contract OracleInterface {
    struct PriceData {
        uint ARTTokenPrice;
        uint blockHeight;
    }

    mapping(uint => PriceData) public historicPricing;
    uint public index;
    address public owner;
    uint8 public decimals;

    function setPrice(uint price) public returns (uint _index) {}

    function getPrice() public view returns (uint price, uint _index, uint blockHeight) {}

    function getHistoricalPrice(uint _index) public view returns (uint price, uint blockHeight) {}

    event Updated(uint indexed price, uint indexed index);
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20Interface is ERC20Basic {
    uint8 public decimals;
}

contract HasNoTokens {

  
  function tokenFallback(address from_, uint256 value_, bytes data_) external {
    from_;
    value_;
    data_;
    revert();
  }

}

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract HasNoEther is Ownable {

   
  constructor() public payable {
    require(msg.value == 0);
  }

   
  function() external {
  }

   
  function reclaimEther() external onlyOwner {
    owner.transfer(address(this).balance);
  }
}

contract DutchAuction is Ownable, HasNoEther, HasNoTokens {

    using SafeMath for uint256;

     
    uint public min_shares_to_sell;
    uint public max_shares_to_sell;
    uint public min_share_price;
    uint public available_shares;

    bool private fundraise_defined;
    uint public fundraise_max;

     
    state public status = state.pending;
    enum state { pending, active, ended, decrypted, success, failure }

     
    event Started(uint block_number);
    event BidAdded(uint index);
    event Ended(uint block_number);
    event BidDecrypted(uint index, bool it_will_process);
    event FundraiseDefined(uint min_share_price, uint max);
    event BidBurned(uint index);
    event Decrypted(uint blocknumber, uint bids_decrypted, uint bids_burned);
    event Computed(uint index, uint share_price, uint shares_count);
    event Assigned(uint index, uint shares, uint executed_amout, uint refunded);
    event Refunded(uint index, uint refunded);
    event Success(uint raised, uint share_price, uint delivered_shares);
    event Failure(uint raised, uint share_price);

    event Execution(address destination,uint value,bytes data);
    event ExecutionFailure(address destination,uint value,bytes data);

     
    uint public final_share_price;
    uint public computed_fundraise;
    uint public final_fundraise;
    uint public computed_shares_sold;
    uint public final_shares_sold;
    uint public winner_bids;
    uint public assigned_bids;
    uint public assigned_shares;

     
    struct BidData {
        uint origin_index;
        uint bid_id;
        address investor_address;
        uint share_price;
        uint shares_count;
        uint transfer_valuation;
        uint transfer_token;
        uint asigned_shares_count;
        uint executed_amount;
        bool closed;
    }
    uint public bids_sorted_count;
    uint public bids_sorted_refunded;
    mapping (uint => BidData) public bids_sorted;  

    uint public bids_burned_count;
    mapping (uint => uint) public bids_burned;

    uint public bids_ignored_count;
    uint public bids_ignored_refunded;
    mapping (uint => BidData) public bids_ignored;


    uint public bids_decrypted_count;
    mapping (uint => uint) public bids_decrypted;
    uint private bids_reset_count;

    struct Bid {
         
        bytes32 bid_hash;
        uint art_price;
        uint art_price_index;
        bool exist;
        bool is_decrypted;
        bool is_burned;
        bool will_compute;
    }
    uint public bids_count;
    mapping (uint => Bid) public bids;

    uint public bids_computed_cursor;

    uint public shares_holders_count;
    mapping (uint => address) public shares_holders;
    mapping (address => uint) public shares_holders_balance;

     

    OracleInterface oracle;
    uint public oracle_price_decimals_factor;
    ERC20Interface art_token_contract;
    uint public decimal_precission_difference_factor;

     
     
     
     
     
     
    constructor(
        uint _min_shares_to_sell,
        uint _max_shares_to_sell,
        uint _available_shares,
        address _oracle,
        address _art_token_contract
    ) public {
        require(_max_shares_to_sell > 0);
        require(_max_shares_to_sell >= _min_shares_to_sell);
        require(_available_shares >= _max_shares_to_sell);
        require(_oracle != address(0x0));
        owner = msg.sender;
        min_shares_to_sell = _min_shares_to_sell;
        max_shares_to_sell = _max_shares_to_sell;
        available_shares = _available_shares;
        oracle = OracleInterface(_oracle);
        uint256 oracle_decimals = uint256(oracle.decimals());
        oracle_price_decimals_factor = 10**oracle_decimals;
        art_token_contract = ERC20Interface(_art_token_contract);
        uint256 art_token_decimals = uint256(art_token_contract.decimals());
        decimal_precission_difference_factor = 10**(art_token_decimals.sub(oracle_decimals));
    }

     
     
     
     
     
    function setFundraiseLimits(uint _min_share_price, uint _fundraise_max) public onlyOwner{
        require(!fundraise_defined);
        require(_min_share_price > 0);
        require(_fundraise_max > 0);
        require(status == state.ended);
        fundraise_max = _fundraise_max;
        min_share_price = _min_share_price;
        emit FundraiseDefined(min_share_price,fundraise_max);
        fundraise_defined = true;
    }

     
    function startAuction() public onlyOwner{
        require(status == state.pending);
        status = state.active;
        emit Started(block.number);
    }

     
    function endAuction() public onlyOwner{
        require(status == state.active);
        status = state.ended;
        emit Ended(block.number);
    }

     
     
     
    function appendEncryptedBid(bytes32 _bid_hash, uint price_index) public onlyOwner returns (uint index){
        require(status == state.active);
        uint art_price;
        uint art_price_blockHeight;
        (art_price, art_price_blockHeight) = oracle.getHistoricalPrice(price_index);
        bids[bids_count] = Bid(_bid_hash, art_price, price_index, true, false, false, false);
        index = bids_count;
        emit BidAdded(bids_count++);
    }

     
    function getBidHash(uint nonce, uint bid_id, address investor_address, uint share_price, uint shares_count) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(nonce, bid_id, investor_address, share_price, shares_count));
    }

     
     
     
    function burnBid(uint _index) public onlyOwner {
        require(status == state.ended);
        require(bids_sorted_count == 0);
        require(bids[_index].exist == true);
        require(bids[_index].is_decrypted == false);
        require(bids[_index].is_burned == false);
        
        bids_burned[bids_burned_count] = _index;
        bids_burned_count++;
        
        bids_decrypted[bids_decrypted_count] = _index;
        bids_decrypted_count++;

        bids[_index].is_burned = true;
        emit BidBurned(_index);
    }

     
     
     
     
     
     
     
     
     
     
     
    function appendDecryptedBid(uint _nonce, uint _index, uint _bid_id, address _investor_address, uint _share_price, uint _shares_count, uint _transfered_token) onlyOwner public {
        require(status == state.ended);
        require(fundraise_defined);
        require(bids[_index].exist == true);
        require(bids[_index].is_decrypted == false);
        require(bids[_index].is_burned == false);
        require(_share_price > 0);
        require(_shares_count > 0);
        require(_transfered_token >= convert_valuation_to_art(_shares_count.mul(_share_price),bids[_index].art_price));
        
        if (bids_sorted_count > 0){
            BidData memory previous_bid_data = bids_sorted[bids_sorted_count-1];
            require(_share_price <= previous_bid_data.share_price);
            if (_share_price == previous_bid_data.share_price){
                require(_index > previous_bid_data.origin_index);
            }
        }
        
        require(
            getBidHash(_nonce, _bid_id,_investor_address,_share_price,_shares_count) == bids[_index].bid_hash
        );
        
        uint _transfer_amount = _share_price.mul(_shares_count);
        
        BidData memory bid_data = BidData(_index, _bid_id, _investor_address, _share_price, _shares_count, _transfer_amount, _transfered_token, 0, 0, false);
        bids[_index].is_decrypted = true;
        
        if (_share_price >= min_share_price){
            bids[_index].will_compute = true;
            bids_sorted[bids_sorted_count] = bid_data;
            bids_sorted_count++;
            emit BidDecrypted(_index,true);
        }else{
            bids[_index].will_compute = false;
            bids_ignored[bids_ignored_count] = bid_data;
            bids_ignored_count++;
            emit BidDecrypted(_index,false);
        }
        bids_decrypted[bids_decrypted_count] = _index;
        bids_decrypted_count++;
        if(bids_decrypted_count == bids_count){
            emit Decrypted(block.number, bids_decrypted_count.sub(bids_burned_count), bids_burned_count);
            status = state.decrypted;
        }
    }

     
     
    function appendDecryptedBids(uint[] _nonce, uint[] _index, uint[] _bid_id, address[] _investor_address, uint[] _share_price, uint[] _shares_count, uint[] _transfered_token) public onlyOwner {
        require(_nonce.length == _index.length);
        require(_index.length == _bid_id.length);
        require(_bid_id.length == _investor_address.length);
        require(_investor_address.length == _share_price.length);
        require(_share_price.length == _shares_count.length);
        require(_shares_count.length == _transfered_token.length);
        require(bids_count.sub(bids_decrypted_count) > 0);
        for (uint i = 0; i < _index.length; i++){
            appendDecryptedBid(_nonce[i], _index[i], _bid_id[i], _investor_address[i], _share_price[i], _shares_count[i], _transfered_token[i]);
        }
    }

     
     
    function resetAppendDecryptedBids(uint _count) public onlyOwner{
        require(status == state.ended);
        require(bids_decrypted_count > 0);
        require(_count > 0);
        if (bids_reset_count == 0){
            bids_reset_count = bids_decrypted_count;
        }
        uint count = _count;
        if(bids_reset_count < count){
            count = bids_reset_count;
        }

        do {
            bids_reset_count--;
            bids[bids_decrypted[bids_reset_count]].is_decrypted = false;
            bids[bids_decrypted[bids_reset_count]].is_burned = false;
            bids[bids_decrypted[bids_reset_count]].will_compute = false;
            count--;
        } while(count > 0);
        
        if (bids_reset_count == 0){
            bids_sorted_count = 0;
            bids_ignored_count = 0;
            bids_decrypted_count = 0;
            bids_burned_count = 0;
        }
    }

     
     
     
     
     
     
     
     
     
    function computeBids(uint _count) public onlyOwner{
        require(status == state.decrypted);
        require(_count > 0);
        uint count = _count;
         
        if (bids_sorted_count == 0){
            status = state.failure;
            emit Failure(0, 0);
            return;
        }
         
         
        require(bids_computed_cursor < bids_sorted_count);
        
         
        BidData memory bid;

        do{
             
            bid = bids_sorted[bids_computed_cursor];
             
             
            if (bid.share_price.mul(computed_shares_sold).add(bid.share_price) > fundraise_max){
                if(bids_computed_cursor > 0){
                    bids_computed_cursor--;
                }
                bid = bids_sorted[bids_computed_cursor];
                break;
            }
             
            computed_shares_sold = computed_shares_sold.add(bid.shares_count);
             
            computed_fundraise = bid.share_price.mul(computed_shares_sold);
            emit Computed(bid.origin_index, bid.share_price, bid.shares_count);
             
            bids_computed_cursor++;
            count--;
        }while(
            count > 0 &&  
            bids_computed_cursor < bids_sorted_count &&  
            (
                computed_fundraise < fundraise_max &&  
                computed_shares_sold < max_shares_to_sell  
            )
        );

        if (
            bids_computed_cursor == bids_sorted_count ||   
            computed_fundraise >= fundraise_max || 
            computed_shares_sold >= max_shares_to_sell 
        ){
            
            final_share_price = bid.share_price;
            
             
            if(computed_shares_sold >= max_shares_to_sell){
                computed_shares_sold = max_shares_to_sell; 
                computed_fundraise = final_share_price.mul(computed_shares_sold);
                winner_bids = bids_computed_cursor;
                status = state.success;
                emit Success(computed_fundraise, final_share_price, computed_shares_sold);
                return;            
            }

             
            if(computed_fundraise.add(final_share_price.mul(1)) >= fundraise_max){ 
                computed_fundraise = fundraise_max; 
                winner_bids = bids_computed_cursor;
                status = state.success;
                emit Success(computed_fundraise, final_share_price, computed_shares_sold);
                return;
            }
            
             
            if (bids_computed_cursor == bids_sorted_count){
                if (computed_shares_sold >= min_shares_to_sell){
                    winner_bids = bids_computed_cursor;
                    status = state.success;
                    emit Success(computed_fundraise, final_share_price, computed_shares_sold);
                    return;
                }else{
                    status = state.failure;
                    emit Failure(computed_fundraise, final_share_price);
                    return;
                }
            }
        }
    }

     
     
    function convert_valuation_to_art(uint _valuation, uint _art_price) view public returns(uint amount){
        amount = ((
                _valuation.mul(oracle_price_decimals_factor)
            ).div(
                _art_price
            )).mul(decimal_precission_difference_factor);
    }

     
     
     
     
     
    function refundIgnoredBids(uint _count) public onlyOwner{
        require(status == state.success || status == state.failure);
        uint count = _count;
        if(bids_ignored_count < bids_ignored_refunded.add(count)){
            count = bids_ignored_count.sub(bids_ignored_refunded);
        }
        require(count > 0);
        uint cursor = bids_ignored_refunded;
        bids_ignored_refunded = bids_ignored_refunded.add(count);
        BidData storage bid;
        while (count > 0) {
            bid = bids_ignored[cursor];
            if(bid.closed){
                continue;
            }
            bid.closed = true;
            art_token_contract.transfer(bid.investor_address, bid.transfer_token);
            emit Refunded(bid.origin_index, bid.transfer_token);
            cursor ++;
            count --;
        }
    }

     
     
     
     
     
    function refundLosersBids(uint _count) public onlyOwner{
        require(status == state.success || status == state.failure);
        uint count = _count;
        if(bids_sorted_count.sub(winner_bids) < bids_sorted_refunded.add(count)){
            count = bids_sorted_count.sub(winner_bids).sub(bids_sorted_refunded);
        }
        require(count > 0);
        uint cursor = bids_sorted_refunded.add(winner_bids);
        bids_sorted_refunded = bids_sorted_refunded.add(count);
        BidData memory bid;
        while (count > 0) {
            bid = bids_sorted[cursor];
            if(bid.closed){
                continue;
            }
            bids_sorted[cursor].closed = true;
            art_token_contract.transfer(bid.investor_address, bid.transfer_token);
            emit Refunded(bid.origin_index, bid.transfer_token);
            cursor ++;
            count --;
        }
    }

     
     
     
     
     
     
    function calculate_shares_and_return(uint _shares_count, uint _share_price, uint _transfer_valuation, uint _final_share_price, uint _art_price, uint transfer_token) view public 
        returns(
            uint _shares_to_assign,
            uint _executed_amount_valuation,
            uint _return_amount
        ){
        if(assigned_shares.add(_shares_count) > max_shares_to_sell){
            _shares_to_assign = max_shares_to_sell.sub(assigned_shares);
        }else{
            _shares_to_assign = _shares_count;
        }
        _executed_amount_valuation = _shares_to_assign.mul(_final_share_price);
        if (final_fundraise.add(_executed_amount_valuation) > fundraise_max){
            _executed_amount_valuation = fundraise_max.sub(final_fundraise);
            _shares_to_assign = _executed_amount_valuation.div(_final_share_price);
            _executed_amount_valuation = _shares_to_assign.mul(_final_share_price);
        }
        uint _executed_amount = convert_valuation_to_art(_executed_amount_valuation, _art_price);
        _return_amount = transfer_token.sub(_executed_amount);
    }


     
     
     
     
     
    function assignShareTokens(uint _count) public onlyOwner{
        require(status == state.success);
        uint count = _count;
        if(winner_bids < assigned_bids.add(count)){
            count = winner_bids.sub(assigned_bids);
        }
        require(count > 0);
        uint cursor = assigned_bids;
        assigned_bids = assigned_bids.add(count);
        BidData storage bid;

        while (count > 0) {
            bid = bids_sorted[cursor];
            uint _shares_to_assign;
            uint _executed_amount_valuation;
            uint _return_amount;
            (_shares_to_assign, _executed_amount_valuation, _return_amount) = calculate_shares_and_return(
                bid.shares_count,
                bid.share_price,
                bid.transfer_valuation,
                final_share_price,
                bids[bid.origin_index].art_price,
                bid.transfer_token
            );
            bid.executed_amount = _executed_amount_valuation;
            bid.asigned_shares_count = _shares_to_assign;
            assigned_shares = assigned_shares.add(_shares_to_assign);
            final_fundraise = final_fundraise.add(_executed_amount_valuation);
            final_shares_sold = final_shares_sold.add(_shares_to_assign);
            if(_return_amount > 0){
                art_token_contract.transfer(bid.investor_address, _return_amount);
            }
            bid.closed = true;
            if (shares_holders_balance[bid.investor_address] == 0){
                shares_holders[shares_holders_count++] = bid.investor_address;
            }
            emit Assigned(bid.origin_index,_shares_to_assign, _executed_amount_valuation, _return_amount);
            shares_holders_balance[bid.investor_address] = shares_holders_balance[bid.investor_address].add(_shares_to_assign);
            cursor ++;
            count --;
        }
    }

     
    function getShareBalance() view public returns (uint256 share_balance){
        require(status == state.success);
        require(winner_bids == assigned_bids);
        share_balance = shares_holders_balance[msg.sender];
    }

     
    function reclaimToken(ERC20Basic token) external onlyOwner {
        require(token != art_token_contract);
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
    }

    function reclaim_art_token() external onlyOwner {
        require(status == state.success || status == state.failure);
        require(winner_bids == assigned_bids);
        uint256 balance = art_token_contract.balanceOf(this);
        art_token_contract.transfer(owner, balance); 
    }

     
    function executeTransaction(address destination, uint value, bytes data) public onlyOwner{
        if (destination.call.value(value)(data))
            emit Execution(destination,value,data);
        else
            emit ExecutionFailure(destination,value,data);
    }
}

library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}