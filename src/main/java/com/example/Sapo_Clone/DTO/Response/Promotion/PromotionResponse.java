package com.example.Sapo_Clone.DTO.Response.Promotion;

import com.example.Sapo_Clone.Entity.Promotion;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

import java.util.List;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
@FieldDefaults(level = lombok.AccessLevel.PRIVATE)
public class PromotionResponse {
    int id;
    int scope;
    String promotionName;
    Double discountValue;
    String discountType;
    Double maxAccount;
    Double minAccount;
    String description;
    java.time.LocalDateTime startDate;
    java.time.LocalDateTime endDate;
    int status;
    List<Integer> productIds;

    public static PromotionResponse fromEntity(Promotion promotion) {
        if (promotion == null) return null;
        return PromotionResponse.builder()
                .id(promotion.getId())
                .scope(promotion.getScope())
                .promotionName(promotion.getPromotionName())
                .discountValue(promotion.getDiscountValue())
                .discountType(String.valueOf(promotion.getDiscountType()))
                .maxAccount(promotion.getMaxAccount())
                .minAccount(promotion.getMinAccount())
                .startDate(promotion.getStartedAt())
                .endDate(promotion.getEndedAt())
                .status(promotion.getStatus())
                .description(promotion.getDescription())
                .productIds(promotion.getProducts() != null ? promotion.getProducts().stream().map(p -> p.getId()).toList() : null)
                .build();
    }
}
