package com.example.Sapo_Clone.Controller;

import com.example.Sapo_Clone.Common.ApiResponse;
import com.example.Sapo_Clone.DTO.Request.Cart.AddToCartDTO;
import com.example.Sapo_Clone.DTO.Request.Cart.UpdateCartItemDTO;
import com.example.Sapo_Clone.DTO.Response.Cart.CartResponse;
import com.example.Sapo_Clone.Service.CartService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/cart")
@RequiredArgsConstructor
@Slf4j
public class CartController {

    private final CartService cartService;

    // 1. ADD ITEM TO CART
    @PostMapping("/items")
    public ResponseEntity<ApiResponse<CartResponse>> addItem(
            @Valid @RequestBody AddToCartDTO dto) {
        log.info("API POST /api/cart/items");
        CartResponse response = cartService.addItem(dto);
        return ResponseEntity.ok(ApiResponse.success("Item added to cart", response));
    }

    // 2. UPDATE QUANTITY
    @PatchMapping("/items/{productId}")
    public ResponseEntity<ApiResponse<CartResponse>> updateQuantity(
            @PathVariable int productId,
            @Valid @RequestBody UpdateCartItemDTO dto) {
        log.info("API PATCH /api/cart/items/{}", productId);
        CartResponse response = cartService.updateQuantity(productId, dto);
        return ResponseEntity.ok(ApiResponse.success("Cart item updated", response));
    }

    // 3. REMOVE ITEM
    @DeleteMapping("/items/{productId}")
    public ResponseEntity<ApiResponse<CartResponse>> removeItem(
            @PathVariable int productId) {
        log.info("API DELETE /api/cart/items/{}", productId);
        CartResponse response = cartService.removeItem(productId);
        return ResponseEntity.ok(ApiResponse.success("Item removed from cart", response));
    }

    // 4. GET CART
    @GetMapping
    public ResponseEntity<ApiResponse<CartResponse>> getCart() {
        log.info("API GET /api/cart");
        CartResponse response = cartService.getCart();
        return ResponseEntity.ok(ApiResponse.success("Success", response));
    }

    // 5. CLEAR CART
    @DeleteMapping("/clear")
    public ResponseEntity<ApiResponse<Void>> clearCart() {
        log.info("API DELETE /api/cart/clear");
        cartService.clearCart(null);
        return ResponseEntity.ok(ApiResponse.success("Cart cleared successfully", null));
    }
}
