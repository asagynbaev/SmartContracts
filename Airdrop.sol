pragma solidity ^0.8.4;
// SPDX-License-Identifier: Unlicensed
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

abstract contract ReentrancyGuard {
   
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

   
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    

}




contract Airdrop is ReentrancyGuard, Context, Ownable {
    using SafeMath for uint256;
    
    mapping (address => uint256) public _contributions;

    IERC20 public _token;
    uint256 private _tokenDecimals;
    address payable public _wallet;
    uint256 public endAirdrop;
    uint public availableTokensAirdrop;

    event TokensPurchased(address  purchaser, address  beneficiary, uint256 value);
    constructor (address payable wallet,IERC20 token)  {
        require(address(token) != address(0), "Airdrop: token is the zero address");
        _token = token;
        _tokenDecimals = 18;
        _wallet = wallet;
    }


    receive () external payable {
        if(endAirdrop > 0 && block.timestamp < endAirdrop){
            claimAirdrop(_msgSender());
        }
        else{
            revert('Airdrop is closed');
        }
    }
    
    
    //Start Airdrop
    function startAirdrop() public onlyOwner AirdropNotActive() {
        availableTokensAirdrop = _token.balanceOf(address(this));
        require(availableTokensAirdrop > 0 && availableTokensAirdrop <= _token.totalSupply(), 'availableTokens should be > 0 and <= totalSupply');
        endAirdrop = 1629482400;
    }
    
    //Airdrop 
    function claimAirdrop(address beneficiary) public nonReentrant AirdropActive {
        uint256 tokens = 1000*10**18;
        availableTokensAirdrop = availableTokensAirdrop - tokens;
        _processPurchase(beneficiary, tokens);
        emit TokensPurchased(_msgSender(), beneficiary, tokens);
    }

    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.transfer(beneficiary, tokenAmount);
    }

 
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }

    function checkContribution(address addr) public view returns(uint256){
        return _contributions[addr];
    }
    
    function setAvailableTokens(uint256 amount) public onlyOwner AirdropNotActive{
        availableTokensAirdrop = amount;
    }
    
    function _forwardFunds() internal onlyOwner() {
        _wallet.transfer(msg.value);
    }
    
    // function withdraw() external onlyOwner AirdropNotActive{
    //      require(address(this).balance > 0, 'Contract has no money');
    //     _wallet.transfer(address(this).balance);    
    // }
    
    function _getTokensBack() external onlyOwner AirdropNotActive {
        _token.transfer(_wallet, availableTokensAirdrop);
    }
    
    
    modifier AirdropActive() {
        require(endAirdrop > 0 && block.timestamp < endAirdrop && availableTokensAirdrop > 0, "AirdropNotActive must be active");
        _;
    }
    
    modifier AirdropNotActive() {
        require(endAirdrop < block.timestamp, 'Airdrop should not be active');
        _;
    }
    
}