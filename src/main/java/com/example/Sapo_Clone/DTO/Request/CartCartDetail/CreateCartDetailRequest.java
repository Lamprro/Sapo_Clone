package com.example.Sapo_Clone.DTO.Request.CartCartDetail;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

@Data
@AllArgsConstructor
@NoArgsConstructor
@FieldDefaults(level = lombok.AccessLevel.PRIVATE)
public class CreateCartDetailRequest {
    @NotNull(message = "ProductId is required")
    int productId;
    @NotNull(message = "ProductId is required")
    @Min(value = 1, message = "The minimum of quantity is 1")
    int quantity;
}
