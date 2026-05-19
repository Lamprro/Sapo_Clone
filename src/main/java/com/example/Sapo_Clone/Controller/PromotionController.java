package com.example.Sapo_Clone.Controller;

import com.example.Sapo_Clone.Common.ApiResponse;
import com.example.Sapo_Clone.DTO.Request.Promotion.PromotionCreateDTO;
import com.example.Sapo_Clone.DTO.Request.Promotion.PromotionUpdateDTO;
import com.example.Sapo_Clone.DTO.Response.Promotion.PromotionListResponse;
import com.example.Sapo_Clone.DTO.Response.Promotion.PromotionResponse;
import com.example.Sapo_Clone.Service.PromotionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/promotion")
@RequiredArgsConstructor
@Slf4j
public class PromotionController {

    private final PromotionService promotionService;

    // 1. CREATE PRODUCT PROMOTION
    @PostMapping("/product")
    public ResponseEntity<ApiResponse<PromotionResponse>> createProductPromotion(
            @Valid @RequestBody PromotionCreateDTO dto) {
        log.info("API POST /api/promotion/product");
        PromotionResponse response = promotionService.createProductPromotion(dto);
        return ResponseEntity.ok(ApiResponse.success("Product promotion created successfully", response));
    }

    // 2. CREATE ORDER PROMOTION
    @PostMapping("/order")
    public ResponseEntity<ApiResponse<PromotionResponse>> createOrderPromotion(
            @Valid @RequestBody PromotionCreateDTO dto) {
        log.info("API POST /api/promotion/order");
        PromotionResponse response = promotionService.createOrderPromotion(dto);
        return ResponseEntity.ok(ApiResponse.success("Order promotion created successfully", response));
    }

    // 3. CHANGE STATUS
    @PatchMapping("/{promotionId}")
    public ResponseEntity<ApiResponse<PromotionResponse>> updateStatus(
            @PathVariable int promotionId,
            @RequestParam int status) {
        log.info("API PATCH /api/promotion/{}?status={}", promotionId, status);
        PromotionResponse response = promotionService.updatePromotionStatus(promotionId, status);
        return ResponseEntity.ok(ApiResponse.success("Promotion status updated successfully", response));
    }

    // 4. UPDATE THE PROMOTION
    @PutMapping("/{promotionId}")
    public ResponseEntity<ApiResponse<PromotionResponse>> updatePromotion(
            @PathVariable int promotionId,
            @Valid @RequestBody PromotionUpdateDTO dto
    ){
        log.info("API PUT /api/promotion/{}", promotionId);
        PromotionResponse response = promotionService.updatePromotion(promotionId, dto);
        return ResponseEntity.ok(ApiResponse.success("Promotion updated successfully", response));
    }
    // 5. GET PROMOTION BY COMPANY ID AND KEYWORD
    @GetMapping("/company/{companyId}")
    public ResponseEntity<ApiResponse<Page<PromotionListResponse>>> getPromotionByCompanyId_Keyword(
            @PathVariable int companyId,
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size
    ){
        log.info("API GET /api/promotion/company/{}?keyword={}&page={}&size={}", companyId, keyword, page, size);
        Page<PromotionListResponse> response = promotionService.getPromotionByCompanyId_Keyword(companyId, keyword, page, size);
        return ResponseEntity.ok(ApiResponse.success("Success", response));
    }
    
    // 6. GET BY ID
    @GetMapping("/{promotionId}")
    public ResponseEntity<ApiResponse<PromotionResponse>> getById(@PathVariable int promotionId) {
        log.info("API GET /api/promotion/{}", promotionId);
        PromotionResponse response = promotionService.getPromotionById(promotionId);
        return ResponseEntity.ok(ApiResponse.success("Success", response));
    }
}
