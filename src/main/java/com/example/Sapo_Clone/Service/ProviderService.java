package com.example.Sapo_Clone.Service;

import com.example.Sapo_Clone.DTO.Request.Provider.ProviderCreateDTO;
import com.example.Sapo_Clone.DTO.Request.Provider.ProviderUpdateDTO;
import com.example.Sapo_Clone.DTO.Response.Provider.ProviderResponse;
import org.springframework.data.domain.Page;

public interface ProviderService {
    ProviderResponse create(ProviderCreateDTO dto);
    ProviderResponse getById(int id);
    Page<ProviderResponse> search(String keyword, int page, int size);
    ProviderResponse update(int id, ProviderUpdateDTO dto);
    ProviderResponse changeStatus(int id, int status);
}

