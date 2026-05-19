package com.example.Sapo_Clone.DTO.Response.Store;

import com.example.Sapo_Clone.Entity.Store;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class StoreWithInventoryResponse {
    private int id;
    private String storeName;
    private int companyId;
    private String storeAddress;
    private Double latitude;
    private Double longitude;
    private LocalDateTime createdAt;
    
    // Additional field for stock quantity
    private int quantity;
    
    public static StoreWithInventoryResponse fromEntityAndQuantity(Store store, int quantity) {
        return StoreWithInventoryResponse.builder()
                .id(store.getId())
                .storeName(store.getStoreName())
                .companyId(store.getCompany() != null ? store.getCompany().getId() : 0)
                .latitude(store.getLatitude())
                .longitude(store.getLongitude())
                .createdAt(store.getCreatedAt())
                .storeAddress(store.getStoreAddress())
                .quantity(quantity)
                .build();
    }
}
