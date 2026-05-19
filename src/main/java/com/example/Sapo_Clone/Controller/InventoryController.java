package com.example.Sapo_Clone.Controller;

import com.example.Sapo_Clone.Common.ApiResponse;
import com.example.Sapo_Clone.DTO.Response.Inventory.InventoryByStoreResponse;
import com.example.Sapo_Clone.DTO.Response.Product.ProductInventoryResponse;
import com.example.Sapo_Clone.Service.InventoryService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/inventory")
@RequiredArgsConstructor
@Slf4j
public class InventoryController {

    private final InventoryService inventoryService;

    // 1. GET INVENTORY BY PRODUCT + STORE
    @GetMapping
    public ResponseEntity<ApiResponse<ProductInventoryResponse>> getInventory(
            @RequestParam int productId,
            @RequestParam(required = false) Integer storeId) {
        log.info("API GET /api/inventory?productId={}", productId);
        ProductInventoryResponse result = inventoryService.getInventory(productId, storeId);
        return ResponseEntity.ok(ApiResponse.success("Success", result));
    }

    // 2. GET INVENTORY BY STORE
    @GetMapping("/store")
    public ResponseEntity<ApiResponse<Page<InventoryByStoreResponse>>> getInventoryByStore(
            @RequestParam(required = false) Integer storeId,
            @RequestParam(required = false) String searching,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        
        log.info("API GET /api/inventory/store?searching={}", searching);
        Page<InventoryByStoreResponse> results = inventoryService.getInventoryByStore(storeId, searching, page, size);
        return ResponseEntity.ok(ApiResponse.success("Success", results));
    }
}
