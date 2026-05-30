package com.example.Sapo_Clone.Service.Impl;

import com.example.Sapo_Clone.DTO.Request.LoginSignup.LoginRequest;
import com.example.Sapo_Clone.DTO.Request.LoginSignup.SignUpRequest;
import com.example.Sapo_Clone.DTO.Request.User.UserCreateDTO;
import com.example.Sapo_Clone.DTO.Response.User.LoginSignUp.LoginResponse;
import com.example.Sapo_Clone.DTO.Response.User.UserResponse;
import com.example.Sapo_Clone.Entity.User;
import com.example.Sapo_Clone.Exception.AppException;
import com.example.Sapo_Clone.Exception.ErrorCode;
import com.example.Sapo_Clone.Repository.UserRepository;
import com.example.Sapo_Clone.Security.Jwt.JwtService;
import com.example.Sapo_Clone.Service.AuthService;
import com.example.Sapo_Clone.Service.UserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuthServiceImpl implements AuthService {

    private final UserRepository userRepository;
    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;
    private final UserService userService;
    private final com.example.Sapo_Clone.Service.TokenBlacklistService tokenBlacklistService;
    private final com.example.Sapo_Clone.Service.EmailVerificationService emailVerificationService;

    // -------------------------------------------------------------------------
    // LOGIN
    // -------------------------------------------------------------------------
    
    @Override
    public void logout(String token) {
        try {
            java.util.Date expiration = jwtService.extractExpiration(token);
            long now = System.currentTimeMillis();
            long diff = (expiration.getTime() - now) / 1000;
            
            if (diff > 0) {
                tokenBlacklistService.blacklistToken(token, diff);
                log.info("Token blacklisted successfully on logout");
            }
        } catch (Exception e) {
            log.error("Failed to blacklist token on logout", e);
            // Even if it fails, we want the user to feel logged out from client side
        }
    }

    @Override
    public LoginResponse login(LoginRequest dto) {
        log.info("Login attempt username={}", dto.getUsername());

        // 1. Authenticate credentials via Spring Security (validates password with
        // BCrypt)
        // Throws BadCredentialsException if username/password wrong → we catch → 401
        try {
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(dto.getUsername() + ":" + dto.getCompanyId(), dto.getPassword()));
        } catch (BadCredentialsException e) {
            log.warn("Invalid credentials for username={}", dto.getUsername());
            throw new AppException(ErrorCode.LOGIN_NOT_FOUND);
        }

        // 2. Load full user entity (guaranteed to exist after successful auth)
        User user = userRepository.findByUsernameAndCompany_Id(dto.getUsername(), dto.getCompanyId())
                .orElseThrow(() -> new AppException(ErrorCode.LOGIN_NOT_FOUND));

        // 3. Check status
        if (user.getUserStatus() == 0) {
            log.warn("Banned user attempted login username={}", dto.getUsername());
            throw new AppException(ErrorCode.USER_BANNED);
        }
        
        if (user.getUserStatus() == 2) {
            log.warn("Unverified user attempted login username={}", dto.getUsername());
            // Before throwing, we could resend the code automatically or just tell them to verify
            throw new AppException(ErrorCode.EMAIL_NOT_VERIFIED);
        }

        // 4. Generate JWT — claims include userId and role (see JwtService)
        String token = jwtService.generateToken(dto.getUsername(), dto.getCompanyId());
        log.info("Login successful username={}", dto.getUsername());

        // 5. Return token + user info
        return LoginResponse.builder()
                .token(token)
                .user(UserResponse.fromEntity(user))
                .build();
    }

    // -------------------------------------------------------------------------
    // SIGNUP
    // -------------------------------------------------------------------------

    @Override
    public UserResponse signup(SignUpRequest dto) {
        log.info("Signup attempt username={}", dto.getUsername());

        // Check password == repeat_password
        if (!dto.getPassword().equals(dto.getRepeatPassword())) {
            throw new AppException(ErrorCode.PASSWORD_MISMATCH);
        }
        // Delegate to UserService.createUser() — reuses all duplicate checks + BCrypt
        // encode
        UserCreateDTO createDTO = new UserCreateDTO();
        createDTO.setCompanyId(dto.getCompanyId());
        createDTO.setAddress(dto.getAddress());
        createDTO.setStoreId(dto.getStoreId());
        createDTO.setRoleId(dto.getRoleId());
        createDTO.setFullName(dto.getFullName());
        createDTO.setPhone(dto.getPhone());
        createDTO.setEmail(dto.getEmail());
        createDTO.setUsername(dto.getUsername());
        createDTO.setPassword(dto.getPassword());
        UserResponse response = userService.createUser(createDTO);
        
        return response;
    }
}
