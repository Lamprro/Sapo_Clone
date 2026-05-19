package com.example.Sapo_Clone.Repository;

import com.example.Sapo_Clone.Entity.Promotion;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface PromotionRepository extends JpaRepository<Promotion, Integer> {

    @Query("SELECT p FROM Promotion p WHERE p.status = :status AND p.endedAt < :now")
    List<Promotion> findByStatusAndEndedAtBefore(@Param("status") int status, @Param("now") LocalDateTime now);

    @Query("SELECT p FROM Promotion p WHERE p.company.id = :companyId AND p.status = 1")
    Page<Promotion> findAllByCompanyId(int companyId, Pageable pageable);

    // Make sure we only get promotions that are active
    @Query("SELECT p FROM Promotion p WHERE p.status = 1 AND p.startedAt <= :now AND p.endedAt >= :now")
    List<Promotion> findActivePromotions(@Param("now") LocalDateTime now);

    @Query("SELECT p FROM Promotion p WHERE p.company.id = :companyId AND"+
            "(:keyword IS NULL OR :keyword = '' OR LOWER(p.promotionName) LIKE LOWER(CONCAT('%', :keyword, '%')) OR "+
            "CAST(p.id AS string) LIKE CONCAT('%', :keyword, '%'))"
    )
    Page<Promotion> searchPromotions(@Param("companyId") int companyId, @Param("keyword") String keyword ,Pageable pageable);
}
