package com.example.Sapo_Clone.Repository;

import com.example.Sapo_Clone.Entity.Rating;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface RatingRepository extends JpaRepository<Rating, Integer> {

    Page<Rating> findByProductIdAndStatus(int productId, int status, Pageable pageable);

    List<Rating> findByUserId(int userId);

    @Query("SELECT r FROM Rating r WHERE r.user.id = :userId AND r.product.id = :productId")
    Optional<Rating> findByUserIdAndProductId(@Param("userId") int userId, @Param("productId") int productId);

    // SQL kiểm tra KHÁCH HÀNG ĐÃ MUA SẢN PHẨM NÀY CHƯA (trạng thái đơn hàng là Đã hoàn thành = 4)
    @Query("SELECT CASE WHEN COUNT(od) > 0 THEN true ELSE false END " +
           "FROM OrderDetail od " +
           "JOIN od.order o " +
           "WHERE o.customer.id = :userId " +
           "AND od.product.id = :productId " +
           "AND o.status = 4")
    boolean hasPurchasedProduct(@Param("userId") int userId, @Param("productId") int productId);

    // Tùy chọn: SQL kiểm tra xem khách hàng này đã ĐÁNH GIÁ SẢN PHẨM NÀY BAO NHIÊU LẦN
    @Query("SELECT COUNT(r) FROM Rating r WHERE r.user.id = :userId AND r.product.id = :productId")
    long countRatingsByCustomerAndProduct(@Param("userId") int userId, @Param("productId") int productId);

    // SQL kiểm tra tổng số lượng SẢN PHẨM MÀ KHÁCH ĐÃ MUA (COMPLETED = 4)
    @Query("SELECT COALESCE(SUM(od.quantity), 0) " +
           "FROM OrderDetail od " +
           "JOIN od.order o " +
           "WHERE o.customer.id = :userId " +
           "AND od.product.id = :productId " +
           "AND o.status = 4" +
            "AND o.paymentStatus = 1"
    )
    long countPurchasedQuantity(@Param("userId") int userId, @Param("productId") int productId);

    @Query("SELECT AVG(r.rating) FROM Rating r WHERE r.product.id = :productId AND r.status = 1")
    Double calculateAverageRating(@Param("productId") int productId);

    // Optional: Get all ratings for a product regardless of status (for Admin)
    Page<Rating> findByProductId(int productId, Pageable pageable);

    @Modifying
    @Query("DELETE FROM Rating r WHERE r.user.id = :userId")
    int deleteByUserId(@Param("userId") int userId);
}
