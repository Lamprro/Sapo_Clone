package com.example.Sapo_Clone.Repository;

import com.example.Sapo_Clone.Entity.OrderDetail;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

@Repository
public interface OrderDetailRepository extends JpaRepository<OrderDetail, Integer> {

    @Modifying
    @Transactional
    @Query("DELETE FROM OrderDetail od WHERE od.order.id = :orderId")
    void deleteAllByOrderId(@Param("orderId") int orderId);

    @Query("SELECT od FROM OrderDetail od WHERE od.product.id = :productId AND od.order.store.company.id = :companyId")
    org.springframework.data.domain.Page<OrderDetail> findByProduct_IdAndCompany_Id(
            @Param("productId") int productId, 
            @Param("companyId") int companyId, 
            org.springframework.data.domain.Pageable pageable);
}
