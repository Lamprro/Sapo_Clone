package com.example.Sapo_Clone.Controller;

import com.example.Sapo_Clone.Common.ApiResponse;
import com.example.Sapo_Clone.DTO.Response.Category.CategoryResponse;
import com.example.Sapo_Clone.Service.CategoryService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.data.domain.Page;

@RestController
@RequestMapping("/api/category")
@RequiredArgsConstructor
@Slf4j
public class CategoryController {

    private final CategoryService categoryService;

    // GET /api/category?keyword=&page=0&size=20
    @GetMapping
    public ResponseEntity<ApiResponse<Page<CategoryResponse>>> getList(
            @RequestParam(required = false, defaultValue = "") String keyword,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        log.info("API GET /api/category?keyword={}&page={}&size={}", keyword, page, size);
        return ResponseEntity.ok(ApiResponse.success("Success", categoryService.getList(keyword, page, size)));
    }
}
