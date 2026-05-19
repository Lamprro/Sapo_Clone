package com.example.Sapo_Clone.Service;

import com.example.Sapo_Clone.DTO.Request.Store.StoreDTO;
import com.example.Sapo_Clone.DTO.Response.Store.StoreResponse;
import com.example.Sapo_Clone.DTO.Response.Store.StoreWithInventoryResponse;
import org.springframework.data.domain.Page;

import java.util.List;

public interface StoreService {
    StoreResponse createStore(StoreDTO dto);
    Page<StoreResponse> getList(String keyword, int page, int size);
    List<StoreResponse> getAllStoresForCustomer();
    Page<StoreWithInventoryResponse> getStoresByProductId(Integer productId, int page, int size);
    StoreResponse updateStore(int id, StoreDTO dto);
}