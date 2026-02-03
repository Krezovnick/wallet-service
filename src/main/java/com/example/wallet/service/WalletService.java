package com.example.wallet.service;

import com.example.wallet.dto.OperationType;
import com.example.wallet.dto.WalletBalanceResponse;
import com.example.wallet.dto.WalletOperationRequest;
import com.example.wallet.exception.*;
import com.example.wallet.model.Wallet;
import com.example.wallet.repository.WalletRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.OptimisticLockingFailureException;
import org.springframework.retry.annotation.Backoff;
import org.springframework.retry.annotation.Retryable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class WalletService {
    
    private final WalletRepository walletRepository;
    
    @Transactional(readOnly = true)
    public WalletBalanceResponse getWalletBalance(UUID walletId) {
        Wallet wallet = walletRepository.findByWalletId(walletId)
                .orElseThrow(() -> new WalletNotFoundException(walletId));
        
        return WalletBalanceResponse.builder()
                .walletId(wallet.getWalletId())
                .balance(wallet.getBalance())
                .currency(wallet.getCurrency())
                .updatedAt(wallet.getUpdatedAt())
                .active(wallet.isActive())
                .build();
    }
    
    // Основной метод с оптимистической блокировкой и ретраями
    @Transactional(isolation = Isolation.READ_COMMITTED)
    @Retryable(
            retryFor = {OptimisticLockingFailureException.class},
            maxAttempts = 5,
            backoff = @Backoff(delay = 100, multiplier = 2)
    )
    public Wallet processOperation(WalletOperationRequest request) {
        // Валидация входных данных
        validateOperationRequest(request);
        
        // Используем пессимистическую блокировку для конкурентного доступа
        Wallet wallet = walletRepository.findByWalletIdWithLock(request.getWalletId())
                .orElseThrow(() -> new WalletNotFoundException(request.getWalletId()));
        
        if (!wallet.isActive()) {
            throw new RuntimeException("Wallet is inactive");
        }
        
        BigDecimal amount = request.getAmount();
        
        if (request.getOperationType() == OperationType.DEPOSIT) {
            wallet.deposit(amount);
            log.info("Deposited {} to wallet {}", amount, request.getWalletId());
        } else {
            if (!wallet.hasSufficientFunds(amount)) {
                throw new InsufficientFundsException(
                    request.getWalletId(), 
                    wallet.getBalance(), 
                    amount
                );
            }
            wallet.withdraw(amount);
            log.info("Withdrew {} from wallet {}", amount, request.getWalletId());
        }
        
        return walletRepository.save(wallet);
    }
    
    // Альтернативный метод с оптимизированными UPDATE запросами (меньше блокировок)
    @Transactional(isolation = Isolation.SERIALIZABLE)
    @Retryable(
            retryFor = {OptimisticLockingFailureException.class},
            maxAttempts = 3,
            backoff = @Backoff(delay = 50, multiplier = 2)
    )
    public boolean processOperationOptimized(WalletOperationRequest request) {
        validateOperationRequest(request);
        
        if (request.getOperationType() == OperationType.DEPOSIT) {
            int updated = walletRepository.deposit(request.getWalletId(), request.getAmount());
            if (updated == 0) {
                throw new WalletNotFoundException(request.getWalletId());
            }
            return true;
        } else {
            int updated = walletRepository.withdraw(request.getWalletId(), request.getAmount());
            if (updated == 0) {
                // Проверяем, существует ли кошелек
                if (!walletRepository.existsByWalletId(request.getWalletId())) {
                    throw new WalletNotFoundException(request.getWalletId());
                }
                // Если кошелек существует, значит недостаточно средств
                Wallet wallet = walletRepository.findByWalletId(request.getWalletId())
                        .orElseThrow(() -> new WalletNotFoundException(request.getWalletId()));
                throw new InsufficientFundsException(
                    request.getWalletId(),
                    wallet.getBalance(),
                    request.getAmount()
                );
            }
            return true;
        }
    }
    
    @Transactional
    public Wallet createWallet(UUID walletId, String currency) {
        if (walletRepository.existsByWalletId(walletId)) {
            throw new RuntimeException("Wallet already exists: " + walletId);
        }
        
        Wallet wallet = Wallet.builder()
                .walletId(walletId)
                .currency(currency != null && !currency.isEmpty() ? currency : "USD")
                .balance(BigDecimal.ZERO)
                .active(true)
                .build();
        
        return walletRepository.save(wallet);
    }
    
    private void validateOperationRequest(WalletOperationRequest request) {
        if (request.getAmount() == null || request.getAmount().compareTo(BigDecimal.ZERO) <= 0) {
            throw new InvalidAmountException("Amount must be greater than zero");
        }
        
        if (request.getOperationType() == null) {
            throw new RuntimeException("Operation type is required");
        }
        
        if (request.getWalletId() == null) {
            throw new RuntimeException("Wallet ID is required");
        }
    }
}
