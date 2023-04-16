pragma solidity ^0.8.0;

contract BSCtoCosmosBridge {
    
    address public bscToken;
    address public cosmosToken;
    address public bscBridge;
    address public cosmosBridge;
    
    constructor(address _bscToken, address _cosmosToken, address _bscBridge, address _cosmosBridge) {
        bscToken = _bscToken;
        cosmosToken = _cosmosToken;
        bscBridge = _bscBridge;
        cosmosBridge = _cosmosBridge;
    }
    
    function transferToCosmos(address recipient, uint amount) public {
        require(IBEP20(bscToken).balanceOf(msg.sender) >= amount, "Insufficient balance");
        require(IBEP20(bscToken).allowance(msg.sender, address(this)) >= amount, "Not enough allowance");
        
        IBEP20(bscToken).transferFrom(msg.sender, address(this), amount);
        IBEP20(bscToken).approve(bscBridge, amount);
        IBSCBridge(bscBridge).lockToken(bscToken, amount, recipient);
    }
    
    function receiveFromCosmos(uint amount) public {
        require(IERC20(cosmosToken).balanceOf(msg.sender) >= amount, "Insufficient balance");
        require(IERC20(cosmosToken).allowance(msg.sender, address(this)) >= amount, "Not enough allowance");
        
        IERC20(cosmosToken).transferFrom(msg.sender, address(this), amount);
        IERC20(cosmosToken).approve(cosmosBridge, amount);
        ICosmosBridge(cosmosBridge).burnToken(amount, msg.sender);
    }
    
    function updateBscToken(address newToken) public {
        require(msg.sender == owner, "Only owner can update BSC token");
        bscToken = newToken;
    }
    
    function updateCosmosToken(address newToken) public {
        require(msg.sender == owner, "Only owner can update Cosmos token");
        cosmosToken = newToken;
    }
    
    function updateBscBridge(address newBridge) public {
        require(msg.sender == owner, "Only owner can update BSC bridge");
        bscBridge = newBridge;
    }
    
    function updateCosmosBridge(address newBridge) public {
        require(msg.sender == owner, "Only owner can update Cosmos bridge");
        cosmosBridge = newBridge;
    }
