package com.example.Sapo_Clone.Service;

import com.example.Sapo_Clone.DTO.Response.Category.CategoryResponse;
import org.springframework.data.domain.Page;

public interface CategoryService {
    Page<CategoryResponse> getList(String keyword, int page, int size);
}

