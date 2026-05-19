package com.example.Sapo_Clone.Controller;

import com.example.Sapo_Clone.Common.ApiResponse;
import com.example.Sapo_Clone.DTO.Request.User.ChangePasswordRequest;
import com.example.Sapo_Clone.DTO.Request.User.UpdateUserDTO;
import com.example.Sapo_Clone.DTO.Request.User.UserCreateDTO;
import com.example.Sapo_Clone.DTO.Response.User.UserResponse;
import com.example.Sapo_Clone.Service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/user")
@RequiredArgsConstructor
@Slf4j
public class UserController {

    private final UserService userService;

    // 1. CREATE USER (Supports Signup if not authenticated or Internal Creation if authenticated)
    @PostMapping
    public ResponseEntity<ApiResponse<UserResponse>> createUser(
            @Valid @RequestBody UserCreateDTO dto) {
        log.info("POST /api/user - username={}", dto.getUsername());
        UserResponse response = userService.createUser(dto);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("User created successfully", response));
    }

    // 2. UPDATE STATUS
    @PatchMapping("/{id}")
    public ResponseEntity<ApiResponse<UserResponse>> updateStatus(
            @PathVariable int id,
            @RequestParam int status) {
        log.info("PATCH /api/user/{} - status={}", id, status);
        UserResponse response = userService.updateStatus(id, status);
        return ResponseEntity.ok(ApiResponse.success("User status updated successfully", response));
    }

    // 3. GET LIST
    @GetMapping
    public ResponseEntity<ApiResponse<Page<UserResponse>>> getList(
            @RequestParam(required = false, defaultValue = "") String keyword,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        log.info("GET /api/user - keyword={} page={} size={}", keyword, page, size);
        Page<UserResponse> users = userService.getList(keyword, page, size);
        return ResponseEntity.ok(ApiResponse.success("Success", users));
    }

    // 4. UPDATE PROFILE (Current User)
    @PutMapping("/profile")
    public ResponseEntity<ApiResponse<UserResponse>> updateProfile(
            @Valid @RequestBody UpdateUserDTO dto) {
        log.info("PUT /api/user/profile");
        UserResponse response = userService.updateProfile(dto);
        return ResponseEntity.ok(ApiResponse.success("Profile updated successfully", response));
    }

    // 5. CHANGE PASSWORD (Current User)
    @PatchMapping("/password")
    public ResponseEntity<ApiResponse<String>> changePassword(
            @Valid @RequestBody ChangePasswordRequest request) {
        log.info("PATCH /api/user/password");
        userService.changePassword(request);
        return ResponseEntity.ok(ApiResponse.success("Password changed successfully", null));
    }
    //6. Forgot Password
    @PatchMapping("/forgot-password")
    public ResponseEntity<ApiResponse<String>> forgotPassword(
            @Valid @RequestBody com.example.Sapo_Clone.DTO.Request.User.ForgotPasswordRequest forgotPasswordRequest) {
        log.info("PATCH /api/user/forgot-password - email={}", forgotPasswordRequest.getEmail());
        userService.forgotPassword(forgotPasswordRequest);
        return ResponseEntity.ok(ApiResponse.success("If the email exists, a password reset link has been sent", null));
    }
}
