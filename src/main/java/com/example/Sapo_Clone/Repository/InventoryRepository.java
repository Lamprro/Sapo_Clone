package com.example.Sapo_Clone.Repository;

import com.example.Sapo_Clone.Entity.Inventory;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface InventoryRepository extends JpaRepository<Inventory, Integer> {

    // Find inventory record by product and store IDs using derived query on nested
    // properties
    Optional<Inventory> findByProduct_IdAndStore_Id(int productId, int storeId);

    // Find all inventory records for a store
    Page<Inventory> findByStore_Id(int storeId, Pageable pageable);

    @Query("SELECT i FROM Inventory i WHERE i.store.id = :storeId " +
           "AND (:searching IS NULL OR LOWER(i.product.productName) LIKE LOWER(CONCAT('%', :searching, '%')) " +
           "OR LOWER(i.product.barcode) LIKE LOWER(CONCAT('%', :searching, '%')))")
    Page<Inventory> findByStore_IdAndSearching(@Param("storeId") int storeId, @Param("searching") String searching, Pageable pageable);

    // Atomically reserve stock if enough quantity remains.
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("UPDATE Inventory i " +
            "SET i.quantity = i.quantity - :quantity " +
            "WHERE i.product.id = :productId " +
            "AND i.store.id = :storeId " +
            "AND i.quantity >= :quantity")
    int reserveStockIfAvailable(@Param("productId") int productId,
            @Param("storeId") int storeId,
            @Param("quantity") int quantity);
}
