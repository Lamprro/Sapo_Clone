package com.example.Sapo_Clone.DTO.Response.Order.Manage;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

import java.time.LocalDateTime;

@Data
@AllArgsConstructor
@NoArgsConstructor
@FieldDefaults(level = lombok.AccessLevel.PRIVATE)
public class OrderInfoResponseM {
    int id;
    String shippingAddress;
    double totalAmount;
    int status;
    int redeemPoint;
    int earnPoint;
    LocalDateTime createdAt;
    LocalDateTime updatedAt;
    String paymentMethod;
    String note;
    int customerId;
    int employeeId;
    int promotionId;
    int storeId;
}
