package com.example.Sapo_Clone.Entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "email_verification", uniqueConstraints = {
    @UniqueConstraint(columnNames = { "email", "company_id", "purpose" })
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EmailVerification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(nullable = false)
    private String email;

    @Column(nullable = false, length = 6)
    private String code;

    @ManyToOne
    @JoinColumn(name = "company_id", nullable = false)
    private Company company;

    @Column(nullable = false)
    private LocalDateTime expiresAt;

    @Column(nullable = false)
    @Builder.Default
    private int attempts = 0;

    @Column(nullable = false)
    @Builder.Default
    private int purpose = 0; // 0: verifyEmail, 1: forgotPassword

    @Column(length = 255)
    private String newPassword;
}
