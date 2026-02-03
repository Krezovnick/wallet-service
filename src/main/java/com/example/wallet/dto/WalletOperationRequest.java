package com.example.wallet.dto;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.*;
import lombok.Data;

import java.math.BigDecimal;
import java.util.UUID;

@Data
public class WalletOperationRequest {
    
    @NotNull(message = "Wallet ID is required")
    private UUID walletId;
    
    @NotNull(message = "Operation type is required")
    private OperationType operationType;
    
    @NotNull(message = "Amount is required")
    @DecimalMin(value = "0.01", message = "Amount must be greater than 0")
    @DecimalMax(value = "1000000", message = "Amount must be less than 1,000,000")
    private BigDecimal amount;
    
    private String reference;
    
    @JsonCreator
    public WalletOperationRequest(
            @JsonProperty("walletId") UUID walletId,
            @JsonProperty("operationType") OperationType operationType,
            @JsonProperty("amount") BigDecimal amount,
            @JsonProperty("reference") String reference) {
        this.walletId = walletId;
        this.operationType = operationType;
        this.amount = amount;
        this.reference = reference;
    }
}
