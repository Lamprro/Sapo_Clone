package com.example.Sapo_Clone.DTO.Request.Product;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class ChangeProductStatusDTO {

    @NotNull(message = "Status is required")
    private Integer status; // 0: inactive | 1: active
}
