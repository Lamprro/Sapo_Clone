package com.example.Sapo_Clone.Controller;

import com.example.Sapo_Clone.Common.ApiResponse;
import com.example.Sapo_Clone.Entity.Notification;
import com.example.Sapo_Clone.Service.NotificationService;
import com.example.Sapo_Clone.Utils.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
@Slf4j
public class NotificationController {

    private final NotificationService notificationService;

    @GetMapping
    public ResponseEntity<ApiResponse<Page<Notification>>> getMyNotifications(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        
        int userId = SecurityUtils.getCurrentUserId();
        String role = SecurityUtils.getCurrentRole();
        
        log.info("Fetching notifications for userId={}, role={}", userId, role);
        
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Notification> notifications = notificationService.getNotificationsForUser(userId, role, pageable);
        
        return ResponseEntity.ok(ApiResponse.success("Success", notifications));
    }

    @PatchMapping("/{id}/read")
    public ResponseEntity<ApiResponse<Void>> markAsRead(@PathVariable int id) {
        notificationService.markAsRead(id);
        return ResponseEntity.ok(ApiResponse.success("Marked as read", null));
    }

    // Admin endpoint to broadcast system messages
    @PostMapping("/broadcast")
    public ResponseEntity<ApiResponse<Notification>> broadcast(
            @RequestParam String title,
            @RequestParam String message,
            @RequestParam(required = false) String targetRole) {
        
        Notification notification = Notification.builder()
                .title(title)
                .message(message)
                .type(com.example.Sapo_Clone.Enum.NotificationType.ADMIN_ALERT)
                .targetRole(targetRole != null ? targetRole : "ADMIN")
                .build();
        
        Notification saved = notificationService.createNotification(notification);
        return ResponseEntity.ok(ApiResponse.success("Broadcast sent", saved));
    }
}
