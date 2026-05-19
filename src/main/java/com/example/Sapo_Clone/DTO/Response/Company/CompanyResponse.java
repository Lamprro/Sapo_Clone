package com.example.Sapo_Clone.DTO.Response.Company;

import com.example.Sapo_Clone.Entity.Company;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class CompanyResponse {
    private int id;
    private String companyName;
    private String companyAddress;
    private LocalDateTime createdAt;
    
    public static CompanyResponse fromEntity(Company company) {
        return CompanyResponse.builder()
                .id(company.getId())
                .companyName(company.getCompanyName())
                .companyAddress(company.getCompanyAddress())
                .createdAt(company.getCreatedAt())
                .build();
    }
}
