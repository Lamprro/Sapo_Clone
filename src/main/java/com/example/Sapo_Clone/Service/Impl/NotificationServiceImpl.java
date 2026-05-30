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
    @Transactional(propagation = org.springframework.transaction.annotation.Propagation.REQUIRES_NEW)
    public Notification createNotification(Notification notification) {
        log.info("Attempting to create notification with title: '{}', companyId: {}", notification.getTitle(), notification.getCompanyId());
        Notification saved = notificationRepository.save(notification);
        log.info("Saved notification to DB, assigned ID: {}", saved.getId());
        
        // Push via WebSocket
        if (saved.getTargetUserId() != null) {
            log.info("Pushing unicast WebSocket notification to targetUserId={}", saved.getTargetUserId());
            // Push to specific user (since userId is globally unique)
            messagingTemplate.convertAndSendToUser(
                saved.getTargetUserId().toString(), 
                "/topic/notifications", 
                saved
            );
        } else if (saved.getTargetRole() != null) {
            log.info("Pushing multicast WebSocket notification to companyId={} role={}", saved.getCompanyId(), saved.getTargetRole());
            // Push to all users in this company with this role
            messagingTemplate.convertAndSend(
                "/topic/company/" + (saved.getCompanyId() != null ? saved.getCompanyId() : 0) + "/role/" + saved.getTargetRole(), 
                saved
            );
        } else {
            log.info("Pushing broadcast WebSocket notification to companyId={}", saved.getCompanyId());
            // Broadcast to all in this company
            messagingTemplate.convertAndSend(
                "/topic/company/" + (saved.getCompanyId() != null ? saved.getCompanyId() : 0) + "/public", 
                saved
            );
        }
        
        return saved;
    }

    @Override
    @Transactional
    public void markAsRead(int notificationId) {
        log.info("Marking notification ID: {} as READ", notificationId);
        notificationRepository.findById(notificationId).ifPresent(n -> {
            n.setRead(true);
            notificationRepository.saveAndFlush(n);
            log.info("Notification ID: {} successfully updated as READ", notificationId);
        });
    }

    @Override
    public Page<Notification> getNotificationsForUser(int userId, String role, int companyId, Pageable pageable) {
        log.info("Fetching notifications page for userId={}, role='{}', companyId={}, page={}, size={}", 
                userId, role, companyId, pageable.getPageNumber(), pageable.getPageSize());
        pageable = PageRequest.of(pageable.getPageNumber(), pageable.getPageSize(), Sort.by(Sort.Direction.DESC, "createdAt"));
        return notificationRepository.findByUserAndCompany(userId, role, companyId, pageable);
    }
}
