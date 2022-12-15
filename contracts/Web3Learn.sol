// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
/**
Buy
 教材を購入する際の関数
 JPYCもしくはUSDC が送られているのかを確認
 購入した瞬間に、UserはClaimできるようにMappingの値が追加される

 */

// 一旦, ETHは入れない
contract Web3Learn is ReentrancyGuard {

    using SafeERC20 for IERC20; 

    /*********************************************************************************************
     ************************************   VARIABLES     ****************************************
     *********************************************************************************************/

    uint256 constant TOTAL_RATIO = 10000;    
    address payable public owner;
    mapping(address => bool) whitelist; // JPYC, USDC
    mapping(address => mapping(address => uint256)) reward; // payee -> token -> amount

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

    /*********************************************************************************************
     *********************************   PUBLIC FUNCTIONS     ************************************
     *********************************************************************************************/

    function claimReard(address token, uint amount) public nonReentrant {
        if(amount > _getReward(msg.sender, token)) revert();
        reward[msg.sender][token] -= amount;
        SafeERC20.safeTransfer(IERC20(token), msg.sender, amount);
    }
    
    function buy(uint amount, address receivedToken, address sendingToken, Split[] memory splits) external nonReentrant {
        if(!whitelist[sendingToken]) revert();
        if(receivedToken != sendingToken) revert();
        if(!_checkRatio(splits)) revert();
        address ADDRESS_THIS = address(this);
        uint beforeBalance = IERC20(sendingToken).balanceOf(ADDRESS_THIS);
        SafeERC20.safeTransferFrom(IERC20(sendingToken), msg.sender, ADDRESS_THIS, amount);
        uint afterBalance = IERC20(sendingToken).balanceOf(ADDRESS_THIS);
        uint actualBalance = afterBalance - beforeBalance;
        setClaimableAmounts(sendingToken,actualBalance,splits);
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
            unchecked { ++i;}
        }

        uint gap = amount - totalAmounts;
        if(gap != 0) reward[msg.sender][token] += gap;
    }
}
