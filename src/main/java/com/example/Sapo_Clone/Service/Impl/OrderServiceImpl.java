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
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.Executor;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

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

    private final OrderV2Repository orderV2Repository;
    private final OrderDetailV2Repository orderDetailV2Repository;
    private final PaymentMethodRepository paymentMethodRepository;
    private final NotificationRepository notificationRepository;
    private final PurchaseOrderRepository purchaseOrderRepository;
    private final PurchaseOrderDetailRepository purchaseOrderDetailRepository;
    private final Executor reportExportExecutor;

    @org.springframework.beans.factory.annotation.Value("${app.allowed-company-ids:}")
    private String allowedCompanyIdsProp;

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
            // Tạm thời comment lại đoạn code gọi đến GORI/Goong API và tìm store gần nhất
            /*
            customerLoc = mapService.getCoordinatesFromAddress(dto.getShippingAddress());
            if (customerLoc == null)
                throw new AppException(ErrorCode.ADDRESS_NOT_FOUND);
            */

            for (OrderDetailCreateDTO item : dto.getOrderDetails()) {
                if (item.getStoreId() != null) {
                    storeOrderMap.computeIfAbsent(item.getStoreId(), k -> new ArrayList<>()).add(item);
                } else {
                    /*
                    Integer nearestStoreId = storeRepository.findNearestStoreIdWithStock(
                            item.getProductId(), item.getQuantity(), customerLoc.getLat(), customerLoc.getLng(),
                            companyId).orElseThrow(() -> new AppException(ErrorCode.OUT_OF_STOCK, "None of stores have enough stock for: " + (productRepository.findById(item.getProductId())).orElseThrow(() -> new AppException(ErrorCode.PRODUCT_NOT_FOUND)).getProductName()));
                    */
                    // Quét xem cửa hàng đầu tiên nào còn hàng thì chọn cửa hàng đó
                    List<Store> stores = storeRepository.findByCompanyId(companyId);
                    Integer firstAvailableStoreId = null;
                    for (Store s : stores) {
                        if (inventoryService.checkStock(item.getProductId(), s.getId(), item.getQuantity())) {
                            firstAvailableStoreId = s.getId();
                            break;
                        }
                    }
                    if (firstAvailableStoreId == null) {
                        Product product = productRepository.findById(item.getProductId())
                                .orElseThrow(() -> new AppException(ErrorCode.PRODUCT_NOT_FOUND));
                        throw new AppException(ErrorCode.OUT_OF_STOCK, "None of stores have enough stock for: " + product.getProductName());
                    }
                    storeOrderMap.computeIfAbsent(firstAvailableStoreId, k -> new ArrayList<>()).add(item);
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

            // Resolve PaymentMethod
            String pmStr = dto.getPaymentMethod();
            PaymentMethod pm = null;
            if (pmStr != null) {
                if (pmStr.equals("0") || pmStr.equalsIgnoreCase("Money")) {
                    pm = paymentMethodRepository.findById(0).orElse(null);
                } else if (pmStr.equals("1") || pmStr.equalsIgnoreCase("Banking")) {
                    pm = paymentMethodRepository.findById(1).orElse(null);
                } else {
                    try {
                        int pmId = Integer.parseInt(pmStr);
                        pm = paymentMethodRepository.findById(pmId).orElse(null);
                    } catch (NumberFormatException e) {
                        pm = paymentMethodRepository.findByName(pmStr).orElse(null);
                    }
                }
            }
            if (pm == null) {
                pm = paymentMethodRepository.findById(0).orElse(null);
            }
            order.setPaymentMethod(pm);

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
                    .orderId(savedOrder.getId())
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
        order.setPaymentMethod(paymentMethodRepository.findById(0).orElse(null)); // Không cần thanh toán
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

        if (order.getStatus() != STATUS_PENDING && order.getStatus() != STATUS_COMPLETED) {
            throw new AppException(ErrorCode.ORDER_LOCKED);
        }

        // Nếu đơn hàng đã hoàn thành, hoàn trả tạm thời điểm tích lũy cũ
        User customer = order.getCustomer();
        Point customerPoint = customer != null ? customer.getPoint() : null;
        if (order.getStatus() == STATUS_COMPLETED && customerPoint != null) {
            customerPoint.setPoint(Math.max(0, customerPoint.getPoint() - order.getEarnPoint()));
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
            } else {
                // Hủy khuyến mại nếu không đủ điều kiện tối thiểu
                order.setPromotion(null);
            }
        }

        order.setTotalAmount(Math.max(0, totalAmount - order.getRedeemPoint()));
        order.setEarnPoint((int) (order.getTotalAmount() / 100000));

        // Cộng điểm tích lũy mới nếu đơn hàng đã hoàn thành
        if (order.getStatus() == STATUS_COMPLETED && customerPoint != null) {
            customerPoint.setPoint(customerPoint.getPoint() + order.getEarnPoint());
            userRepository.save(customer);
        }

        // Resolve PaymentMethod
        String pmStr = dto.getPaymentMethod();
        PaymentMethod pm = null;
        if (pmStr != null) {
            if (pmStr.equals("0") || pmStr.equalsIgnoreCase("Money")) {
                pm = paymentMethodRepository.findById(0).orElse(null);
            } else if (pmStr.equals("1") || pmStr.equalsIgnoreCase("Banking")) {
                pm = paymentMethodRepository.findById(1).orElse(null);
            } else {
                try {
                    int pmId = Integer.parseInt(pmStr);
                    pm = paymentMethodRepository.findById(pmId).orElse(null);
                } catch (NumberFormatException e) {
                    pm = paymentMethodRepository.findByName(pmStr).orElse(null);
                }
            }
        }
        if (pm != null) {
            order.setPaymentMethod(pm);
        }

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
    public Page<OrderListResponse> getList(int status, String keyword, LocalDateTime startDate, LocalDateTime endDate, int page, int size) {
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
        return orderRepository.searchOrders(companyId, customerId, storeId, status, keyword, startDate, endDate, pageable)
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
                    .orderId(savedOrder.getId())
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
                    .orderId(savedOrder.getId())
                    .build());
                    
            // Notify EMPLOYEE
            eventPublisher.publishEvent(Notification.builder()
                    .title(title)
                    .message(msg)
                    .type(NotificationType.ORDER_STATUS_UPDATE)
                    .targetRole("EMPLOYEE")
                    .companyId(companyId)
                    .orderId(savedOrder.getId())
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
                start,
                end,
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

    // --- NEW FEATURES IMPLEMENTATION ---

    private void checkCompanyAccess() {
        int currentCompanyId = SecurityUtils.getCurrentCompanyId();
        if (allowedCompanyIdsProp == null || allowedCompanyIdsProp.trim().isEmpty()) {
            throw new AppException(ErrorCode.FORBIDDEN, "This feature is not enabled for your company.");
        }
        boolean isAllowed = Arrays.stream(allowedCompanyIdsProp.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .map(Integer::parseInt)
                .anyMatch(id -> id == currentCompanyId);
        if (!isAllowed) {
            throw new AppException(ErrorCode.FORBIDDEN, "This feature is not enabled for your company.");
        }
    }

    @Override
    @Transactional
    public OrderResponse convertToV2(int orderId) {
        checkCompanyAccess();
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new AppException(ErrorCode.ORDER_NOT_FOUND));

        int companyId = SecurityUtils.getCurrentCompanyId();
        if (order.getStore().getCompany().getId() != companyId) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        // 1. Create OrderV2
        OrderV2 orderV2 = new OrderV2();
        orderV2.setTotalAmount(order.getTotalAmount());
        orderV2.setEarnPoint(order.getEarnPoint());
        orderV2.setRedeemPoint(order.getRedeemPoint());
        orderV2.setStatus(order.getStatus());
        orderV2.setPaymentStatus(order.getPaymentStatus());
        orderV2.setPaymentMethod(order.getPaymentMethod());
        orderV2.setShippingAddress(order.getShippingAddress());
        orderV2.setNote(order.getNote());
        orderV2.setCreatedAt(order.getCreatedAt());
        orderV2.setUpdatedAt(order.getUpdatedAt());
        orderV2.setCustomer(order.getCustomer());
        orderV2.setEmployee(order.getEmployee());
        orderV2.setStore(order.getStore());
        orderV2.setPromotion(order.getPromotion());

        List<OrderDetailV2> detailsV2 = new ArrayList<>();
        for (OrderDetail od : order.getOrderDetails()) {
            OrderDetailV2 odV2 = new OrderDetailV2();
            odV2.setOrder(orderV2);
            odV2.setProduct(od.getProduct());
            odV2.setQuantity(od.getQuantity());
            odV2.setPrice(od.getPrice());
            odV2.setSubtotal(od.getSubtotal());
            odV2.setImportPrice(od.getImportPrice());
            detailsV2.add(odV2);
        }
        orderV2.setOrderDetails(detailsV2);

        // 2. Save OrderV2
        OrderV2 savedV2 = orderV2Repository.save(orderV2);

        // 3. Stock adjustments (PurchaseOrderDetail match)
        for (OrderDetail od : order.getOrderDetails()) {
            int neededQty = od.getQuantity();
            List<PurchaseOrderDetail> completedPODs = purchaseOrderDetailRepository
                    .findCompletedDetails(order.getStore().getId(), od.getProduct().getId());

            for (PurchaseOrderDetail pod : completedPODs) {
                if (neededQty <= 0) break;

                int podQty = pod.getQuantity();
                if (podQty > neededQty) {
                    pod.setQuantity(podQty - neededQty);
                    pod.setSubtotal(pod.getQuantity() * pod.getPrice());
                    neededQty = 0;
                } else {
                    neededQty -= podQty;
                    pod.setQuantity(0);
                    pod.setSubtotal(0.0);
                }
                purchaseOrderDetailRepository.save(pod);

                PurchaseOrder po = pod.getPurchaseOrder();
                if (po != null) {
                    double newTotal = po.getPurchaseOrderDetails().stream()
                            .mapToDouble(PurchaseOrderDetail::getSubtotal)
                            .sum();
                    po.setTotalAmount(newTotal);
                    purchaseOrderRepository.save(po);
                }
            }
        }

        // 4. Delete notifications related to this order
        notificationRepository.deleteByOrderId(orderId);

        // 5. Delete original Order
        orderRepository.delete(order);

        return mapV2ToResponse(savedV2);
    }

    @Override
    @Transactional
    public OrderResponse convertToV1(int orderV2Id) {
        checkCompanyAccess();
        OrderV2 orderV2 = orderV2Repository.findById(orderV2Id)
                .orElseThrow(() -> new AppException(ErrorCode.ORDER_NOT_FOUND));

        int companyId = SecurityUtils.getCurrentCompanyId();
        if (orderV2.getStore().getCompany().getId() != companyId) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        // 1. Create Order
        Order order = new Order();
        order.setTotalAmount(orderV2.getTotalAmount());
        order.setEarnPoint(orderV2.getEarnPoint());
        order.setRedeemPoint(orderV2.getRedeemPoint());
        order.setStatus(orderV2.getStatus());
        order.setPaymentStatus(orderV2.getPaymentStatus());
        order.setPaymentMethod(orderV2.getPaymentMethod());
        order.setShippingAddress(orderV2.getShippingAddress());
        order.setNote(orderV2.getNote());
        order.setCreatedAt(orderV2.getCreatedAt());
        order.setUpdatedAt(orderV2.getUpdatedAt());
        order.setCustomer(orderV2.getCustomer());
        order.setEmployee(orderV2.getEmployee());
        order.setStore(orderV2.getStore());
        order.setPromotion(orderV2.getPromotion());

        List<OrderDetail> details = new ArrayList<>();
        for (OrderDetailV2 odV2 : orderV2.getOrderDetails()) {
            OrderDetail od = new OrderDetail();
            od.setOrder(order);
            od.setProduct(odV2.getProduct());
            od.setQuantity(odV2.getQuantity());
            od.setPrice(odV2.getPrice());
            od.setSubtotal(odV2.getSubtotal());
            od.setImportPrice(odV2.getImportPrice());
            details.add(od);
        }
        order.setOrderDetails(details);

        // 2. Save Order
        Order savedOrder = orderRepository.save(order);

        // 3. Stock adjustments (PurchaseOrderDetail restore)
        for (OrderDetailV2 odV2 : orderV2.getOrderDetails()) {
            List<PurchaseOrderDetail> completedPODs = purchaseOrderDetailRepository
                    .findCompletedDetails(orderV2.getStore().getId(), odV2.getProduct().getId());
            if (!completedPODs.isEmpty()) {
                PurchaseOrderDetail latestPOD = completedPODs.get(0);
                latestPOD.setQuantity(latestPOD.getQuantity() + odV2.getQuantity());
                latestPOD.setSubtotal(latestPOD.getQuantity() * latestPOD.getPrice());
                purchaseOrderDetailRepository.save(latestPOD);

                PurchaseOrder po = latestPOD.getPurchaseOrder();
                if (po != null) {
                    double newTotal = po.getPurchaseOrderDetails().stream()
                            .mapToDouble(PurchaseOrderDetail::getSubtotal)
                            .sum();
                    po.setTotalAmount(newTotal);
                    purchaseOrderRepository.save(po);
                }
            }
        }

        // 4. Delete OrderV2
        orderV2Repository.delete(orderV2);

        return OrderResponse.fromEntity(savedOrder);
    }

    @Override
    @Transactional
    public void hardDeleteOrder(int orderId) {
        checkCompanyAccess();
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new AppException(ErrorCode.ORDER_NOT_FOUND));

        int companyId = SecurityUtils.getCurrentCompanyId();
        if (order.getStore().getCompany().getId() != companyId) {
            throw new AppException(ErrorCode.FORBIDDEN);
        }

        // 1. Revert inventory stock
        for (OrderDetail detail : order.getOrderDetails()) {
            inventoryService.increaseStock(detail.getProduct().getId(), order.getStore().getId(),
                    detail.getQuantity());
        }

        // 2. Delete notifications related to this order
        notificationRepository.deleteByOrderId(orderId);

        // 3. Clear details and delete order
        order.getOrderDetails().clear();
        orderDetailRepository.deleteAllByOrderId(orderId);
        orderRepository.delete(order);
    }

    @Override
    public Map<String, Object> getCombinedFinancialReport(int storeId, LocalDateTime start, LocalDateTime end) {
        checkCompanyAccess();
        Integer targetStoreId = null;
        if (storeId == -2) {
            // Entire company
        } else if (storeId == -1 || storeId == 0) {
            int currentStoreId = SecurityUtils.getCurrentStoreId();
            if (currentStoreId > 0) {
                targetStoreId = currentStoreId;
            }
        } else {
            targetStoreId = storeId;
        }

        int companyId = SecurityUtils.getCurrentCompanyId();
        if (start == null) {
            start = LocalDate.now().atStartOfDay();
        }
        if (end == null) {
            end = LocalDate.now().plusDays(1).atStartOfDay();
        }

        // Calculate Revenue from both
        Double rev1 = orderRepository.calculateRevenue(companyId, targetStoreId, start, end);
        Double rev2 = orderV2Repository.calculateRevenue(companyId, targetStoreId, start, end);
        double totalRevenue = (rev1 != null ? rev1 : 0.0) + (rev2 != null ? rev2 : 0.0);

        // Calculate Profit from both
        Double prof1 = orderRepository.calculateProfit(companyId, targetStoreId, start, end);
        Double prof2 = orderV2Repository.calculateProfit(companyId, targetStoreId, start, end);
        double totalProfit = (prof1 != null ? prof1 : 0.0) + (prof2 != null ? prof2 : 0.0);

        // Fetch detailed completed orders from Order
        Page<Order> detailedOrders1 = orderRepository.searchOrders(
                companyId, null, targetStoreId, 4, null, start, end, PageRequest.of(0, 5000)
        );
        LocalDateTime finalEnd = end;
        LocalDateTime finalStart = start;
        List<OrderResponse> list1 = detailedOrders1.getContent().stream()
                .filter(o -> o.getCreatedAt().isAfter(finalStart) && o.getCreatedAt().isBefore(finalEnd))
                .map(OrderResponse::fromEntity)
                .collect(Collectors.toList());

        // Fetch detailed completed orders from OrderV2
        Page<OrderV2> detailedOrders2 = orderV2Repository.searchOrders(
                companyId, null, targetStoreId, 4, null, PageRequest.of(0, 5000)
        );
        List<OrderResponse> list2 = detailedOrders2.getContent().stream()
                .filter(o -> o.getCreatedAt().isAfter(finalStart) && o.getCreatedAt().isBefore(finalEnd))
                .map(this::mapV2ToResponse)
                .collect(Collectors.toList());

        // Combine and sort
        List<OrderResponse> combinedList = new ArrayList<>();
        combinedList.addAll(list1);
        combinedList.addAll(list2);
        combinedList.sort((o1, o2) -> o2.getCreatedAt().compareTo(o1.getCreatedAt()));

        Map<String, Object> report = new HashMap<>();
        report.put("revenue", totalRevenue);
        report.put("profit", totalProfit);
        report.put("startDate", start);
        report.put("endDate", end);
        report.put("companyId", companyId);
        report.put("storeId", storeId);
        report.put("orders", combinedList);

        return report;
    }

    @Override
    public Map<String, Object> getMonthlyStats(int year, int month, Integer storeId) {
        checkCompanyAccess();
        int companyId = SecurityUtils.getCurrentCompanyId();

        LocalDateTime start = LocalDateTime.of(year, month, 1, 0, 0);
        LocalDateTime end = start.plusMonths(1);

        // 1. Calculate Monthly Total (only from Order table)
        Double monthlyTotal = orderRepository.calculateRevenue(companyId, storeId, start, end);

        // 2. Daily totals map
        Map<Integer, Double> dailyTotals = new HashMap<>();
        int daysInMonth = start.toLocalDate().lengthOfMonth();
        for (int d = 1; d <= daysInMonth; d++) {
            dailyTotals.put(d, 0.0);
        }

        // Fetch completed orders of that month
        Page<Order> ordersPage = orderRepository.searchOrders(
                companyId, null, storeId, 4, null, start, end, PageRequest.of(0, 10000)
        );
        List<Order> monthlyOrders = ordersPage.getContent().stream()
                .filter(o -> o.getCreatedAt().isAfter(start) && o.getCreatedAt().isBefore(end))
                .collect(Collectors.toList());

        for (Order o : monthlyOrders) {
            int day = o.getCreatedAt().getDayOfMonth();
            dailyTotals.put(day, dailyTotals.getOrDefault(day, 0.0) + o.getTotalAmount());
        }

        Map<String, Object> stats = new HashMap<>();
        stats.put("year", year);
        stats.put("month", month);
        stats.put("storeId", storeId);
        stats.put("monthlyTotal", monthlyTotal != null ? monthlyTotal : 0.0);
        stats.put("dailyTotals", dailyTotals);

        return stats;
    }

    @Override
    public List<OrderResponse> getDailyOrders(LocalDate date, Integer storeId) {
        checkCompanyAccess();
        int companyId = SecurityUtils.getCurrentCompanyId();
        LocalDateTime start = date.atStartOfDay();
        LocalDateTime end = start.plusDays(1);

        Page<Order> ordersPage = orderRepository.searchOrders(
                companyId, null, storeId, null, null, start, end, PageRequest.of(0, 5000)
        );
        return ordersPage.getContent().stream()
                .filter(o -> o.getCreatedAt().isAfter(start) && o.getCreatedAt().isBefore(end))
                .map(OrderResponse::fromEntity)
                .collect(Collectors.toList());
    }

    @Override
    public String startExcelExport(int year, int month) {
        checkCompanyAccess();
        String filename = "report_" + year + "_" + String.format("%02d", month) + "_" + System.currentTimeMillis() + ".xlsx";

        CompletableFuture.runAsync(() -> {
            try {
                generateExcelReport(year, month, filename);
            } catch (Exception e) {
                log.error("Error generating Excel report asynchronously: ", e);
            }
        }, reportExportExecutor);

        return filename;
    }

    private void generateExcelReport(int year, int month, String filename) throws Exception {
        int companyId = SecurityUtils.getCurrentCompanyId();
        LocalDateTime start = LocalDateTime.of(year, month, 1, 0, 0);
        LocalDateTime end = start.plusMonths(1);

        Page<Order> ordersPage = orderRepository.searchOrders(
                companyId, null, null, 4, null, start, end, PageRequest.of(0, 10000)
        );
        List<Order> monthlyOrders = ordersPage.getContent().stream()
                .filter(o -> o.getCreatedAt().isAfter(start) && o.getCreatedAt().isBefore(end))
                .collect(Collectors.toList());

        double totalCash = 0.0;
        double totalBanking = 0.0;

        int daysInMonth = start.toLocalDate().lengthOfMonth();
        double[] dailyCash = new double[daysInMonth + 1];
        double[] dailyBanking = new double[daysInMonth + 1];

        for (Order o : monthlyOrders) {
            int day = o.getCreatedAt().getDayOfMonth();
            int pmId = o.getPaymentMethod() != null ? o.getPaymentMethod().getId() : 0;
            if (pmId == 0) {
                totalCash += o.getTotalAmount();
                dailyCash[day] += o.getTotalAmount();
            } else if (pmId == 1) {
                totalBanking += o.getTotalAmount();
                dailyBanking[day] += o.getTotalAmount();
            }
        }

        try (Workbook workbook = new XSSFWorkbook()) {
            Sheet summarySheet = workbook.createSheet("Monthly Summary");

            Row titleRow = summarySheet.createRow(0);
            Cell titleCell = titleRow.createCell(0);
            titleCell.setCellValue("REVENUE SUMMARY - MONTH " + month + "/" + year);

            Row cashRow = summarySheet.createRow(2);
            cashRow.createCell(0).setCellValue("Total Cash (Money)");
            cashRow.createCell(1).setCellValue(totalCash);

            Row bankRow = summarySheet.createRow(3);
            bankRow.createCell(0).setCellValue("Total Banking (Transfer)");
            bankRow.createCell(1).setCellValue(totalBanking);

            Row totalRow = summarySheet.createRow(4);
            totalRow.createCell(0).setCellValue("Total Revenue");
            totalRow.createCell(1).setCellValue(totalCash + totalBanking);

            Row dailyHeader = summarySheet.createRow(6);
            dailyHeader.createCell(0).setCellValue("Day");
            dailyHeader.createCell(1).setCellValue("Cash Sales");
            dailyHeader.createCell(2).setCellValue("Banking Sales");
            dailyHeader.createCell(3).setCellValue("Daily Total");

            int rowIdx = 7;
            for (int d = 1; d <= daysInMonth; d++) {
                Row r = summarySheet.createRow(rowIdx++);
                r.createCell(0).setCellValue("Day " + d);
                r.createCell(1).setCellValue(dailyCash[d]);
                r.createCell(2).setCellValue(dailyBanking[d]);
                r.createCell(3).setCellValue(dailyCash[d] + dailyBanking[d]);
            }

            Sheet detailsSheet = workbook.createSheet("Order Details");
            Row detailsHeader = detailsSheet.createRow(0);
            detailsHeader.createCell(0).setCellValue("Order ID");
            detailsHeader.createCell(1).setCellValue("Customer");
            detailsHeader.createCell(2).setCellValue("Employee");
            detailsHeader.createCell(3).setCellValue("Store");
            detailsHeader.createCell(4).setCellValue("Created At");
            detailsHeader.createCell(5).setCellValue("Payment Method");
            detailsHeader.createCell(6).setCellValue("Status");
            detailsHeader.createCell(7).setCellValue("Total Amount");

            int detailRowIdx = 1;
            for (Order o : monthlyOrders) {
                Row r = detailsSheet.createRow(detailRowIdx++);
                r.createCell(0).setCellValue(o.getId());
                r.createCell(1).setCellValue(o.getCustomer() != null ? o.getCustomer().getUserFullName() : "N/A");
                r.createCell(2).setCellValue(o.getEmployee() != null ? o.getEmployee().getUserFullName() : "N/A");
                r.createCell(3).setCellValue(o.getStore() != null ? o.getStore().getStoreName() : "N/A");
                r.createCell(4).setCellValue(o.getCreatedAt().toString());
                r.createCell(5).setCellValue(o.getPaymentMethod() != null ? o.getPaymentMethod().getName() : "Money");
                r.createCell(6).setCellValue(o.getStatus());
                r.createCell(7).setCellValue(o.getTotalAmount());
            }

            java.io.File dir = new java.io.File("exports");
            if (!dir.exists()) {
                dir.mkdirs();
            }
            java.io.File file = new java.io.File(dir, filename);
            try (java.io.FileOutputStream fos = new java.io.FileOutputStream(file)) {
                workbook.write(fos);
            }
        }
    }

    private OrderResponse mapV2ToResponse(OrderV2 o) {
        if (o == null) return null;
        List<com.example.Sapo_Clone.DTO.Response.Order.OrderItemResponse> items = new ArrayList<>();
        if (o.getOrderDetails() != null) {
            for (OrderDetailV2 od : o.getOrderDetails()) {
                items.add(com.example.Sapo_Clone.DTO.Response.Order.OrderItemResponse.builder()
                        .productId(od.getProduct().getId())
                        .productName(od.getProduct().getProductName())
                        .quantity(od.getQuantity())
                        .price(od.getPrice())
                        .subtotal(od.getSubtotal())
                        .build());
            }
        }

        return OrderResponse.builder()
                .id(o.getId())
                .customerId(o.getCustomer() != null ? o.getCustomer().getId() : null)
                .customerName(o.getCustomer() != null ? o.getCustomer().getUserFullName() : null)
                .employeeId(o.getEmployee() != null ? o.getEmployee().getId() : null)
                .employeeName(o.getEmployee() != null ? o.getEmployee().getUserFullName() : null)
                .storeId(o.getStore() != null ? o.getStore().getId() : null)
                .storeName(o.getStore() != null ? o.getStore().getStoreName() : null)
                .status(o.getStatus())
                .totalAmount(o.getTotalAmount())
                .paymentMethod(o.getPaymentMethod() != null ? String.valueOf(o.getPaymentMethod().getId()) : null)
                .paymentStatus(o.getPaymentStatus())
                .createdAt(o.getCreatedAt())
                .shippingAddress(o.getShippingAddress())
                .note(o.getNote())
                .promotionId(o.getPromotion() != null ? o.getPromotion().getId() : null)
                .promotionName(o.getPromotion() != null ? o.getPromotion().getPromotionName() : null)
                .items(items)
                .build();
    }
}