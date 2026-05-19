package com.example.Sapo_Clone.Schedule;

import com.example.Sapo_Clone.Entity.Notification;
import com.example.Sapo_Clone.Enum.NotificationType;
import com.example.Sapo_Clone.Service.NotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@Slf4j
public class NotificationEventListener {

    private final NotificationService notificationService;

    // We can define custom events or use maps/generic events.
    // For now, let's assume we have a generic event for simplicity or handle specific ones.

    @Async
    @EventListener
    public void handleNotificationEvent(Notification notification) {
        log.info("Processing notification event: {}", notification.getTitle());
        notificationService.createNotification(notification);
    }
}
