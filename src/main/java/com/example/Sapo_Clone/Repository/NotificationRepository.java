package com.example.Sapo_Clone.Repository;

import com.example.Sapo_Clone.Entity.Notification;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, Integer> {
    @Query("SELECT n FROM Notification n WHERE n.companyId = :companyId AND (n.targetUserId = :userId OR n.targetRole = :role)")
    Page<Notification> findByUserAndCompany(@Param("userId") Integer userId, @Param("role") String role, @Param("companyId") Integer companyId, Pageable pageable);
}
