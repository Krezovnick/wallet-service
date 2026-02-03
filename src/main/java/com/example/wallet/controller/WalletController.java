package com.example.wallet.controller;

import com.example.wallet.dto.*;
import com.example.wallet.model.Wallet;
import com.example.wallet.service.WalletService;
import io.micrometer.core.annotation.Timed;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/v1/wallets")
@RequiredArgsConstructor
public class WalletController {
    
    private final WalletService walletService;
    
    // POST /api/v1/wallets - как указано в задании
    @PostMapping
    @Timed(value = "wallet.operation.time", description = "Time taken to process wallet operation")
    public ResponseEntity<ApiResponse<WalletBalanceResponse>> processOperation(
            @Valid @RequestBody WalletOperationRequest request) {
        
        log.info("Processing {} operation for wallet: {}, amount: {}", 
                request.getOperationType(), request.getWalletId(), request.getAmount());
        
        try {
            // Используем оптимизированный метод для конкурентной обработки
            walletService.processOperationOptimized(request);
            
            // Получаем обновленный баланс
            WalletBalanceResponse balanceResponse = walletService.getWalletBalance(request.getWalletId());
            
            return ResponseEntity.ok(ApiResponse.success(balanceResponse));
            
        } catch (Exception e) {
            log.error("Error processing operation: {}", e.getMessage(), e);
            return ResponseEntity
                    .status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.error(e.getMessage(), "OPERATION_ERROR"));
        }
    }
    
    // GET /api/v1/wallets/{walletId} - как указано в задании
    @GetMapping("/{walletId}")
    @Timed(value = "wallet.balance.time", description = "Time taken to get wallet balance")
    public ResponseEntity<ApiResponse<WalletBalanceResponse>> getBalance(
            @PathVariable UUID walletId) {
        
        log.info("Getting balance for wallet: {}", walletId);
        
        try {
            WalletBalanceResponse balanceResponse = walletService.getWalletBalance(walletId);
            return ResponseEntity.ok(ApiResponse.success(balanceResponse));
        } catch (Exception e) {
            log.error("Error getting balance: {}", e.getMessage(), e);
            return ResponseEntity
                    .status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.error(e.getMessage(), "WALLET_NOT_FOUND"));
        }
    }
    
    // Дополнительный endpoint для создания кошелька (не в требованиях, но полезно для тестирования)
    @PostMapping("/{walletId}/create")
    @ResponseStatus(HttpStatus.CREATED)
    public ResponseEntity<ApiResponse<WalletBalanceResponse>> createWallet(
            @PathVariable UUID walletId,
            @RequestParam(defaultValue = "USD") String currency) {
        
        log.info("Creating wallet: {} with currency: {}", walletId, currency);
        
        try {
            Wallet wallet = walletService.createWallet(walletId, currency);
            
            WalletBalanceResponse response = WalletBalanceResponse.builder()
                    .walletId(wallet.getWalletId())
                    .balance(wallet.getBalance())
                    .currency(wallet.getCurrency())
                    .updatedAt(wallet.getUpdatedAt())
                    .active(wallet.isActive())
                    .build();
            
            return ResponseEntity
                    .status(HttpStatus.CREATED)
                    .body(ApiResponse.success(response));
        } catch (Exception e) {
            return ResponseEntity
                    .status(HttpStatus.CONFLICT)
                    .body(ApiResponse.error(e.getMessage(), "WALLET_ALREADY_EXISTS"));
        }
    }
    
    // Health check endpoint
    @GetMapping("/health")
    public ResponseEntity<ApiResponse<String>> health() {
        return ResponseEntity.ok(ApiResponse.success("Wallet Service is healthy"));
    }
}
