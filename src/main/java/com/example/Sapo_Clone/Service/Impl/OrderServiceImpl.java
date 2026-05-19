package com.example.Sapo_Clone.Service.Impl;

import com.example.Sapo_Clone.DTO.Request.Order.OrderCreateDTO;
import com.example.Sapo_Clone.DTO.Request.Order.OrderDetailCreateDTO;
import com.example.Sapo_Clone.DTO.Request.Order.OrderPaymentDTO;
import com.example.Sapo_Clone.DTO.Request.Order.OrderStatusDTO;
import com.example.Sapo_Clone.DTO.Request.Order.OrderUpdateDTO;
import com.example.Sapo_Clone.DTO.Response.Order.OrderListResponse;
import com.example.Sapo_Clone.DTO.Response.Order.OrderResponse;
import com.example.Sapo_Clone.Entity.*;
import com.example.Sapo_Clone.Exception.AppException;
import com.example.Sapo_Clone.Exception.ErrorCode;
import com.example.Sapo_Clone.Repository.*;
import com.example.Sapo_Clone.Service.InventoryService;
import com.example.Sapo_Clone.Service.OrderService;
import com.example.Sapo_Clone.Utils.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

@Service
@RequiredArgsConstructor
@Slf4j
public class OrderServiceImpl implements OrderService {

    private final OrderRepository orderRepository;
    private final OrderDetailRepository orderDetailRepository;
    private final ProductRepository productRepository;
    private final UserRepository userRepository;
    private final StoreRepository storeRepository;
    private final PromotionRepository promotionRepository;
    private final InventoryService inventoryService;
    private final CartRepository cartRepository;
    private final CartItemRepository cartItemRepository;

    // Status Constants
    private static final int STATUS_PENDING = 0;
    private static final int STATUS_CONFIRMED = 1;
    private static final int STATUS_SHIPPING = 2;
    private static final int STATUS_COMPLETED = 3;
    private static final int STATUS_CANCELLED = 4;

    private static final int PAYMENT_UNPAID = 0;
    private static final int PAYMENT_PAID = 1;
    private static final int PAYMENT_FAILED = 2;
    private static final int PAYMENT_REFUNDED = 3;

    @Override
    @Transactional
    public OrderResponse createOrder(OrderCreateDTO dto) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        int currentUserId = SecurityUtils.getCurrentUserId();
        String currentRole = SecurityUtils.getCurrentRole();

        log.info("Creating order for companyId={}, userId={}", companyId, currentUserId);

        if (dto.getCustomerId() == null)
            throw new AppException(ErrorCode.VALIDATION_ERROR);
        int customerId = dto.getCustomerId();
        User customer = userRepository.findById(customerId)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));

        if (customer.getCompany() == null || customer.getCompany().getId() != companyId) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        if (dto.getStoreId() == null)
            throw new AppException(ErrorCode.VALIDATION_ERROR);
        int storeId = dto.getStoreId();
        Store store = storeRepository.findById(storeId)
                .orElseThrow(() -> new AppException(ErrorCode.STORE_NOT_FOUND));

        if (store.getCompany().getId() != companyId) {
            throw new AppException(ErrorCode.COMPANY_NOT_FOUND);
        }

        Order order = new Order();
        order.setCustomer(customer);
        order.setStore(store);
        order.setPaymentMethod(dto.getPaymentMethod());
        order.setNote(dto.getNote());
        order.setShippingAddress(dto.getShippingAddress());
        order.setStatus(STATUS_PENDING);
        order.setPaymentStatus(PAYMENT_UNPAID);

        // Employee assignment must be derived from authenticated context.
        if ("EMPLOYEE".equals(currentRole) || "MANAGER".equals(currentRole)) {
            User currentUser = userRepository.findById(currentUserId)
                    .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));
            order.setEmployee(currentUser);
        } else if ("ADMIN".equals(currentRole) && dto.getEmployeeId() != null) {
            Integer empIdObj = dto.getEmployeeId();
            if (empIdObj == null)
                throw new AppException(ErrorCode.VALIDATION_ERROR);
            int empId = empIdObj;
            User assignedEmployee = userRepository.findById(empId)
                    .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));

            boolean validRole = assignedEmployee.getRoles() != null &&
                    "EMPLOYEE".equals(assignedEmployee.getRoles().getRolesName());
            boolean sameCompany = assignedEmployee.getCompany() != null &&
                    assignedEmployee.getCompany().getId() == companyId;

            if (!validRole || !sameCompany) {
                throw new AppException(ErrorCode.FORBIDDEN);
            }

            order.setEmployee(assignedEmployee);
        }

        // Handle Promotion
        if (dto.getPromotionId() != null) {
            Integer promoIdObj = dto.getPromotionId();
            if (promoIdObj == null)
                throw new AppException(ErrorCode.VALIDATION_ERROR);
            int promoId = promoIdObj;
            Promotion promotion = promotionRepository.findById(promoId)
                    .orElseThrow(() -> new AppException(ErrorCode.PROMOTION_NOT_FOUND));
            order.setPromotion(promotion);
        }

        // [INTEGRITY CHECK] Only for online customer orders
        boolean isOnlineOrder = currentRole.contains("CUSTOMER");
        Cart cart = null;
        if (isOnlineOrder) {
            cart = cartRepository.findByUser_Id(customer.getId()).orElse(null);
        }

        double rawTotalAmount = 0.0;
        List<OrderDetail> details = new ArrayList<>();

        for (OrderDetailCreateDTO itemDto : dto.getOrderDetails()) {
            Integer prodIdObj = itemDto.getProductId();
            Integer qtyObj = itemDto.getQuantity();
            if (prodIdObj == null || qtyObj == null)
                throw new AppException(ErrorCode.VALIDATION_ERROR);
            int prodId = prodIdObj;
            int qty = qtyObj;

            if (!inventoryService.checkStock(prodId, storeId, qty)) {
                throw new AppException(ErrorCode.INSUFFICIENT_STOCK);
            }

            Product product = productRepository.findById(prodId)
                    .orElseThrow(() -> new AppException(ErrorCode.PRODUCT_NOT_FOUND));

            if (isOnlineOrder && cart != null) {
                cartItemRepository.findByCart_IdAndProduct_Id(cart.getId(), product.getId())
                        .ifPresent(ci -> {
                            if (ci.getQuantity() <= qty) {
                                cartItemRepository.delete(ci);
                            } else {
                                ci.setQuantity(ci.getQuantity() - qty);
                                cartItemRepository.save(ci);
                            }
                        });
            }

            OrderDetail detail = new OrderDetail();
            detail.setOrder(order);
            detail.setProduct(product);
            detail.setQuantity(qty);
            detail.setPrice(product.getSellPrice());
            detail.setImportPrice(product.getImportPrice());
            detail.setSubtotal(qty * product.getSellPrice());

            rawTotalAmount += detail.getSubtotal();
            details.add(detail);
        }
        double totalAmount = rawTotalAmount;
        if (order.getPromotion() != null) {
            double reduction = PromotionServiceImpl.calculateReduction(rawTotalAmount,
                    order.getPromotion().getDiscountType(), order.getPromotion().getDiscountValue(),
                    order.getPromotion().getMaxAccount());
            totalAmount = Math.max(0, rawTotalAmount - reduction);
        }

        Point customerPoint = customer.getPoint();
        if (dto.getRedeemPoint() != null && dto.getRedeemPoint() > 0) {
            if (customerPoint == null || customerPoint.getPoint() < dto.getRedeemPoint()) {
                throw new AppException(ErrorCode.INSUFFICIENT_POINTS);
            }
            customerPoint.setPoint(customerPoint.getPoint() - dto.getRedeemPoint());
        }

        order.setOrderDetails(details);
        order.setTotalAmount(Math.max(0, totalAmount - (dto.getRedeemPoint() != null ? dto.getRedeemPoint() : 0)));
        order.setRedeemPoint(dto.getRedeemPoint() != null ? dto.getRedeemPoint() : 0);
        order.setEarnPoint((int) (order.getTotalAmount() / 100000)); //

        // Atomically reserve stock for each line.
        for (OrderDetail item : details) {
            inventoryService.reserveStock(item.getProduct().getId(), dto.getStoreId(), item.getQuantity());
        }

        Order saved = orderRepository.save(order);

        return OrderResponse.fromEntity(saved);
    }

    @Override
    @Transactional
    public OrderResponse updateOrder(int orderId, OrderUpdateDTO dto) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new AppException(ErrorCode.ORDER_NOT_FOUND));

        if (order.getStore().getCompany().getId() != companyId) {
            throw new AppException(ErrorCode.ORDER_NOT_FOUND);
        }

        if (order.getStatus() != STATUS_PENDING) {
            throw new AppException(ErrorCode.ORDER_LOCKED);
        }

        Map<Integer, Integer> oldQtyByProduct = new HashMap<>();
        for (OrderDetail oldDetail : order.getOrderDetails()) {
            int productId = oldDetail.getProduct().getId();
            oldQtyByProduct.merge(productId, oldDetail.getQuantity(), Integer::sum);
        }

        double rawTotalAmount = 0.0;
        List<OrderDetail> newDetails = new ArrayList<>();
        Map<Integer, Integer> newQtyByProduct = new HashMap<>();

        for (OrderDetailCreateDTO itemDto : dto.getItems()) {
            Integer prodIdObj = itemDto.getProductId();
            Integer qtyObj = itemDto.getQuantity();
            if (prodIdObj == null || qtyObj == null)
                throw new AppException(ErrorCode.VALIDATION_ERROR);
            int prodId = prodIdObj;
            int qty = qtyObj;

            Product product = productRepository.findById(prodId)
                    .orElseThrow(() -> new AppException(ErrorCode.PRODUCT_NOT_FOUND));

            if (product.getCompany() == null || product.getCompany().getId() != companyId) {
                throw new AppException(ErrorCode.PRODUCT_NOT_FOUND);
            }

            OrderDetail detail = new OrderDetail();
            detail.setOrder(order);
            detail.setProduct(product);
            detail.setQuantity(qty);
            detail.setPrice(product.getSellPrice());
            detail.setImportPrice(product.getImportPrice());
            detail.setSubtotal(qty * product.getSellPrice());

            rawTotalAmount += detail.getSubtotal();
            newDetails.add(detail);
            newQtyByProduct.merge(prodId, qty, Integer::sum);
        }

        Set<Integer> affectedProducts = new HashSet<>();
        affectedProducts.addAll(oldQtyByProduct.keySet());
        affectedProducts.addAll(newQtyByProduct.keySet());

        for (Integer productId : affectedProducts) {
            int oldQty = oldQtyByProduct.getOrDefault(productId, 0);
            int newQty = newQtyByProduct.getOrDefault(productId, 0);
            int delta = newQty - oldQty;

            if (delta > 0) {
                inventoryService.reserveStock(productId, order.getStore().getId(), delta);
            } else if (delta < 0) {
                inventoryService.increaseStock(productId, order.getStore().getId(), -delta);
            }
        }

        // Replace old order details only after inventory adjustments succeed.
        order.getOrderDetails().clear();
        orderDetailRepository.deleteAllByOrderId(orderId);
        order.getOrderDetails().addAll(newDetails);

        double totalAmount = rawTotalAmount;
        if (order.getPromotion() != null) {
            double reduction = PromotionServiceImpl.calculateReduction(rawTotalAmount,
                    order.getPromotion().getDiscountType(), order.getPromotion().getDiscountValue(),
                    order.getPromotion().getMaxAccount());
            totalAmount = Math.max(0, rawTotalAmount - reduction);
        }

        order.setTotalAmount(Math.max(0, totalAmount - order.getRedeemPoint()));
        order.setEarnPoint((int) (order.getTotalAmount() / 100000));

        order.setPaymentMethod(dto.getPaymentMethod());
        order.setShippingAddress(dto.getShippingAddress());
        order.setNote(dto.getNote());

        return OrderResponse.fromEntity(orderRepository.save(order));
    }

    @Override
    public OrderResponse getOrder(int id) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.ORDER_NOT_FOUND));
        if (order.getStore().getCompany().getId() != companyId) {
            throw new AppException(ErrorCode.ORDER_NOT_FOUND);
        }
        return OrderResponse.fromEntity(order);
    }

    @Override
    public Page<OrderListResponse> getList(int status, String keyword, int page, int size) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        int currentUserId = SecurityUtils.getCurrentUserId();
        String currentRole = SecurityUtils.getCurrentRole();

        Integer customerId = null;
        Integer storeId = null;

        // Role based filtering logic
        if ("CUSTOMER".equals(currentRole)) {
            // Customer only sees their own orders
            customerId = currentUserId;
        } else if ("EMPLOYEE".equals(currentRole) || "MANAGER".equals(currentRole)) {
            // Staff members only see orders in their store (if assigned)
            Integer currentStoreId = SecurityUtils.getCurrentUser().getStoreId();
            if (currentStoreId != null && currentStoreId > 0) {
                storeId = currentStoreId;
            }
        }
        // ADMIN can see everything in the company (customerId and storeId remain null)

        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        return orderRepository.searchOrders(companyId, customerId, storeId, status, keyword, pageable)
                .map(OrderListResponse::fromEntity);
    }

    @Override
    @Transactional
    public OrderResponse changeStatus(int id, OrderStatusDTO dto) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.ORDER_NOT_FOUND));

        if (order.getStore().getCompany().getId() != companyId) {
            throw new AppException(ErrorCode.ORDER_NOT_FOUND);
        }

        int oldStatus = order.getStatus();
        int newStatus = dto.getStatus();

        if (newStatus == oldStatus)
            return OrderResponse.fromEntity(order);

        if (newStatus == STATUS_COMPLETED && oldStatus != STATUS_COMPLETED) {
            User customer = order.getCustomer();
            Point customerPoint = customer.getPoint();
            if (customerPoint != null) {
                customerPoint.setPoint(customerPoint.getPoint() + order.getEarnPoint());
                userRepository.save(customer);
            }
        } else if (newStatus == STATUS_CANCELLED && oldStatus != STATUS_CANCELLED) {
            for (OrderDetail detail : order.getOrderDetails()) {
                inventoryService.increaseStock(detail.getProduct().getId(), order.getStore().getId(),
                        detail.getQuantity());
            }
            if (order.getRedeemPoint() > 0) {
                User customer = order.getCustomer();
                Point customerPoint = customer.getPoint();
                if (customerPoint != null) {
                    customerPoint.setPoint(customerPoint.getPoint() + order.getRedeemPoint());
                    userRepository.save(customer);
                }
            }
        }

        order.setStatus(newStatus);
        return OrderResponse.fromEntity(orderRepository.save(order));
    }

    @Override
    @Transactional
    public OrderResponse changePaymentStatus(int id, OrderPaymentDTO dto) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.ORDER_NOT_FOUND));

        if (order.getStore().getCompany().getId() != companyId) {
            throw new AppException(ErrorCode.ORDER_NOT_FOUND);
        }

        order.setPaymentStatus(dto.getPaymentStatus());
        return OrderResponse.fromEntity(orderRepository.save(order));
    }

    @Override
    public Map<String, Object> getFinancialReport(int storeId, LocalDateTime start, LocalDateTime end) {
        if (storeId == -1 || storeId == 0) {
            storeId = SecurityUtils.getCurrentStoreId();
        }
        storeRepository.findById(storeId)
                .orElseThrow(() -> new AppException(ErrorCode.STORE_NOT_FOUND));
        int companyId = SecurityUtils.getCurrentCompanyId();
        if (start == null) {
            start = LocalDate.now().atStartOfDay();
        }
        if (end == null) {
            end = LocalDate.now().plusDays(1).atStartOfDay();
        }
        Double revenue = orderRepository.calculateRevenue(companyId, storeId, start, end);
        Double profit = orderRepository.calculateProfit(companyId, storeId, start, end);

        Map<String, Object> report = new HashMap<>();
        report.put("revenue", revenue != null ? revenue : 0.0);
        report.put("profit", profit != null ? profit : 0.0);
        report.put("startDate", start);
        report.put("endDate", end);
        report.put("companyId", companyId);
        report.put("storeId", storeId);

        return report;
    }

}
