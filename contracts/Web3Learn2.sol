// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// 一旦, ETHは入れない
contract Web3Learn is ReentrancyGuard {

    using SafeERC20 for IERC20; 
    address constant DEMO_ADDRESS = 0x6EE96FA35b26d3F8Cd249A4cba6617D8189BfB5d;
    // sender == msg.sender, amount == transferred amount, token == tokenAddress success: true == 1, false == 0
    event Buy(
        address indexed sender,  
        address indexed token, 
        uint indexed amount, 
        bool success
    );


    event SetSplit(
        address indexed sender,  
        address indexed token, 
        uint indexed amount
    );


    /*********************************************************************************************
     ************************************   VARIABLES     ****************************************
     *********************************************************************************************/

    uint256 constant TOTAL_RATIO = 10000;    
    address payable public owner;
    mapping(address => bool) whitelist; // JPYC, USDC
    mapping(address => mapping(address => uint256)) reward; // payee -> token -> amount
    mapping(address => uint256[]) buyList; // address = walletAddress uint256[] = 購入したコンテンツID

    /*********************************************************************************************
     ************************************     STRUCT     ****************************************
     *********************************************************************************************/
    
    struct Split {
        uint256 ratio; // 100% == 10000  e.g) 5% = 500
        address payee;
    }

    /*********************************************************************************************
     ************************************    MODEFIER     ****************************************
     *********************************************************************************************/

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /*********************************************************************************************
     **********************************    CONSTRUCTOR     ***************************************
     *********************************************************************************************/

    constructor() {
        owner = payable(msg.sender);
    }

    /*********************************************************************************************
     *********************************   OWNER FUNCTIONS     *************************************
     *********************************************************************************************/

    function addWhitelist(address token) external onlyOwner {
        whitelist[token] = true;
    }

    function removeWhitelist(address token) external onlyOwner {
        whitelist[token] = false;
    }

    /*********************************************************************************************
     *******************************   VIEW | PURE FUNCTIONS     *********************************
     *********************************************************************************************/

    function _isWhitelistedToken(address token) public view returns(bool isWhitelisted_) {
        isWhitelisted_ = whitelist[token];
    }
    function _getReward(address user, address token) public view returns(uint canClaimAmount_) {
        canClaimAmount_ = reward[user][token];
    }
    function _checkRatio(Split[] memory splits) public pure returns(bool isValid_){
        uint length = splits.length;
        uint totalRatio;
        for(uint i; i < length;) {
            totalRatio += splits[i].ratio;
            unchecked { ++i;}
        }
        isValid_ = (totalRatio == TOTAL_RATIO);
    }

    ///こっちがOK

   function getBuyLists(address user) public view returns (uint256[] memory){
        uint length = buyList[user].length;
        uint256[] memory ret = new uint256[](length);
        for (uint i = 0; i < length; i++) {
            ret[i] = buyList[user][i];
        }
        return ret;
    }

    /*********************************************************************************************
     *********************************   PUBLIC FUNCTIONS     ************************************
     *********************************************************************************************/

    function claimReard(address token, uint amount) public nonReentrant {
        if(amount > _getReward(msg.sender, token)) revert();
        reward[msg.sender][token] -= amount;
        SafeERC20.safeTransfer(IERC20(token), msg.sender, amount);
    }
    
    function buy(uint amount, uint256 id, address token, Split[] memory splits) external nonReentrant {
        // if(!whitelist[token]) revert();
        require(token == DEMO_ADDRESS,"Invalid Token");

        if(!_checkRatio(splits)) revert();

        address ADDRESS_THIS = address(this);

        uint beforeBalance = IERC20(token).balanceOf(ADDRESS_THIS);
        IERC20(token).safeTransferFrom(msg.sender,ADDRESS_THIS,amount);

        uint afterBalance = IERC20(token).balanceOf(ADDRESS_THIS);
    

        uint actualBalance = afterBalance - beforeBalance;

        setClaimableAmounts(token,actualBalance,splits);

        buyList[msg.sender].push(id); // add

        emit Buy(msg.sender, token, amount, true);
    }

    /*********************************************************************************************
     *********************************   PRIVATE FUNCTIONS     ***********************************
     *********************************************************************************************/

    function setClaimableAmounts(address token, uint256 amount, Split[] memory splits) private {

        uint length = splits.length;
        uint totalAmounts;

        for(uint i; i < length;) {


            uint claimableAmount = amount * splits[i].ratio / 10000;
            reward[splits[i].payee][token] += claimableAmount;
            totalAmounts += claimableAmount;

            emit SetSplit(splits[i].payee, token, claimableAmount);
            unchecked { ++i;}
        }

        uint gap = amount - totalAmounts;
        if(gap != 0) reward[msg.sender][token] += gap;
    }
}

