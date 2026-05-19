package com.example.Sapo_Clone.Integration;

import com.example.Sapo_Clone.Entity.Inventory;
import com.example.Sapo_Clone.Entity.Product;
import com.example.Sapo_Clone.Entity.Store;
import com.example.Sapo_Clone.Repository.InventoryRepository;
import com.example.Sapo_Clone.Repository.ProductRepository;
import com.example.Sapo_Clone.Repository.StoreRepository;
import com.example.Sapo_Clone.Repository.CompanyRepository;
import com.example.Sapo_Clone.Repository.UnitRepository;
import com.example.Sapo_Clone.Service.InventoryService;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

@SpringBootTest
public class InventoryReserveRollbackTest {

    @Autowired
    private InventoryRepository inventoryRepository;
    @Autowired
    private ProductRepository productRepository;
    @Autowired
    private StoreRepository storeRepository;
    @Autowired
    private CompanyRepository companyRepository;
    @Autowired
    private UnitRepository unitRepository;
    @Autowired
    private InventoryService inventoryService;
    @Autowired
    private PlatformTransactionManager txManager;

    private int productId;
    private int storeId;

    @BeforeEach
    public void setup() {
        inventoryRepository.deleteAll();
        productRepository.deleteAll();
        storeRepository.deleteAll();

        var company = new com.example.Sapo_Clone.Entity.Company();
        company.setCompanyName("rb-company");
        company = companyRepository.save(company);

        var unit = new com.example.Sapo_Clone.Entity.Unit();
        unit.setUnitName("u");
        unit = unitRepository.save(unit);

        Product p = new Product();
        p.setProductName("rb-product");
        p.setSellPrice(10.0);
        p.setImportPrice(5.0);
        p.setBarcode("RB-1");
        p.setCompany(company);
        p.setUnit(unit);
        p = productRepository.save(p);

        Store s = new Store();
        s.setStoreName("rb-store");
        s = storeRepository.save(s);

        Inventory inv = new Inventory();
        inv.setProduct(p);
        inv.setStore(s);
        inv.setQuantity(3);
        inventoryRepository.save(inv);

        productId = p.getId();
        storeId = s.getId();
    }

    @Test
    public void reserve_then_outerException_shouldRollback() {
        TransactionTemplate tt = new TransactionTemplate(txManager);

        try {
            tt.executeWithoutResult(status -> {
                // This call participates in the transaction; after we throw, transaction should
                // rollback
                inventoryService.reserveStock(productId, storeId, 2);
                throw new RuntimeException("force outer rollback");
            });
        } catch (RuntimeException ex) {
            // expected
        }

        Inventory inv = inventoryRepository.findByProduct_IdAndStore_Id(productId, storeId).orElseThrow();
        // Since outer transaction rolled back, quantity should remain original (3)
        Assertions.assertEquals(3, inv.getQuantity());
    }
}
