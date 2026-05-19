package com.example.Sapo_Clone.DTO.Response.ProductImage;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductImageListResponse {
    private ProductImageResponse mainImage;
    private List<ProductImageResponse> images;
}
