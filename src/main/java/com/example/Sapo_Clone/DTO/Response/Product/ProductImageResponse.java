package com.example.Sapo_Clone.DTO.Response.Product;

import com.example.Sapo_Clone.Entity.ProductImage;
import lombok.Builder;
import lombok.Data;

import java.io.Serializable;

@Data
@Builder
public class ProductImageResponse implements Serializable {
    private int id;
    private String imageUrl;
    private String publicId;
    private int status;
    private boolean isMain; // Indicates if this is the main image (e.g., the first one)

    public static ProductImageResponse fromEntity(ProductImage image, boolean isMain) {
        return ProductImageResponse.builder()
                .id(image.getId())
                .imageUrl(image.getImageUrl())
                .publicId(image.getPublicId())
                .status(image.getStatus())
                .isMain(isMain)
                .build();
    }
}