package com.example.Sapo_Clone.Service.Impl;

import com.example.Sapo_Clone.Entity.Notification;
import com.example.Sapo_Clone.Repository.NotificationRepository;
import com.example.Sapo_Clone.Service.NotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationServiceImpl implements NotificationService {

    private final NotificationRepository notificationRepository;
    private final SimpMessagingTemplate messagingTemplate;

    @Override
    @Transactional
    public Notification createNotification(Notification notification) {
        Notification saved = notificationRepository.save(notification);
        
        // Push via WebSocket
        if (saved.getTargetUserId() != null) {
            // Push to specific user
            messagingTemplate.convertAndSendToUser(
                saved.getTargetUserId().toString(), 
                "/topic/notifications", 
                saved
            );
        } else if (saved.getTargetRole() != null) {
            // Push to all users with role
            messagingTemplate.convertAndSend(
                "/topic/role/" + saved.getTargetRole(), 
                saved
            );
        } else {
            // Broadcast to all
            messagingTemplate.convertAndSend("/topic/public", saved);
        }
        
        return saved;
    }

    @Override
    @Transactional
    public void markAsRead(int notificationId) {
        notificationRepository.findById(notificationId).ifPresent(n -> {
            n.setRead(true);
            notificationRepository.save(n);
        });
    }

    @Override
    public Page<Notification> getNotificationsForUser(int userId, String role, Pageable pageable) {
        pageable = PageRequest.of(pageable.getPageNumber(), pageable.getPageSize(), Sort.by(Sort.Direction.DESC, "createdAt"));
        return notificationRepository.findByTargetUserIdOrTargetRole(userId, role, pageable);
    }
}
