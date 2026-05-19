package com.example.Sapo_Clone.Service.Impl;

import com.example.Sapo_Clone.DTO.Request.Provider.ProviderCreateDTO;
import com.example.Sapo_Clone.DTO.Request.Provider.ProviderUpdateDTO;
import com.example.Sapo_Clone.DTO.Response.Provider.ProviderResponse;
import com.example.Sapo_Clone.Entity.Provider;
import com.example.Sapo_Clone.Exception.AppException;
import com.example.Sapo_Clone.Exception.ErrorCode;
import com.example.Sapo_Clone.Repository.ProviderRepository;
import com.example.Sapo_Clone.Service.ProviderService;
import com.example.Sapo_Clone.Utils.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
public class ProviderServiceImpl implements ProviderService {

    private final ProviderRepository providerRepository;

    private Provider verifyOwnership(int id) {
        int companyId = SecurityUtils.getCurrentCompanyId();
        Provider provider = providerRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.PROVIDER_NOT_FOUND));
        return provider;
    }

    @Override
    @Transactional
    public ProviderResponse create(ProviderCreateDTO dto) {
        log.info("Creating provider: {}", dto.getProviderName());

        if (providerRepository.existsByProviderUei(dto.getProviderUei())) {
            throw new AppException(ErrorCode.PROVIDER_ALREADY_EXISTS);
        }

        if (providerRepository.existsByProviderPhone(dto.getProviderPhone())) {
            throw new AppException(ErrorCode.PROVIDER_ALREADY_EXISTS);
        }

        Provider provider = new Provider();
        provider.setProviderName(dto.getProviderName());
        provider.setProviderUei(dto.getProviderUei());
        provider.setProviderPhone(dto.getProviderPhone());
        provider.setProviderAddress(dto.getProviderAddress());
        provider.setDescription(dto.getDescription());
        provider.setStatus(1); // Active by default

        return ProviderResponse.fromEntity(providerRepository.save(provider));
    }

    @Override
    public ProviderResponse getById(int id) {
        log.info("Fetching provider id: {}", id);
        Provider provider = verifyOwnership(id);
        return ProviderResponse.fromEntity(provider);
    }

    @Override
    public Page<ProviderResponse> search(String keyword, int page, int size) {
        log.info("Searching providers keyword: {}", keyword);
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));

        if (keyword == null || keyword.trim().isEmpty()) {
            return providerRepository.findAll(pageable).map(ProviderResponse::fromEntity);
        }

        return providerRepository.searchProviders(keyword.trim(), pageable).map(ProviderResponse::fromEntity);
    }

    @Override
    @Transactional
    public ProviderResponse update(int id, ProviderUpdateDTO dto) {
        log.info("Updating provider id: {}", id);
        Provider provider = verifyOwnership(id);

        if (dto.getProviderName() != null) provider.setProviderName(dto.getProviderName());
        if (dto.getProviderPhone() != null) provider.setProviderPhone(dto.getProviderPhone());
        if (dto.getProviderAddress() != null) provider.setProviderAddress(dto.getProviderAddress());
        if (dto.getDescription() != null) provider.setDescription(dto.getDescription());
        if (dto.getStatus() != null) provider.setStatus(dto.getStatus());

        return ProviderResponse.fromEntity(providerRepository.save(provider));
    }

    @Override
    @Transactional
    public ProviderResponse changeStatus(int id, int status) {
        log.info("Changing status for provider id: {} to {}", id, status);
        Provider provider = verifyOwnership(id);
        
        provider.setStatus(status);
        return ProviderResponse.fromEntity(providerRepository.save(provider));
    }
}

