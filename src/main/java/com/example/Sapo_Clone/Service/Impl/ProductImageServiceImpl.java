package com.example.Sapo_Clone.Service.Impl;

import com.example.Sapo_Clone.DTO.Response.Cloud.CloudResponse;
import com.example.Sapo_Clone.DTO.Response.ProductImage.ProductImageListResponse;
import com.example.Sapo_Clone.DTO.Response.ProductImage.ProductImageResponse;
import com.example.Sapo_Clone.Entity.Product;
import com.example.Sapo_Clone.Entity.ProductImage;
import com.example.Sapo_Clone.Exception.AppException;
import com.example.Sapo_Clone.Exception.ErrorCode;
import com.example.Sapo_Clone.Repository.ProductImageRepository;
import com.example.Sapo_Clone.Repository.ProductRepository;
import com.example.Sapo_Clone.Service.CloudService;
import com.example.Sapo_Clone.Service.ProductImageService;
import com.example.Sapo_Clone.Utils.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Caching;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CompletableFuture;

@Service
@RequiredArgsConstructor
@Slf4j
public class ProductImageServiceImpl implements ProductImageService {

    private final ProductImageRepository productImageRepository;
    private final ProductRepository productRepository;
    private final CloudService cloudService;

    private static final int STATUS_ACTIVE = 1;
    private static final int STATUS_MAIN = 2;

    private void verifyOwnership(int companyId, int productId) {
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new AppException(ErrorCode.PRODUCT_NOT_FOUND));
        if (product.getCompany() == null || product.getCompany().getId() != companyId) {
            throw new AppException(ErrorCode.PRODUCT_NOT_FOUND);
        }
    }

    @Override
    public ProductImageListResponse getImagesByProduct(int productId) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        log.info("Fetching images for productId={} company={}", productId, companyId);

        verifyOwnership(companyId, productId);

        List<ProductImage> allImages = productImageRepository.findByProduct_Id(productId);
        ProductImage main = null;
        List<ProductImageResponse> others = new ArrayList<>();

        for (ProductImage img : allImages) {
            if (img.getStatus() == STATUS_MAIN && main == null) {
                main = img;
            } else {
                others.add(ProductImageResponse.fromEntity(img, false));
            }
        }

        return ProductImageListResponse.builder()
                .mainImage(main != null ? ProductImageResponse.fromEntity(main, true) : null)
                .images(others)
                .build();
    }

    @Override
    @Transactional
    @Caching(evict = {
            @CacheEvict(value = "product:list:manage", allEntries = true),
            @CacheEvict(value = "product:list:customer", allEntries = true),
            @CacheEvict(value = "product:store", allEntries = true),
            @CacheEvict(value = "product:customer", key = "'-c:' + T(com.example.Sapo_Clone.Utils.SecurityUtils).getCurrentCompanyId() + '-p:' + #productId"),
            @CacheEvict(value = "product:manage", key = "'-c:' + T(com.example.Sapo_Clone.Utils.SecurityUtils).getCurrentCompanyId() + '-p:' + #productId")
    })
    public ProductImageResponse uploadImage(int productId, MultipartFile file) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        log.info("Uploading image for productId={} company={}", productId, companyId);
        
        if (file == null || file.isEmpty()) throw new AppException(ErrorCode.VALIDATION_ERROR);

        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new AppException(ErrorCode.PRODUCT_NOT_FOUND));
        if (product.getCompany().getId() != companyId) throw new AppException(ErrorCode.PRODUCT_NOT_FOUND);

        // Determine status first
        List<ProductImage> existingImages = productImageRepository.findByProduct_Id(productId);
        int status = existingImages.isEmpty() ? STATUS_MAIN : STATUS_ACTIVE;

        // Read bytes before starting async task to ensure they are available
        byte[] fileBytes;
        String originalFilename = file.getOriginalFilename();
        try {
            fileBytes = file.getBytes();
        } catch (java.io.IOException e) {
            log.error("Failed to read bytes from upload file", e);
            throw new AppException(ErrorCode.VALIDATION_ERROR);
        }

        // Save a placeholder image record in the database first so the user gets a fast response
        ProductImage imagePlaceholder = new ProductImage();
        imagePlaceholder.setProduct(product);
        imagePlaceholder.setImageUrl("UPLOADING..."); 
        imagePlaceholder.setPublicId("PENDING");
        imagePlaceholder.setStatus(status);
        final ProductImage savedImage = productImageRepository.saveAndFlush(imagePlaceholder);
        final int savedImageId = savedImage.getId();

        // Upload asynchronously
        CompletableFuture<CloudResponse> futureCloudResponse = cloudService.uploadToCloudAsync(fileBytes, originalFilename);
        
        futureCloudResponse.thenAccept(cloudResponse -> {
            // Fetch the image again to ensure we have a fresh copy (though save() handles detached well)
            productImageRepository.findById(savedImageId).ifPresent(img -> {
                img.setImageUrl(cloudResponse.getImageUrl());
                img.setPublicId(cloudResponse.getPublicId());
                productImageRepository.save(img);
                log.info("Async upload finished. Updated DB for product image ID: {}", savedImageId);
            });
        }).exceptionally(ex -> {
            log.error("Async upload failed for product image ID: {}", savedImageId, ex);
            productImageRepository.deleteById(savedImageId);
            return null;
        });

        // Return immediately with the placeholder info
        return ProductImageResponse.fromEntity(savedImage, status == STATUS_MAIN);
    }

    @Override
    @Transactional
    @Caching(evict = {
            @CacheEvict(value = "product:list:manage", allEntries = true),
            @CacheEvict(value = "product:list:customer", allEntries = true),
            @CacheEvict(value = "product:store", allEntries = true),
            @CacheEvict(value = "product:customer", key = "'-c:' + T(com.example.Sapo_Clone.Utils.SecurityUtils).getCurrentCompanyId() + '-p:' + #productId"),
            @CacheEvict(value = "product:manage", key = "'-c:' + T(com.example.Sapo_Clone.Utils.SecurityUtils).getCurrentCompanyId() + '-p:' + #productId")
    })
    public void setMainImage(int productId, int imageId) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        log.info("Setting imageId={} as MAIN for productId={} company={}", imageId, productId, companyId);

        verifyOwnership(companyId, productId);

        ProductImage image = productImageRepository.findByIdAndProduct_Id(imageId, productId)
                .orElseThrow(() -> new AppException(ErrorCode.IMAGE_NOT_FOUND));

        productImageRepository.resetAllImagesToActive(productId);
        image.setStatus(STATUS_MAIN);
        productImageRepository.save(image);
    }

    @Override
    @Transactional
    @Caching(evict = {
            @CacheEvict(value = "product:list:manage", allEntries = true),
            @CacheEvict(value = "product:list:customer", allEntries = true),
            @CacheEvict(value = "product:store", allEntries = true),
            @CacheEvict(value = "product:customer", key = "'-c:' + T(com.example.Sapo_Clone.Utils.SecurityUtils).getCurrentCompanyId() + '-p:' + #productId"),
            @CacheEvict(value = "product:manage", key = "'-c:' + T(com.example.Sapo_Clone.Utils.SecurityUtils).getCurrentCompanyId() + '-p:' + #productId")
    })
    public void deleteImage(int productId, int imageId) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        log.info("Deleting imageId={} for productId={} company={}", imageId, productId, companyId);

        verifyOwnership(companyId, productId);

        ProductImage image = productImageRepository.findByIdAndProduct_Id(imageId, productId)
                .orElseThrow(() -> new AppException(ErrorCode.IMAGE_NOT_FOUND));

        boolean wasMain = (image.getStatus() == STATUS_MAIN);
        try {
            cloudService.deleteFromCloud(image.getPublicId());
        } catch (Exception e) {
            log.warn("Failed to delete image from cloud storage for publicId={}, proceeding with DB deletion", image.getPublicId(), e);
        }
        productImageRepository.delete(image);

        if (wasMain) {
            productImageRepository.findFirstByProduct_IdAndStatus(productId, STATUS_ACTIVE)
                    .ifPresent(nextImg -> {
                        nextImg.setStatus(STATUS_MAIN);
                        productImageRepository.save(nextImg);
                    });
        }
    }
}