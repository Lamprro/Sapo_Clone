package com.example.Sapo_Clone.Service.Impl;

import com.example.Sapo_Clone.Entity.EmailVerification;
import com.example.Sapo_Clone.Entity.User;
import com.example.Sapo_Clone.Exception.AppException;
import com.example.Sapo_Clone.Exception.ErrorCode;
import com.example.Sapo_Clone.Repository.EmailVerificationRepository;
import com.example.Sapo_Clone.Repository.UserRepository;
import com.example.Sapo_Clone.Service.EmailVerificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Random;
import java.util.concurrent.CompletableFuture;

@Service
@RequiredArgsConstructor
@Slf4j
public class EmailVerificationServiceImpl implements EmailVerificationService {

    private final EmailVerificationRepository emailVerificationRepository;
    private final UserRepository userRepository;
    private final JavaMailSender mailSender;

    @Value("${email.verification.ttl:15}")
    private int ttlMinutes;

    @Override
    @Transactional
    public CompletableFuture<Void> sendVerificationCode(String email) {
        User user = userRepository.findByUserEmail(email)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));
        if (user.getUserStatus() == 1) {
            throw new AppException(ErrorCode.USER_ALREADY_EXISTS);
        }
        String code = String.format("%06d", new Random().nextInt(1000000));
        
        EmailVerification verification = emailVerificationRepository.findByEmail(email)
                .orElse(EmailVerification.builder().email(email).build());
        
        verification.setCode(code);
        verification.setExpiresAt(LocalDateTime.now().plusMinutes(ttlMinutes));
        verification.setAttempts(0);
        
        emailVerificationRepository.save(verification);
        
        return sendEmailAsync(email, code);
    }

    private CompletableFuture<Void> sendEmailAsync(String email, String code) {
        return CompletableFuture.runAsync(() -> {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setTo(email);
            message.setSubject("Sapo_Clone - Xác nhận email của bạn");
            message.setText("Mã xác nhận của bạn là: " + code + "\nMã này sẽ hết hạn sau " + ttlMinutes + " phút.");
            
            try {
                mailSender.send(message);
                log.info("Email verification sent to {}", email);
            } catch (Exception e) {
                log.error("Failed to send email to {}: {}", email, e.getMessage());
                // In a real app, you might want to throw an exception here
            }
        });
    }

    @Override
    @Transactional
    public boolean verifyCode(String email, String code) {
        EmailVerification verification = emailVerificationRepository.findByEmailAndCode(email, code)
                .orElseThrow(() -> new AppException(ErrorCode.VALIDATION_ERROR, "Mã xác nhận không đúng hoặc đã hết hạn"));

        if (verification.getExpiresAt().isBefore(LocalDateTime.now())) {
            emailVerificationRepository.delete(verification);
            throw new AppException(ErrorCode.VALIDATION_ERROR, "Mã xác nhận đã hết hạn");
        }

        User user = userRepository.findByUserEmail(email)
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));

        user.setUserStatus(1); // ACTIVE
        userRepository.save(user);

        emailVerificationRepository.delete(verification);
        log.info("User {} verified successfully", email);
        return true;
    }
}
