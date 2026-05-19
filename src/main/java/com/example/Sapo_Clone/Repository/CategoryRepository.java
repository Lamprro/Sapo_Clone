package com.example.Sapo_Clone.Repository;

import com.example.Sapo_Clone.Entity.Category;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

@Repository
public interface CategoryRepository extends JpaRepository<Category, Integer> {
    // findAllById is inherited from JpaRepository — used to validate categoryIds
    List<Category> findAllByIdIn(List<Integer> categoryIds);

    @Query("SELECT c FROM Category c WHERE LOWER(c.categoryName) LIKE LOWER(CONCAT('%', :keyword, '%'))")
    Page<Category> searchByName(@Param("keyword") String keyword, Pageable pageable);
}
