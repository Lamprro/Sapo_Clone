package com.example.Sapo_Clone.DTO.Response.User;

import com.example.Sapo_Clone.Entity.User;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserResponse {

    private int id;
    private String fullName;
    private String email;
    private String username;
    private String phone;
    private String address;
    private int status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private String roleName;
    private Integer companyId;
    private Integer storeId;
    private Integer pointValue;

    /**
     * Maps from User entity to UserResponse DTO.
     * Prevents exposing the raw entity directly to the external API.
     */
    public static UserResponse fromEntity(User user) {
        return UserResponse.builder()
                .id(user.getId())
                .fullName(user.getUserFullName())
                .email(user.getUserEmail())
                .username(user.getUsername())
                .phone(user.getUserPhone())
                .address(user.getUserAddress())
                .status(user.getUserStatus())
                .createdAt(user.getCreatedAt())
                .updatedAt(user.getUpdatedAt())
                .roleName(user.getRoles() != null ? user.getRoles().getRolesName() : null)
                .companyId(user.getCompany() != null ? user.getCompany().getId() : null)
                .storeId(user.getStore() != null ? user.getStore().getId() : null)
                .pointValue(user.getPoint() != null ? user.getPoint().getPoint() : 0)
                .build();
    }
}