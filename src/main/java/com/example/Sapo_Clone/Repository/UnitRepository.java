package com.example.Sapo_Clone.Repository;

import com.example.Sapo_Clone.Entity.Unit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import java.util.Optional;

@Repository
public interface UnitRepository extends JpaRepository<Unit, Integer> {

    Optional<Unit> findByUnitName(String unitName);

    @Query("SELECT u FROM Unit u WHERE LOWER(u.unitName) LIKE LOWER(CONCAT('%', :keyword, '%'))")
    Page<Unit> searchByName(@Param("keyword") String keyword, Pageable pageable);
}
