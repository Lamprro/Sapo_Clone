package com.example.Sapo_Clone.DTO.Response.Order;

import com.example.Sapo_Clone.Entity.OrderDetail;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class OrderItemResponse {
    private Integer productId;
    private String productName;
    private Integer quantity;
    private Double price;
    private Double subtotal;

    public static OrderItemResponse fromEntity(OrderDetail detail) {
        if (detail == null) return null;
        return OrderItemResponse.builder()
                .productId(detail.getProduct() != null ? detail.getProduct().getId() : null)
                .productName(detail.getProduct() != null ? detail.getProduct().getProductName() : "Sản phẩm đã bị xóa")
                .quantity(detail.getQuantity())
                .price(detail.getPrice())
                .subtotal(detail.getSubtotal())
                .build();
    }
}
