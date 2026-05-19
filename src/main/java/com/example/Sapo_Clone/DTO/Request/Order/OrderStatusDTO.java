package com.example.Sapo_Clone.DTO.Request.Order;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class OrderStatusDTO {
    @NotNull(message = "Status cannot be null")
    private int status;
}
