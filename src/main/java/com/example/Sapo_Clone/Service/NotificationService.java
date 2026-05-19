package com.example.Sapo_Clone.Service;

import com.example.Sapo_Clone.Entity.Notification;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface NotificationService {
    Notification createNotification(Notification notification);
    void markAsRead(int notificationId);
    Page<Notification> getNotificationsForUser(int userId, String role, Pageable pageable);
}
