package com.example.Sapo_Clone.Controller;

import com.example.Sapo_Clone.Common.ApiResponse;
import com.example.Sapo_Clone.DTO.Request.Provider.ProviderCreateDTO;
import com.example.Sapo_Clone.DTO.Request.Provider.ProviderUpdateDTO;
import com.example.Sapo_Clone.DTO.Response.Provider.ProviderResponse;
import com.example.Sapo_Clone.Service.ProviderService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/provider")
@RequiredArgsConstructor
@Slf4j
public class ProviderController {

    private final ProviderService providerService;

    // 1. CREATE PROVIDER (Only Admin/Manager potentially, but leaving open for now per spec)
    @PostMapping
    public ResponseEntity<ApiResponse<ProviderResponse>> create(
            @Valid @RequestBody ProviderCreateDTO dto) {
        log.info("API POST /api/provider - Creating Global Provider: {}", dto.getProviderName());
        ProviderResponse response = providerService.create(dto);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Provider created successfully", response));
    }

    // 2. GET PROVIDER DETAIL
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ProviderResponse>> getById(
            @PathVariable int id) {
        log.info("API GET /api/provider/{} - Fetching Global Provider", id);
        ProviderResponse response = providerService.getById(id);
        return ResponseEntity.ok(ApiResponse.success("Success", response));
    }

    // 3. SEARCH & LIST PROVIDERS
    @GetMapping
    public ResponseEntity<ApiResponse<Page<ProviderResponse>>> search(
            @RequestParam(required = false) String searching,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        log.info("API GET /api/provider?searching={}&page={}&size={} - Global Search", searching, page, size);
        Page<ProviderResponse> response = providerService.search(searching, page, size);
        return ResponseEntity.ok(ApiResponse.success("Success", response));
    }

    // 4. UPDATE PROVIDER
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<ProviderResponse>> update(
            @PathVariable int id,
            @Valid @RequestBody ProviderUpdateDTO dto) {
        log.info("API PUT /api/provider/{} - Updating Global Provider", id);
        ProviderResponse response = providerService.update(id, dto);
        return ResponseEntity.ok(ApiResponse.success("Provider updated successfully", response));
    }

    // 5. CHANGE STATUS
    @PatchMapping("/{id}/status")
    public ResponseEntity<ApiResponse<ProviderResponse>> changeStatus(
            @PathVariable int id,
            @RequestParam int status) {
        log.info("API PATCH /api/provider/{}/status?status={} - Updating Global Status", id, status);
        ProviderResponse response = providerService.changeStatus(id, status);
        return ResponseEntity.ok(ApiResponse.success("Provider status updated successfully", response));
    }
}

