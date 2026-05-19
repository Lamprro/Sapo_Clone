package com.example.Sapo_Clone.Repository;

import com.example.Sapo_Clone.DTO.Response.Product.ProductReportProjection;
import com.example.Sapo_Clone.Entity.Product;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ProductRepository extends JpaRepository<Product, Integer> {

    boolean existsByCompany_IdAndBarcode(int companyId, String barcode);

    // Check barcode duplicate excluding itself (for update) within the same company
    boolean existsByCompany_IdAndBarcodeAndIdNot(int companyId, String barcode, int id);

    @Query("SELECT p FROM Product p WHERE p.company.id = :companyId AND (:isManage IS TRUE OR p.status = 1)")
    Page<Product> findAllByCompanyIdAndStatus(@Param("companyId") int companyId, @Param("isManage") boolean isManage, Pageable pageable);

    // Search by productName or barcode (case-insensitive) and optionally filter by categories
    @Query("SELECT DISTINCT p FROM Product p " +
            "LEFT JOIN p.categoryList c " +
            "WHERE p.company.id = :companyId " +
            "AND (" +
            "  :text IS NULL OR :text = '' " +
            "  OR LOWER(p.productName) LIKE LOWER(CONCAT('%', :text, '%')) " +
            "  OR p.barcode LIKE CONCAT('%', :text, '%')" +
            ") " +
            "AND (" +
            "  COALESCE(:categoryIds, NULL) IS NULL OR c.id IN :categoryIds" +
            ") " +
            "AND (:isManage IS TRUE OR p.status = 1)")
    Page<Product> searchByTextAndCategories(@Param("companyId") int companyId, 
                                            @Param("text") String text, 
                                            @Param("categoryIds") List<Integer> categoryIds,
                                            @Param("isManage") boolean isManage,
                                            Pageable pageable);

    // Products that exist in a specific store's inventory
    @Query("SELECT p FROM Product p JOIN p.inventories i WHERE i.store.id = :storeId AND i.store.company.id = :companyId AND (:isManage IS TRUE OR p.status = 1)")
    Page<Product> findByStoreIdAndStatus(@Param("companyId") int companyId, @Param("storeId") int storeId, @Param("isManage") boolean isManage, Pageable pageable);

    // Report: all or single product - SUM quantity sold, revenue, profit, using
    // persisted avgstar
    @Query(nativeQuery = true, value = "SELECT p.id AS productId, p.product_name AS productName, " +
            " (SELECT COALESCE(SUM(od.quantity), 0) FROM order_details od JOIN orders o ON od.order_id = o.id WHERE od.product_id = p.id AND o.status = 4) AS totalSellQuantity, "
            +
            " (SELECT COALESCE(SUM(CAST(od.quantity AS FLOAT) * od.price), 0) FROM order_details od JOIN orders o ON od.order_id = o.id WHERE od.product_id = p.id AND o.status = 4) AS totalRevenue, "
            +
            " (SELECT COALESCE(SUM(CAST(od.quantity AS FLOAT) * (od.price - od.import_price)), 0) FROM order_details od JOIN orders o ON od.order_id = o.id WHERE od.product_id = p.id AND o.status = 4) AS totalProfit, "
            +
            " p.avgstar AS evaluationScore " +
            "FROM product p " +
            "WHERE p.company_id = :companyId " +
            "AND (:productId IS NULL OR p.id = :productId) " +
            "GROUP BY p.id, p.product_name, p.avgstar")
    List<ProductReportProjection> getProductReport(@Param("companyId") int companyId,
            @Param("productId") Integer productId);
}