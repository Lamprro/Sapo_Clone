package com.example.Sapo_Clone.Integration;

import com.example.Sapo_Clone.DTO.Request.Order.OrderCreateDTO;
import com.example.Sapo_Clone.DTO.Request.Order.OrderDetailCreateDTO;
import com.example.Sapo_Clone.Entity.Inventory;
import com.example.Sapo_Clone.Entity.Product;
import com.example.Sapo_Clone.Entity.Roles;
import com.example.Sapo_Clone.Entity.Store;
import com.example.Sapo_Clone.Repository.*;
import com.example.Sapo_Clone.Service.OrderService;
import com.example.Sapo_Clone.Service.InventoryService;
import com.example.Sapo_Clone.Security.UserPrincipal;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import java.util.List;

@SpringBootTest
public class OrderCreateRollbackTest {

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
    private UserRepository userRepository;
    @Autowired
    private com.example.Sapo_Clone.Repository.RoleRepository roleRepository;
    @Autowired
    private OrderRepository orderRepository;
    @Autowired
    private OrderService orderService;
    @Autowired
    private InventoryService inventoryService;
    @Autowired
    private PlatformTransactionManager txManager;

    private int productId;
    private int storeId;
    private int customerId;

    @BeforeEach
    public void setup() {
        orderRepository.deleteAll();
        inventoryRepository.deleteAll();
        productRepository.deleteAll();
        storeRepository.deleteAll();
        userRepository.deleteAll();

        var company = new com.example.Sapo_Clone.Entity.Company();
        company.setCompanyName("ord-company");
        company = companyRepository.save(company);

        var unit = new com.example.Sapo_Clone.Entity.Unit();
        unit.setUnitName("u");
        unit = unitRepository.save(unit);

        Roles r = new Roles();
        r.setRolesName("CUSTOMER");
        // persist role via userRepository's entity manager by saving a user later;
        // instead save using userRepository through new user

        Product p = new Product();
        p.setProductName("ord-product");
        p.setSellPrice(20.0);
        p.setImportPrice(10.0);
        p.setBarcode("ORD-1");
        p.setCompany(company);
        p.setUnit(unit);
        p = productRepository.save(p);

        Store s = new Store();
        s.setStoreName("ord-store");
        s = storeRepository.save(s);

        Inventory inv = new Inventory();
        inv.setProduct(p);
        inv.setStore(s);
        inv.setQuantity(5);
        inventoryRepository.save(inv);

        // create and persist Roles and User
        var role = new com.example.Sapo_Clone.Entity.Roles();
        role.setRolesName("CUSTOMER");
        role = roleRepository.save(role);

        com.example.Sapo_Clone.Entity.User user = new com.example.Sapo_Clone.Entity.User();
        user.setUsername("test-cust");
        user.setPassword("x");
        user.setUserFullName("Customer");
        user.setCompany(company);
        user.setRoles(role);
        user = userRepository.save(user);

        productId = p.getId();
        storeId = s.getId();
        customerId = user.getId();

        // set authentication principal
        UserPrincipal principal = UserPrincipal.builder()
                .id(customerId)
                .username(user.getUsername())
                .companyId(company.getId())
                .storeId(s.getId())
                .role("CUSTOMER")
                .build();
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(principal, null, principal.getAuthorities()));
    }

    @Test
    public void createOrder_then_outerException_shouldRollbackInventoryAndOrder() {
        OrderDetailCreateDTO detail = new OrderDetailCreateDTO(productId, 1, 2);
        OrderCreateDTO dto = OrderCreateDTO.builder()
                .customerId(customerId)
                .storeId(storeId)
                .paymentMethod("CASH")
                .orderDetails(List.of(detail))
                .build();

        TransactionTemplate tt = new TransactionTemplate(txManager);

        try {
            tt.executeWithoutResult(status -> {
                orderService.createOrder(dto);
                throw new RuntimeException("force rollback");
            });
        } catch (RuntimeException ex) {
            // expected
        }

        Inventory inv = inventoryRepository.findByProduct_IdAndStore_Id(productId, storeId).orElseThrow();
        // reservation should have been rolled back, original quantity 5
        Assertions.assertEquals(5, inv.getQuantity());

        var orders = orderRepository.findAll();
        Assertions.assertTrue(orders.isEmpty(), "Order should not be persisted after rollback");
    }
}
