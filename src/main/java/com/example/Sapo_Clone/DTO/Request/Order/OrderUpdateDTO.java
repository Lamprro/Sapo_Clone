package com.example.Sapo_Clone.DTO.Request.Order;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.List;

@Data
public class OrderUpdateDTO {
    @NotNull(message = "Payment method cannot be null")
    private String paymentMethod;

    private String shippingAddress;
    private String note;

    @NotEmpty(message = "Order must have at least one item")
    private List<OrderDetailCreateDTO> items;
}

