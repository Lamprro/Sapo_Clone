package com.example.Sapo_Clone.Service;

import com.example.Sapo_Clone.DTO.Request.PurchaseOrder.PurchaseOrderCreateDTO;
import com.example.Sapo_Clone.DTO.Response.PurchaseOrder.PurchaseOrderResponse;
import lombok.Builder;
import lombok.Data;
import org.springframework.data.domain.Page;

import java.time.LocalDateTime;
import java.util.List;

public interface PurchaseOrderService {

    PurchaseOrderResponse createPurchaseOrder(PurchaseOrderCreateDTO dto);

    Page<PurchaseOrderResponse> getList(String searching, Integer status, int page, int size);

    PurchaseOrderResponse updateStatus(int purchaseOrderId, int status);

    PurchaseReportResponse getPurchaseReport(int storeId, LocalDateTime start, LocalDateTime end);

    public PurchaseOrderResponse getById(Integer purchaseOrderId);
    @Data
    @Builder
    class PurchaseReportResponse {
        Double totalExpenditure;
        Long totalOrders;
        List<PurchaseOrderResponse> orders;
    }
}
