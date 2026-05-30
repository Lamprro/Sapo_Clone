package com.example.Sapo_Clone.Repository;

import com.example.Sapo_Clone.Entity.EmailVerification;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface EmailVerificationRepository extends JpaRepository<EmailVerification, Integer> {
    Optional<EmailVerification> findByEmailAndCompany_Id(String email, int companyId);
    Optional<EmailVerification> findByEmailAndCompany_IdAndPurpose(String email, int companyId, int purpose);
    Optional<EmailVerification> findByEmailAndCompany_IdAndCode(String email, int companyId, String code);
    Optional<EmailVerification> findByEmailAndCompany_IdAndCodeAndPurpose(String email, int companyId, String code, int purpose);
    void deleteByEmailAndCompanyId(String email, int companyId);
}
