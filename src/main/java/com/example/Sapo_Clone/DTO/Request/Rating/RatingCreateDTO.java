package com.example.Sapo_Clone.DTO.Request.Rating;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

@Data
@AllArgsConstructor
@NoArgsConstructor
@FieldDefaults(level = lombok.AccessLevel.PRIVATE)
public class RatingCreateDTO {

    @NotNull(message = "Rating score is required")
    @Min(value = 1, message = "Rating must be at least 1 star")
    @Max(value = 5, message = "Rating cannot exceed 5 stars")
    Integer rating;

    @NotBlank(message = "Comment cannot be empty")
    String comment;

    @NotNull(message = "Product ID is required")
    Integer productId;
    
    // Note: customerId/userId will be taken from Authentication context for security
}
