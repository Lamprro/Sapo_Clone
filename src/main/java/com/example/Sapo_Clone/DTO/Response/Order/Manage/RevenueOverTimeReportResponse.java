package com.example.Sapo_Clone.DTO.Response.Order.Manage;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = lombok.AccessLevel.PRIVATE)
public class RevenueOverTimeReportResponse {
    int storeId;
    String storeName;
    LocalDateTime startDate;
    LocalDateTime endDate;
    double totalRevenue;
    double totalOrder;
    List<OrderInfoResponseM> orderInfoResponseMList;
}
