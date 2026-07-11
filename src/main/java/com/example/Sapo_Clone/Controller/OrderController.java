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
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import java.nio.file.Path;
import java.nio.file.Paths;

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
            @RequestParam(required = false) @org.springframework.format.annotation.DateTimeFormat(iso = org.springframework.format.annotation.DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @RequestParam(required = false) @org.springframework.format.annotation.DateTimeFormat(iso = org.springframework.format.annotation.DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        log.info("API GET /api/order - search/list");
        Page<OrderListResponse> response = orderService.getList(status, keyword, startDate, endDate, page, size);
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

    // 8. CONVERT ORDER TO V2
    @PostMapping("/{id}/convert-to-v2")
    public ResponseEntity<ApiResponse<OrderResponse>> convertToV2(@PathVariable int id) {
        log.info("API POST /api/order/{}/convert-to-v2", id);
        OrderResponse response = orderService.convertToV2(id);
        return ResponseEntity.ok(ApiResponse.success("Order converted to V2 successfully", response));
    }

    // 9. CONVERT ORDER V2 TO V1
    @PostMapping("/v2/{id}/convert-to-v1")
    public ResponseEntity<ApiResponse<OrderResponse>> convertToV1(@PathVariable int id) {
        log.info("API POST /api/order/v2/{}/convert-to-v1", id);
        OrderResponse response = orderService.convertToV1(id);
        return ResponseEntity.ok(ApiResponse.success("Order converted to V1 successfully", response));
    }

    // 10. HARD DELETE ORDER
    @DeleteMapping("/{id}/hard-delete")
    public ResponseEntity<ApiResponse<Void>> hardDeleteOrder(@PathVariable int id) {
        log.info("API DELETE /api/order/{}/hard-delete", id);
        orderService.hardDeleteOrder(id);
        return ResponseEntity.ok(ApiResponse.success("Order hard deleted successfully", null));
    }

    // 11. COMBINED FINANCIAL REPORT
    @GetMapping("/report/combined")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getCombinedFinancialReport(
            @RequestParam(required = false, defaultValue = "-1") int storeId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime start,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime end) {
        log.info("API GET /api/order/report/combined");
        Map<String, Object> report = orderService.getCombinedFinancialReport(storeId, start, end);
        return ResponseEntity.ok(ApiResponse.success("Success", report));
    }

    // 12. MONTHLY STATISTICS
    @GetMapping("/stats/monthly")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getMonthlyStats(
            @RequestParam int year,
            @RequestParam int month,
            @RequestParam(required = false) Integer storeId) {
        log.info("API GET /api/order/stats/monthly?year={}&month={}", year, month);
        Map<String, Object> stats = orderService.getMonthlyStats(year, month, storeId);
        return ResponseEntity.ok(ApiResponse.success("Success", stats));
    }

    // 13. DAILY ORDERS LIST
    @GetMapping("/stats/daily-orders")
    public ResponseEntity<ApiResponse<List<OrderResponse>>> getDailyOrders(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam(required = false) Integer storeId) {
        log.info("API GET /api/order/stats/daily-orders?date={}", date);
        List<OrderResponse> orders = orderService.getDailyOrders(date, storeId);
        return ResponseEntity.ok(ApiResponse.success("Success", orders));
    }

    // 14. EXCEL REPORT GENERATION
    @GetMapping("/report/export-excel")
    public ResponseEntity<ApiResponse<String>> exportExcel(
            @RequestParam int year,
            @RequestParam int month) {
        log.info("API GET /api/order/report/export-excel?year={}&month={}", year, month);
        String filename = orderService.startExcelExport(year, month);
        String downloadUrl = "/api/order/report/download/" + filename;
        return ResponseEntity.ok(ApiResponse.success("Excel generation started. Download link: " + downloadUrl, downloadUrl));
    }

    // 15. DOWNLOAD EXCEL REPORT FILE
    @GetMapping("/report/download/{filename:.+}")
    public ResponseEntity<Resource> downloadFile(@PathVariable String filename) {
        try {
            Path file = Paths.get("exports").resolve(filename).normalize();
            Resource resource = new UrlResource(file.toUri());
            if (resource.exists() || resource.isReadable()) {
                return ResponseEntity.ok()
                        .contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                        .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + resource.getFilename() + "\"")
                        .body(resource);
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            log.error("Error downloading file: ", e);
            return ResponseEntity.internalServerError().build();
        }
    }
}