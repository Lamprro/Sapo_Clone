package com.example.Sapo_Clone.DTO.Response.Cart;

import lombok.Builder;
import lombok.Data;
import java.util.List;

@Data
@Builder
public class CartResponse {
    private Integer cartId;
    private List<CartItemResponse> items;
    private Double totalAmount;
}
