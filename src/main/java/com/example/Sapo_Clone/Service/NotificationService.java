package com.example.Sapo_Clone.Service;

import com.example.Sapo_Clone.Entity.Notification;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import java.util.List;

public interface NotificationService {
    Notification createNotification(Notification notification);
    void markAsRead(int notificationId);
    Page<Notification> getNotificationsForUser(int userId, String role, int companyId, Pageable pageable);
    List<Notification> getAllNotificationsForUser(int userId, String role, int companyId);
}

