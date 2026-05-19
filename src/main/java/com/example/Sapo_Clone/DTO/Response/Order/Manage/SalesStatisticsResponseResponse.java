package com.example.Sapo_Clone.DTO.Response.Order.Manage;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = lombok.AccessLevel.PRIVATE)
public class SalesStatisticsResponseResponse {
    int storeId;
    String storeName;
    LocalDateTime startDate;
    LocalDateTime endDate;
    Double totalRevenue;
    Double totalCogs;
    Double inventoryValue;
    Double totalPurchaseSpending;
}
