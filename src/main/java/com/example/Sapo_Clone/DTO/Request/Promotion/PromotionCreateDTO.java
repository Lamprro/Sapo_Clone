package com.example.Sapo_Clone.DTO.Request.Promotion;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

import java.time.LocalDateTime;
import java.util.List;

import jakarta.validation.constraints.NotNull;

@Data
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = lombok.AccessLevel.PRIVATE)
public class PromotionCreateDTO {
    @NotBlank(message = "Promotion name is required")
    String promotionName;
    @NotBlank(message = "Description is required")
    String description;
    @NotNull(message = "Scope is required")
    Integer scope;
    @NotNull(message = "Discount type is required")
    Integer discountType;
    @NotNull(message = "Discount value is required")
    Double discountValue;
    @NotNull(message = "Max account is required")
    Double maxAccount;
    @NotNull(message = "Min account is required")
    Double minAccount;
    @NotNull(message = "Start date is required")
    LocalDateTime startDate;
    @NotNull(message = "End date is required")
    LocalDateTime endDate;

    List<Integer> productIds;

}
