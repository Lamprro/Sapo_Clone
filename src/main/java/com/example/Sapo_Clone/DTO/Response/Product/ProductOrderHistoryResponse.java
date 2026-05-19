package com.example.Sapo_Clone.DTO.Response.Product;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Builder
public class ProductOrderHistoryResponse {
    private int orderId;
    private String customerName;
    private int quantity;
    private Double price;
    private Double subtotal;
    private LocalDateTime createdAt;
}
