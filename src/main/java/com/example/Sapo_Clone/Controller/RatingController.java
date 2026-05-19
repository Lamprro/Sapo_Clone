package com.example.Sapo_Clone.Controller;

import com.example.Sapo_Clone.Common.ApiResponse;
import com.example.Sapo_Clone.DTO.Request.Rating.RatingCreateDTO;
import com.example.Sapo_Clone.DTO.Request.Rating.RatingUpdateDTO;
import com.example.Sapo_Clone.DTO.Response.Rating.RatingResponse;
import com.example.Sapo_Clone.Service.RatingService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/rating")
@RequiredArgsConstructor
@Slf4j
public class RatingController {

    private final RatingService ratingService;

    @PostMapping
    public ResponseEntity<ApiResponse<RatingResponse>> createRating(
            @Valid @RequestBody RatingCreateDTO dto) {
        log.info("API POST /api/rating");
        RatingResponse response = ratingService.createRating(dto);
        return ResponseEntity.ok(ApiResponse.success("Rating submitted successfully", response));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<RatingResponse>> updateRating(
            @PathVariable int id,
            @Valid @RequestBody RatingUpdateDTO dto) {
        log.info("API PUT /api/rating/{}", id);
        RatingResponse response = ratingService.updateRating(id, dto);
        return ResponseEntity.ok(ApiResponse.success("Rating updated successfully", response));
    }

    @GetMapping("/product/{productId}")
    public ResponseEntity<ApiResponse<Page<RatingResponse>>> getByProduct(
            @PathVariable int productId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        log.info("API GET /api/rating/product/{}", productId);
        Page<RatingResponse> response = ratingService.getByProduct(productId, page, size);
        return ResponseEntity.ok(ApiResponse.success("Success", response));
    }

    @GetMapping("/user")
    public ResponseEntity<ApiResponse<List<RatingResponse>>> getByUser() {
        log.info("API GET /api/rating/user");
        List<RatingResponse> response = ratingService.getByUser();
        return ResponseEntity.ok(ApiResponse.success("Success", response));
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<ApiResponse<RatingResponse>> changeStatus(
            @PathVariable int id,
            @RequestParam int status) {
        log.info("API PATCH /api/rating/{}/status to {}", id, status);
        RatingResponse response = ratingService.changeStatus(id, status);
        return ResponseEntity.ok(ApiResponse.success("Rating status updated", response));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteRating(
            @PathVariable int id) {
        log.info("API DELETE /api/rating/{}", id);
        ratingService.deleteRating(id);
        return ResponseEntity.ok(ApiResponse.success("Rating deleted successfully"));
    }
}
