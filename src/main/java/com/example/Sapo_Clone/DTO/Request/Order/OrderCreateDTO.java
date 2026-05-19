package com.example.Sapo_Clone.DTO.Request.Order;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
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
public class OrderCreateDTO {

    @NotNull(message = "Customer ID is required")
    Integer customerId;

    Integer employeeId;

    // Remove NotNull because we can determine store from shipping address
    Integer storeId;

    Integer status;

    Integer promotionId;

    @NotNull(message = "Payment method is required")
    String paymentMethod;

    String shippingAddress;

    String note;

    @Min(value = 0, message = "Earn point cannot be negative")
    @Builder.Default
    Integer earnPoint = 0;

    @Min(value = 0, message = "Redeem point cannot be negative")
    @Builder.Default
    Integer redeemPoint = 0;

    @NotEmpty(message = "Order details cannot be empty")
    @Valid
    List<OrderDetailCreateDTO> orderDetails;


}
