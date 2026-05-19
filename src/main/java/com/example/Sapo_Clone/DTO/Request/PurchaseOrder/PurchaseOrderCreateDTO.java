package com.example.Sapo_Clone.DTO.Request.PurchaseOrder;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = lombok.AccessLevel.PRIVATE)
public class PurchaseOrderCreateDTO {
    
    int status; // 0: DRAFT, 1: COMPLETED, 4: CANCELLED

    String note;

    Integer storeId;

    @NotNull(message = "Provider ID is required")
    Integer providerId;

    @NotEmpty(message = "Purchase order details are required")
    @Valid
    List<PurchaseOrderDetailCreateDTO> purchaseOrderDetails;
}
