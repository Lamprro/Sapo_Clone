package com.example.Sapo_Clone.Repository;

import com.example.Sapo_Clone.Entity.PurchaseOrderDetail;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PurchaseOrderDetailRepository extends JpaRepository<PurchaseOrderDetail, Integer> {
    List<PurchaseOrderDetail> findByPurchaseOrderId(int purchaseOrderId);

    @Modifying
    @Query("DELETE FROM PurchaseOrderDetail pod WHERE pod.purchaseOrder.user.id = :userId")
    int deleteByPurchaseOrderUserId(@Param("userId") int userId);
}
