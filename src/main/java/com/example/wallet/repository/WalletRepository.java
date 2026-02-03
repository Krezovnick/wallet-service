package com.example.wallet.repository;

import com.example.wallet.model.Wallet;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import jakarta.persistence.LockModeType;
import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface WalletRepository extends JpaRepository<Wallet, UUID> {
    
    Optional<Wallet> findByWalletId(UUID walletId);
    
    // Пессимистическая блокировка для конкурентных операций
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT w FROM Wallet w WHERE w.walletId = :walletId")
    Optional<Wallet> findByWalletIdWithLock(@Param("walletId") UUID walletId);
    
    boolean existsByWalletId(UUID walletId);
    
    // Оптимизированные операции для уменьшения блокировок
    @Modifying
    @Query("UPDATE Wallet w SET w.balance = w.balance + :amount, w.version = w.version + 1 WHERE w.walletId = :walletId")
    int deposit(@Param("walletId") UUID walletId, @Param("amount") BigDecimal amount);
    
    @Modifying
    @Query("UPDATE Wallet w SET w.balance = w.balance - :amount, w.version = w.version + 1 WHERE w.walletId = :walletId AND w.balance >= :amount")
    int withdraw(@Param("walletId") UUID walletId, @Param("amount") BigDecimal amount);
}
