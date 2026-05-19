package com.example.Sapo_Clone.Service;

import com.example.Sapo_Clone.DTO.Request.Cart.AddToCartDTO;
import com.example.Sapo_Clone.DTO.Request.Cart.UpdateCartItemDTO;
import com.example.Sapo_Clone.DTO.Response.Cart.CartResponse;

public interface CartService {
    CartResponse addItem(AddToCartDTO dto);
    CartResponse updateQuantity(int productId, UpdateCartItemDTO dto);
    CartResponse removeItem(int productId);
    CartResponse getCart();
    void clearCart(Integer userId); // Keeping Integer userId for internal clear (e.g. from OrderService), but will overload or handle internally
}
