package com.example.Sapo_Clone.Repository;

import com.example.Sapo_Clone.Entity.User;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Integer> {

    Optional<User> findByUsername(String username);

    Optional<User> findByUsernameAndCompany_Id(String username, int companyId);

    boolean existsByUserPhoneAndCompany_Id(String phone, int companyId);

    boolean existsByUserEmailAndCompany_Id(String email, int companyId);

    boolean existsByUsernameAndCompany_Id(String username, int companyId);

    boolean existsByUserPhone(String phone);

    boolean existsByUserEmail(String email);

    boolean existsByUsername(String username);

    Optional<User> findByUserEmail(String email);

    @Query("SELECT u FROM User u WHERE " +
            "u.company.id = :companyId AND (" +
            "LOWER(u.userFullName) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            "u.userPhone LIKE CONCAT('%', :keyword, '%') OR " +
            "LOWER(u.userEmail) LIKE LOWER(CONCAT('%', :keyword, '%')))")
    Page<User> searchByKeyword(@Param("companyId") int companyId, @Param("keyword") String keyword, Pageable pageable);

    @Query("SELECT u FROM User u WHERE u.company.id = :companyId")
    Page<User> findAllByCompanyId(@Param("companyId") int companyId, Pageable pageable);
}
