package com.example.Sapo_Clone.DTO.Response.Inventory;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InventoryByStoreResponse {
    private int productId;
    private String barcode;
    private String productName;
    private String mainImage;
    private int quantity;
}
