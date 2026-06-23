package com.example.Sapo_Clone.Service.Impl;

import com.example.Sapo_Clone.DTO.Request.Order.DisposeOrderCreateDTO;
import com.example.Sapo_Clone.DTO.Request.Order.DisposeOrderDetailDTO;
import com.example.Sapo_Clone.DTO.Request.Order.OrderCreateDTO;
import com.example.Sapo_Clone.DTO.Request.Order.OrderDetailCreateDTO;
import com.example.Sapo_Clone.DTO.Request.Order.OrderPaymentDTO;
import com.example.Sapo_Clone.DTO.Request.Order.OrderStatusDTO;
import com.example.Sapo_Clone.DTO.Request.Order.OrderUpdateDTO;
import com.example.Sapo_Clone.DTO.Response.Coordinates;
import com.example.Sapo_Clone.DTO.Response.Order.OrderListResponse;
import com.example.Sapo_Clone.DTO.Response.Order.OrderResponse;
import com.example.Sapo_Clone.Entity.*;
import com.example.Sapo_Clone.Enum.NotificationType;
import com.example.Sapo_Clone.Exception.AppException;
import com.example.Sapo_Clone.Exception.ErrorCode;
import com.example.Sapo_Clone.Repository.*;
import com.example.Sapo_Clone.Service.CartService;
import com.example.Sapo_Clone.Service.InventoryService;
import com.example.Sapo_Clone.Service.MapService;
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
import java.util.stream.Collectors;

import static com.example.Sapo_Clone.Exception.ErrorCode.CATCH;

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
    private final CartService cartService;
    private final CartRepository cartRepository;
    private final CartItemRepository cartItemRepository;
    private final CompanyRepository companyRepository;
    private final MapService mapService;
    private final org.springframework.context.ApplicationEventPublisher eventPublisher;

    // Status Constants
    private static final int STATUS_PENDING = 0;
    private static final int STATUS_CONFIRMED = 1;
    private static final int STATUS_SHIPPING = 2;
    private static final int STATUS_DELIVERED = 3;
    private static final int STATUS_COMPLETED = 4;
    private static final int STATUS_CANCELLED = 5;
    private static final int STATUS_ERROR = 6;
    private static final int STATUS_DISPOSE = 7;

    private static final int PAYMENT_UNPAID = 0;
    private static final int PAYMENT_PAID = 1;
    private static final int PAYMENT_FAILED = 2;
    private static final int PAYMENT_REFUNDED = 3;

    @Override
    @Transactional
    public List<OrderResponse> createOrder(OrderCreateDTO dto) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        int currentUserId = SecurityUtils.getCurrentUserId();
        String currentRole = SecurityUtils.getCurrentRole();

        log.info("Creating order for companyId={}, userId={}", companyId, currentUserId);

        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new AppException(ErrorCode.COMPANY_NOT_FOUND));

        User customer = userRepository.findById(dto.getCustomerId())
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));

        boolean isOnlineOrder = currentRole.contains("CUSTOMER");
        Cart cart = null;
        if (isOnlineOrder) {
            cart = cartRepository.findByUser_Id(customer.getId()).orElse(null);
            if (dto.getStoreId() == null && (dto.getShippingAddress() == null || dto.getShippingAddress().isEmpty())) {
                throw new AppException(ErrorCode.ADDRESS_NOT_FOUND);
            }
        }

        // 1. Phân nhóm sản phẩm theo StoreId
        Map<Integer, List<OrderDetailCreateDTO>> storeOrderMap = new HashMap<>();
        Coordinates customerLoc = null;

        if (dto.getStoreId() != null) {
            for (OrderDetailCreateDTO item : dto.getOrderDetails()) {
                Integer targetStoreId = item.getStoreId() != null ? item.getStoreId() : dto.getStoreId();
                storeOrderMap.computeIfAbsent(targetStoreId, k -> new ArrayList<>()).add(item);
            }
        } else {
            // Tính toán store gần nhất cho từng sản phẩm nếu chưa có storeId
            customerLoc = mapService.getCoordinatesFromAddress(dto.getShippingAddress());
            if (customerLoc == null)
                throw new AppException(ErrorCode.ADDRESS_NOT_FOUND);

            for (OrderDetailCreateDTO item : dto.getOrderDetails()) {
                if (item.getStoreId() != null) {
                    storeOrderMap.computeIfAbsent(item.getStoreId(), k -> new ArrayList<>()).add(item);
                } else {
                    Integer nearestStoreId = storeRepository.findNearestStoreIdWithStock(
                            item.getProductId(), item.getQuantity(), customerLoc.getLat(), customerLoc.getLng(),
                            companyId).orElseThrow(() -> new AppException(ErrorCode.OUT_OF_STOCK, "None of stores have enough stock for: " + (productRepository.findById(item.getProductId())).orElseThrow(() -> new AppException(ErrorCode.PRODUCT_NOT_FOUND)).getProductName()));
                            
                    storeOrderMap.computeIfAbsent(nearestStoreId, k -> new ArrayList<>()).add(item);
                }
            }
        }

        List<OrderResponse> createdOrders = new ArrayList<>();
        int numberOfOrders = storeOrderMap.size();

        // Chia đều điểm đổi (redeemPoint) cho các đơn hàng nếu có chia tách
        int redeemPointPerOrder = dto.getRedeemPoint() != null ? dto.getRedeemPoint() / numberOfOrders : 0;
        int remainingRedeemPoint = dto.getRedeemPoint() != null ? dto.getRedeemPoint() % numberOfOrders : 0;

        // Trừ tổng điểm của khách hàng một lần
        Point customerPoint = customer.getPoint();
        if (dto.getRedeemPoint() != null && dto.getRedeemPoint() > 0) {
            if (customerPoint == null || customerPoint.getPoint() < dto.getRedeemPoint()) {
                throw new AppException(CATCH); // Or custom exception for not enough points
            }
            customerPoint.setPoint(customerPoint.getPoint() - dto.getRedeemPoint());
            userRepository.save(customer); // LƯU NGAY customerPoint VÀO DB
        }

        // Tạo từng đơn hàng cho mỗi Store
        for (Map.Entry<Integer, List<OrderDetailCreateDTO>> entry : storeOrderMap.entrySet()) {
            Integer currentStoreId = entry.getKey();
            List<OrderDetailCreateDTO> itemsForStore = entry.getValue();

            Store store = storeRepository.findById(currentStoreId)
                    .orElseThrow(() -> new AppException(ErrorCode.STORE_NOT_FOUND));

            if (store.getCompany().getId() != companyId) {
                throw new AppException(ErrorCode.COMPANY_NOT_FOUND);
            }

            Order order = new Order();
            order.setCustomer(customer);
            order.setStore(store);
            order.setPaymentMethod(dto.getPaymentMethod());
            order.setNote(dto.getNote() + (numberOfOrders > 1 ? " (Split the order)" : ""));
            order.setShippingAddress(dto.getShippingAddress());
            order.setPaymentStatus(PAYMENT_UNPAID);
            if (dto.getStatus() == null || dto.getStatus() == 0){
                order.setStatus(STATUS_PENDING);
            }else{
                order.setStatus(STATUS_COMPLETED);
                order.setPaymentStatus(PAYMENT_PAID);
            }


            if (dto.getEmployeeId() != null) {
                User creator = userRepository.findById(dto.getEmployeeId())
                        .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));
                if (creator.getRoles() != null && creator.getRoles().getRolesName().contains("EMPLOYEE")) {
                    order.setEmployee(creator);
                }
            }

            if (dto.getPromotionId() != null) {
                Promotion promotion = promotionRepository.findById(dto.getPromotionId())
                        .orElseThrow(() -> new AppException(ErrorCode.PROMOTION_NOT_FOUND));
                if (promotion.getStatus() != 1 || promotion.getScope() != 0) {
                    throw new AppException(ErrorCode.PROMOTION_NOT_ACTIVE);
                }
                order.setPromotion(promotion);
            }

            double rawTotalAmount = 0.0;
            List<OrderDetail> details = new ArrayList<>();

            for (OrderDetailCreateDTO itemDto : itemsForStore) {
                Product product = productRepository.findById(itemDto.getProductId())
                    .orElseThrow(() -> new AppException(ErrorCode.PRODUCT_NOT_FOUND));
                if (!inventoryService.checkStock(itemDto.getProductId(), currentStoreId, itemDto.getQuantity())) {
                    throw new AppException(ErrorCode.INSUFFICIENT_STOCK, "Warnning: Not enough stock for: " + product.getProductName());
                }

                if (isOnlineOrder && cart != null) {
                    cartItemRepository.findByCart_IdAndProduct_Id(cart.getId(), product.getId())
                            .ifPresent(ci -> {
                                if (ci.getQuantity() <= itemDto.getQuantity()) {
                                    cartItemRepository.delete(ci);
                                } else {
                                    ci.setQuantity(ci.getQuantity() - itemDto.getQuantity());
                                    cartItemRepository.save(ci);
                                }
                            });
                }

                OrderDetail detail = new OrderDetail();
                detail.setOrder(order);
                detail.setProduct(product);
                detail.setQuantity(itemDto.getQuantity());
                detail.setPrice(product.getSellPrice());
                detail.setImportPrice(product.getImportPrice());
                detail.setSubtotal(itemDto.getQuantity() * product.getSellPrice());

                rawTotalAmount += detail.getSubtotal();
                details.add(detail);
            }

            double totalAmount = rawTotalAmount;
            if (order.getPromotion() != null) {
                Promotion promotion = order.getPromotion();
                // Check minimum account condition
                if (rawTotalAmount >= promotion.getMinAccount()) {
                    double reduction = PromotionServiceImpl.calculateReduction(rawTotalAmount,
                            promotion.getDiscountType(), promotion.getDiscountValue(),
                            promotion.getMaxAccount());
                    totalAmount = Math.max(0, rawTotalAmount - reduction);
                }
            }

            int currentOrderRedeemPoint = redeemPointPerOrder + (remainingRedeemPoint > 0 ? 1 : 0);
            if (remainingRedeemPoint > 0)
                remainingRedeemPoint--;

            order.setOrderDetails(details);
            double redeemValue = currentOrderRedeemPoint * 1000.0;
            order.setTotalAmount(Math.max(0, totalAmount - redeemValue));
            order.setRedeemPoint(currentOrderRedeemPoint);
            int earnPoint = (int) (order.getTotalAmount() / 100000);
            order.setEarnPoint(earnPoint);
            
            // Note: If you want the customer to earn points immediately when placing order:
            // customerPoint.setPoint(customerPoint.getPoint() + earnPoint);
            // However, usually points are earned when order is COMPLETED/DELIVERED, 
            // which is handled in changeStatus. I'll leave it as is if that was your intention, 
            // but normally you don't add earnPoint at creation unless status is immediately COMPLETED.
            if (order.getStatus() == STATUS_COMPLETED) {
                customerPoint.setPoint(customerPoint.getPoint() + earnPoint);
                userRepository.save(customer); // LƯU LẠI VÀO DB
            }

            // Mấu chốt fix lỗi StackOverflow: LƯU order trước khi gọi inventoryService.decreaseStock
            // vì nếu ko có OrderID, các operation tiếp theo có thể gây lỗi vòng lặp hoặc flush lỗi
            Order savedOrder = orderRepository.save(order);
            
            for (OrderDetail item : details) {
                inventoryService.decreaseStock(item.getProduct().getId(), currentStoreId, item.getQuantity());
            }

            createdOrders.add(OrderResponse.fromEntity(savedOrder));

            // Publish notification for MANAGER and ADMIN
            eventPublisher.publishEvent(Notification.builder()
                    .title("New Order Created")
                    .message("A new order #" + savedOrder.getId() + " has been placed.")
                    .type(NotificationType.ORDER_NEW)
                    .targetRole("MANAGER") // Broad notification for Managers
                    .companyId(companyId)
                    .build());
        }

        return createdOrders;
    }

    @Override
    @Transactional
    public OrderResponse createDisposeOrder(DisposeOrderCreateDTO dto) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        int currentUserId = SecurityUtils.getCurrentUserId();

        User creator = userRepository.findById(currentUserId)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));

        Integer targetStoreId = dto.getStoreId();
        if (targetStoreId == null) {
            // Lấy từ user nếu không truyền
            if (creator.getStore() != null) {
                targetStoreId = creator.getStore().getId();
            } else {
                throw new AppException(ErrorCode.STORE_NOT_FOUND); // Hoặc tạo lỗi phù hợp
            }
        }

        log.info("Creating dispose order for storeId={}, companyId={}", targetStoreId, companyId);

        Store store = storeRepository.findById(targetStoreId)
                .orElseThrow(() -> new AppException(ErrorCode.STORE_NOT_FOUND));

        if (store.getCompany().getId() != companyId) {
            throw new AppException(ErrorCode.COMPANY_NOT_FOUND);
        }

        Order order = new Order();
        order.setStore(store);
        order.setEmployee(creator); // Trực tiếp gán người đang đăng nhập tạo đơn Dispose
        order.setCustomer(creator); // Dispose thì người tạo cũng là customer luôn cho dễ quản lý
        order.setPaymentMethod("0"); // Không cần thanh toán
        order.setNote("DISPOSE: " + (dto.getNote() != null ? dto.getNote() : ""));
        order.setShippingAddress(store.getStoreAddress());
        order.setStatus(STATUS_DISPOSE);
        order.setPaymentStatus(PAYMENT_PAID); // Đã xử lý xong coi như paid

        double totalAmount = 0.0;
        List<OrderDetail> details = new ArrayList<>();

        for (DisposeOrderDetailDTO itemDto : dto.getDisposeDetails()) {
            if (!inventoryService.checkStock(itemDto.getProductId(), store.getId(), itemDto.getQuantity())) {
                throw new AppException(ErrorCode.INSUFFICIENT_STOCK);
            }

            Product product = productRepository.findById(itemDto.getProductId())
                    .orElseThrow(() -> new AppException(ErrorCode.PRODUCT_NOT_FOUND));

            OrderDetail detail = new OrderDetail();
            detail.setOrder(order);
            detail.setProduct(product);
            detail.setQuantity(itemDto.getQuantity());
            // Set price to 0 since it's disposed
            detail.setPrice(0.0);
            detail.setImportPrice(product.getImportPrice());
            detail.setSubtotal(0.0);

            totalAmount += detail.getSubtotal();
            details.add(detail);
        }

        order.setOrderDetails(details);
        order.setTotalAmount(totalAmount);
        order.setEarnPoint(0);
        order.setRedeemPoint(0);

        Order savedOrder = orderRepository.save(order);

        // Trừ kho luôn sau khi save order
        for (OrderDetail item : details) {
            inventoryService.decreaseStock(item.getProduct().getId(), store.getId(), item.getQuantity());
        }

        return OrderResponse.fromEntity(savedOrder);
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

        // Hoàn trả lại số lượng tồn kho cũ (vì trạng thái order chưa hủy)
        for (OrderDetail oldDetail : order.getOrderDetails()) {
            inventoryService.increaseStock(oldDetail.getProduct().getId(), order.getStore().getId(),
                    oldDetail.getQuantity());
        }

        // Xóa sạch order_detail cũ khỏi DB
        order.getOrderDetails().clear();
        orderDetailRepository.deleteAllByOrderId(orderId);

        double rawTotalAmount = 0.0;
        List<OrderDetail> newDetails = new ArrayList<>();

        for (OrderDetailCreateDTO itemDto : dto.getItems()) {
            // Kiểm tra tồn kho cho số lượng mới
            if (!inventoryService.checkStock(itemDto.getProductId(), order.getStore().getId(), itemDto.getQuantity())) {
                throw new AppException(ErrorCode.INSUFFICIENT_STOCK);
            }

            Product product = productRepository.findById(itemDto.getProductId())
                    .orElseThrow(() -> new AppException(ErrorCode.PRODUCT_NOT_FOUND));

            OrderDetail detail = new OrderDetail();
            detail.setOrder(order);
            detail.setProduct(product);
            detail.setQuantity(itemDto.getQuantity());
            detail.setPrice(product.getSellPrice());
            detail.setImportPrice(product.getImportPrice());
            detail.setSubtotal(itemDto.getQuantity() * product.getSellPrice());

            rawTotalAmount += detail.getSubtotal();
            newDetails.add(detail);

            // Trừ lại tồn kho theo số lượng mới
            inventoryService.decreaseStock(itemDto.getProductId(), order.getStore().getId(), itemDto.getQuantity());
        }

        order.getOrderDetails().addAll(newDetails);

        double totalAmount = rawTotalAmount;
        if (order.getPromotion() != null) {
            Promotion promotion = order.getPromotion();
            if (rawTotalAmount >= promotion.getMinAccount()) {
                double reduction = PromotionServiceImpl.calculateReduction(rawTotalAmount,
                        promotion.getDiscountType(), promotion.getDiscountValue(),
                        promotion.getMaxAccount());
                totalAmount = Math.max(0, rawTotalAmount - reduction);
            }
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
        int currentUserId = SecurityUtils.getCurrentUserId();
        String currentRole = SecurityUtils.getCurrentRole();
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.ORDER_NOT_FOUND));

        if (order.getStore().getCompany().getId() != companyId) {
            throw new AppException(ErrorCode.ORDER_NOT_FOUND);
        }

        int oldStatus = order.getStatus();
        int newStatus = dto.getStatus();

        if (newStatus == oldStatus)
            return OrderResponse.fromEntity(order);

        boolean isCustomer = currentRole != null && currentRole.equalsIgnoreCase("CUSTOMER");
        boolean isStaff = currentRole != null
                && (currentRole.equalsIgnoreCase("EMPLOYEE") || currentRole.equalsIgnoreCase("MANAGER"));
        if (isCustomer) {
            User customer = order.getCustomer();
            if (customer == null || customer.getId() != currentUserId) {
                throw new AppException(ErrorCode.FORBIDDEN);
            }

            if (newStatus == STATUS_COMPLETED) {
                if (oldStatus != STATUS_DELIVERED) {
                    throw new AppException(ErrorCode.ORDER_LOCKED);
                }
            } else if (newStatus == STATUS_CANCELLED) {
                if (oldStatus != STATUS_PENDING && oldStatus != STATUS_CONFIRMED && oldStatus != STATUS_DELIVERED) {
                    throw new AppException(ErrorCode.ORDER_LOCKED);
                }
            } else {
                throw new AppException(ErrorCode.FORBIDDEN);
            }
        } else if (isStaff) {
            if (newStatus != STATUS_PENDING
                    && newStatus != STATUS_CONFIRMED
                    && newStatus != STATUS_SHIPPING
                    && newStatus != STATUS_DELIVERED
                    && newStatus != STATUS_COMPLETED
                    && newStatus != STATUS_CANCELLED
                    && newStatus != STATUS_ERROR) {
                throw new AppException(ErrorCode.FORBIDDEN);
            }
        }

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
            // Do not automatically set PAYMENT_REFUNDED - manager must trigger manually via refund button
            if (order.getRedeemPoint() > 0) {
                User customer = order.getCustomer();
                Point customerPoint = customer.getPoint();
                if (customerPoint != null) {
                    customerPoint.setPoint(customerPoint.getPoint() + order.getRedeemPoint());
                    userRepository.save(customer);
                }
            }
        } else if (newStatus == STATUS_ERROR && oldStatus != STATUS_ERROR) {
            // Không hoàn kho vì hàng lỗi.
            // Do not automatically set PAYMENT_REFUNDED - manager must trigger manually via refund button
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
        Order savedOrder = orderRepository.save(order);
        
        // Notify Customer about status change
        if (savedOrder.getCustomer() != null) {
            eventPublisher.publishEvent(Notification.builder()
                    .title("Order Status Updated")
                    .message("Your order #" + savedOrder.getId() + " status has changed to: " + getStatusName(newStatus))
                    .type(NotificationType.ORDER_STATUS_UPDATE)
                    .targetUserId(savedOrder.getCustomer().getId())
                    .companyId(companyId)
                    .build());
        }

        // If updated by a Customer (receive/cancel), notify MANAGER and EMPLOYEE
        if (isCustomer) {
            String title = newStatus == STATUS_COMPLETED ? "Order Completed by Customer" : "Order Cancelled by Customer";
            String msg = "Order #" + savedOrder.getId() + " has been " + (newStatus == STATUS_COMPLETED ? "completed" : "cancelled") + " by " + (savedOrder.getCustomer() != null ? savedOrder.getCustomer().getUserFullName() : "Customer");
            
            // Notify MANAGER
            eventPublisher.publishEvent(Notification.builder()
                    .title(title)
                    .message(msg)
                    .type(NotificationType.ORDER_STATUS_UPDATE)
                    .targetRole("MANAGER")
                    .companyId(companyId)
                    .build());
                    
            // Notify EMPLOYEE
            eventPublisher.publishEvent(Notification.builder()
                    .title(title)
                    .message(msg)
                    .type(NotificationType.ORDER_STATUS_UPDATE)
                    .targetRole("EMPLOYEE")
                    .companyId(companyId)
                    .build());
        }

        return OrderResponse.fromEntity(savedOrder);
    }

    private String getStatusName(int status) {
        return switch (status) {
            case STATUS_PENDING -> "Pending";
            case STATUS_CONFIRMED -> "Confirmed";
            case STATUS_SHIPPING -> "Shipping";
            case STATUS_DELIVERED -> "Delivered";
            case STATUS_COMPLETED -> "Completed";
            case STATUS_CANCELLED -> "Cancelled";
            case STATUS_ERROR -> "Error";
            default -> "Unknown";
        };
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

        int currentPaymentStatus = order.getPaymentStatus();
        int newPaymentStatus = dto.getPaymentStatus();

        // 1. If order is cancelled and current payment is unpaid: lock unpaid status.
        if (order.getStatus() == STATUS_CANCELLED && currentPaymentStatus == PAYMENT_UNPAID) {
            throw new AppException(ErrorCode.ORDER_LOCKED);
        }

        // 2. If already refunded: fully locked.
        if (currentPaymentStatus == PAYMENT_REFUNDED) {
            throw new AppException(ErrorCode.ORDER_LOCKED);
        }

        // 3. If already paid: can only transition to refunded if order is cancelled or error.
        if (currentPaymentStatus == PAYMENT_PAID) {
            if (newPaymentStatus == PAYMENT_REFUNDED && (order.getStatus() == STATUS_CANCELLED || order.getStatus() == STATUS_ERROR)) {
                // Allowed transition
            } else {
                throw new AppException(ErrorCode.ORDER_LOCKED);
            }
        }

        order.setPaymentStatus(newPaymentStatus);
        Order savedOrder = orderRepository.save(order);

        // Notify Customer about payment status change
        if (savedOrder.getCustomer() != null) {
            eventPublisher.publishEvent(Notification.builder()
                    .title("Payment Status Updated")
                    .message("The payment for your order #" + savedOrder.getId() + " is now: " + getPaymentStatusName(dto.getPaymentStatus()))
                    .type(NotificationType.PAYMENT_STATUS_UPDATE)
                    .targetUserId(savedOrder.getCustomer().getId())
                    .companyId(companyId)
                    .build());
        }

        return OrderResponse.fromEntity(savedOrder);
    }

    private String getPaymentStatusName(int status) {
        return switch (status) {
            case PAYMENT_UNPAID -> "Unpaid";
            case PAYMENT_PAID -> "Paid";
            case PAYMENT_FAILED -> "Failed";
            case PAYMENT_REFUNDED -> "Refunded";
            default -> "Unknown";
        };
    }

    @Override
    public Map<String, Object> getFinancialReport(int storeId, LocalDateTime start, LocalDateTime end) {
        Integer targetStoreId = null;
        if (storeId == -2) {
            // -2 represents the entire company!
        } else if (storeId == -1 || storeId == 0) {
            int currentStoreId = SecurityUtils.getCurrentStoreId();
            if (currentStoreId > 0) {
                targetStoreId = currentStoreId;
                storeRepository.findById(targetStoreId)
                        .orElseThrow(() -> new AppException(ErrorCode.STORE_NOT_FOUND));
            }
        } else {
            targetStoreId = storeId;
            storeRepository.findById(targetStoreId)
                    .orElseThrow(() -> new AppException(ErrorCode.STORE_NOT_FOUND));
        }

        int companyId = SecurityUtils.getCurrentCompanyId();
        if (start == null) {
            start = LocalDate.now().atStartOfDay();
        }
        if (end == null) {
            end = LocalDate.now().plusDays(1).atStartOfDay();
        }
        Double revenue = orderRepository.calculateRevenue(companyId, targetStoreId, start, end);
        Double profit = orderRepository.calculateProfit(companyId, targetStoreId, start, end);

        Page<Order> detailedOrders = orderRepository.searchOrders(
                companyId,
                null,
                targetStoreId,
                4, // 4 = COMPLETED
                null,
                PageRequest.of(0, 1000)
        );
        LocalDateTime finalEnd = end;
        LocalDateTime finalStart = start;
        List<OrderResponse> orderList = detailedOrders.getContent().stream()
                .filter(o -> o.getCreatedAt().isAfter(finalStart) && o.getCreatedAt().isBefore(finalEnd))
                .map(OrderResponse::fromEntity)
                .collect(Collectors.toList());

        Map<String, Object> report = new HashMap<>();
        report.put("revenue", revenue != null ? revenue : 0.0);
        report.put("profit", profit != null ? profit : 0.0);
        report.put("startDate", start);
        report.put("endDate", end);
        report.put("companyId", companyId);
        report.put("storeId", storeId);
        report.put("orders", orderList);

        return report;
    }

}