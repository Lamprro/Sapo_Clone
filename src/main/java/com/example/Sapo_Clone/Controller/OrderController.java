package com.example.Sapo_Clone.Controller;

import com.example.Sapo_Clone.Common.ApiResponse;
import com.example.Sapo_Clone.DTO.Request.Order.DisposeOrderCreateDTO;
import com.example.Sapo_Clone.DTO.Request.Order.OrderCreateDTO;
import com.example.Sapo_Clone.DTO.Request.Order.OrderPaymentDTO;
import com.example.Sapo_Clone.DTO.Request.Order.OrderStatusDTO;
import com.example.Sapo_Clone.DTO.Request.Order.OrderUpdateDTO;
import com.example.Sapo_Clone.DTO.Response.Order.OrderListResponse;
import com.example.Sapo_Clone.DTO.Response.Order.OrderResponse;
import com.example.Sapo_Clone.Service.OrderService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/order")
@RequiredArgsConstructor
@Slf4j
public class OrderController {

    private final OrderService orderService;

    // 1. CREATE ORDER (Online Customer) -> PENDING
    @PostMapping
    public ResponseEntity<ApiResponse<List<OrderResponse>>> createOrder(@Valid @RequestBody OrderCreateDTO dto) {
        log.info("API POST /api/order - create order");
        // Ensure status is PENDING (0) for online orders
        dto.setStatus(0); 
        List<OrderResponse> response = orderService.createOrder(dto);
        return ResponseEntity.ok(ApiResponse.success("Order(s) created successfully", response));
    }

    // 1.2 CREATE ORDER AT COUNTER (Employee) -> COMPLETED
    @PostMapping("/in-store")
    public ResponseEntity<ApiResponse<List<OrderResponse>>> createOrderInStore(@Valid @RequestBody OrderCreateDTO dto) {
        log.info("API POST /api/order/in-store - create in-store order");
        // Set status to COMPLETED (4) and payment to PAID (1) for in-store orders
        dto.setStatus(4); 
        // You might also want to force payment method/status here if needed, 
        // e.g., dto.setPaymentMethod("1"); // assuming 1 is cash/card
        List<OrderResponse> response = orderService.createOrder(dto);
        return ResponseEntity.ok(ApiResponse.success("In-store order created successfully", response));
    }

    // 1.1 CREATE DISPOSE ORDER
    @PostMapping("/dispose")
    public ResponseEntity<ApiResponse<OrderResponse>> createDisposeOrder(@Valid @RequestBody DisposeOrderCreateDTO dto) {
        log.info("API POST /api/order/dispose - create dispose order");
        OrderResponse response = orderService.createDisposeOrder(dto);
        return ResponseEntity.ok(ApiResponse.success("Dispose order created successfully", response));
    }

    // 2. UPDATE ORDER (PENDING only)
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<OrderResponse>> updateOrder(
            @PathVariable int id,
            @Valid @RequestBody OrderUpdateDTO dto) {
        log.info("API PUT /api/order/{} - update", id);
        OrderResponse response = orderService.updateOrder(id, dto);
        return ResponseEntity.ok(ApiResponse.success("Order updated successfully", response));
    }

    // 3. GET ORDER BY ID
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<OrderResponse>> getOrder(@PathVariable int id) {
        log.info("API GET /api/order/{} - detail", id);
        OrderResponse response = orderService.getOrder(id);
        return ResponseEntity.ok(ApiResponse.success("Success", response));
    }

    // 4. GET ALL ORDERS paginated
    @GetMapping
    public ResponseEntity<ApiResponse<Page<OrderListResponse>>> getList(
            @RequestParam(required = false, defaultValue = "-1") Integer status,
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        log.info("API GET /api/order - search/list");
        Page<OrderListResponse> response = orderService.getList(status, keyword, page, size);
        return ResponseEntity.ok(ApiResponse.success("Success", response));
    }

    // 5. CHANGE STATUS
    @PatchMapping("/{id}/status")
    public ResponseEntity<ApiResponse<OrderResponse>> changeStatus(
            @PathVariable int id,
            @Valid @RequestBody OrderStatusDTO dto) {
        log.info("API PATCH /api/order/{}/status", id);
        OrderResponse response = orderService.changeStatus(id, dto);
        return ResponseEntity.ok(ApiResponse.success("Order status updated", response));
    }

    // 6. PAYMENT
    @PatchMapping("/{id}/payment")
    public ResponseEntity<ApiResponse<OrderResponse>> changePaymentStatus(
            @PathVariable int id,
            @Valid @RequestBody OrderPaymentDTO dto) {
        log.info("API PATCH /api/order/{}/payment", id);
        OrderResponse response = orderService.changePaymentStatus(id, dto);
        return ResponseEntity.ok(ApiResponse.success("Order payment status updated", response));
    }

    // 7. FINANCIAL REPORT
    @GetMapping("/report")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getFinancialReport(
            @RequestParam(required = false, defaultValue = "-1") int storeId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime start,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime end) {

        log.info("API GET /api/order/report");
        Map<String, Object> report = orderService.getFinancialReport(storeId, start, end);
        return ResponseEntity.ok(ApiResponse.success("Success", report));
    }
}