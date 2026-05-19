package com.example.Sapo_Clone.DTO.Request.Company;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class CompanyDTO {
    @NotBlank(message = "Company name is required")
    private String companyName;
    private String companyAddress;
}
