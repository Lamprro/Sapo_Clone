package com.example.Sapo_Clone.Service;

import com.example.Sapo_Clone.DTO.Request.Company.CompanyDTO;
import com.example.Sapo_Clone.DTO.Response.Company.CompanyResponse;
import org.springframework.data.domain.Page;

public interface CompanyService {
    CompanyResponse createCompany(CompanyDTO dto);
    Page<CompanyResponse> getList(String keyword, int page, int size);
    CompanyResponse updateCompany(int id, CompanyDTO dto);
}
