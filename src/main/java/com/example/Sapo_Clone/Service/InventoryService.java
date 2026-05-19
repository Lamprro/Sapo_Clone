package com.example.Sapo_Clone.Service;

import com.example.Sapo_Clone.DTO.Response.Inventory.InventoryByStoreResponse;
import com.example.Sapo_Clone.DTO.Response.Product.ProductInventoryResponse;
import org.springframework.data.domain.Page;

public interface InventoryService {

    // 1. GET INVENTORY BY PRODUCT + STORE
    ProductInventoryResponse getInventory(int productId, Integer storeId);

    // 2. GET INVENTORY BY STORE
    Page<InventoryByStoreResponse> getInventoryByStore(Integer storeId, String searching, int page, int size);

    // 3. INCREASE INVENTORY
    void increaseStock(int productId, int storeId, int quantity);

    // 4. DECREASE INVENTORY
    void decreaseStock(int productId, int storeId, int quantity);

    // 4.1 RESERVE STOCK ATOMICALLY (prevents race conditions)
    void reserveStock(int productId, int storeId, int quantity);

    // 5. CHECK STOCK
    boolean checkStock(int productId, int storeId, int quantity);
}
