package com.example.Sapo_Clone.Service;

import java.util.concurrent.CompletableFuture;

public interface EmailVerificationService {
    CompletableFuture<Void> sendVerificationCode(String email);
    boolean verifyCode(String email, String code);
}
