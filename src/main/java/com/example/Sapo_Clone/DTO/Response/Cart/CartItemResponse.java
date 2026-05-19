package com.example.Sapo_Clone.DTO.Response.Cart;

import com.example.Sapo_Clone.Entity.CartItem;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class CartItemResponse {
    private Integer productId;
    private String productName;
    private Double sellPrice;
    private Integer quantity;
    private Double totalPrice;

    public static CartItemResponse fromEntity(CartItem cartItem) {
        if (cartItem == null) return null;
        
        double price = cartItem.getProduct().getSellPrice();
        return CartItemResponse.builder()
                .productId(cartItem.getProduct().getId())
                .productName(cartItem.getProduct().getProductName())
                .sellPrice(price)
                .quantity(cartItem.getQuantity())
                .totalPrice(price * cartItem.getQuantity())
                .build();
    }
}
