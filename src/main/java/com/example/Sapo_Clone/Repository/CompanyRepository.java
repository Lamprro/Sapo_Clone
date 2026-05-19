package com.example.Sapo_Clone.Repository;

import com.example.Sapo_Clone.Entity.Company;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface CompanyRepository extends JpaRepository<Company, Integer> {
    @Query("SELECT c FROM Company c WHERE (:keyword IS NULL OR :keyword = '' OR LOWER(c.companyName) LIKE LOWER(CONCAT('%', :keyword, '%')) OR CAST(c.id AS string) LIKE CONCAT('%', :keyword, '%'))")
    Page<Company> searchCompanies(@Param("keyword") String keyword, Pageable pageable);
}