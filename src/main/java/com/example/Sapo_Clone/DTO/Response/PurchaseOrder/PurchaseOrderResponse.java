package com.example.Sapo_Clone.DTO.Response.PurchaseOrder;

import com.example.Sapo_Clone.DTO.Response.PurchaseOrderDetail.PurchaseOrderDetailResponse;
import com.example.Sapo_Clone.Entity.PurchaseOrder;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

import java.util.List;
import java.util.stream.Collectors;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = lombok.AccessLevel.PRIVATE)
public class PurchaseOrderResponse {
    int id;
    Double totalAmount;
    int status;
    String note;
    int userId;
    String userName;
    int storeId;
    String storeName;
    int providerId;
    String providerName;
    String createdAt;
    String updatedAt;
    List<PurchaseOrderDetailResponse> items;

    public static PurchaseOrderResponse fromEntity(PurchaseOrder purchaseOrder) {
        if (purchaseOrder == null) return null;
        return PurchaseOrderResponse.builder()
                .id(purchaseOrder.getId())
                .totalAmount(purchaseOrder.getTotalAmount())
                .status(purchaseOrder.getStatus())
                .note(purchaseOrder.getNote())
                .userId(purchaseOrder.getUser().getId())
                .userName(purchaseOrder.getUser().getUserFullName())
                .storeId(purchaseOrder.getStore().getId())
                .storeName(purchaseOrder.getStore().getStoreName())
                .providerId(purchaseOrder.getProvider().getId())
                .providerName(purchaseOrder.getProvider().getProviderName())
                .createdAt(purchaseOrder.getCreatedAt() != null ? purchaseOrder.getCreatedAt().toString() : null)
                .updatedAt(purchaseOrder.getUpdatedAt() != null ? purchaseOrder.getUpdatedAt().toString() : null)
                .items(purchaseOrder.getPurchaseOrderDetails() != null ? 
                    purchaseOrder.getPurchaseOrderDetails().stream()
                        .map(detail -> {
                            PurchaseOrderDetailResponse res = new PurchaseOrderDetailResponse();
                            res.setId(detail.getId());
                            res.setQuantity(detail.getQuantity());
                            res.setPrice(detail.getPrice());
                            res.setSubtotal(detail.getSubtotal());
                            res.setPurchaseOrderId(purchaseOrder.getId());
                            
                            res.setProductResponse(com.example.Sapo_Clone.DTO.Response.Product.ProductResponse.fromEntity(detail.getProduct()));
                            return res;
                        }).collect(Collectors.toList()) : null)
                .build();
    }
}
