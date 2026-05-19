package com.example.Sapo_Clone.Service;

import com.example.Sapo_Clone.DTO.Response.Unit.UnitResponse;

import org.springframework.data.domain.Page;

public interface UnitService {
    Page<UnitResponse> getList(String keyword, int page, int size);
}

