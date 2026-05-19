package com.example.Sapo_Clone.DTO.Response.Order.Customer;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

import java.time.LocalDateTime;

@Data
@AllArgsConstructor
@NoArgsConstructor
@FieldDefaults(level = lombok.AccessLevel.PRIVATE)
public class OrderInfoResponseC {
    int id;
    int storeId;
    LocalDateTime orderDate;
    double totalAmount;
    int status;
    String shippingAddress;
    String paymentMethod;
    int customerId;
    int earnPoint;
    Integer promotionId;
}
