package com.example.Sapo_Clone.Service;

import com.example.Sapo_Clone.DTO.Response.Cloud.CloudResponse;
import org.springframework.web.multipart.MultipartFile;
import java.util.concurrent.CompletableFuture;

public interface CloudService {
    CompletableFuture<CloudResponse> uploadToCloudAsync(byte[] fileBytes, String originalFilename);
    CloudResponse uploadToCloud(MultipartFile file);
    CloudResponse uploadToCloud(byte[] fileBytes, String originalFilename);
    void deleteFromCloud(String publicId);
}
