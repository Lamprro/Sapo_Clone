package com.example.Sapo_Clone.Service.Impl;

import com.example.Sapo_Clone.DTO.Request.PurchaseOrder.PurchaseOrderCreateDTO;
import com.example.Sapo_Clone.DTO.Request.PurchaseOrder.PurchaseOrderDetailCreateDTO;
import com.example.Sapo_Clone.DTO.Response.PurchaseOrder.PurchaseOrderResponse;
import com.example.Sapo_Clone.Entity.*;
import com.example.Sapo_Clone.Exception.AppException;
import com.example.Sapo_Clone.Exception.ErrorCode;
import com.example.Sapo_Clone.Repository.*;
import com.example.Sapo_Clone.Service.InventoryService;
import com.example.Sapo_Clone.Service.PurchaseOrderService;
import com.example.Sapo_Clone.Utils.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class PurchaseOrderServiceImpl implements PurchaseOrderService {

    private static final int STATUS_DRAFT = 0;
    private static final int STATUS_COMPLETED = 1;
    private static final int STATUS_CANCELLED = 4;

    private final PurchaseOrderRepository purchaseOrderRepository;
    private final PurchaseOrderDetailRepository purchaseOrderDetailRepository;
    private final ProductRepository productRepository;
    private final StoreRepository storeRepository;
    private final ProviderRepository providerRepository;
    private final UserRepository userRepository;
    private final InventoryService inventoryService;

    @Override
    @Transactional
    public PurchaseOrderResponse createPurchaseOrder(PurchaseOrderCreateDTO dto) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        int currentUserId = SecurityUtils.getCurrentUserId();

        log.info("Creating Purchase Order for companyId={}, storeId={}, creatorId={}", companyId, dto.getStoreId(),
                currentUserId);

        if (dto.getStoreId() == null) {
            throw new AppException(ErrorCode.VALIDATION_ERROR);
        }
        if (dto.getProviderId() == null) {
            throw new AppException(ErrorCode.VALIDATION_ERROR);
        }

        User creator = userRepository.findById(currentUserId)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));

        Integer storeIdObj = dto.getStoreId();
        if (storeIdObj == null)
            throw new AppException(ErrorCode.VALIDATION_ERROR);
        int storeId = storeIdObj;
        Store store = storeRepository.findById(storeId)
                .orElseThrow(() -> new AppException(ErrorCode.STORE_NOT_FOUND));
        if (store.getCompany().getId() != companyId)
            throw new AppException(ErrorCode.STORE_NOT_FOUND);

        Integer providerIdObj = dto.getProviderId();
        if (providerIdObj == null)
            throw new AppException(ErrorCode.VALIDATION_ERROR);
        int providerId = providerIdObj;
        Provider provider = providerRepository.findById(providerId)
                .orElseThrow(() -> new AppException(ErrorCode.PROVIDER_NOT_FOUND));

        PurchaseOrder po = new PurchaseOrder();
        po.setStore(store);
        po.setProvider(provider);
        po.setUser(creator);
        po.setNote(dto.getNote());
        po.setStatus(dto.getStatus());

        PurchaseOrder savedPo = purchaseOrderRepository.save(po);

        List<PurchaseOrderDetail> details = new ArrayList<>();
        double totalAmount = 0.0;

        for (PurchaseOrderDetailCreateDTO itemDto : dto.getPurchaseOrderDetails()) {
            Integer pIdObj = itemDto.getProductId();
            if (pIdObj == null)
                throw new AppException(ErrorCode.VALIDATION_ERROR);
            int pId = pIdObj;
            Product product = productRepository.findById(pId)
                    .orElseThrow(() -> new AppException(ErrorCode.PRODUCT_NOT_FOUND));

            if (product.getCompany().getId() != companyId)
                throw new AppException(ErrorCode.PRODUCT_NOT_FOUND);

            double subtotal = itemDto.getQuantity() * itemDto.getPrice();
            totalAmount += subtotal;

            PurchaseOrderDetail detail = new PurchaseOrderDetail();
            detail.setPurchaseOrder(savedPo);
            detail.setProduct(product);
            detail.setQuantity(itemDto.getQuantity());
            detail.setPrice(itemDto.getPrice());
            detail.setSubtotal(subtotal);
            details.add(detail);

            if (savedPo.getStatus() == STATUS_COMPLETED) {
                inventoryService.increaseStock(product.getId(), store.getId(), itemDto.getQuantity());
            }

            product.setImportPrice(itemDto.getPrice());
            productRepository.save(product);
        }

        purchaseOrderDetailRepository.saveAll(details);
        savedPo.setTotalAmount(totalAmount);
        savedPo.setPurchaseOrderDetails(details);

        return PurchaseOrderResponse.fromEntity(purchaseOrderRepository.save(savedPo));
    }
    @Override
    public PurchaseOrderResponse getById(Integer purchaseOrderId) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        String currentRole = SecurityUtils.getCurrentRole();

        Integer storeId = null;
        if ("EMPLOYEE".equals(currentRole) || "MANAGER".equals(currentRole)) {
            storeId = SecurityUtils.getCurrentUser().getStoreId();
            if (storeId == null || storeId <= 0) {
                throw new AppException(ErrorCode.FORBIDDEN);
            }
        }

        if (storeId != null) {
            Store store = storeRepository.findById(storeId)
                    .orElseThrow(() -> new AppException(ErrorCode.STORE_NOT_FOUND));
            if (store.getCompany() == null || store.getCompany().getId() != companyId) {
                throw new AppException(ErrorCode.FORBIDDEN);
            }
        }
        PurchaseOrder order = purchaseOrderRepository.findById(purchaseOrderId)
                .orElseThrow(() -> new AppException(ErrorCode.ORDER_NOT_FOUND));

        return PurchaseOrderResponse.fromEntity(order);
    }

    @Override
    public Page<PurchaseOrderResponse> getList(String searching, Integer status, int page, int size) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        String currentRole = SecurityUtils.getCurrentRole();

        Integer storeId = null;
        if ("EMPLOYEE".equals(currentRole) || "MANAGER".equals(currentRole)) {
            storeId = SecurityUtils.getCurrentUser().getStoreId();
            if (storeId == null || storeId <= 0) {
                throw new AppException(ErrorCode.FORBIDDEN);
            }
        }

        if (storeId != null) {
            Store store = storeRepository.findById(storeId)
                    .orElseThrow(() -> new AppException(ErrorCode.STORE_NOT_FOUND));
            if (store.getCompany() == null || store.getCompany().getId() != companyId) {
                throw new AppException(ErrorCode.FORBIDDEN);
            }
        }

        PageRequest pageRequest = PageRequest.of(page, size, Sort.by("createdAt").descending());
        return purchaseOrderRepository.findByFilters(companyId, storeId, status, searching, pageRequest)
                .map(PurchaseOrderResponse::fromEntity);
    }

    @Override
    @Transactional
    public PurchaseOrderResponse updateStatus(int purchaseOrderId, int status) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        PurchaseOrder po = purchaseOrderRepository.findById(purchaseOrderId)
                .orElseThrow(() -> new AppException(ErrorCode.VALIDATION_ERROR));

        if (po.getStore().getCompany().getId() != companyId)
            throw new AppException(ErrorCode.FORBIDDEN);

        int oldStatus = po.getStatus();
        int newStatus = status;

        if (oldStatus == newStatus)
            return PurchaseOrderResponse.fromEntity(po);

        // LOCK: Cannot change status back from Cancelled
        if (oldStatus == STATUS_CANCELLED) {
            throw new AppException(ErrorCode.VALIDATION_ERROR);
        }

        // Logic for Stock Sync
        if (oldStatus != STATUS_COMPLETED && newStatus == STATUS_COMPLETED) {
            // Transition to Completed -> Increase Stock
            for (PurchaseOrderDetail detail : po.getPurchaseOrderDetails()) {
                inventoryService.increaseStock(detail.getProduct().getId(), po.getStore().getId(),
                        detail.getQuantity());
            }
        } else if (oldStatus == STATUS_COMPLETED && newStatus == STATUS_CANCELLED) {
            // Transition from Completed to Cancelled -> Decrease Stock (Restoration)
            for (PurchaseOrderDetail detail : po.getPurchaseOrderDetails()) {
                inventoryService.decreaseStock(detail.getProduct().getId(), po.getStore().getId(),
                        detail.getQuantity());
            }
        }

        po.setStatus(newStatus);
        return PurchaseOrderResponse.fromEntity(purchaseOrderRepository.save(po));
    }

    @Override
    public PurchaseReportResponse getPurchaseReport(int storeId, LocalDateTime start, LocalDateTime end) {
        if (storeId == -1 || storeId == 0) {
            storeId = SecurityUtils.getCurrentStoreId();
        }
        Store store = storeRepository.findById(storeId)
                .orElseThrow(() -> new AppException(ErrorCode.STORE_NOT_FOUND));
        int companyId = SecurityUtils.getCurrentCompanyId();
        int currentUserId = SecurityUtils.getCurrentUserId();
        String currentRole = SecurityUtils.getCurrentRole();

        if (start == null) {
            start = LocalDate.now().atStartOfDay();
        }
        if (end == null) {
            end = LocalDate.now().plusDays(1).atStartOfDay();
        }

        Double totalExpenditure = purchaseOrderRepository.sumTotalAmountByStoreAndDate(companyId, storeId, start, end);
        Long totalOrders = purchaseOrderRepository.countOrdersByStoreAndDate(companyId, storeId, start, end);

        Page<PurchaseOrder> detailedOrders = purchaseOrderRepository.findByFilters(companyId, storeId, null, null,
                PageRequest.of(0, 1000));
        LocalDateTime finalEnd = end;
        LocalDateTime finalStart = start;
        List<PurchaseOrderResponse> orderList = detailedOrders.getContent().stream()
                .filter(o -> o.getCreatedAt().isAfter(finalStart) && o.getCreatedAt().isBefore(finalEnd))
                .map(PurchaseOrderResponse::fromEntity)
                .collect(Collectors.toList());

        return PurchaseReportResponse.builder()
                .totalExpenditure(totalExpenditure != null ? totalExpenditure : 0.0)
                .totalOrders(totalOrders != null ? totalOrders : 0)
                .orders(orderList)
                .build();
    }
}