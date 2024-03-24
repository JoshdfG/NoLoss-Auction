// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library FeeCalculator {
    // Function to calculate various fees based on the bid amount
    function calculateFees(
        uint _amount
    )
        internal
        pure
        returns (
            uint burnFee,
            uint daoFee,
            uint outbidRefund,
            uint teamFee,
            uint userFee
        )
    {
        // Calculate total fee as 10% of the bid amount
        uint totalFee = (_amount * 10) / 100;

        // Calculate individual fee amounts
        burnFee = (totalFee * 2) / 100;
        daoFee = (totalFee * 2) / 100;
        outbidRefund = (totalFee * 3) / 100;
        teamFee = (totalFee * 2) / 100;
        userFee = (totalFee * 1) / 100;

        return (burnFee, daoFee, outbidRefund, teamFee, userFee);
    }
}
