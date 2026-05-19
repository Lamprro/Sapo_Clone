package com.example.Sapo_Clone.DTO.Response.Promotion;

import com.example.Sapo_Clone.Entity.Promotion;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
@FieldDefaults(level = lombok.AccessLevel.PRIVATE)
public class PromotionListResponse {
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

    public static PromotionListResponse fromEntity(Promotion promotion) {
        if (promotion == null) return null;
        return PromotionListResponse.builder()
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
                .build();
    }
}
