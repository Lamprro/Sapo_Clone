package com.example.Sapo_Clone.Service.Impl;

import com.example.Sapo_Clone.DTO.Request.Store.StoreDTO;
import com.example.Sapo_Clone.DTO.Response.Store.StoreResponse;
import com.example.Sapo_Clone.DTO.Response.Store.StoreWithInventoryResponse;
import com.example.Sapo_Clone.Entity.Company;
import com.example.Sapo_Clone.Entity.Store;
import com.example.Sapo_Clone.Exception.AppException;
import com.example.Sapo_Clone.Exception.ErrorCode;
import com.example.Sapo_Clone.Repository.CompanyRepository;
import com.example.Sapo_Clone.Repository.StoreRepository;
import com.example.Sapo_Clone.Service.StoreService;
import com.example.Sapo_Clone.Service.MapService;
import com.example.Sapo_Clone.DTO.Response.Coordinates;
import com.example.Sapo_Clone.Utils.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class StoreServiceImpl implements StoreService {
    private final StoreRepository storeRepository;
    private final CompanyRepository companyRepository;
    private final MapService mapService;

    @Override
    public StoreResponse createStore(StoreDTO dto) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        if ("ADMIN".equals(SecurityUtils.getCurrentRole()) && dto.getCompanyId() != null) {
            companyId = dto.getCompanyId();
        }
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new AppException(ErrorCode.COMPANY_NOT_FOUND));

        Store store = new Store();
        store.setStoreName(dto.getStoreName());
        store.setStoreAddress(dto.getStoreAddress());
        store.setCompany(company);

        // Fetch coordinates from Goong API if not provided
        if (dto.getLatitude() == null || dto.getLongitude() == null) {
            Coordinates coords = mapService.getCoordinatesFromAddress(dto.getStoreAddress());
            if (coords != null) {
                store.setLatitude(coords.getLat());
                store.setLongitude(coords.getLng());
            }
        } else {
            store.setLatitude(dto.getLatitude());
            store.setLongitude(dto.getLongitude());
        }

        return StoreResponse.fromEntity(storeRepository.save(store));
    }

    @Override
    public Page<StoreResponse> getList(String keyword, int page, int size) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        return storeRepository.searchStores(companyId, keyword, pageable).map(StoreResponse::fromEntity);
    }

    @Override
    public List<StoreResponse> getAllStoresForCustomer() {
        int companyId = SecurityUtils.getCurrentCompanyId();
        List<Store> stores;
        if ("ADMIN".equals(SecurityUtils.getCurrentRole())) {
            stores = storeRepository.findAll();
        } else {
            stores = storeRepository.findByCompanyId(companyId);
        }
        return stores.stream().map(StoreResponse::fromEntity).collect(Collectors.toList());
    }

    @Override
    public Page<StoreWithInventoryResponse> getStoresByProductId(Integer productId, int page, int size) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        Pageable pageable = PageRequest.of(page, size);
        return storeRepository.findStoresAndStockByProductId(productId, companyId, pageable).map(result -> {
            Store store = (Store) result[0];
            int quantity = (int) result[1];
            return StoreWithInventoryResponse.fromEntityAndQuantity(store, quantity);
        });
    }

    @Override
    public StoreResponse updateStore(int id, StoreDTO dto) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        Store store = storeRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.STORE_NOT_FOUND));

        if (!"ADMIN".equals(SecurityUtils.getCurrentRole()) && (store.getCompany() == null || store.getCompany().getId() != companyId)) {
            throw new AppException(ErrorCode.STORE_NOT_FOUND);
        }

        store.setStoreName(dto.getStoreName());
        store.setStoreAddress(dto.getStoreAddress());
        
        if ("ADMIN".equals(SecurityUtils.getCurrentRole()) && dto.getCompanyId() != null) {
            Company company = companyRepository.findById(dto.getCompanyId())
                    .orElseThrow(() -> new AppException(ErrorCode.COMPANY_NOT_FOUND));
            store.setCompany(company);
        }

        // Fetch coordinates from Goong API if not provided
        if (dto.getLatitude() == null || dto.getLongitude() == null) {
            Coordinates coords = mapService.getCoordinatesFromAddress(dto.getStoreAddress());
            if (coords != null) {
                store.setLatitude(coords.getLat());
                store.setLongitude(coords.getLng());
            }
        } else {
            store.setLatitude(dto.getLatitude());
            store.setLongitude(dto.getLongitude());
        }

        return StoreResponse.fromEntity(storeRepository.save(store));
    }
}