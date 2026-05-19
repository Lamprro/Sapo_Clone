package com.example.Sapo_Clone.Repository;

import com.example.Sapo_Clone.Entity.Notification;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, Integer> {
    Page<Notification> findByTargetUserId(Integer userId, Pageable pageable);
    Page<Notification> findByTargetRole(String role, Pageable pageable);
    Page<Notification> findByTargetUserIdOrTargetRole(Integer userId, String role, Pageable pageable);
}
