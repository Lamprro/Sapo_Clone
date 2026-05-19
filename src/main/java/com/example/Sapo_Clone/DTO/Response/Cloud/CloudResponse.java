package com.example.Sapo_Clone.DTO.Response.Cloud;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CloudResponse {
    private String imageUrl;
    private String publicId;
}
