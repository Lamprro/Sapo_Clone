package com.example.Sapo_Clone.Controller;

import com.example.Sapo_Clone.Common.ApiResponse;
import com.example.Sapo_Clone.DTO.Request.Company.CompanyDTO;
import com.example.Sapo_Clone.DTO.Response.Company.CompanyResponse;
import com.example.Sapo_Clone.Service.CompanyService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/company")
@RequiredArgsConstructor
public class CompanyController {
    private final CompanyService companyService;

    @PostMapping
    public ResponseEntity<ApiResponse<CompanyResponse>> createCompany(@Valid @RequestBody CompanyDTO dto) {
        return ResponseEntity.ok(ApiResponse.success("Create company successfully", companyService.createCompany(dto)));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<Page<CompanyResponse>>> getList(
            @RequestParam(required = false, defaultValue = "") String keyword,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return ResponseEntity.ok(ApiResponse.success("Success", companyService.getList(keyword, page, size)));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<CompanyResponse>> updateCompany(
            @PathVariable int id, 
            @Valid @RequestBody CompanyDTO dto) {
        return ResponseEntity.ok(ApiResponse.success("Update company successfully", companyService.updateCompany(id, dto)));
    }
}
