package com.example.Sapo_Clone.Controller;

import com.example.Sapo_Clone.Common.ApiResponse;
import com.example.Sapo_Clone.DTO.Request.Product.ChangeProductStatusDTO;
import com.example.Sapo_Clone.DTO.Request.Product.ProductCreateDTO;
import com.example.Sapo_Clone.DTO.Request.Product.ProductUpdateDTO;
import com.example.Sapo_Clone.DTO.Response.Product.ProductInventoryResponse;
import com.example.Sapo_Clone.DTO.Response.Product.ProductReportDetailResponse;
import com.example.Sapo_Clone.DTO.Response.Product.ProductReportProjection;
import com.example.Sapo_Clone.DTO.Response.Product.ProductResponse;
import com.example.Sapo_Clone.Service.ProductService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/product")
@RequiredArgsConstructor
@Slf4j
public class ProductController {

    private final ProductService productService;

    // 1. CREATE PRODUCT
    @PostMapping
    public ResponseEntity<ApiResponse<ProductResponse>> createProduct(@Valid @RequestBody ProductCreateDTO dto) {
        log.info("API POST /api/product");
        ProductResponse response = productService.createProduct(dto);
        return ResponseEntity.ok(ApiResponse.success("Product created successfully", response));
    }

    // 2. GET PRODUCT FOR CUSTOMER
    @GetMapping("/{id}/customer")
    public ResponseEntity<ApiResponse<ProductResponse>> getProductByIdForCustomer(
            @PathVariable int id) {
        log.info("API GET /api/product/{}/customer", id);
        ProductResponse response = productService.getProductByIdForCustomer(id);
        return ResponseEntity.ok(ApiResponse.success("Success", response));
    }

    // 3. GET PRODUCT FOR MANAGE
    @GetMapping("/{id}/manage")
    public ResponseEntity<ApiResponse<ProductResponse>> getProductByIdForManage(
            @PathVariable int id) {
        log.info("API GET /api/product/{}/manage", id);
        ProductResponse response = productService.getProductByIdForManage(id);
        return ResponseEntity.ok(ApiResponse.success("Success", response));
    }

    // 4. GET LIST (Search/Filter/Paginate)
    @GetMapping
    public ResponseEntity<ApiResponse<Page<ProductResponse>>> getList(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) List<Integer> categoryIds,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        log.info("API GET /api/product keyword={} categoryIds={}", keyword, categoryIds);
        Page<ProductResponse> response = productService.getList(keyword, categoryIds, page, size);
        return ResponseEntity.ok(ApiResponse.success("Success", response));
    }

    // 5. UPDATE PRODUCT
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<ProductResponse>> updateProduct(
            @PathVariable int id,
            @Valid @RequestBody ProductUpdateDTO dto) {
        log.info("API PUT /api/product/{}", id);
        ProductResponse response = productService.updateProduct(id, dto);
        return ResponseEntity.ok(ApiResponse.success("Product updated successfully", response));
    }

    // 6. CHANGE STATUS
    @PatchMapping("/{id}/status")
    public ResponseEntity<ApiResponse<ProductResponse>> changeStatus(
            @PathVariable int id,
            @Valid @RequestBody ChangeProductStatusDTO dto) {
        log.info("API PATCH /api/product/{}/status", id);
        ProductResponse response = productService.changeStatus(id, dto);
        return ResponseEntity.ok(ApiResponse.success("Product status updated", response));
    }

    // 7. GET INVENTORY BY PRODUCT + STORE
    @GetMapping("/{id}/inventory/{storeId}")
    public ResponseEntity<ApiResponse<ProductInventoryResponse>> getInventory(
            @PathVariable int id,
            @PathVariable int storeId) {
        log.info("API GET /api/product/{}/inventory/{}", id, storeId);
        ProductInventoryResponse response = productService.getProductInventory(id, storeId);
        return ResponseEntity.ok(ApiResponse.success("Success", response));
    }

    // 8. GET REPORT (Aggregated)
    @GetMapping("/report")
    public ResponseEntity<ApiResponse<List<com.example.Sapo_Clone.DTO.Response.Product.ProductReportProjection>>> getReport() {
        log.info("API GET /api/product/report");
        List<ProductReportProjection> response = productService.getReportAll();
        return ResponseEntity.ok(ApiResponse.success("Success", response));
    }

    @GetMapping("/report/{productId}")
    public ResponseEntity<ApiResponse<com.example.Sapo_Clone.DTO.Response.Product.ProductReportDetailResponse>> getReportByProduct(
            @PathVariable int productId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        log.info("API GET /api/product/report/{}", productId);
        ProductReportDetailResponse response = productService.getReportByProduct(productId, page, size);
        return ResponseEntity.ok(ApiResponse.success("Success", response));
    }

    //9. GET ALL PRODUCT FROM A STORE
    @GetMapping("/store")
    public  ResponseEntity<ApiResponse<Page<ProductResponse>>> getProductsByStore(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        log.info("API GET /api/product/store");
        Page<ProductResponse> response = productService.getProductsByStore(page,size);
        return ResponseEntity.ok(ApiResponse.success("Success", response));
    }
}