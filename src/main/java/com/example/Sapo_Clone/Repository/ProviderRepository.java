package com.example.Sapo_Clone.Repository;

import com.example.Sapo_Clone.Entity.Provider;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface ProviderRepository extends JpaRepository<Provider, Integer> {

    @Query("SELECT p FROM Provider p")
    Page<Provider> findAll(Pageable pageable);

    @Query("SELECT p FROM Provider p WHERE (" +
            "LOWER(p.providerName) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            "LOWER(p.providerUei) LIKE LOWER(CONCAT('%', :keyword, '%')))")
    Page<Provider> searchProviders(
            @Param("keyword") String keyword,
            Pageable pageable);

    boolean existsByProviderUei(String providerUei);

    boolean existsByProviderPhone(String providerPhone);

    boolean existsByProviderUeiAndIdNot(String providerUei, int id);
}
