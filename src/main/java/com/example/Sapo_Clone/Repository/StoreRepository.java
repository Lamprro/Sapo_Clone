package com.example.Sapo_Clone.Repository;

import com.example.Sapo_Clone.Entity.Store;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface StoreRepository extends JpaRepository<Store, Integer> {
       @Query(value = "SELECT s FROM Store s WHERE s.company.id = :companyId AND (" +
                     "(:keyword IS NULL OR :keyword = '') OR " +
                     "LOWER(s.storeName) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
                     "CAST(s.id AS string) LIKE CONCAT('%', :keyword, '%'))", countQuery = "SELECT count(s) FROM Store s WHERE s.company.id = :companyId AND ("
                                   +
                                   "(:keyword IS NULL OR :keyword = '') OR " +
                                   "LOWER(s.storeName) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
                                   "CAST(s.id AS string) LIKE CONCAT('%', :keyword, '%'))")
       Page<Store> searchStores(@Param("companyId") int companyId, @Param("keyword") String keyword, Pageable pageable);

       List<Store> findByCompanyId(int companyId);

       @Query("SELECT s, i.quantity FROM Store s JOIN s.inventories i WHERE i.product.id = :productId AND i.quantity > 0 AND s.company.id = :companyId")
       Page<Object[]> findStoresAndStockByProductId(@Param("productId") Integer productId,
                     @Param("companyId") int companyId, Pageable pageable);

       @Query("SELECT s FROM Store s JOIN s.inventories i WHERE i.product.id = :productId AND i.quantity > 0 AND s.company.id = :companyId")
       Page<Store> findStoresByProductIdAndStock(@Param("productId") Integer productId,
                     @Param("companyId") int companyId, Pageable pageable);

       @Query(value = "SELECT TOP 1 s.id " +
                     "FROM store s " +
                     "JOIN inventory i ON s.id = i.store_id " +
                     "WHERE i.product_id = :productId AND i.quantity >= :quantity AND s.company_id = :companyId " +
                     "ORDER BY (6371 * acos(cos(radians(:lat)) * cos(radians(s.latitude)) * " +
                     "cos(radians(s.longitude) - radians(:lng)) + " +
                     "sin(radians(:lat)) * sin(radians(s.latitude)))) ASC", nativeQuery = true)
       Optional<Integer> findNearestStoreIdWithStock(@Param("productId") Integer productId,
                     @Param("quantity") Integer quantity,
                     @Param("lat") Double lat,
                     @Param("lng") Double lng,
                     @Param("companyId") Integer companyId);
}
