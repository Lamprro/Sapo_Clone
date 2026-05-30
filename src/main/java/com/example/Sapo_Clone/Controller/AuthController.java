package com.example.Sapo_Clone.Controller;

import com.example.Sapo_Clone.Common.ApiResponse;
import com.example.Sapo_Clone.DTO.Request.LoginSignup.LoginRequest;
import com.example.Sapo_Clone.DTO.Request.LoginSignup.SignUpRequest;
import com.example.Sapo_Clone.DTO.Response.User.LoginSignUp.LoginResponse;
import com.example.Sapo_Clone.DTO.Response.User.UserResponse;
import com.example.Sapo_Clone.Service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
@Slf4j
public class AuthController {

    private final AuthService authService;
    private final com.example.Sapo_Clone.Service.EmailVerificationService emailVerificationService;

    // -------------------------------------------------------------------------
    // POST /api/auth/login — Authenticate and receive JWT token
    // -------------------------------------------------------------------------
    @PostMapping("/login")
    public ResponseEntity<ApiResponse<LoginResponse>> login(
            @Valid @RequestBody LoginRequest dto) {
        log.info("POST /api/auth/login - username={} - company={}", dto.getUsername(),dto.getCompanyId());
        LoginResponse response = authService.login(dto);
        return ResponseEntity.ok(ApiResponse.success("Login successful", response));
    }

    // -------------------------------------------------------------------------
    // POST /api/auth/signup — Register new account (public)
    // -------------------------------------------------------------------------
    @PostMapping("/signup")
    public ResponseEntity<ApiResponse<UserResponse>> signup(
            @Valid @RequestBody SignUpRequest dto) {
        log.info("POST /api/auth/signup - username={} - companyId={}", dto.getUsername(),dto.getCompanyId());
        UserResponse response = authService.signup(dto);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("Account registered successfully. Please check your email for verification code.", response));
    }

    // -------------------------------------------------------------------------
    // POST /api/auth/verify-email — Activate account
    // -------------------------------------------------------------------------
    @PostMapping("/verify-email")
    public ResponseEntity<ApiResponse<Void>> verifyEmail(
            @RequestParam String email,
            @RequestParam String code,
            @RequestParam int companyId) {
        log.info("POST /api/auth/verify-email - email={} - companyId={}", email, companyId);
        emailVerificationService.verifyCode(email, code, companyId);
        return ResponseEntity.ok(ApiResponse.success("Email verified successfully. You can now login.", null));
    }

    // -------------------------------------------------------------------------
    // POST /api/auth/resend-verification — Resend code
    // -------------------------------------------------------------------------
    @PostMapping("/resend-verification")
    public ResponseEntity<ApiResponse<Void>> resendVerification(
            @RequestParam String email,
            @RequestParam int companyId) {
        log.info("POST /api/auth/resend-verification - email={} - companyId={}", email, companyId);
        emailVerificationService.sendVerificationCode(email, companyId);
        return ResponseEntity.ok(ApiResponse.success("Verification code resent successfully.", null));
    }

    // -------------------------------------------------------------------------
    // POST /api/auth/logout — Invalidate current JWT
    // -------------------------------------------------------------------------
    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<Void>> logout(
            @RequestHeader(value = "Authorization", required = false) String authHeader) {
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7);
            authService.logout(token);
        }
        return ResponseEntity.ok(ApiResponse.success("Logged out successfully", null));
    }
}
