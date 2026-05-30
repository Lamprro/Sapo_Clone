package com.example.Sapo_Clone.Service.Impl;

import com.example.Sapo_Clone.DTO.Request.Product.ChangeProductStatusDTO;
import com.example.Sapo_Clone.DTO.Request.Product.ProductCreateDTO;
import com.example.Sapo_Clone.DTO.Request.Product.ProductUpdateDTO;
import com.example.Sapo_Clone.DTO.Response.Product.*;
import com.example.Sapo_Clone.Entity.*;
import com.example.Sapo_Clone.Exception.AppException;
import com.example.Sapo_Clone.Exception.ErrorCode;
import com.example.Sapo_Clone.Repository.CategoryRepository;
import com.example.Sapo_Clone.Repository.InventoryRepository;
import com.example.Sapo_Clone.Repository.ProductRepository;
import com.example.Sapo_Clone.Repository.UnitRepository;
import com.example.Sapo_Clone.Service.ProductService;
import com.example.Sapo_Clone.Utils.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.CachePut;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.cache.annotation.Caching;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class ProductServiceImpl implements ProductService {

    private final ProductRepository productRepository;
    private final UnitRepository unitRepository;
    private final CategoryRepository categoryRepository;
    private final InventoryRepository inventoryRepository;
    private final com.example.Sapo_Clone.Repository.CompanyRepository companyRepository;
    private final com.example.Sapo_Clone.Repository.OrderDetailRepository orderDetailRepository;
    private final org.springframework.cache.CacheManager cacheManager;

    @Override
    @Transactional
    public ProductResponse createProduct(ProductCreateDTO dto) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        log.info("Creating product with barcode={} companyId={}", dto.getBarcode(), companyId);

        if (productRepository.existsByCompany_IdAndBarcode(companyId, dto.getBarcode())) {
            throw new AppException(ErrorCode.BARCODE_ALREADY_EXISTS);
        }

        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new AppException(ErrorCode.COMPANY_NOT_FOUND));

        Unit unit = unitRepository.findById(dto.getUnitId().intValue())
                .orElseThrow(() -> new AppException(ErrorCode.UNIT_NOT_FOUND));

        List<Category> categories = categoryRepository.findAllByIdIn(
                dto.getCategoryIds().stream().map(Long::intValue).toList());
        if (categories.size() != dto.getCategoryIds().size()) {
            throw new AppException(ErrorCode.CATEGORY_NOT_FOUND);
        }

        Product product = new Product();
        product.setProductName(dto.getProductName());
        product.setDescription(dto.getDescription());
        product.setBarcode(dto.getBarcode());
        product.setImportPrice(dto.getImportPrice());
        product.setSellPriceOriginal(dto.getSellPriceOriginal());
        product.setSellPrice(dto.getSellPrice());
        product.setUnit(unit);
        product.setCategoryList(categories);
        product.setStatus(1); // ACTIVE
        product.setAvgstar(0.0);
        product.setCompany(company);

        Product savedProduct = productRepository.save(product);
        clearProductListCaches();
        return ProductResponse.fromEntity(savedProduct);
    }

    @Override
    @Cacheable(value = "product:customer", key = "'-c:' + T(com.example.Sapo_Clone.Utils.SecurityUtils).getCurrentCompanyId() + '-p:' + #productId")
    public ProductResponse getProductByIdForCustomer(int productId) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new AppException(ErrorCode.PRODUCT_NOT_FOUND));
        if (product.getStatus() != 1 || product.getCompany() == null || product.getCompany().getId() != companyId) {
            throw new AppException(ErrorCode.PRODUCT_NOT_FOUND);
        }
        return ProductResponse.fromEntityForCustomer(product);
    }

    @Override
    @Cacheable(value = "product:manage", key = "'-c:' + T(com.example.Sapo_Clone.Utils.SecurityUtils).getCurrentCompanyId() + '-p:' + #productId")
    public ProductResponse getProductByIdForManage(int productId) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new AppException(ErrorCode.PRODUCT_NOT_FOUND));
        if (product.getCompany() == null || product.getCompany().getId() != companyId) {
            throw new AppException(ErrorCode.PRODUCT_NOT_FOUND);
        }
        return ProductResponse.fromEntity(product);
    }

    @Override
    @Caching(cacheable = {
        @Cacheable(value = "product:list:manage", key = "'-c:' + T(com.example.Sapo_Clone.Utils.SecurityUtils).getCurrentCompanyId() + '-kw:' + (#keyword != null ? #keyword : '') + '-cat:' + (#categoryIds != null ? #categoryIds.toString() : '') + '-p:' + #page + '-s:' + #size", condition = "!'CUSTOMER'.equals(T(com.example.Sapo_Clone.Utils.SecurityUtils).getCurrentRole())"),
        @Cacheable(value = "product:list:customer", key = "'-c:' + T(com.example.Sapo_Clone.Utils.SecurityUtils).getCurrentCompanyId() + '-kw:' + (#keyword != null ? #keyword : '') + '-cat:' + (#categoryIds != null ? #categoryIds.toString() : '') + '-p:' + #page + '-s:' + #size", condition = "'CUSTOMER'.equals(T(com.example.Sapo_Clone.Utils.SecurityUtils).getCurrentRole())")
    })
    public Page<ProductResponse> getList(String keyword, List<Integer> categoryIds, int page, int size) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        String roleName = Optional.ofNullable(SecurityUtils.getCurrentRole()).orElse("");
        boolean isManage = !roleName.equals("CUSTOMER");
        
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));

        String search = (keyword == null || keyword.trim().isEmpty()) ? null : keyword.trim();
        List<Integer> categories = (categoryIds == null || categoryIds.isEmpty()) ? null : categoryIds;

        if (search != null && search.matches("\\d+") && categories == null) {
            int id = Integer.parseInt(search);
            Optional<Product> opt = productRepository.findById(id);
            List<ProductResponse> singleResult = new ArrayList<>();
            opt.ifPresent(c -> {
                if (c.getCompany() != null && c.getCompany().getId() == companyId) {
                    singleResult.add(isManage ? ProductResponse.fromEntity(c) : ProductResponse.fromEntityForCustomer(c));
                }
            });
            return new PageImpl<>(singleResult, pageable, singleResult.size());
        }

        return productRepository.searchByTextAndCategories(companyId, search, categories, isManage , pageable)
                .map(product -> isManage ? ProductResponse.fromEntity(product)
                        : ProductResponse.fromEntityForCustomer(product));
    }

    @Override
    @Transactional
    public ProductResponse updateProduct(int productId, ProductUpdateDTO dto) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new AppException(ErrorCode.PRODUCT_NOT_FOUND));

        if (product.getCompany() == null || product.getCompany().getId() != companyId) {
            throw new AppException(ErrorCode.PRODUCT_NOT_FOUND);
        }

        if (productRepository.existsByCompany_IdAndBarcodeAndIdNot(companyId, dto.getBarcode(), productId)) {
            throw new AppException(ErrorCode.BARCODE_ALREADY_EXISTS);
        }

        Unit unit = unitRepository.findById(dto.getUnitId().intValue())
                .orElseThrow(() -> new AppException(ErrorCode.UNIT_NOT_FOUND));

        List<Category> categories = categoryRepository.findAllByIdIn(
                dto.getCategoryIds().stream().map(Long::intValue).toList());
        if (categories.size() != dto.getCategoryIds().size()) {
            throw new AppException(ErrorCode.CATEGORY_NOT_FOUND);
        }

        product.setProductName(dto.getProductName());
        product.setDescription(dto.getDescription());
        product.setBarcode(dto.getBarcode());
        product.setImportPrice(dto.getImportPrice());
        product.setSellPriceOriginal(dto.getSellPriceOriginal());
        product.setSellPrice(dto.getSellPrice());
        product.setUnit(unit);
        product.setCategoryList(categories);

        Product savedProduct = productRepository.save(product);
        
        clearProductListCaches();
        clearProductDetailCache(companyId, productId);
        
        String roleName = SecurityUtils.getCurrentRole();
        if ("CUSTOMER".equals(roleName)) {
             return ProductResponse.fromEntityForCustomer(savedProduct);
        }
        return ProductResponse.fromEntity(savedProduct);
    }

    @Override
    @Transactional
    public ProductResponse changeStatus(int productId, ChangeProductStatusDTO dto) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        if (dto.getStatus() != 0 && dto.getStatus() != 1) {
            throw new AppException(ErrorCode.INVALID_PRODUCT_STATUS);
        }

        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new AppException(ErrorCode.PRODUCT_NOT_FOUND));

        if (product.getCompany() == null || product.getCompany().getId() != companyId) {
            throw new AppException(ErrorCode.PRODUCT_NOT_FOUND);
        }

        product.setStatus(dto.getStatus());
        Product savedProduct = productRepository.save(product);
        
        clearProductListCaches();
        clearProductDetailCache(companyId, productId);
        
        String roleName = SecurityUtils.getCurrentRole();
        if ("CUSTOMER".equals(roleName)) {
             return ProductResponse.fromEntityForCustomer(savedProduct);
        }
        return ProductResponse.fromEntity(savedProduct);
    }

    @Override
    public ProductInventoryResponse getProductInventory(int productId, int storeId) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new AppException(ErrorCode.PRODUCT_NOT_FOUND));

        if (product.getCompany() == null || product.getCompany().getId() != companyId) {
            throw new AppException(ErrorCode.PRODUCT_NOT_FOUND);
        }

        Integer quantity = inventoryRepository.findByProduct_IdAndStore_Id(productId, storeId)
                .map(Inventory::getQuantity)
                .orElse(0);

        return ProductInventoryResponse.builder()
                .productId(productId)
                .storeId(storeId)
                .quantity(quantity)
                .build();
    }

    @Override
    @Cacheable(value = "product:store", key = "'-c:' + T(com.example.Sapo_Clone.Utils.SecurityUtils).getCurrentCompanyId() + '-s:' + T(com.example.Sapo_Clone.Utils.SecurityUtils).getCurrentStoreId() + '-p:' + #page + '-size:' + #size")
    public Page<ProductResponse> getProductsByStore(int page, int size) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        int storeId = SecurityUtils.getCurrentStoreId();
        boolean isManage = !"CUSTOMER".equals(SecurityUtils.getCurrentRole());
        Pageable pageable = PageRequest.of(page, size);
        return productRepository.findByStoreIdAndStatus(companyId, storeId, isManage, pageable)
                .map(ProductResponse::fromEntity);
    }

    @Override
    public List<ProductReportProjection> getReportAll() {
        int companyId = SecurityUtils.getCurrentCompanyId();
        return productRepository.getProductReport(companyId, null);
    }

    @Override
    public ProductReportDetailResponse getReportByProduct(int productId, int page, int size) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        
        // 1. Fetch Summary Stats
        ProductReportProjection summary = productRepository.getProductReport(companyId, productId).stream()
                .findFirst()
                .orElseThrow(() -> new AppException(ErrorCode.PRODUCT_NOT_FOUND));

        // 2. Fetch Paginated Order History
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "order.createdAt"));
        Page<OrderDetail> historyPage = orderDetailRepository.findByProduct_IdAndCompany_Id(productId, companyId, pageable);

        Page<ProductOrderHistoryResponse> historyResponse = historyPage.map(od -> ProductOrderHistoryResponse.builder()
                .orderId(od.getOrder().getId())
                .customerName(od.getOrder().getCustomer() != null ? od.getOrder().getCustomer().getUserFullName() : "Guest")
                .quantity(od.getQuantity())
                .price(od.getPrice())
                .subtotal(od.getSubtotal())
                .createdAt(od.getOrder().getCreatedAt())
                .build());

        return ProductReportDetailResponse.builder()
                .productId(summary.getProductId())
                .productName(summary.getProductName())
                .totalSellQuantity(summary.getTotalSellQuantity())
                .totalRevenue(summary.getTotalRevenue())
                .totalProfit(summary.getTotalProfit())
                .evaluationScore(summary.getEvaluationScore())
                .orderHistory(historyResponse)
                .build();
    }

    protected void clearProductListCaches() {
        try {
            if (cacheManager.getCache("product:list:manage") != null) cacheManager.getCache("product:list:manage").clear();
            if (cacheManager.getCache("product:list:customer") != null) cacheManager.getCache("product:list:customer").clear();
            if (cacheManager.getCache("product:store") != null) cacheManager.getCache("product:store").clear();
        } catch (Exception e) {
            log.warn("Failed to clear product list caches", e);
        }
    }

    private void clearProductDetailCache(int companyId, int productId) {
        try {
            String key = "-c:" + companyId + "-p:" + productId;
            if (cacheManager.getCache("product:customer") != null) cacheManager.getCache("product:customer").evict(key);
            if (cacheManager.getCache("product:manage") != null) cacheManager.getCache("product:manage").evict(key);
        } catch (Exception e) {
            log.warn("Failed to clear product detail cache for product " + productId, e);
        }
    }
}