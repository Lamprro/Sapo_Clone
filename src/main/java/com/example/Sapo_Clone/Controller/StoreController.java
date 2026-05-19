package com.example.Sapo_Clone.Controller;

import com.example.Sapo_Clone.Common.ApiResponse;
import com.example.Sapo_Clone.DTO.Request.Store.StoreDTO;
import com.example.Sapo_Clone.DTO.Response.Store.StoreResponse;
import com.example.Sapo_Clone.DTO.Response.Store.StoreWithInventoryResponse;
import com.example.Sapo_Clone.Service.StoreService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/store")
@RequiredArgsConstructor
public class StoreController {
    private final StoreService storeService;

    @PostMapping
    public ResponseEntity<ApiResponse<StoreResponse>> createStore(@Valid @RequestBody StoreDTO dto) {
        return ResponseEntity.ok(ApiResponse.success("Create Store successfully", storeService.createStore(dto)));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<Page<StoreResponse>>> getList(
            @RequestParam(required = false, defaultValue = "") String keyword,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return ResponseEntity.ok(ApiResponse.success("Success", storeService.getList(keyword, page, size)));
    }

    @GetMapping("/all")
    public ResponseEntity<ApiResponse<List<StoreResponse>>> getAllStores() {
        return ResponseEntity.ok(ApiResponse.success("Success", storeService.getAllStoresForCustomer()));
    }

    @GetMapping("/product/{productId}")
    public ResponseEntity<ApiResponse<Page<StoreWithInventoryResponse>>> getStoresByProductId(
            @PathVariable Integer productId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return ResponseEntity.ok(ApiResponse.success("Success", storeService.getStoresByProductId(productId, page, size)));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<StoreResponse>> updateStore(
            @PathVariable int id, 
            @Valid @RequestBody StoreDTO dto) {
        return ResponseEntity.ok(ApiResponse.success("Update store successfully", storeService.updateStore(id, dto)));
    }

}