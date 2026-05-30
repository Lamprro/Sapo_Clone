package com.example.Sapo_Clone.Service.Impl;

import com.example.Sapo_Clone.DTO.Request.Promotion.PromotionCreateDTO;
import com.example.Sapo_Clone.DTO.Request.Promotion.PromotionUpdateDTO;
import com.example.Sapo_Clone.DTO.Response.Promotion.PromotionListResponse;
import com.example.Sapo_Clone.DTO.Response.Promotion.PromotionResponse;
import com.example.Sapo_Clone.Entity.Company;
import com.example.Sapo_Clone.Entity.Notification;
import com.example.Sapo_Clone.Entity.Product;
import com.example.Sapo_Clone.Entity.Promotion;
import com.example.Sapo_Clone.Enum.NotificationType;
import com.example.Sapo_Clone.Exception.AppException;
import com.example.Sapo_Clone.Exception.ErrorCode;
import com.example.Sapo_Clone.Repository.CompanyRepository;
import com.example.Sapo_Clone.Repository.ProductRepository;
import com.example.Sapo_Clone.Repository.PromotionRepository;
import com.example.Sapo_Clone.Service.PromotionService;
import com.example.Sapo_Clone.Utils.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class PromotionServiceImpl implements PromotionService {

    private final PromotionRepository promotionRepository;
    private final ProductRepository productRepository;
    private final CompanyRepository companyRepository;
    private final ProductServiceImpl productService;
    private final org.springframework.context.ApplicationEventPublisher eventPublisher;

    private Promotion buildPromotionEntity(PromotionCreateDTO dto) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new AppException(ErrorCode.COMPANY_NOT_FOUND));

        Promotion promotion = new Promotion();
        promotion.setPromotionName(dto.getPromotionName());
        promotion.setScope(dto.getScope());
        promotion.setDiscountType(dto.getDiscountType());
        promotion.setDiscountValue(dto.getDiscountValue());
        promotion.setMaxAccount(dto.getMaxAccount());
        promotion.setMinAccount(dto.getMinAccount());
        promotion.setStartedAt(dto.getStartDate());
        promotion.setEndedAt(dto.getEndDate());
        promotion.setCompany(company);
        promotion.setDescription(dto.getDescription());
        promotion.setStatus(1); // Default to active

        return promotion;
    }

    @Override
    @Transactional
    public PromotionResponse createProductPromotion(PromotionCreateDTO dto) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        log.info("Creating product promotion name={}, companyId={}", dto.getPromotionName(), companyId);

        if (dto.getScope() != 1) { // 1 = Product Scope
            throw new AppException(ErrorCode.VALIDATION_ERROR);
        }

        Promotion promotion = buildPromotionEntity(dto);
        Promotion savedPromotion = promotionRepository.save(promotion);

        List<Product> affectedProducts = new ArrayList<>();
        if (dto.getProductIds() != null && !dto.getProductIds().isEmpty()) {
            for (Integer pId : dto.getProductIds()) {
                Product product = productRepository.findById(pId)
                        .orElseThrow(() -> new AppException(ErrorCode.PRODUCT_NOT_FOUND));

                if (product.getCompany().getId() != companyId) {
                    throw new AppException(ErrorCode.PRODUCT_NOT_FOUND);
                }

                // Add to join table and bidirectionally update for price recalculation
                if (product.getPromotions() == null) product.setPromotions(new ArrayList<>());
                product.getPromotions().add(savedPromotion);
                
                recalculateProductPrice(product, -1);
                affectedProducts.add(product);

            }
        }
        
        savedPromotion.setProducts(affectedProducts);
        promotionRepository.save(savedPromotion);
        productRepository.saveAll(affectedProducts);
        
        // Notify Customers about new promotion
        eventPublisher.publishEvent(Notification.builder()
                .title("New Promotion: " + savedPromotion.getPromotionName())
                .message("Check out our new promotion: " + savedPromotion.getDescription())
                .type(NotificationType.PROMOTION_CREATED)
                .targetRole("CUSTOMER")
                .companyId(companyId)
                .build());

        productService.clearProductListCaches();

        return PromotionResponse.fromEntity(savedPromotion);
    }

    @Override
    @Transactional
    public PromotionResponse createOrderPromotion(PromotionCreateDTO dto) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        log.info("Creating order promotion name={}, companyId={}", dto.getPromotionName(), companyId);

        if (dto.getScope() != 0) { // 0 = Order Scope
            throw new AppException(ErrorCode.VALIDATION_ERROR);
        }

        Promotion promotion = buildPromotionEntity(dto);
        Promotion saved = promotionRepository.save(promotion);

        // Notify Customers about new promotion
        eventPublisher.publishEvent(Notification.builder()
                .title("New Order Promotion: " + saved.getPromotionName())
                .message("Save big on your next order: " + saved.getDescription())
                .type(NotificationType.PROMOTION_CREATED)
                .targetRole("CUSTOMER")
                .companyId(companyId)
                .build());

        return PromotionResponse.fromEntity(saved);
    }

    @Override
    @Transactional
    public PromotionResponse updatePromotionStatus(int promotionId, int status) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        log.info("Updating promotion id={} status={} companyId={}", promotionId, status, companyId);
        
        Promotion promotion = promotionRepository.findById(promotionId)
                .orElseThrow(() -> new AppException(ErrorCode.PROMOTION_NOT_FOUND));

        if (promotion.getCompany().getId() != companyId) {
            throw new AppException(ErrorCode.COMPANY_NOT_FOUND);
        }

        boolean activeToInactive = (promotion.getStatus() == 1 && status == 0);
        
        promotion.setStatus(status);
        if (status == 0) {
            promotion.setEndedAt(LocalDateTime.now());
        } else if (status == 1) {
            promotion.setEndedAt(LocalDate.now().atTime(23, 59, 59));
        }

        // Hardening: Intelligently revert or re-apply prices
        if (activeToInactive && promotion.getScope() == 1) {
            List<Product> products = promotion.getProducts();
            if (products != null) {
                for (Product p : products) {
                    recalculateProductPrice(p, promotionId);
                }
                productRepository.saveAll(products);
            }
        }

        Promotion saved = promotionRepository.save(promotion);
        productService.clearProductListCaches();
        return PromotionResponse.fromEntity(saved);
    }

    @Override
    @Transactional
    public PromotionResponse updatePromotion(int promotionId, PromotionUpdateDTO dto) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        log.info("Updating promotion id={} companyId={}", promotionId, companyId);
        
        Promotion promotion = promotionRepository.findById(promotionId)
                .orElseThrow(() -> new AppException(ErrorCode.PROMOTION_NOT_FOUND));
        
        if (promotion.getCompany().getId() != companyId) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        if (dto.getPromotionName() != null) promotion.setPromotionName(dto.getPromotionName());
        if (dto.getDescription() != null) promotion.setDescription(dto.getDescription());
        if (dto.getScope() != null) promotion.setScope(dto.getScope());
        if (dto.getDiscountType() != null) promotion.setDiscountType(dto.getDiscountType());
        if (dto.getDiscountValue() != null) promotion.setDiscountValue(dto.getDiscountValue());
        if (dto.getMaxAccount() != null) promotion.setMaxAccount(dto.getMaxAccount());
        if (dto.getMinAccount() != null) promotion.setMinAccount(dto.getMinAccount());
        if (dto.getStartDate() != null) promotion.setStartedAt(dto.getStartDate());
        if (dto.getEndDate() != null) promotion.setEndedAt(dto.getEndDate());
        if (dto.getStatus() != null) promotion.setStatus(dto.getStatus());

        // If it's a product promotion, update the product associations and recalculate prices
        if (promotion.getScope() == 1 && dto.getProductIds() != null) {
            List<Product> oldProducts = promotion.getProducts() != null ? new ArrayList<>(promotion.getProducts()) : new ArrayList<>();
            List<Product> newProducts = productRepository.findAllById(dto.getProductIds());
            
            // Filter to ensure only company's products are added
            List<Product> validNewProducts = new ArrayList<>(newProducts.stream()
                    .filter(p -> p.getCompany().getId() == companyId)
                    .toList());
            
            promotion.setProducts(validNewProducts);
            Promotion saved = promotionRepository.save(promotion);

            // Products removed from this promotion
            for (Product p : oldProducts) {
                if (!validNewProducts.contains(p)) {
                    recalculateProductPrice(p, promotionId);
                    productRepository.save(p);
                }
            }

            // Products in/added to this promotion
            for (Product p : validNewProducts) {
                // Ensure bidirectional relationship is updated for recalculation
                if (p.getPromotions() == null) p.setPromotions(new ArrayList<>());
                if (!p.getPromotions().contains(saved)) {
                    p.getPromotions().add(saved);
                }
                recalculateProductPrice(p, -1);
                productRepository.save(p);
            }
            return PromotionResponse.fromEntity(saved);
        }

        Promotion saved = promotionRepository.save(promotion);
        productService.clearProductListCaches();
        return PromotionResponse.fromEntity(saved);
    }

    @Override
    public Page<PromotionListResponse> getPromotionByCompanyId_Keyword(int companyId, String keyword, int page, int size) {

        return promotionRepository.searchPromotions(companyId, keyword, PageRequest.of(page, size))
                .map(PromotionListResponse::fromEntity);
    }

    @Override
    public PromotionResponse getPromotionById(int promotionId) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        Promotion promotion = promotionRepository.findById(promotionId)
                .orElseThrow(() -> new AppException(ErrorCode.PROMOTION_NOT_FOUND));

        if (promotion.getCompany().getId() != companyId) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }
        return PromotionResponse.fromEntity(promotion);
    }

    @Override
    public void recalculateProductPrice(Product p, int excludedPromotionId) {
        // Find other active promotions for this product
        // We look for status=1 AND current time between start/end
        LocalDateTime now = LocalDateTime.now();
        List<Promotion> otherActive = p.getPromotions().stream()
                .filter(pr -> pr.getId() != excludedPromotionId 
                        && pr.getStatus() == 1 
                        && pr.getScope() == 1
                        && !pr.getStartedAt().isAfter(now)
                        && !pr.getEndedAt().isBefore(now))
                .toList();

        if (otherActive.isEmpty()) {
            p.setSellPrice(p.getSellPriceOriginal());
        } else {
            // If multiple active, apply the most aggressive one (or latest, depends on policy)
            // Here we pick highest reduction
            double maxReduction = 0;
            for (Promotion activePr : otherActive) {
                double originalPrice = p.getSellPriceOriginal();
                if (originalPrice >= activePr.getMinAccount()) {
                    double reduction = calculateReduction(originalPrice, activePr.getDiscountType(), 
                            activePr.getDiscountValue(), activePr.getMaxAccount());
                    if (reduction > maxReduction) maxReduction = reduction;
                }
            }
            p.setSellPrice(Math.max(0, p.getSellPriceOriginal() - maxReduction));
        }
    }

    public static double calculateReduction(double originalPrice, int type, double value, double max) {
        double reduction = 0;
        if (type == 0) { // Flat amount
            reduction = value;
        } else if (type == 1) { // Percentage
            reduction = originalPrice * (value / 100.0);
        }
        
        double finalReduction = (max > 0) ? Math.min(reduction, max) : reduction;
        log.debug("calculateReduction: original={}, type={}, value={}, max={}, result={}", 
                originalPrice, type, value, max, finalReduction);
        return finalReduction;
    }
}

