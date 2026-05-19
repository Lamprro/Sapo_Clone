package com.example.Sapo_Clone.Repository;

import com.example.Sapo_Clone.Entity.ProductImage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ProductImageRepository extends JpaRepository<ProductImage, Integer> {

    List<ProductImage> findByProduct_Id(int productId);

    Optional<ProductImage> findByIdAndProduct_Id(int imageId, int productId);

    @Modifying
    @Query("UPDATE ProductImage p SET p.status = 1 WHERE p.product.id = :productId")
    void resetAllImagesToActive(@Param("productId") int productId);

    // Get the first image that is not MAIN to promote it
    Optional<ProductImage> findFirstByProduct_IdAndStatus(int productId, int status);
}
