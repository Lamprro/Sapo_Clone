package com.example.Sapo_Clone.Service;

import com.example.Sapo_Clone.DTO.Request.Promotion.PromotionCreateDTO;
import com.example.Sapo_Clone.DTO.Request.Promotion.PromotionUpdateDTO;
import com.example.Sapo_Clone.DTO.Response.Promotion.PromotionListResponse;
import com.example.Sapo_Clone.DTO.Response.Promotion.PromotionResponse;
import com.example.Sapo_Clone.Entity.Product;
import org.springframework.data.domain.Page;

public interface PromotionService {
    PromotionResponse createProductPromotion(PromotionCreateDTO dto);
    PromotionResponse createOrderPromotion(PromotionCreateDTO dto);
    PromotionResponse updatePromotionStatus(int promotionId, int status);
    PromotionResponse updatePromotion(int promotionId, PromotionUpdateDTO promotionUpdateDTO);
    Page<PromotionListResponse> getPromotionByCompanyId_Keyword(int companyId, String keyword, int page, int size);
    PromotionResponse getPromotionById(int promotionId);
    void recalculateProductPrice(Product p, int excludedPromotionId);
}
