package com.example.wallet.exception;

import java.math.BigDecimal;
import java.util.UUID;

public class InsufficientFundsException extends RuntimeException {
    public InsufficientFundsException(UUID walletId, BigDecimal currentBalance, BigDecimal requiredAmount) {
        super(String.format(
            "Insufficient funds in wallet '%s'. Current balance: %s, Required amount: %s",
            walletId, currentBalance, requiredAmount
        ));
    }
}
