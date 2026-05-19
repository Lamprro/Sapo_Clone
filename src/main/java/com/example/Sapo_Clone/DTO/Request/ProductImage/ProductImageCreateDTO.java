package com.example.Sapo_Clone.DTO.Request.ProductImage;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

@Data
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = lombok.AccessLevel.PRIVATE)
public class ProductImageCreateDTO {

    @NotBlank(message = "Image URL is required")
    String imageUrl;

    @NotBlank(message = "Public Id is required")
    String publicId;

    @NotBlank(message = "Status is required")
    int status;

    @NotBlank(message = "Product Id is required")
    int productId;

}


