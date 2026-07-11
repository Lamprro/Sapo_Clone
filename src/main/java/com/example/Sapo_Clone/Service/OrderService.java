package com.example.Sapo_Clone.Service;

import com.example.Sapo_Clone.DTO.Request.Order.DisposeOrderCreateDTO;
import com.example.Sapo_Clone.DTO.Request.Order.OrderCreateDTO;
import com.example.Sapo_Clone.DTO.Request.Order.OrderPaymentDTO;
import com.example.Sapo_Clone.DTO.Request.Order.OrderStatusDTO;
import com.example.Sapo_Clone.DTO.Request.Order.OrderUpdateDTO;
import com.example.Sapo_Clone.DTO.Response.Order.OrderListResponse;
import com.example.Sapo_Clone.DTO.Response.Order.OrderResponse;
import org.springframework.data.domain.Page;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public interface OrderService {
    List<OrderResponse> createOrder(OrderCreateDTO dto);
    OrderResponse createDisposeOrder(DisposeOrderCreateDTO dto);
    OrderResponse updateOrder(int orderId, OrderUpdateDTO dto);
    OrderResponse getOrder(int id);
    Page<OrderListResponse> getList(int status, String keyword, LocalDateTime startDate, LocalDateTime endDate, int page, int size);
    OrderResponse changeStatus(int id, OrderStatusDTO dto);
    OrderResponse changePaymentStatus(int id, OrderPaymentDTO dto);
    
    // Reporting
    Map<String, Object> getFinancialReport(int storeId, LocalDateTime start, LocalDateTime end);

    // New features
    OrderResponse convertToV2(int orderId);
    OrderResponse convertToV1(int orderV2Id);
    void hardDeleteOrder(int orderId);
    Map<String, Object> getCombinedFinancialReport(int storeId, LocalDateTime start, LocalDateTime end);
    Map<String, Object> getMonthlyStats(int year, int month, Integer storeId);
    List<OrderResponse> getDailyOrders(java.time.LocalDate date, Integer storeId);
    String startExcelExport(int year, int month);
}