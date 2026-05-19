package com.example.Sapo_Clone.DTO.Request.Store;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class StoreDTO {
    @NotBlank(message = "Store name is required")
    private String storeName;

    @NotBlank(message = "Store address is required")
    private String storeAddress;
    
    private Double latitude;
    private Double longitude;
}
