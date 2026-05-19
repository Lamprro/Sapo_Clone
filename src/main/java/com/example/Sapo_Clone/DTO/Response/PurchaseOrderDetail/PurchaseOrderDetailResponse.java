package com.example.Sapo_Clone.DTO.Response.PurchaseOrderDetail;

import com.example.Sapo_Clone.DTO.Response.Product.ProductResponse;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

@Data
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = lombok.AccessLevel.PRIVATE)
public class PurchaseOrderDetailResponse {
    int id;
    int quantity;
    Double price;
    Double subtotal;
    int purchaseOrderId;
    ProductResponse ProductResponse;
}


