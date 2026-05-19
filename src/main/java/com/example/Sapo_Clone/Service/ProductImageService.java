package com.example.Sapo_Clone.Service;

import com.example.Sapo_Clone.DTO.Response.ProductImage.ProductImageListResponse;
import com.example.Sapo_Clone.DTO.Response.ProductImage.ProductImageResponse;
import org.springframework.web.multipart.MultipartFile;

public interface ProductImageService {

    ProductImageListResponse getImagesByProduct(int productId);

    ProductImageResponse uploadImage(int productId, MultipartFile file);

    void setMainImage(int productId, int imageId);

    void deleteImage(int productId, int imageId);
}
