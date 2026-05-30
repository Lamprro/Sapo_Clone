package com.example.Sapo_Clone.Repository;

import com.example.Sapo_Clone.Entity.PurchaseOrder;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;

@Repository
public interface PurchaseOrderRepository extends JpaRepository<PurchaseOrder, Integer> {

    @Query("SELECT p FROM PurchaseOrder p " +
           "WHERE p.store.company.id = :companyId " +
           "AND (:storeId IS NULL OR p.store.id = :storeId) " +
           "AND (:status IS NULL OR p.status = :status) " +
           "AND (:searching IS NULL OR " +
           "     CAST(p.id AS string) LIKE %:searching% OR " +
           "     p.provider.providerName LIKE %:searching%)")
    Page<PurchaseOrder> findByFilters(@Param("companyId") int companyId,
                                     @Param("storeId") Integer storeId, 
                                     @Param("status") Integer status, 
                                     @Param("searching") String searching, 
                                     Pageable pageable);

    @Query("SELECT SUM(p.totalAmount) FROM PurchaseOrder p " +
           "WHERE p.store.company.id = :companyId " +
           "AND (:storeId IS NULL OR p.store.id = :storeId) " +
           "AND p.status = 1 " + // 1 = COMPLETED
           "AND p.createdAt BETWEEN :start AND :end")
    Double sumTotalAmountByStoreAndDate(@Param("companyId") int companyId,
                                       @Param("storeId") Integer storeId, 
                                       @Param("start") LocalDateTime start, 
                                       @Param("end") LocalDateTime end);

    @Query("SELECT COUNT(p) FROM PurchaseOrder p " +
           "WHERE p.store.company.id = :companyId " +
           "AND (:storeId IS NULL OR p.store.id = :storeId) " +
           "AND p.status = 1 " + // 1 = COMPLETED
           "AND p.createdAt BETWEEN :start AND :end")
    Long countOrdersByStoreAndDate(@Param("companyId") int companyId,
                                  @Param("storeId") Integer storeId, 
                                  @Param("start") LocalDateTime start, 
                                  @Param("end") LocalDateTime end);
}
