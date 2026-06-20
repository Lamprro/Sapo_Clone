package com.example.Sapo_Clone.Service.Impl;

import com.example.Sapo_Clone.DTO.Response.Inventory.InventoryByStoreResponse;
import com.example.Sapo_Clone.DTO.Response.Product.ProductInventoryResponse;
import com.example.Sapo_Clone.Entity.Inventory;
import com.example.Sapo_Clone.Entity.Product;
import com.example.Sapo_Clone.Entity.Store;
import com.example.Sapo_Clone.Entity.User;
import com.example.Sapo_Clone.Entity.ProductImage;
import com.example.Sapo_Clone.Exception.AppException;
import com.example.Sapo_Clone.Exception.ErrorCode;
import com.example.Sapo_Clone.Repository.*;
import com.example.Sapo_Clone.Service.InventoryService;
import com.example.Sapo_Clone.Utils.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class InventoryServiceImpl implements InventoryService {

    private final InventoryRepository inventoryRepository;
    private final ProductRepository productRepository;
    private final StoreRepository storeRepository;
    private final ProductImageRepository productImageRepository;
    private final UserRepository userRepository;

    @Override
    public ProductInventoryResponse getInventory(int productId, Integer storeId) {
        if (storeId == null || storeId <= 0) {
            String currentRole = SecurityUtils.getCurrentRole();
            if ("EMPLOYEE".equals(currentRole) || "MANAGER".equals(currentRole)) {
                // Get real-time storeId from database
                int userId = SecurityUtils.getCurrentUserId();
                User user = userRepository.findById(userId).orElse(null);
                storeId = (user != null && user.getStore() != null) ? user.getStore().getId() : null;
            }
        }

        if (storeId == null || storeId <= 0) {
            throw new AppException(ErrorCode.STORE_NOT_FOUND);
        }

        log.info("Fetching inventory for productId={} and storeId={}", productId, storeId);
        int quantity = inventoryRepository.findByProduct_IdAndStore_Id(productId, storeId)
                .map(Inventory::getQuantity)
                .orElse(0);

        return ProductInventoryResponse.builder()
                .productId(productId)
                .storeId(storeId)
                .quantity(quantity)
                .build();
    }

    @Override
    public Page<InventoryByStoreResponse> getInventoryByStore(Integer storeId, String searching, int page, int size) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        String currentRole = SecurityUtils.getCurrentRole();

        // Get real-time storeId from database for employee/manager
        int userId = SecurityUtils.getCurrentUserId();
        User user = userRepository.findById(userId).orElse(null);
        int userStoreId = (user != null && user.getStore() != null) ? user.getStore().getId() : 0;

        if ("EMPLOYEE".equals(currentRole) || ("MANAGER".equals(currentRole) && userStoreId > 0)) {
            storeId = userStoreId;
        }

        if (storeId == null || storeId <= 0) {
            throw new AppException(ErrorCode.STORE_NOT_FOUND);
        }

        log.info("Fetching inventory for storeId={} requesterRole={} companyId={} userStoreId={}", storeId, currentRole, companyId, userStoreId);
        java.util.List<Store> allStores = storeRepository.findAll();
        log.info("All stores in database: {}", allStores.stream().map(s -> "ID=" + s.getId() + ", Name=" + s.getStoreName() + ", CompanyID=" + (s.getCompany() != null ? s.getCompany().getId() : "null")).collect(java.util.stream.Collectors.toList()));

        Store store = storeRepository.findById(storeId)
                .orElseThrow(() -> new AppException(ErrorCode.STORE_NOT_FOUND));
        if (store.getCompany().getId() != companyId) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        Pageable pageable = PageRequest.of(page, size);
        String searchPattern = (searching == null || searching.trim().isEmpty()) ? null : "%" + searching.trim().toLowerCase() + "%";
        return inventoryRepository.findByStore_IdAndSearching(storeId, searchPattern, pageable)
                .map(inv -> {
                    List<ProductImage> images = productImageRepository.findByProduct_Id(inv.getProduct().getId());
                    String mainImg = null;
                    if (images != null && !images.isEmpty()) {
                        mainImg = images.stream()
                                .filter(img -> img.getStatus() == 2)
                                .findFirst()
                                .map(ProductImage::getImageUrl)
                                .orElse(images.get(0).getImageUrl());
                    }
                    return InventoryByStoreResponse.builder()
                            .productId(inv.getProduct().getId())
                            .barcode(inv.getProduct().getBarcode())
                            .productName(inv.getProduct().getProductName())
                            .mainImage(mainImg)
                            .quantity(inv.getQuantity())
                            .build();
                });
    }

    @Override
    @Transactional
    public void increaseStock(int productId, int storeId, int quantity) {
        log.info("Increasing stock productId={} storeId={} quantity={}", productId, storeId, quantity);
        if (quantity <= 0) {
            throw new AppException(ErrorCode.VALIDATION_ERROR);
        }

        Inventory inventory = inventoryRepository.findByProduct_IdAndStore_Id(productId, storeId)
                .orElse(null);

        if (inventory == null) {
            Product product = productRepository.findById(productId)
                    .orElseThrow(() -> new AppException(ErrorCode.PRODUCT_NOT_FOUND));
            Store store = storeRepository.findById(storeId)
                    .orElseThrow(() -> new AppException(ErrorCode.STORE_NOT_FOUND));

            inventory = new Inventory();
            inventory.setProduct(product);
            inventory.setStore(store);
            inventory.setQuantity(quantity);
        } else {
            inventory.setQuantity(inventory.getQuantity() + quantity);
        }

        inventoryRepository.save(inventory);
    }

    @Override
    @Transactional
    public void decreaseStock(int productId, int storeId, int quantity) {
        reserveStock(productId, storeId, quantity);
    }

    @Override
    @Transactional
    public void reserveStock(int productId, int storeId, int quantity) {
        log.info("Reserving stock atomically productId={} storeId={} quantity={}", productId, storeId, quantity);
        if (quantity <= 0) {
            throw new AppException(ErrorCode.VALIDATION_ERROR);
        }

        int updatedRows = inventoryRepository.reserveStockIfAvailable(productId, storeId, quantity);
        if (updatedRows > 0) {
            return;
        }

        Inventory inventory = inventoryRepository.findByProduct_IdAndStore_Id(productId, storeId)
                .orElseThrow(() -> new AppException(ErrorCode.OUT_OF_STOCK));

        if (inventory.getQuantity() < quantity) {
            throw new AppException(ErrorCode.INSUFFICIENT_STOCK);
        }

        throw new AppException(ErrorCode.INTERNAL_SERVER_ERROR);
    }

    @Override
    public boolean checkStock(int productId, int storeId, int quantity) {
        log.info("Checking stock productId={} storeId={} quantity request={}", productId, storeId, quantity);
        Inventory inventory = inventoryRepository.findByProduct_IdAndStore_Id(productId, storeId)
                .orElse(null);

        if (inventory == null) {
            return false;
        }

        return inventory.getQuantity() >= quantity;
    }
}
