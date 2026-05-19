package com.example.Sapo_Clone.DTO.Response.Product;

import lombok.Builder;
import lombok.Data;
import org.springframework.data.domain.Page;

@Data
@Builder
public class ProductReportDetailResponse {
    private int productId;
    private String productName;
    private int totalSellQuantity;
    private Double totalRevenue;
    private Double totalProfit;
    private Double evaluationScore;
    
    private Page<ProductOrderHistoryResponse> orderHistory;
}
