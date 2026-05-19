package com.example.Sapo_Clone.Controller;

import com.example.Sapo_Clone.Common.ApiResponse;
import com.example.Sapo_Clone.DTO.Request.PurchaseOrder.PurchaseOrderCreateDTO;
import com.example.Sapo_Clone.DTO.Response.PurchaseOrder.PurchaseOrderResponse;
import com.example.Sapo_Clone.Service.PurchaseOrderService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;

@RestController
@RequestMapping("/api/purchase_order")
@RequiredArgsConstructor
@Slf4j
public class PurchaseOrderController {

    private final PurchaseOrderService purchaseOrderService;

    // 1. CREATE PURCHASE ORDER
    @PostMapping
    public ResponseEntity<ApiResponse<PurchaseOrderResponse>> createPurchaseOrder(
            @Valid @RequestBody PurchaseOrderCreateDTO dto) {
        log.info("API POST /api/purchase_order - create");
        PurchaseOrderResponse response = purchaseOrderService.createPurchaseOrder(dto);
        return ResponseEntity.ok(ApiResponse.success("Purchase order created successfully", response));
    }

    // 2. SEARCH & FILTER
    @GetMapping
    public ResponseEntity<ApiResponse<Page<PurchaseOrderResponse>>> getList(
            @RequestParam(required = false) String searching,
            @RequestParam(required = false) Integer status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        
        log.info("API GET /api/purchase_order - list/search");
        Page<PurchaseOrderResponse> response = purchaseOrderService.getList(searching, status, page, size);
        return ResponseEntity.ok(ApiResponse.success("Success", response));
    }

    // 3. UPDATE STATUS
    @PatchMapping("/{id}")
    public ResponseEntity<ApiResponse<PurchaseOrderResponse>> updateStatus(
            @PathVariable int id,
            @RequestParam int status) {
        log.info("API PATCH /api/purchase_order/{} to status={}", id, status);
        PurchaseOrderResponse response = purchaseOrderService.updateStatus(id, status);
        return ResponseEntity.ok(ApiResponse.success("Purchase order status updated", response));
    }

    // 4. REPORTING
    @GetMapping("/report")
    public ResponseEntity<ApiResponse<PurchaseOrderService.PurchaseReportResponse>> getReport(
            @RequestParam (required = false, defaultValue = "-1") int storeId,
            @RequestParam (required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime start,
            @RequestParam (required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime end) {
        
        log.info("API GET /api/purchase_order/report/{} ", storeId);
        PurchaseOrderService.PurchaseReportResponse response = purchaseOrderService.getPurchaseReport(storeId, start, end);
        return ResponseEntity.ok(ApiResponse.success("Report generated successfully", response));
    }

    // 5. GET BY PURCHASEORDERID
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<PurchaseOrderResponse>> getById(
            @PathVariable() Integer id ){
        log.info("API GET /api/purchase_order/{id} - searchByPurchaseOrderId");
        PurchaseOrderResponse response = purchaseOrderService.getById(id);
        return ResponseEntity.ok(ApiResponse.success("Success", response));
    }
}
