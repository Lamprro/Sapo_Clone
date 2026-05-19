package com.example.Sapo_Clone.Service.Impl;

import com.example.Sapo_Clone.DTO.Response.Category.CategoryResponse;
import com.example.Sapo_Clone.Entity.Category;
import com.example.Sapo_Clone.Repository.CategoryRepository;
import com.example.Sapo_Clone.Service.CategoryService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

@Service
@RequiredArgsConstructor
@Slf4j
public class CategoryServiceImpl implements CategoryService {

    private final CategoryRepository categoryRepository;

    @Override
    @Cacheable(value = "category:list", key = "'-kw:' + (#keyword != null ? #keyword : '') + '-p:' + #page + '-s:' + #size")
    public Page<CategoryResponse> getList(String keyword, int page, int size) {
        log.info("Getting category list keyword={}, page={}, size={}", keyword, page, size);
        Pageable pageable = PageRequest.of(page, size);

        if (keyword == null || keyword.trim().isEmpty()) {
            return categoryRepository.findAll(pageable).map(CategoryResponse::fromEntity);
        }

        String search = keyword.trim();

        if (search.matches("\\d+")) {
            int id = Integer.parseInt(search);
            Optional<Category> opt = categoryRepository.findById(id);
            List<CategoryResponse> singleResult = new ArrayList<>();
            opt.ifPresent(c -> singleResult.add(CategoryResponse.fromEntity(c)));
            return new PageImpl<>(singleResult, pageable, singleResult.size());
        }

        return categoryRepository.searchByName(search, pageable).map(CategoryResponse::fromEntity);
    }
}
