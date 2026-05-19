package com.example.Sapo_Clone.DTO.Request.Provider;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

@Data
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = lombok.AccessLevel.PRIVATE)
public class ProviderCreateDTO {
    @NotBlank(message = "Provider name is required")
    String providerName;
    
    @NotBlank(message = "Provider UEi is required")
    String providerUei;
    
    @NotBlank(message = "Provider phone is required")
    String providerPhone;
    
    @NotBlank(message = "Provider address is required")
    String providerAddress;
    
    String description;
}
