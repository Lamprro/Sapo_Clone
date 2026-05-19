package com.example.Sapo_Clone.DTO.Request.Product;

import jakarta.validation.constraints.*;
import lombok.Data;

import java.util.List;

@Data
public class ProductCreateDTO {

    @NotBlank(message = "Product name cannot be blank")
    private String productName;

    private String description;

    @NotBlank(message = "Barcode cannot be blank")
    private String barcode;

    @NotNull(message = "Import price is required")
    @PositiveOrZero(message = "Import price must be >= 0")
    private Double importPrice;

    @NotNull(message = "Original sell price is required")
    @Positive(message = "Original sell price must be > 0")
    private Double sellPriceOriginal;

    @NotNull(message = "Sell price is required")
    @Positive(message = "Sell price must be > 0")
    private Double sellPrice;

    @NotNull(message = "Unit is required")
    private Long unitId;

    @NotEmpty(message = "At least one category is required")
    private List<Long> categoryIds;
}
