package com.example.Sapo_Clone.Entity;

import com.example.Sapo_Clone.Enum.NotificationType;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "notification")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Notification {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    private String title;
    
    @Column(columnDefinition = "NVARCHAR(MAX)")
    private String message;

    @Enumerated(EnumType.STRING)
    private NotificationType type;

    private Integer targetUserId; // Null if broadcast to role

    private String targetRole; // e.g., CUSTOMER, MANAGER, EMPLOYEE, ADMIN

    private boolean isRead = false;

    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
