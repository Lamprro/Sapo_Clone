package com.example.Sapo_Clone.DTO.Request.PurchaseOrder;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

@Data
@AllArgsConstructor
@NoArgsConstructor
@FieldDefaults(level = lombok.AccessLevel.PRIVATE)
public class PurchaseOrderDetailUpdateDTO {
    @NotBlank(message = "Product Id is required")
    int productId;

    int quantity;

    Double price;

    Double subtotal;

    @NotBlank(message = "Purchase Order Id is required")
    int purchaseOrderId;
}

