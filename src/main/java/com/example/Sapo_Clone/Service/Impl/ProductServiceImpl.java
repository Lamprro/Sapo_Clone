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

// Apache POI and Input/Output/Network Utility Imports
import org.apache.poi.ss.usermodel.*;
import java.io.ByteArrayInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.UUID;
import org.springframework.scheduling.annotation.Async;
import com.example.Sapo_Clone.Enum.NotificationType;

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
    private final com.example.Sapo_Clone.Repository.StoreRepository storeRepository;
    private final org.springframework.cache.CacheManager cacheManager;
    private final com.example.Sapo_Clone.Service.CloudService cloudService;
    private final com.example.Sapo_Clone.Service.NotificationService notificationService;
    private final com.example.Sapo_Clone.Repository.ProductImageRepository productImageRepository;
    private final org.springframework.transaction.support.TransactionTemplate transactionTemplate;

    @Override
    @Transactional
    public ProductResponse createProduct(ProductCreateDTO dto) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        log.info("Creating product with barcode={} companyId={}", dto.getBarcode(), companyId);

        if (dto.getBarcode() != null && !dto.getBarcode().isEmpty()) {
            if (!dto.getBarcode().matches("[a-zA-Z0-9-_]+")) {
                throw new AppException(ErrorCode.VALIDATION_ERROR, "Barcode contains invalid characters (letters, numbers, hyphens, and underscores only)");
            }
        }

        if (dto.getSellPriceOriginal() < dto.getImportPrice()) {
            throw new AppException(ErrorCode.VALIDATION_ERROR, "Original sell price cannot be less than import price");
        }
        if (dto.getSellPrice() < dto.getImportPrice()) {
            throw new AppException(ErrorCode.VALIDATION_ERROR, "Sell price cannot be less than import price");
        }
        if (dto.getSellPrice() > dto.getSellPriceOriginal()) {
            throw new AppException(ErrorCode.VALIDATION_ERROR, "Sell price cannot exceed original sell price");
        }

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
        ProductResponse response = ProductResponse.fromEntityForCustomer(product);
        response.setHasStore(inventoryRepository.existsByProductId(productId));
        return response;
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
        ProductResponse response = ProductResponse.fromEntity(product);
        response.setHasStore(inventoryRepository.existsByProductId(productId));
        return response;
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

        if (search != null && search.matches("\\d+") && search.length() < 9 && categories == null) {
            try {
                int id = Integer.parseInt(search);
                Optional<Product> opt = productRepository.findById(id);
                if (opt.isPresent() && opt.get().getCompany() != null && opt.get().getCompany().getId() == companyId) {
                    ProductResponse res = isManage ? ProductResponse.fromEntity(opt.get()) : ProductResponse.fromEntityForCustomer(opt.get());
                    res.setHasStore(inventoryRepository.existsByProductId(opt.get().getId()));
                    List<ProductResponse> singleResult = List.of(res);
                    return new PageImpl<>(singleResult, pageable, singleResult.size());
                }
            } catch (NumberFormatException e) {
                // Fall through to regular search
            }
        }

        return productRepository.searchByTextAndCategories(companyId, search, categories, isManage , pageable)
                .map(product -> {
                    ProductResponse res = isManage ? ProductResponse.fromEntity(product)
                            : ProductResponse.fromEntityForCustomer(product);
                    res.setHasStore(inventoryRepository.existsByProductId(product.getId()));
                    return res;
                });
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

        if (dto.getBarcode() != null && !dto.getBarcode().isEmpty()) {
            if (!dto.getBarcode().matches("[a-zA-Z0-9-_]+")) {
                throw new AppException(ErrorCode.VALIDATION_ERROR, "Barcode contains invalid characters (letters, numbers, hyphens, and underscores only)");
            }
        }

        if (dto.getSellPriceOriginal() < dto.getImportPrice()) {
            throw new AppException(ErrorCode.VALIDATION_ERROR, "Original sell price cannot be less than import price");
        }
        if (dto.getSellPrice() < dto.getImportPrice()) {
            throw new AppException(ErrorCode.VALIDATION_ERROR, "Sell price cannot be less than import price");
        }
        if (dto.getSellPrice() > dto.getSellPriceOriginal()) {
            throw new AppException(ErrorCode.VALIDATION_ERROR, "Sell price cannot exceed original sell price");
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

    @Override
    @Async("imageUploadExecutor")
    public void importProductsAsync(byte[] fileBytes, int userId, int companyId, int storeId, String role) {
        log.info("Starting asynchronous product import from Excel. userId={}, companyId={}, storeId={}", userId, companyId, storeId);
        
        List<String> uploadedCloudinaryPublicIds = new ArrayList<>();
        List<Path> tempImagePaths = new ArrayList<>();
        
        // Ensure the temp directory exists
        Path tempDir = Paths.get("temp_images");
        try {
            if (!Files.exists(tempDir)) {
                Files.createDirectories(tempDir);
                log.info("Created temporary images directory: {}", tempDir.toAbsolutePath());
            }
        } catch (Exception e) {
            log.error("Failed to create temporary images directory", e);
            sendImportNotification(userId, companyId, role, false, "Failed to initialize temp directory: " + e.getMessage());
            return;
        }

        List<ParsedProduct> parsedProducts = new ArrayList<>();

        try (Workbook workbook = WorkbookFactory.create(new ByteArrayInputStream(fileBytes))) {
            Sheet sheet = workbook.getSheetAt(0);
            if (sheet.getPhysicalNumberOfRows() <= 1) {
                throw new IllegalArgumentException("The Excel sheet is empty or has no data rows.");
            }

            // Read header row (Row 0)
            Row headerRow = sheet.getRow(0);
            if (headerRow == null) {
                throw new IllegalArgumentException("Header row is missing.");
            }

            // Map header names to column indexes
            int nameColIdx = -1;
            int descColIdx = -1;
            int barcodeColIdx = -1;
            int importPriceColIdx = -1;
            int sellPriceOriginalColIdx = -1;
            int sellPriceColIdx = -1;
            int unitColIdx = -1;
            int categoryColIdx = -1;
            List<Integer> pictureColIdxs = new ArrayList<>();

            for (int col = 0; col < headerRow.getLastCellNum(); col++) {
                Cell cell = headerRow.getCell(col);
                if (cell == null) continue;
                String header = getCellStringValue(cell).toLowerCase();
                if (header.isEmpty()) continue;

                if (header.equals("product name") || header.equals("tên sản phẩm") || header.equals("ten san pham")) {
                    nameColIdx = col;
                } else if (header.equals("description") || header.equals("mô tả") || header.equals("mo ta")) {
                    descColIdx = col;
                } else if (header.equals("barcode") || header.equals("mã vạch") || header.equals("ma vach")) {
                    barcodeColIdx = col;
                } else if (header.equals("import price") || header.equals("giá nhập") || header.equals("gia nhap")) {
                    importPriceColIdx = col;
                } else if (header.equals("sell price original") || header.equals("giá bán gốc") || header.equals("gia ban goc")) {
                    sellPriceOriginalColIdx = col;
                } else if (header.equals("sell price") || header.equals("giá bán") || header.equals("gia ban")) {
                    sellPriceColIdx = col;
                } else if (header.equals("unit") || header.equals("đơn vị") || header.equals("don vi")) {
                    unitColIdx = col;
                } else if (header.equals("category") || header.equals("danh mục") || header.equals("danh muc")) {
                    categoryColIdx = col;
                } else if (header.startsWith("picture") || header.startsWith("hình ảnh") || header.startsWith("hinh anh")) {
                    pictureColIdxs.add(col);
                }
            }

            // Validate mandatory headers
            if (nameColIdx == -1) throw new IllegalArgumentException("Missing 'Product Name' column in Excel.");
            if (barcodeColIdx == -1) throw new IllegalArgumentException("Missing 'Barcode' column in Excel.");
            if (importPriceColIdx == -1) throw new IllegalArgumentException("Missing 'Import Price' column in Excel.");
            if (sellPriceOriginalColIdx == -1) throw new IllegalArgumentException("Missing 'Sell Price Original' column in Excel.");
            if (sellPriceColIdx == -1) throw new IllegalArgumentException("Missing 'Sell Price' column in Excel.");
            if (unitColIdx == -1) throw new IllegalArgumentException("Missing 'Unit' column in Excel.");

            // Parse each row
            for (int r = 1; r <= sheet.getLastRowNum(); r++) {
                Row row = sheet.getRow(r);
                if (row == null) continue;

                // Check if the row is empty (at least Name and Barcode are blank)
                String productName = getCellStringValue(row.getCell(nameColIdx));
                String barcode = getCellStringValue(row.getCell(barcodeColIdx));
                if (productName.isEmpty() && barcode.isEmpty()) {
                    continue; // Skip empty row
                }

                if (productName.isEmpty()) {
                    throw new IllegalArgumentException("Row " + (r + 1) + ": Product Name cannot be blank.");
                }
                if (barcode.isEmpty()) {
                    throw new IllegalArgumentException("Row " + (r + 1) + ": Barcode cannot be blank.");
                }
                if (!barcode.matches("[a-zA-Z0-9-_]+")) {
                    throw new IllegalArgumentException("Row " + (r + 1) + ": Barcode '" + barcode + "' contains invalid characters.");
                }
                if (productRepository.existsByCompany_IdAndBarcode(companyId, barcode)) {
                    throw new IllegalArgumentException("Row " + (r + 1) + ": Barcode '" + barcode + "' already exists for this company.");
                }

                // Prices
                Double importPrice = getCellDoubleValue(row.getCell(importPriceColIdx));
                Double sellPriceOriginal = getCellDoubleValue(row.getCell(sellPriceOriginalColIdx));
                Double sellPrice = getCellDoubleValue(row.getCell(sellPriceColIdx));

                if (importPrice == null || importPrice < 0) {
                    throw new IllegalArgumentException("Row " + (r + 1) + ": Import Price must be >= 0.");
                }
                if (sellPriceOriginal == null || sellPriceOriginal < 0) {
                    throw new IllegalArgumentException("Row " + (r + 1) + ": Original Sell Price must be >= 0.");
                }
                if (sellPrice == null || sellPrice < 0) {
                    throw new IllegalArgumentException("Row " + (r + 1) + ": Sell Price must be >= 0.");
                }
                if (sellPriceOriginal < importPrice) {
                    throw new IllegalArgumentException("Row " + (r + 1) + ": Original Sell Price cannot be less than Import Price.");
                }
                if (sellPrice < importPrice) {
                    throw new IllegalArgumentException("Row " + (r + 1) + ": Sell Price cannot be less than Import Price.");
                }
                if (sellPrice > sellPriceOriginal) {
                    throw new IllegalArgumentException("Row " + (r + 1) + ": Sell Price cannot exceed Original Sell Price.");
                }

                // Unit
                String unitName = getCellStringValue(row.getCell(unitColIdx));
                if (unitName.isEmpty()) {
                    throw new IllegalArgumentException("Row " + (r + 1) + ": Unit cannot be blank.");
                }

                // Categories
                List<String> categoryNames = new ArrayList<>();
                if (categoryColIdx != -1) {
                    String catsStr = getCellStringValue(row.getCell(categoryColIdx));
                    if (!catsStr.isEmpty()) {
                        String[] catNames = catsStr.split("[,;]");
                        for (String catName : catNames) {
                            String trimmedCatName = catName.trim();
                            if (!trimmedCatName.isEmpty()) {
                                categoryNames.add(trimmedCatName);
                            }
                        }
                    }
                }

                // Description
                String description = descColIdx != -1 ? getCellStringValue(row.getCell(descColIdx)) : "";

                // Pictures URLs
                List<String> imageUrls = new ArrayList<>();
                for (int pIdx : pictureColIdxs) {
                    String imgUrl = getCellStringValue(row.getCell(pIdx));
                    if (!imgUrl.isEmpty()) {
                        imageUrls.add(imgUrl);
                    }
                }

                ParsedProduct pp = new ParsedProduct();
                pp.productName = productName;
                pp.barcode = barcode;
                pp.importPrice = importPrice;
                pp.sellPriceOriginal = sellPriceOriginal;
                pp.sellPrice = sellPrice;
                pp.unitName = unitName;
                pp.categoryNames = categoryNames;
                pp.description = description;
                pp.imageUrls = imageUrls;
                parsedProducts.add(pp);
            }

            // Step 2: Download and upload images (OUTSIDE Database Transaction)
            for (ParsedProduct pp : parsedProducts) {
                for (int i = 0; i < pp.imageUrls.size(); i++) {
                    String imageUrl = pp.imageUrls.get(i);
                    String tempFilename = "prod_" + pp.barcode + "_" + i + "_" + UUID.randomUUID().toString().substring(0, 8) + ".jpg";
                    Path tempFile = tempDir.resolve(tempFilename);
                    
                    log.info("Downloading image from URL: {} to {}", imageUrl, tempFile.toAbsolutePath());
                    try {
                        downloadImage(imageUrl, tempFile);
                        tempImagePaths.add(tempFile);
                        
                        // Upload to Cloudinary
                        byte[] imgBytes = Files.readAllBytes(tempFile);
                        var cloudResponse = cloudService.uploadToCloud(imgBytes, tempFilename);
                        uploadedCloudinaryPublicIds.add(cloudResponse.getPublicId());
                        pp.uploadedImages.add(cloudResponse);

                        // Clean up downloaded temp file immediately
                        Files.deleteIfExists(tempFile);
                        tempImagePaths.remove(tempFile);
                    } catch (Exception imgEx) {
                        log.error("Failed to download/upload image: {}", imageUrl, imgEx);
                        throw new RuntimeException("Failed to download/upload image from URL '" + imageUrl + "': " + imgEx.getMessage());
                    }
                }
            }

            // Step 3: Run Database writes in a single, short-lived transactional block
            transactionTemplate.execute(status -> {
                Company company = companyRepository.findById(companyId)
                        .orElseThrow(() -> new AppException(ErrorCode.COMPANY_NOT_FOUND));

                for (ParsedProduct pp : parsedProducts) {
                    // Resolve/Create Unit
                    Unit unit = unitRepository.findByUnitName(pp.unitName)
                            .orElseGet(() -> {
                                Unit newUnit = new Unit();
                                newUnit.setUnitName(pp.unitName);
                                newUnit.setDescription("Imported from Excel");
                                return unitRepository.save(newUnit);
                            });

                    // Resolve/Create Categories
                    List<Category> categories = new ArrayList<>();
                    for (String catName : pp.categoryNames) {
                        Category category = categoryRepository.findByCategoryName(catName)
                                .orElseGet(() -> {
                                    Category newCat = new Category();
                                    newCat.setCategoryName(catName);
                                    newCat.setDescription("Imported from Excel");
                                    return categoryRepository.save(newCat);
                                });
                        categories.add(category);
                    }

                    // Save Product
                    Product product = new Product();
                    product.setProductName(pp.productName);
                    product.setDescription(pp.description);
                    product.setBarcode(pp.barcode);
                    product.setImportPrice(pp.importPrice);
                    product.setSellPriceOriginal(pp.sellPriceOriginal);
                    product.setSellPrice(pp.sellPrice);
                    product.setUnit(unit);
                    product.setCategoryList(categories);
                    product.setStatus(1); // ACTIVE
                    product.setAvgstar(0.0);
                    product.setCompany(company);

                    Product savedProduct = productRepository.save(product);

                    // Save images
                    List<ProductImage> productImagesList = new ArrayList<>();
                    for (int i = 0; i < pp.uploadedImages.size(); i++) {
                        com.example.Sapo_Clone.DTO.Response.Cloud.CloudResponse cloudRes = pp.uploadedImages.get(i);
                        ProductImage img = new ProductImage();
                        img.setImageUrl(cloudRes.getImageUrl());
                        img.setPublicId(cloudRes.getPublicId());
                        img.setStatus(i == 0 ? 2 : 1);
                        img.setProduct(savedProduct);
                        productImageRepository.save(img);
                        productImagesList.add(img);
                    }
                    savedProduct.setProductImages(productImagesList);
                }
                return null;
            });

            clearProductListCaches();
            sendImportNotification(userId, companyId, role, true, "Import product success");
            log.info("Product import completed successfully for companyId={}", companyId);

        } catch (Exception e) {
            log.error("Error occurred during Excel product import, rolling back", e);
            
            // Clean up uploaded Cloudinary images to avoid garbage
            for (String publicId : uploadedCloudinaryPublicIds) {
                try {
                    cloudService.deleteFromCloud(publicId);
                } catch (Exception cleanEx) {
                    log.error("Failed to clean up Cloudinary image: {}", publicId, cleanEx);
                }
            }

            // Clean up local temp files if any remaining
            for (Path tempFile : tempImagePaths) {
                try {
                    Files.deleteIfExists(tempFile);
                } catch (Exception cleanEx) {
                    log.error("Failed to delete temp file: {}", tempFile, cleanEx);
                }
            }

            sendImportNotification(userId, companyId, role, false, "Import product failed: " + e.getMessage());
            throw new RuntimeException(e.getMessage(), e); // Throw exception to notify executor
        }
    }

    private static class ParsedProduct {
        String productName;
        String description;
        String barcode;
        Double importPrice;
        Double sellPriceOriginal;
        Double sellPrice;
        String unitName;
        List<String> categoryNames = new ArrayList<>();
        List<String> imageUrls = new ArrayList<>();
        List<com.example.Sapo_Clone.DTO.Response.Cloud.CloudResponse> uploadedImages = new ArrayList<>();
    }

    private void downloadImage(String urlStr, Path targetPath) throws Exception {
        URL url = new URL(urlStr);
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod("GET");
        conn.setConnectTimeout(10000);
        conn.setReadTimeout(10000);
        conn.setRequestProperty("User-Agent", "Mozilla/5.0");

        int responseCode = conn.getResponseCode();
        if (responseCode != HttpURLConnection.HTTP_OK) {
            throw new RuntimeException("HTTP error code: " + responseCode);
        }

        try (InputStream in = conn.getInputStream();
             FileOutputStream out = new FileOutputStream(targetPath.toFile())) {
            byte[] buffer = new byte[4096];
            int bytesRead;
            while ((bytesRead = in.read(buffer)) != -1) {
                out.write(buffer, 0, bytesRead);
            }
        }
    }

    private void sendImportNotification(int userId, int companyId, String role, boolean success, String message) {
        try {
            Notification notification = Notification.builder()
                    .title(success ? "Import Product Success" : "Import Product Failed")
                    .message(message)
                    .type(NotificationType.ADMIN_ALERT)
                    .targetUserId(userId)
                    .targetRole(role)
                    .companyId(companyId)
                    .isRead(false)
                    .build();
            notificationService.createNotification(notification);
        } catch (Exception ex) {
            log.error("Failed to create import notification", ex);
        }
    }

    private String getCellStringValue(Cell cell) {
        if (cell == null) {
            return "";
        }
        switch (cell.getCellType()) {
            case STRING:
                return cell.getStringCellValue().trim();
            case NUMERIC:
                double val = cell.getNumericCellValue();
                if (val == (long) val) {
                    return String.valueOf((long) val);
                }
                return String.valueOf(val);
            case BOOLEAN:
                return String.valueOf(cell.getBooleanCellValue());
            case FORMULA:
                try {
                    return cell.getStringCellValue().trim();
                } catch (Exception e) {
                    double fVal = cell.getNumericCellValue();
                    if (fVal == (long) fVal) {
                        return String.valueOf((long) fVal);
                    }
                    return String.valueOf(fVal);
                }
            case BLANK:
            default:
                return "";
        }
    }

    private Double getCellDoubleValue(Cell cell) {
        if (cell == null) {
            return null;
        }
        if (cell.getCellType() == CellType.NUMERIC) {
            return cell.getNumericCellValue();
        } else if (cell.getCellType() == CellType.STRING) {
            String val = cell.getStringCellValue().trim();
            if (val.isEmpty()) return null;
            try {
                return Double.parseDouble(val);
            } catch (NumberFormatException e) {
                return null;
            }
        }
        return null;
    }
}