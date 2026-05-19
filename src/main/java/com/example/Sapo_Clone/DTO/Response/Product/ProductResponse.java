package com.example.Sapo_Clone.DTO.Response.Product;

import com.example.Sapo_Clone.Entity.Category;
import com.example.Sapo_Clone.Entity.Product;
import com.example.Sapo_Clone.Entity.ProductImage;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.util.List;
import java.util.stream.Collectors;
import java.io.Serializable;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ProductResponse implements Serializable {

        private int id;
        private String productName;
        private String description;
        private String barcode;
        private Double avgStar;
        private int status;
        private Double importPrice;
        private Double sellPriceOriginal;
        private Double sellPrice;
        private Long unitId;
        private String unitName;
        private List<Long> categoryIds;
        private List<String> categoryNames;
        private List<ProductImageResponse> images;
        private String mainImage; // Lấy ảnh có status = 2

        public static ProductResponse fromEntity(Product product) {
                List<ProductImageResponse> imageResponses = null;
                String mainImg = null;
                
                if (product.getProductImages() != null && !product.getProductImages().isEmpty()) {
                        // Map toàn bộ ảnh sang Response
                        imageResponses = product.getProductImages().stream()
                                .map(img -> ProductImageResponse.fromEntity(img, img.getStatus() == 2))
                                .collect(Collectors.toList());
                        
                        // Tìm ảnh có status = 2 (Main Image)
                        ProductImage mainImageEntity = product.getProductImages().stream()
                                .filter(img -> img.getStatus() == 2)
                                .findFirst()
                                .orElse(product.getProductImages().get(0)); // Fallback lấy ảnh đầu tiên nếu không có status=2
                                
                        mainImg = mainImageEntity.getImageUrl();
                }

                return ProductResponse.builder()
                                .id(product.getId())
                                .productName(product.getProductName())
                                .barcode(product.getBarcode())
                                .description(product.getDescription())
                                .avgStar(product.getAvgstar())
                                .status(product.getStatus())
                                .importPrice(product.getImportPrice())
                                .sellPriceOriginal(product.getSellPriceOriginal())
                                .sellPrice(product.getSellPrice())
                                .unitId(product.getUnit() != null ? (long) product.getUnit().getId() : null)
                                .unitName(product.getUnit() != null ? product.getUnit().getUnitName() : null)
                                .categoryIds(product.getCategoryList() != null ? product.getCategoryList().stream()
                                                .map(c -> (long) c.getId()).collect(Collectors.toList()) : null)
                                .categoryNames(product.getCategoryList() != null ? product.getCategoryList().stream()
                                                .map(Category::getCategoryName).collect(Collectors.toList()) : null)
                                .images(imageResponses)
                                .mainImage(mainImg)
                                .build();
        }

        public static ProductResponse fromEntityForCustomer(Product product) {
                List<ProductImageResponse> imageResponses = null;
                String mainImg = null;

                if (product.getProductImages() != null && !product.getProductImages().isEmpty()) {
                        // Map toàn bộ ảnh sang Response (Chỉ lấy ảnh có status = 1 hoặc 2)
                        imageResponses = product.getProductImages().stream()
                                .filter(img -> img.getStatus() == 1 || img.getStatus() == 2)
                                .map(img -> ProductImageResponse.fromEntity(img, img.getStatus() == 2))
                                .collect(Collectors.toList());
                        
                        // Tìm ảnh có status = 2 (Main Image)
                        ProductImage mainImageEntity = product.getProductImages().stream()
                                .filter(img -> img.getStatus() == 2)
                                .findFirst()
                                .orElse(product.getProductImages().stream()
                                        .filter(img -> img.getStatus() == 1 || img.getStatus() == 2)
                                        .findFirst()
                                        .orElse(null)); // Fallback
                                
                        mainImg = mainImageEntity != null ? mainImageEntity.getImageUrl() : null;
                }

                return ProductResponse.builder()
                                .id(product.getId())
                                .productName(product.getProductName())
                                .barcode(product.getBarcode())
                                .description(product.getDescription())
                                .avgStar(product.getAvgstar())
                                .status(product.getStatus())
                                .sellPrice(product.getSellPrice())
                                .unitName(product.getUnit() != null ? product.getUnit().getUnitName() : null)
                                .categoryNames(product.getCategoryList() != null ? product.getCategoryList().stream()
                                                .map(Category::getCategoryName).collect(Collectors.toList()) : null)
                                .images(imageResponses)
                                .mainImage(mainImg)
                                .build();
        }
}