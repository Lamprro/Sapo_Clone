package com.example.Sapo_Clone.DTO.Response.Product.Manage;

import com.example.Sapo_Clone.DTO.Response.Category.CategoryResponse;
import com.example.Sapo_Clone.DTO.Response.ProductImage.ProductImageResponse;
import com.example.Sapo_Clone.DTO.Response.Rating.RatingResponse;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
@FieldDefaults(level = lombok.AccessLevel.PRIVATE)
public class ProductInfoDetailResponseM {
    int id;
    String productName;
    String description;
    String barcode;
    Double avgStar;
    Double importPrice;
    Double sellPriceOriginal;
    Double sellPrice;
    String companyName;
    String unitName;
    int status;
    List<ProductImageResponse> ProductImageResponses;
    List<CategoryResponse> categories;
    List<RatingResponse> ratings;
}

