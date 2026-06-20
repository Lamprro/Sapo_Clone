package com.example.Sapo_Clone.Schedule;

import com.example.Sapo_Clone.Entity.Product;
import com.example.Sapo_Clone.Entity.Promotion;
import com.example.Sapo_Clone.Repository.PromotionRepository;
import com.example.Sapo_Clone.Service.PromotionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Component
@Slf4j
@RequiredArgsConstructor
public class PromotionTask {

    private final PromotionRepository promotionRepository;
    private final PromotionService promotionService;
    private final org.springframework.cache.CacheManager cacheManager;

    private void clearProductListCaches() {
        try {
            if (cacheManager.getCache("product:list:manage") != null) cacheManager.getCache("product:list:manage").clear();
            if (cacheManager.getCache("product:list:customer") != null) cacheManager.getCache("product:list:customer").clear();
            if (cacheManager.getCache("product:store") != null) cacheManager.getCache("product:store").clear();
            log.info("Cleared product list caches via PromotionTask");
        } catch (Exception e) {
            log.warn("Failed to clear product list caches in PromotionTask", e);
        }
    }

    @Scheduled(fixedRate = 60000) // Run every 1 minute
    @Transactional
    public void expirePromotionsTask() {
        LocalDateTime now = LocalDateTime.now();
        log.trace("Running scheduled PromotionTask to check for expired promotions at {}", now);

        List<Promotion> expiredPromotions = promotionRepository.findByStatusAndEndedAtBefore(1, now);

        if (!expiredPromotions.isEmpty()) {
            for (Promotion promotion : expiredPromotions) {
                log.info("Expiring Promotion ID = {}", promotion.getId());
                promotion.setStatus(2);

                if (promotion.getScope() == 1) { // Product Promotion
                    List<Product> products = promotion.getProducts();
                    if (products != null && !products.isEmpty()) {
                        for (Product p : products) {
                            promotionService.recalculateProductPrice(p, -1);
                        }
                        log.info("Re-evaluated prices for {} products after Promotion ID = {} expired", products.size(),
                                promotion.getId());
                    }
                }
            }
            promotionRepository.saveAll(expiredPromotions);
            clearProductListCaches();
        }
    }

    @Scheduled(fixedRate = 60000)
    @Transactional
    public void salePromotionsTask() {
        LocalDateTime now = LocalDateTime.now();
        log.trace("Running scheduled PromotionTask to check for selling promotion at {}", now);

        List<Promotion> activePromotion = promotionRepository.findActivePromotions(now);

        if (!activePromotion.isEmpty()) {
            for (Promotion promotion : activePromotion) {
                log.info("Applying/Maintaining Promotion ID = {}", promotion.getId());

                if (promotion.getScope() == 1) { // Product Promotion
                    List<Product> products = promotion.getProducts();
                    if (products != null && !products.isEmpty()) {
                        for (Product p : products) {
                            promotionService.recalculateProductPrice(p, -1);
                        }
                    }
                }
            }
            clearProductListCaches();
        }
    }
}
