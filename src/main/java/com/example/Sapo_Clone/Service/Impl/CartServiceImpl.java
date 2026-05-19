package com.example.Sapo_Clone.Service.Impl;

import com.example.Sapo_Clone.DTO.Request.Cart.AddToCartDTO;
import com.example.Sapo_Clone.DTO.Request.Cart.UpdateCartItemDTO;
import com.example.Sapo_Clone.DTO.Response.Cart.CartItemResponse;
import com.example.Sapo_Clone.DTO.Response.Cart.CartResponse;
import com.example.Sapo_Clone.Entity.Cart;
import com.example.Sapo_Clone.Entity.CartItem;
import com.example.Sapo_Clone.Entity.Product;
import com.example.Sapo_Clone.Entity.User;
import com.example.Sapo_Clone.Exception.AppException;
import com.example.Sapo_Clone.Exception.ErrorCode;
import com.example.Sapo_Clone.Repository.CartItemRepository;
import com.example.Sapo_Clone.Repository.CartRepository;
import com.example.Sapo_Clone.Repository.ProductRepository;
import com.example.Sapo_Clone.Repository.UserRepository;
import com.example.Sapo_Clone.Service.CartService;
import com.example.Sapo_Clone.Utils.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class CartServiceImpl implements CartService {

    private final CartRepository cartRepository;
    private final CartItemRepository cartItemRepository;
    private final ProductRepository productRepository;
    private final UserRepository userRepository;

    @Override
    @Transactional
    public CartResponse addItem(AddToCartDTO dto) {
        int userId = SecurityUtils.getCurrentUserId();
        log.info("Adding item to cart for userId={}, productId={}, quantity={}", userId, dto.getProductId(), dto.getQuantity());

        if (dto.getQuantity() <= 0) {
            throw new AppException(ErrorCode.VALIDATION_ERROR);
        }

        Product product = productRepository.findById(dto.getProductId())
                .orElseThrow(() -> new AppException(ErrorCode.PRODUCT_NOT_FOUND));

        Cart cart = getOrCreateCart(userId);

        if (product.getCompany() == null || cart.getUser().getCompany() == null || 
            product.getCompany().getId() != cart.getUser().getCompany().getId()) {
            throw new AppException(ErrorCode.PRODUCT_NOT_FOUND);
        }

        Optional<CartItem> optCartItem = cartItemRepository.findByCart_IdAndProduct_Id(cart.getId(), product.getId());
        CartItem cartItem;
        if (optCartItem.isPresent()) {
            cartItem = optCartItem.get();
            cartItem.setQuantity(cartItem.getQuantity() + dto.getQuantity());
        } else {
            cartItem = new CartItem();
            cartItem.setCart(cart);
            cartItem.setProduct(product);
            cartItem.setQuantity(dto.getQuantity());
        }

        cartItemRepository.save(cartItem);

        return getCart();
    }

    @Override
    @Transactional
    public CartResponse updateQuantity(int productId, UpdateCartItemDTO dto) {
        int userId = SecurityUtils.getCurrentUserId();
        log.info("Updating cart quantity for userId={}, productId={} to {}", userId, productId, dto.getQuantity());

        Cart cart = getOrCreateCart(userId);

        CartItem cartItem = cartItemRepository.findByCart_IdAndProduct_Id(cart.getId(), productId)
                .orElseThrow(() -> new AppException(ErrorCode.PRODUCT_NOT_FOUND)); // Or CART_ITEM_NOT_FOUND

        if (dto.getQuantity() > 0) {
            cartItem.setQuantity(dto.getQuantity());
            cartItemRepository.save(cartItem);
        } else {
            cart.getCartItems().remove(cartItem);
            cartItemRepository.delete(cartItem);
            cartRepository.save(cart);
        }

        return getCart();
    }

    @Override
    @Transactional
    public CartResponse removeItem(int productId) {
        int userId = SecurityUtils.getCurrentUserId();
        log.info("Removing item from cart for userId={}, productId={}", userId, productId);

        Cart cart = getOrCreateCart(userId);
        CartItem cartItem = cartItemRepository.findByCart_IdAndProduct_Id(cart.getId(), productId)
                .orElseThrow(() -> new AppException(ErrorCode.PRODUCT_NOT_FOUND));
        cart.getCartItems().remove(cartItem);
        cartItemRepository.delete(cartItem);

        return getCart();
    }

    @Override
    public CartResponse getCart() {
        int userId = SecurityUtils.getCurrentUserId();
        log.info("Fetching cart for userId={}", userId);

        Optional<Cart> optCart = cartRepository.findByUser_Id(userId);
        if (optCart.isEmpty()) {
            return CartResponse.builder()
                    .items(new ArrayList<>())
                    .totalAmount(0.0)
                    .build();
        }

        Cart cart = optCart.get();
        List<CartItemResponse> itemResponses = new ArrayList<>();
        double totalAmount = 0.0;

        if (cart.getCartItems() != null) {
            for (CartItem item : cart.getCartItems()) {
                CartItemResponse resp = CartItemResponse.fromEntity(item);
                itemResponses.add(resp);
                totalAmount += resp.getTotalPrice();
            }
        }

        return CartResponse.builder()
                .cartId(cart.getId())
                .items(itemResponses)
                .totalAmount(totalAmount)
                .build();
    }

    @Override
    @Transactional
    public void clearCart(Integer userId) {
        if (userId == null) {
            userId = SecurityUtils.getCurrentUserId();
        }
        log.info("Clearing cart for userId={}", userId);
        Optional<Cart> optCart = cartRepository.findByUser_Id(userId);
        if (optCart.isPresent()) {
            Cart cart = optCart.get();
            cart.getCartItems().clear();
            cartRepository.save(cart);
        }
    }

    private Cart getOrCreateCart(int userId) {
        return cartRepository.findByUser_Id(userId).orElseGet(() -> {
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));
            Cart newCart = new Cart();
            newCart.setUser(user);
            return cartRepository.save(newCart);
        });
    }
}
