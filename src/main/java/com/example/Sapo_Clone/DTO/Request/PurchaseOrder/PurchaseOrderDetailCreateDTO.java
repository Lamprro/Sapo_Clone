package com.example.Sapo_Clone.DTO.Request.PurchaseOrder;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

@Data
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = lombok.AccessLevel.PRIVATE)
public class PurchaseOrderDetailCreateDTO {

    @NotNull(message = "Product ID is required")
    Integer productId;

    @NotNull(message = "Quantity is required")
    @Min(value = 1, message = "Quantity must be at least 1")
    int quantity;

    @NotNull(message = "Purchase price is required")
    @Min(value = 0, message = "Price cannot be negative")
    Double price;
}
