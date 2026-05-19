package com.example.Sapo_Clone.Repository;

import com.example.Sapo_Clone.Entity.CartItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface CartItemRepository extends JpaRepository<CartItem, Integer> {
    Optional<CartItem> findByCart_IdAndProduct_Id(int cartId, int productId);
    void deleteByProductId(int productId);
}
