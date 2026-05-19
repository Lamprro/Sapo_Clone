package com.example.Sapo_Clone.Controller;

import com.example.Sapo_Clone.Common.ApiResponse;
import com.example.Sapo_Clone.DTO.Response.ProductImage.ProductImageListResponse;
import com.example.Sapo_Clone.DTO.Response.ProductImage.ProductImageResponse;
import com.example.Sapo_Clone.Service.ProductImageService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/product/{productId}/images")
@RequiredArgsConstructor
@Slf4j
public class ProductImageController {

    private final ProductImageService productImageService;

    // 1. GET ALL IMAGES BY PRODUCT
    @GetMapping
    public ResponseEntity<ApiResponse<ProductImageListResponse>> getImagesByProduct(@PathVariable int productId) {
        log.info("API GET /api/product/{}/images - Fetch list", productId);
        ProductImageListResponse response = productImageService.getImagesByProduct(productId);
        return ResponseEntity.ok(ApiResponse.success("Success", response));
    }

    // 2. UPLOAD IMAGE
    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<ProductImageResponse>> uploadImage(
            @PathVariable int productId,
            @RequestParam("file") MultipartFile file) {
        log.info("API POST /api/product/{}/images - Upload", productId);
        ProductImageResponse response = productImageService.uploadImage(productId, file);
        return ResponseEntity.ok(ApiResponse.success("Image uploaded successfully", response));
    }

    // 3. SET MAIN IMAGE
    @PatchMapping("/{imageId}")
    public ResponseEntity<ApiResponse<Void>> setMainImage(
            @PathVariable int productId,
            @PathVariable int imageId) {
        log.info("API PATCH /api/product/{}/images/{} - Set Main", productId, imageId);
        productImageService.setMainImage(productId, imageId);
        return ResponseEntity.ok(ApiResponse.success("Main image updated successfully", null));
    }

    // 4. DELETE IMAGE
    @DeleteMapping("/{imageId}")
    public ResponseEntity<ApiResponse<Void>> deleteImage(
            @PathVariable int productId,
            @PathVariable int imageId) {
        log.info("API DELETE /api/product/{}/images/{} - Delete", productId, imageId);
        productImageService.deleteImage(productId, imageId);
        return ResponseEntity.ok(ApiResponse.success("Image deleted successfully", null));
    }
}
