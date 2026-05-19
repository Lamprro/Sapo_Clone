package com.example.Sapo_Clone.DTO.Request.Promotion;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

@Data
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = lombok.AccessLevel.PRIVATE)
public class PromotionUpdateDTO {
    private String promotionName;
    private String description;
    private Integer scope;
    private Integer discountType;
    private Double discountValue;
    private Double maxAccount;
    private Double minAccount;
    private java.time.LocalDateTime startDate;
    private java.time.LocalDateTime endDate;
    private Integer status;
    private java.util.List<Integer> productIds;

}
