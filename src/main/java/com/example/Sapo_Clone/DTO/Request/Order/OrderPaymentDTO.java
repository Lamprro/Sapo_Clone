package com.example.Sapo_Clone.DTO.Request.Order;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class OrderPaymentDTO {
    @NotNull(message = "Payment status cannot be null")
    private int paymentStatus; // 0:UNPAID, 1:PAID, 2:FAILED, 3:REFUNDED
}
