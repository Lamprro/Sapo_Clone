package com.example.Sapo_Clone.Controller;

import com.example.Sapo_Clone.Common.ApiResponse;
import com.example.Sapo_Clone.DTO.Response.Unit.UnitResponse;
import com.example.Sapo_Clone.Service.UnitService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import org.springframework.data.domain.Page;

@RestController
@RequestMapping("/api/unit")
@RequiredArgsConstructor
@Slf4j
public class UnitController {

    private final UnitService unitService;

    // GET /api/unit?keyword=&page=0&size=20
    @GetMapping
    public ResponseEntity<ApiResponse<Page<UnitResponse>>> getList(
            @RequestParam(required = false, defaultValue = "") String keyword,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        log.info("API GET /api/unit?keyword={}&page={}&size={}", keyword, page, size);
        return ResponseEntity.ok(ApiResponse.success("Success", unitService.getList(keyword, page, size)));
    }
}
