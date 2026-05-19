package com.example.Sapo_Clone.DTO.Response.Store;

import com.example.Sapo_Clone.Entity.Store;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class StoreResponse {
    private int id;
    private String storeName;
    private int companyId;
    private String storeAddress;
    private Double latitude;
    private Double longitude;
    private LocalDateTime createdAt;
    
    public static StoreResponse fromEntity(Store store) {
        return StoreResponse.builder()
                .id(store.getId())
                .storeName(store.getStoreName())
                .companyId(store.getCompany() != null ? store.getCompany().getId() : 0)
                .latitude(store.getLatitude())
                .longitude(store.getLongitude())
                .createdAt(store.getCreatedAt())
                .storeAddress(store.getStoreAddress())
                .build();
    }
}
