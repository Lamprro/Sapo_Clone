package com.example.Sapo_Clone.DTO.Response.ProductImage;

import com.example.Sapo_Clone.Entity.ProductImage;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductImageResponse {
    private int id;
    private String imageUrl;
    private String publicId; // Bổ sung publicId
    private int status;
    private boolean isMain;

    public static ProductImageResponse fromEntity(ProductImage image, boolean isMain) {
        if (image == null) return null;
        return ProductImageResponse.builder()
                .id(image.getId())
                .imageUrl(image.getImageUrl())
                .publicId(image.getPublicId())
                .status(image.getStatus())
                .isMain(isMain)
                .build();
    }
}