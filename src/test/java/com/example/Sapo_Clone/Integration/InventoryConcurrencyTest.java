package com.example.Sapo_Clone.Integration;

import com.example.Sapo_Clone.Entity.Inventory;
import com.example.Sapo_Clone.Entity.Product;
import com.example.Sapo_Clone.Entity.Store;
import com.example.Sapo_Clone.Repository.InventoryRepository;
import com.example.Sapo_Clone.Repository.ProductRepository;
import com.example.Sapo_Clone.Repository.StoreRepository;
import com.example.Sapo_Clone.Service.InventoryService;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

@SpringBootTest
public class InventoryConcurrencyTest {

    @Autowired
    private InventoryRepository inventoryRepository;
    @Autowired
    private ProductRepository productRepository;
    @Autowired
    private com.example.Sapo_Clone.Repository.CompanyRepository companyRepository;
    @Autowired
    private com.example.Sapo_Clone.Repository.UnitRepository unitRepository;
    @Autowired
    private StoreRepository storeRepository;
    @Autowired
    private InventoryService inventoryService;

    private int productId;
    private int storeId;

    @BeforeEach
    @Transactional
    public void setup() {
        inventoryRepository.deleteAll();
        productRepository.deleteAll();
        storeRepository.deleteAll();

        // create required Company and Unit for Product
        com.example.Sapo_Clone.Entity.Company company = new com.example.Sapo_Clone.Entity.Company();
        company.setCompanyName("test-company");
        // save via EntityManager through repository - use productRepository's entity
        // manager via saving a companyRepository would be better,
        // but to avoid adding more autowired repos, persist company via
        // productRepository's save cascading is not available.
        // Instead, create and save minimal company using a temporary repository access
        // through storeRepository (stores have company relation)
        // We'll save the company by attaching it to a store later. Create unit first.
        com.example.Sapo_Clone.Entity.Unit unit = new com.example.Sapo_Clone.Entity.Unit();
        unit.setUnitName("pcs");
        // persist unit using JPA directly by creating a temporary Product and setting
        // unit after saving unit via productRepository.save will not work.
        // Simpler: use storeRepository to persist a store with company, then save unit
        // via productRepository by using EntityManager indirectly is complex.
        // To keep test setup straightforward, use Spring Data repositories for Company
        // and Unit by obtaining them via application context would be ideal.
        // Instead, create and save Company and Unit using repository interfaces by
        // casting storeRepository to
        // org.springframework.data.repository.support.SimpleJpaRepository is unsafe.
        // As a practical workaround, create product with null company/unit is invalid;
        // instead we'll set minimal company and unit by using native insert via
        // JdbcTemplate.
        // For simplicity, create and save company and unit through the EntityManager
        // obtained from inventoryRepository by reflection.

        // persist Company and Unit using their repositories
        company = companyRepository.save(company);
        unit = unitRepository.save(unit);

        Product p = new Product();
        p.setProductName("test-product");
        p.setSellPrice(100.0);
        p.setImportPrice(50.0);
        p.setBarcode("TEST-BARCODE");
        p.setCompany(company);
        p.setUnit(unit);
        p = productRepository.save(p);

        Store s = new Store();
        s.setStoreName("test-store");
        s = storeRepository.save(s);

        Inventory inv = new Inventory();
        inv.setProduct(p);
        inv.setStore(s);
        inv.setQuantity(5); // initial stock
        inventoryRepository.save(inv);

        productId = p.getId();
        storeId = s.getId();
    }

    @Test
    public void concurrentReservations_shouldNotOverbook() throws Exception {
        int threads = 10;
        int requestPerThread = 1; // each thread attempts to reserve 1

        ExecutorService ex = Executors.newFixedThreadPool(threads);
        List<Future<Boolean>> futures = new ArrayList<>();

        for (int i = 0; i < threads; i++) {
            futures.add(ex.submit(() -> {
                try {
                    inventoryService.reserveStock(productId, storeId, requestPerThread);
                    return true;
                } catch (Exception e) {
                    return false;
                }
            }));
        }

        ex.shutdown();
        ex.awaitTermination(20, TimeUnit.SECONDS);

        int success = 0;
        for (Future<Boolean> f : futures) {
            if (f.get())
                success++;
        }

        // initial stock = 5, so at most 5 successes
        Assertions.assertTrue(success <= 5, "Reserved more than available stock");

        Inventory inv = inventoryRepository.findByProduct_IdAndStore_Id(productId, storeId).orElseThrow();
        Assertions.assertEquals(5 - success, inv.getQuantity());
    }
}
