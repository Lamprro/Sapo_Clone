package com.example.Sapo_Clone.Service.Impl;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import com.example.Sapo_Clone.DTO.Response.Cloud.CloudResponse;
import com.example.Sapo_Clone.Exception.AppException;
import com.example.Sapo_Clone.Exception.ErrorCode;
import com.example.Sapo_Clone.Service.CloudService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.CompletableFuture;

@Service
@RequiredArgsConstructor
@Slf4j
public class CloudServiceImpl implements CloudService {

    private final Cloudinary cloudinary;

    private final org.springframework.cache.CacheManager cacheManager;

    @Override
    @Async("imageUploadExecutor")
    public CompletableFuture<CloudResponse> uploadToCloudAsync(byte[] fileBytes, String originalFilename) {
        return CompletableFuture.completedFuture(uploadToCloud(fileBytes, originalFilename));
    }

    @Override
    public CloudResponse uploadToCloud(MultipartFile file) {
        try {
            return uploadToCloud(file.getBytes(), file.getOriginalFilename());
        } catch (IOException e) {
            log.error("Failed to read bytes from MultipartFile", e);
            throw new AppException(ErrorCode.CLOUD_UPLOAD_FAIL);
        }
    }

    @Override
    public CloudResponse uploadToCloud(byte[] fileBytes, String originalFilename) {
        try {
            log.info("Uploading file to Cloudinary: {}", originalFilename);

            // Validate size < 5MB
            if (fileBytes.length > 5 * 1024 * 1024) {
                throw new AppException(ErrorCode.INVALID_IMAGE);
            }

            Map<?, ?> uploadResult = cloudinary.uploader().upload(fileBytes,
                    ObjectUtils.asMap(
                            "resource_type", "auto",
                            "folder", "sapo_clone/products"));

            String imageUrl = uploadResult.get("secure_url").toString();
            String publicId = uploadResult.get("public_id").toString();

            log.info("Upload successful. Public ID: {}", publicId);
            try {
                if (cacheManager.getCache("product:list:manage") != null) cacheManager.getCache("product:list:manage").clear();
                if (cacheManager.getCache("product:list:customer") != null) cacheManager.getCache("product:list:customer").clear();
                if (cacheManager.getCache("product:store") != null) cacheManager.getCache("product:store").clear();
            } catch (Exception ex) {
                log.warn("Failed to clear product list caches in CloudServiceImpl", ex);
            }
            return new CloudResponse(imageUrl, publicId);

        } catch (IOException e) {
            log.error("Failed to upload image to Cloudinary", e);
            throw new AppException(ErrorCode.CLOUD_UPLOAD_FAIL);
        }
    }

    @Override
    @Async("imageUploadExecutor")
    public void deleteFromCloud(String publicId) {
        try {
            log.info("Deleting file from Cloudinary asynchronously. public ID: {}", publicId);
            Map<?, ?> destroyResult = cloudinary.uploader().destroy(publicId, ObjectUtils.emptyMap());

            log.info("Delete result for {}: {}", publicId, destroyResult.get("result"));
        } catch (IOException e) {
            log.error("Failed to delete publicId {} from Cloudinary", publicId, e);
        }
    }
}
