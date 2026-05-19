package com.example.Sapo_Clone.DTO.Request.Order;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = lombok.AccessLevel.PRIVATE)
public class DisposeOrderCreateDTO {

    // StoreId is optional now, if null we get it from the employee
    Integer storeId;

    String note;

    @NotEmpty(message = "Dispose details cannot be empty")
    @Valid
    List<DisposeOrderDetailDTO> disposeDetails;
}