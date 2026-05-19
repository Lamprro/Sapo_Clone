package com.example.Sapo_Clone.Service.Impl;

import com.example.Sapo_Clone.DTO.Request.Company.CompanyDTO;
import com.example.Sapo_Clone.DTO.Response.Company.CompanyResponse;
import com.example.Sapo_Clone.Entity.Company;
import com.example.Sapo_Clone.Exception.AppException;
import com.example.Sapo_Clone.Exception.ErrorCode;
import com.example.Sapo_Clone.Repository.CompanyRepository;
import com.example.Sapo_Clone.Service.CompanyService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class CompanyServiceImpl implements CompanyService {
    private final CompanyRepository companyRepository;

    @Override
    public CompanyResponse createCompany(CompanyDTO dto) {
        Company company = new Company();
        company.setCompanyName(dto.getCompanyName());
        company.setCompanyAddress(dto.getCompanyAddress());
        return CompanyResponse.fromEntity(companyRepository.save(company));
    }

    @Override
    public Page<CompanyResponse> getList(String keyword, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        return companyRepository.searchCompanies(keyword, pageable).map(CompanyResponse::fromEntity);
    }

    @Override
    public CompanyResponse updateCompany(int id, CompanyDTO dto) {
        Company company = companyRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.COMPANY_NOT_FOUND));
        
        company.setCompanyName(dto.getCompanyName());
        company.setCompanyAddress(dto.getCompanyAddress());
        return CompanyResponse.fromEntity(companyRepository.save(company));
    }
}
