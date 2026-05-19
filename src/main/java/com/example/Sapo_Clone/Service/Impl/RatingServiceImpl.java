package com.example.Sapo_Clone.Service.Impl;

import com.example.Sapo_Clone.DTO.Request.Rating.RatingCreateDTO;
import com.example.Sapo_Clone.DTO.Request.Rating.RatingUpdateDTO;
import com.example.Sapo_Clone.DTO.Response.Rating.RatingResponse;
import com.example.Sapo_Clone.Entity.Product;
import com.example.Sapo_Clone.Entity.Rating;
import com.example.Sapo_Clone.Entity.User;
import com.example.Sapo_Clone.Exception.AppException;
import com.example.Sapo_Clone.Exception.ErrorCode;
import com.example.Sapo_Clone.Repository.ProductRepository;
import com.example.Sapo_Clone.Repository.RatingRepository;
import com.example.Sapo_Clone.Repository.UserRepository;
import com.example.Sapo_Clone.Service.RatingService;
import com.example.Sapo_Clone.Utils.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class RatingServiceImpl implements RatingService {

    private final RatingRepository ratingRepository;
    private final ProductRepository productRepository;
    private final UserRepository userRepository;
    private final org.springframework.cache.CacheManager cacheManager;

    @Override
    @Transactional
    public RatingResponse createRating(RatingCreateDTO dto) {
        int userId = SecurityUtils.getCurrentUserId();
        log.info("User {} is rating product {}", userId, dto.getProductId());

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));

        Product product = productRepository.findById(dto.getProductId())
                .orElseThrow(() -> new AppException(ErrorCode.PRODUCT_NOT_FOUND));

        // 1. Đếm số lượng sản phẩm khách đã mua thành công
        long purchasedQuantity = ratingRepository.countPurchasedQuantity(userId, dto.getProductId());
        if (purchasedQuantity == 0) {
            throw new AppException(ErrorCode.NOT_PURCHASED_YET);
        }

        // 2. Đếm số lần khách đã đánh giá sản phẩm này
        long currentRatingsCount = ratingRepository.countRatingsByCustomerAndProduct(userId, dto.getProductId());

        // 3. Nếu số lần đánh giá đã bằng hoặc vượt quá số lượng mua, thì chặn lại
        if (currentRatingsCount >= purchasedQuantity) {
            throw new AppException(ErrorCode.ALREADY_RATING);
        }


        Rating rating = new Rating();
        rating.setUser(user);
        rating.setProduct(product);
        rating.setRating(dto.getRating());
        rating.setComment(dto.getComment());
        rating.setStatus(1); // Default active

        Rating savedRating = ratingRepository.save(rating);

        updateProductAverageStar(product.getId());

        return RatingResponse.fromEntity(savedRating);
    }

    @Override
    @Transactional
    public RatingResponse updateRating(int ratingId, RatingUpdateDTO dto) {
        int userId = SecurityUtils.getCurrentUserId();
        log.info("User {} is updating rating {}", userId, ratingId);

        Rating rating = ratingRepository.findById(ratingId)
                .orElseThrow(() -> new AppException(ErrorCode.VALIDATION_ERROR));

        if (rating.getUser().getId() != userId) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        if (dto.getRating() != null) rating.setRating(dto.getRating());
        if (dto.getComment() != null) rating.setComment(dto.getComment());
        if (dto.getStatus() != null) rating.setStatus(dto.getStatus());

        Rating updatedRating = ratingRepository.save(rating);
        updateProductAverageStar(rating.getProduct().getId());

        return RatingResponse.fromEntity(updatedRating);
    }

    @Override
    @Transactional
    public RatingResponse changeStatus(int ratingId, int status) {
        // changeStatus is usually for ADMIN/MANAGE
        Rating rating = ratingRepository.findById(ratingId)
                .orElseThrow(() -> new AppException(ErrorCode.RATING_NOT_FOUND));
        
        rating.setStatus(status);
        ratingRepository.save(rating);
        updateProductAverageStar(rating.getProduct().getId());

        return RatingResponse.fromEntity(rating);
    }

    @Override
    public Page<RatingResponse> getByProduct(int productId, int page, int size) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        log.info("Fetching ratings for product {} for company {}", productId, companyId);
        
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new AppException(ErrorCode.PRODUCT_NOT_FOUND));
        
        // Multi-tenant check: product must belong to current brand/company 
        if (product.getCompany() == null || product.getCompany().getId() != companyId) {
            throw new AppException(ErrorCode.PRODUCT_NOT_FOUND);
        }

        PageRequest pageRequest = PageRequest.of(page, size, Sort.by("createdAt").descending());
        return ratingRepository.findByProductIdAndStatus(productId, 1, pageRequest)
                .map(RatingResponse::fromEntity);
    }

    @Override
    public List<RatingResponse> getByUser() {
        int userId = SecurityUtils.getCurrentUserId();
        return ratingRepository.findByUserId(userId).stream()
                .map(RatingResponse::fromEntity)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public void deleteRating(int ratingId) {
        int userId = SecurityUtils.getCurrentUserId();
        log.info("User {} is deleting rating {}", userId, ratingId);
        
        Rating rating = ratingRepository.findById(ratingId)
                .orElseThrow(() -> new AppException(ErrorCode.VALIDATION_ERROR));

        if (rating.getUser().getId() != userId) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        int productId = rating.getProduct().getId();
        ratingRepository.delete(rating);
        updateProductAverageStar(productId);
    }

    @Override
    @Transactional
    public void updateProductAverageStar(int productId) {
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new AppException(ErrorCode.PRODUCT_NOT_FOUND));

        Double avgStar = ratingRepository.calculateAverageRating(productId);
        product.setAvgstar(avgStar != null ? avgStar : 0.0);
        productRepository.save(product);

        // Evict related product caches
        try {
            int companyId = product.getCompany() != null ? product.getCompany().getId() : SecurityUtils.getCurrentCompanyId();
            String key = "-c:" + companyId + "-p:" + productId;
            
            if (cacheManager.getCache("product:customer") != null) cacheManager.getCache("product:customer").evict(key);
            if (cacheManager.getCache("product:manage") != null) cacheManager.getCache("product:manage").evict(key);
            
            // Clear all list caches because they contain products that might have been updated
            if (cacheManager.getCache("product:list:manage") != null) cacheManager.getCache("product:list:manage").clear();
            if (cacheManager.getCache("product:list:customer") != null) cacheManager.getCache("product:list:customer").clear();
            if (cacheManager.getCache("product:store") != null) cacheManager.getCache("product:store").clear();
            
            log.info("Cleared caches for product {} (Company: {})", productId, companyId);
        } catch (Exception e) {
            log.warn("Failed to evict cache for product " + productId, e);
        }
    }
}
