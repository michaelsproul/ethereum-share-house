pragma solidity ^0.4.0;

contract Sharehouse {
    struct Housemate {
        address addr;
        string name;
        int balance;
        bool approved;
    }

    struct Expense {
        string name;
        uint amount;
        address payer;
        bool approved;
    }

    Housemate[] public housemates;
    Expense[] public expenses;

    function Sharehouse(string creatorName) payable {
        housemates.push(Housemate({
            addr: msg.sender,
            name: creatorName,
            balance: int(msg.value),
            approved: true
        }));
    }

    // Modifier that requires the caller to be an approved housemate.
    modifier onlyHousemates() {
        require(isHousemate(msg.sender));
        _;
    }

    function requestToJoin(string name) payable {
        // If already a housemate or already requested to join, error.
        if (isHousemate(msg.sender) || isJoining(msg.sender)) throw;

        housemates.push(Housemate({
            addr: msg.sender,
            name: name,
            balance: int(msg.value),
            approved: false
        }));
    }

    // Return true if the approval was successful, false if they were already approved.
    function approveJoinRequest(address toApprove) onlyHousemates returns (bool) {
        // Only people who are joining can be approved.
        var (isRegistered, idx) = indexOf(toApprove);
        require(isRegistered);

        if (housemates[idx].approved) {
            return false;
        } else {
            housemates[idx].approved = true;
            return true;
        }
    }

    /// Tell the house about a purchase you made on its behalf.
    // TODO: publish an event for this!
    function fileExpense(string name, uint amount) onlyHousemates
        returns (uint id)
    {
        id = expenses.length;
        expenses.push(Expense({
            name: name,
            amount: amount,
            payer: msg.sender,
            approved: false
        }));
    }

    /// Approve an expense filed by someone else, and re-adjust balances accordingly.
    function approveExpense(uint id) onlyHousemates returns (bool) {
        Expense expense = expenses[id];

        // You can't approve your own expenses.
        require(expense.payer != msg.sender);

        // You can't approve already approved expenses.
        if (expense.approved) {
            return false;
        }
        expense.approved = true;

        // Size of each individual's share of the expense.
        // TODO: think carefully about rounding issues...
        uint share = expense.amount / numHousemates();

        // Update everyone's balances accordingly.
        // TODO: does it really make sense to allow negative balances?
        for (uint i = 0; i < housemates.length; i++) {
            Housemate housemate = housemates[i];

            // Skip unapproved housemates.
            if (!housemate.approved) {
                continue;
            }

            if (housemate.addr == expense.payer) {
                housemate.balance += int(share);
            } else {
                housemate.balance -= int(share);
            }
        }

        return true;
    }

    /// Number of housemates who are waiting to join.
    function numWaitingToJoin() returns (uint) {
        return housemates.length - numHousemates();
    }

    /// Number of approved housemates.
    function numHousemates() returns (uint) {
        uint total = 0;
        for (uint i = 0; i < housemates.length; i++) {
            if (housemates[i].approved) {
                total++;
            }
        }
        return total;
    }

    /// Find the index of a housemate with a given address.
    /// Return (true, i) if such a housemate exists, or (false, 0) otherwise.
    function indexOf(address addr) private returns (bool, uint) {
        for (uint i = 0; i < housemates.length; i++) {
            if (housemates[i].addr == addr) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    /// Check if the address is that of an approved housemate.
    function isHousemate(address addr) returns (bool) {
        var (inList, idx) = indexOf(addr);
        return inList && housemates[idx].approved;
    }

    /// Check if the address is that of an unapproved housemate.
    function isJoining(address addr) returns (bool) {
        var (inList, idx) = indexOf(addr);
        return inList && !housemates[idx].approved;
    }
}
