package com.example.Sapo_Clone.DTO.Response.Provider;

import com.example.Sapo_Clone.Entity.Provider;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = lombok.AccessLevel.PRIVATE)
public class ProviderResponse {
    int id;
    String providerUei;
    String providerName;
    String providerPhone;
    String providerAddress;
    int status;
    String description;
    String createdAt;
    String updatedAt;

    public static ProviderResponse fromEntity(Provider provider) {
        if (provider == null) return null;
        return ProviderResponse.builder()
                .id(provider.getId())
                .providerUei(provider.getProviderUei())
                .providerName(provider.getProviderName())
                .providerPhone(provider.getProviderPhone())
                .providerAddress(provider.getProviderAddress())
                .status(provider.getStatus())
                .description(provider.getDescription())
                .createdAt(provider.getCreatedAt() != null ? provider.getCreatedAt().toString() : null)
                .updatedAt(provider.getUpdatedAt() != null ? provider.getUpdatedAt().toString() : null)
                .build();
    }
}

