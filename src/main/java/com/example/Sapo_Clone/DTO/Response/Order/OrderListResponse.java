package com.example.Sapo_Clone.DTO.Response.Order;

import com.example.Sapo_Clone.Entity.Order;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class OrderListResponse {
    private Integer id;
    private Integer customerId;
    private String customerName;
    private Integer employeeId;
    private String employeeName;
    private Integer storeId;
    private String storeName;
    private int status;
    private Double totalAmount;
    private String paymentMethod;
    private int paymentStatus;
    private LocalDateTime createdAt;
    private String shippingAddress;
    private String note;
    private Integer promotionId;
    private String promotionName;

    public static OrderListResponse fromEntity(Order order) {
        if (order == null)
            return null;

        return OrderListResponse.builder()
                .id(order.getId())
                .customerId(order.getCustomer() != null ? order.getCustomer().getId() : null)
                .customerName(order.getCustomer() != null ? order.getCustomer().getUserFullName() : null)
                .employeeId(order.getEmployee() != null ? order.getEmployee().getId() : null)
                .employeeName(order.getEmployee() != null ? order.getEmployee().getUserFullName() : null)
                .storeId(order.getStore() != null ? order.getStore().getId() : null)
                .storeName(order.getStore() != null ? order.getStore().getStoreName() : null)
                .status(order.getStatus())
                .totalAmount(order.getTotalAmount())
                .paymentMethod(order.getPaymentMethod())
                .paymentStatus(order.getPaymentStatus())
                .createdAt(order.getCreatedAt())
                .shippingAddress(order.getShippingAddress())
                .note(order.getNote())
                .promotionId(order.getPromotion() != null ? order.getPromotion().getId() : null)
                .promotionName(order.getPromotion() != null ? order.getPromotion().getPromotionName() : null)
                .build();
    }
}
