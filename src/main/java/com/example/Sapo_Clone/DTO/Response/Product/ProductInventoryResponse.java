package com.example.Sapo_Clone.DTO.Response.Product;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductInventoryResponse implements Serializable {
    private int productId;
    private int storeId;
    private int quantity;
}
