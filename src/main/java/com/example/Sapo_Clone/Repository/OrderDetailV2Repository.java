package com.example.Sapo_Clone.Repository;

import com.example.Sapo_Clone.Entity.OrderDetailV2;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

@Repository
public interface OrderDetailV2Repository extends JpaRepository<OrderDetailV2, Integer> {

    @Modifying
    @Transactional
    @Query("DELETE FROM OrderDetailV2 od WHERE od.order.id = :orderId")
    void deleteAllByOrderId(@Param("orderId") int orderId);
}
