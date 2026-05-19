package com.example.Sapo_Clone.DTO.Response.Product;

public interface ProductReportProjection {
    int getProductId();
    String getProductName();
    Integer getTotalSellQuantity();
    Double getTotalRevenue();
    Double getTotalProfit();
    Double getEvaluationScore();
}
