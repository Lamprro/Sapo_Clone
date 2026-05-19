package com.example.Sapo_Clone.Service.Impl;

import com.example.Sapo_Clone.DTO.Request.User.ChangePasswordRequest;
import com.example.Sapo_Clone.DTO.Request.User.ForgotPasswordRequest;
import com.example.Sapo_Clone.DTO.Request.User.UserCreateDTO;
import com.example.Sapo_Clone.DTO.Response.User.UserResponse;
import com.example.Sapo_Clone.Entity.*;
import com.example.Sapo_Clone.Exception.AppException;
import com.example.Sapo_Clone.Exception.ErrorCode;
import com.example.Sapo_Clone.Repository.RoleRepository;
import com.example.Sapo_Clone.Repository.UserRepository;
import com.example.Sapo_Clone.Repository.CompanyRepository;
import com.example.Sapo_Clone.Security.Jwt.JwtService;
import com.example.Sapo_Clone.Service.UserService;
import com.example.Sapo_Clone.Service.EmailVerificationService;
import com.example.Sapo_Clone.Utils.SecurityUtils;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Lazy;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.Objects;

@Service
@Slf4j
public class UserServiceImpl implements UserService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private CompanyRepository companyRepository;

    @Autowired
    private com.example.Sapo_Clone.Repository.StoreRepository storeRepository;

    @Autowired
    @Lazy
    private PasswordEncoder passwordEncoder;

    @Autowired
    @Lazy
    private JwtService jwtService;

    @Autowired
    private EmailVerificationService emailVerificationService;

    @Override
    public UserDetails loadUserByUsername(String compositeUsername) throws UsernameNotFoundException {
        String username;
        int companyId;

        if (compositeUsername.contains(":")) {
            String[] parts = compositeUsername.split(":");
            username = parts[0];
            try {
                companyId = Integer.parseInt(parts[1]);
            } catch (NumberFormatException e) {
                throw new UsernameNotFoundException("Invalid company ID format in username");
            }
        } else {
            // Fallback for cases without companyId (if any)
            User user = userRepository.findByUsername(compositeUsername)
                    .orElseThrow(() -> new UsernameNotFoundException("User not found: " + compositeUsername));
            SimpleGrantedAuthority authority = new SimpleGrantedAuthority(user.getRoles().getRolesName());
            return new org.springframework.security.core.userdetails.User(
                    user.getUsername(), user.getPassword(), List.of(authority));
        }

        User user = userRepository.findByUsernameAndCompany_Id(username, companyId)
                .orElseThrow(() -> new UsernameNotFoundException(
                        "User not found: " + username + " in company: " + companyId));

        SimpleGrantedAuthority authority = new SimpleGrantedAuthority(user.getRoles().getRolesName());
        return new org.springframework.security.core.userdetails.User(
                user.getUsername(), user.getPassword(), List.of(authority));
    }

    @Override
    public User findByUserName(String username) {
        return userRepository.findByUsername(username)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));
    }

    @Override
    @Transactional
    public UserResponse createUser(UserCreateDTO dto) {
        log.info("Creating user username={}", dto.getUsername());

        // 1. Get Current User Info from Token (Zero-Query)
        String currentRole = SecurityUtils.getCurrentRole();
        Integer currentCompanyId = SecurityUtils.getCurrentCompanyId();
        if (currentCompanyId <= 0)
            currentCompanyId = null;

        // 2. Determine Target Role and Company based on Hierarchy
        String targetRoleName;
        int targetCompanyId;

        if ("ADMIN".equals(currentRole)) {
            // ADMIN creates MANAGER - Administrator must provide companyId
            targetRoleName = "MANAGER";
            targetCompanyId = dto.getCompanyId();
        } else if ("MANAGER".equals(currentRole)) {
            // MANAGER creates EMPLOYEE - Inherits companyId from MANAGER
            targetRoleName = "EMPLOYEE";
            targetCompanyId = currentCompanyId;
        } else if ("EMPLOYEE".equals(currentRole)) {
            // EMPLOYEE creates CUSTOMER - Inherits companyId from EMPLOYEE
            targetRoleName = "CUSTOMER";
            targetCompanyId = currentCompanyId;
        } else {
            // Public Signup -> CUSTOMER - Must provide companyId
            targetRoleName = "CUSTOMER";
            targetCompanyId = dto.getCompanyId();
        }

        Store store = null;
        if (!targetRoleName.equals("CUSTOMER")) {
            store = storeRepository.findById(dto.getStoreId())
                    .orElseThrow(() -> new AppException(ErrorCode.STORE_NOT_FOUND));
        }

        log.info("Hierarchy check: creatorRole={}, creatorCompanyId={} -> targetRole={}, targetCompanyId={}",
                currentRole, currentCompanyId, targetRoleName, targetCompanyId);

        if (targetCompanyId <= 0) {
            throw new AppException(ErrorCode.COMPANY_NOT_FOUND);
        }

        // 3. Duplicate checks within the target company
        if (userRepository.existsByUserPhoneAndCompany_Id(dto.getPhone(), targetCompanyId)) {
            throw new AppException(ErrorCode.PHONE_ALREADY_EXISTS);
        }
        if (userRepository.existsByUserEmailAndCompany_Id(dto.getEmail(), targetCompanyId)) {
            throw new AppException(ErrorCode.EMAIL_ALREADY_EXISTS);
        }
        if (userRepository.existsByUsernameAndCompany_Id(dto.getUsername(), targetCompanyId)) {
            throw new AppException(ErrorCode.USERNAME_ALREADY_EXISTS);
        }

        // 4. Fetch Role and Company entities
        Roles role = roleRepository.findByRolesName(targetRoleName)
                .orElseThrow(() -> new AppException(ErrorCode.ROLE_NOT_FOUND));

        Company company = companyRepository.findById(targetCompanyId)
                .orElseThrow(() -> new AppException(ErrorCode.COMPANY_NOT_FOUND));

        // 5. Construct User
        User user = new User();
        user.setUserFullName(dto.getFullName());
        user.setUserPhone(dto.getPhone());
        user.setUserEmail(dto.getEmail());
        user.setUsername(dto.getUsername());
        user.setPassword(passwordEncoder.encode(dto.getPassword()));
        user.setUserStatus(2); // Confirmation required
        user.setRoles(role);
        user.setCompany(company);
        Point point = new Point();
        point.setPoint(0);
        point.setUser(user);
        user.setPoint(point);

        user.setUserAddress(dto.getAddress());
        user.setStore(store);

        // 6. Conditional Point and Cart initialization (Only for CUSTOMER)
        if ("CUSTOMER".equals(targetRoleName)) {
            com.example.Sapo_Clone.Entity.Cart cart = new com.example.Sapo_Clone.Entity.Cart();
            cart.setUser(user);
            user.setCart(cart);
        }

        User saved = userRepository.save(user);
        log.info("User created id={} with role={} under company={}", saved.getId(), targetRoleName, targetCompanyId);

        // Send verification email
        try {
            log.info("Triggering verification email for email={}", saved.getUserEmail());
            emailVerificationService.sendVerificationCode(saved.getUserEmail());
        } catch (Exception e) {
            log.error("Failed to send verification email during user creation: {}", e.getMessage());
        }

        return UserResponse.fromEntity(saved);
    }

    @Override
    @Transactional
    public UserResponse updateStatus(int id, int status) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        log.info("Updating status user id={} to status={} companyId={}", id, status, companyId);

        if (status < 0 || status > 2) {
            throw new AppException(ErrorCode.INVALID_STATUS);
        }

        User user = userRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));

        if (user.getCompany() == null || user.getCompany().getId() != companyId) {
            throw new AppException(ErrorCode.USER_NOT_FOUND);
        }

        user.setUserStatus(status);
        return UserResponse.fromEntity(userRepository.save(user));
    }

    @Override
    public Page<UserResponse> getList(String keyword, int page, int size) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        log.info("Getting user list for companyId={}, keyword={}, page={}, size={}", companyId, keyword, page, size);
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));

        if (keyword == null || keyword.trim().isEmpty()) {
            return userRepository.findAllByCompanyId(companyId, pageable).map(UserResponse::fromEntity);
        }

        String search = keyword.trim();
        if (search.matches("\\d+")) {
            int id = Integer.parseInt(search);
            Optional<User> opt = userRepository.findById(id);
            List<UserResponse> singleResult = new ArrayList<>();
            opt.ifPresent(u -> {
                if (u.getCompany() != null && u.getCompany().getId() == companyId) {
                    singleResult.add(UserResponse.fromEntity(u));
                }
            });
            return new PageImpl<>(singleResult, pageable, singleResult.size());
        }

        return userRepository.searchByKeyword(companyId, search, pageable).map(UserResponse::fromEntity);
    }

    @Override
    @Transactional
    public UserResponse updateProfile(com.example.Sapo_Clone.DTO.Request.User.UpdateUserDTO dto) {
        int userId = SecurityUtils.getCurrentUserId();
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));

        int companyId = user.getCompany() != null ? user.getCompany().getId() : 0;

        // Check for duplicates if email or phone is changed
        if (!Objects.equals(user.getUserEmail(), dto.getEmail())
                && userRepository.existsByUserEmailAndCompany_Id(dto.getEmail(), companyId)) {
            throw new AppException(ErrorCode.EMAIL_ALREADY_EXISTS);
        }
        if (!Objects.equals(user.getUserPhone(), dto.getPhone())
                && userRepository.existsByUserPhoneAndCompany_Id(dto.getPhone(), companyId)) {
            throw new AppException(ErrorCode.PHONE_ALREADY_EXISTS);
        }

        user.setUserFullName(dto.getFullName());
        user.setUserPhone(dto.getPhone());
        user.setUserEmail(dto.getEmail());
        user.setUserAddress(dto.getAddress());

        return UserResponse.fromEntity(userRepository.save(user));
    }

    @Override
    @Transactional
    public void changePassword(ChangePasswordRequest request) {
        int userId = SecurityUtils.getCurrentUserId();
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));

        if (!passwordEncoder.matches(request.getOldPassword(), user.getPassword())) {
            throw new AppException(ErrorCode.INVALID_PASSWORD);
        }

        if (!request.getNewPassword().equals(request.getConfirmPassword())) {
            throw new AppException(ErrorCode.PASSWORD_MISMATCH);
        }

        user.setPassword(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);
    }

    @Override
    public void forgotPassword(ForgotPasswordRequest dto) {
        User user = userRepository.findByUsername(dto.getUsername())
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));
        if (!user.getUserEmail().equals(dto.getEmail())){
            throw  new AppException(ErrorCode.EMAIL_NOT_MATCH);
        }

        if (!dto.getNewPassword().equals(dto.getConfirmPassword())) {
            throw new AppException(ErrorCode.PASSWORD_MISMATCH);
        }

        user.setPassword(passwordEncoder.encode(dto.getNewPassword()));
        userRepository.save(user);
    }
}
