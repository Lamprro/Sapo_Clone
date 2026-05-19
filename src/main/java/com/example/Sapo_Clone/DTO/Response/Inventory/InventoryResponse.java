package com.example.Sapo_Clone.DTO.Response.Inventory;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

@Data
@AllArgsConstructor
@NoArgsConstructor
@FieldDefaults(level = lombok.AccessLevel.PRIVATE)
public class InventoryResponse {
    int id;
    int productId;
    int quantity;
    int storeId;
}
