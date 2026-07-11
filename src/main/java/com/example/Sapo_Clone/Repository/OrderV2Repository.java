package com.example.Sapo_Clone.Repository;

import com.example.Sapo_Clone.Entity.OrderV2;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface OrderV2Repository extends JpaRepository<OrderV2, Integer> {

    @Query(value = "SELECT o FROM OrderV2 o JOIN FETCH o.customer c WHERE " +
                  "o.store.company.id = :companyId AND " +
                  "(:customerId IS NULL OR c.id = :customerId) AND " +
                  "(:storeId IS NULL OR o.store.id = :storeId) AND " +
                  "(:status IS NULL OR :status = -1 OR o.status = :status) AND " +
                  "(:keyword IS NULL OR :keyword = '' OR " +
                  "  LOWER(c.userFullName) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
                  "  c.userEmail LIKE CONCAT('%', :keyword, '%') OR " +
                  "  CAST(o.id AS string) LIKE CONCAT('%', :keyword, '%')" +
                  ")", countQuery = "SELECT count(o) FROM OrderV2 o JOIN o.customer c WHERE " +
                                "o.store.company.id = :companyId AND " +
                                "(:customerId IS NULL OR c.id = :customerId) AND " +
                                "(:storeId IS NULL OR o.store.id = :storeId) AND " +
                                "(:status IS NULL OR :status = -1 OR o.status = :status) AND " +
                                "(:keyword IS NULL OR :keyword = '' OR " +
                                "  LOWER(c.userFullName) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
                                "  c.userEmail LIKE CONCAT('%', :keyword, '%') OR " +
                                "  CAST(o.id AS string) LIKE CONCAT('%', :keyword, '%')" +
                                ")")
    Page<OrderV2> searchOrders(@Param("companyId") int companyId,
                               @Param("customerId") Integer customerId,
                               @Param("storeId") Integer storeId,
                               @Param("status") Integer status,
                               @Param("keyword") String keyword,
                               Pageable pageable);

    @Query("SELECT SUM(o.totalAmount) FROM OrderV2 o WHERE o.store.company.id = :companyId " +
                  "AND (:storeId IS NULL OR o.store.id = :storeId) " +
                  "AND o.status = 4 " + // 4 = COMPLETED
                  "AND o.createdAt BETWEEN :start AND :end")
    Double calculateRevenue(@Param("companyId") int companyId,
                            @Param("storeId") Integer storeId,
                            @Param("start") LocalDateTime start,
                            @Param("end") LocalDateTime end);

    @Query("SELECT SUM(od.quantity * (od.price - od.importPrice)) FROM OrderDetailV2 od " +
                  "WHERE od.order.store.company.id = :companyId " +
                  "AND (:storeId IS NULL OR od.order.store.id = :storeId) " +
                  "AND od.order.status = 4 " + // 4 = COMPLETED
                  "AND od.order.createdAt BETWEEN :start AND :end")
    Double calculateProfit(@Param("companyId") int companyId,
                           @Param("storeId") Integer storeId,
                           @Param("start") LocalDateTime start,
                           @Param("end") LocalDateTime end);

    List<OrderV2> findByStore_Company_IdAndCreatedAtBetween(int companyId, LocalDateTime start, LocalDateTime end);

    @Query("SELECT o FROM OrderV2 o WHERE o.store.company.id = :companyId " +
            "AND (:storeId IS NULL OR o.store.id = :storeId) " +
            "AND o.createdAt BETWEEN :start AND :end")
    List<OrderV2> findOrdersForReport(@Param("companyId") int companyId,
                                      @Param("storeId") Integer storeId,
                                      @Param("start") LocalDateTime start,
                                      @Param("end") LocalDateTime end);
}
