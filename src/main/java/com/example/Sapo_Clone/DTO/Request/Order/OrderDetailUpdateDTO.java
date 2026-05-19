package com.example.Sapo_Clone.DTO.Request.Order;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

@Data
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = lombok.AccessLevel.PRIVATE)
public class OrderDetailUpdateDTO {
    @NotBlank(message = "Product Id is required")
    int productId;

    @NotBlank(message = "Quantity is required")
    int quantity;

    Double originalPrice;

    Double price;

    Double subtotal;

    @NotBlank(message = "Order Id is required")
    int orderId;

}


