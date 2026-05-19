package com.example.Sapo_Clone.Service.Impl;

import com.example.Sapo_Clone.DTO.Response.Unit.UnitResponse;
import com.example.Sapo_Clone.Entity.Unit;
import com.example.Sapo_Clone.Repository.UnitRepository;
import com.example.Sapo_Clone.Service.UnitService;
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
public class UnitServiceImpl implements UnitService {

    private final UnitRepository unitRepository;

    @Override
    @Cacheable(value = "unit:list", key = "'-kw:' + (#keyword != null ? #keyword : '') + '-p:' + #page + '-s:' + #size")
    public Page<UnitResponse> getList(String keyword, int page, int size) {
        log.info("Getting unit list keyword={}, page={}, size={}", keyword, page, size);
        Pageable pageable = PageRequest.of(page, size);

        if (keyword == null || keyword.trim().isEmpty()) {
            return unitRepository.findAll(pageable).map(UnitResponse::fromEntity);
        }

        String search = keyword.trim();

        if (search.matches("\\d+")) {
            int id = Integer.parseInt(search);
            Optional<Unit> opt = unitRepository.findById(id);
            List<UnitResponse> singleResult = new ArrayList<>();
            opt.ifPresent(c -> singleResult.add(UnitResponse.fromEntity(c)));
            return new PageImpl<>(singleResult, pageable, singleResult.size());
        }

        return unitRepository.searchByName(search, pageable).map(UnitResponse::fromEntity);
    }
}
