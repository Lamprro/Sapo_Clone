package com.example.Sapo_Clone.Service;

import java.util.concurrent.CompletableFuture;

public interface EmailVerificationService {
    CompletableFuture<Void> sendVerificationCode(String email, int companyId);
    CompletableFuture<Void> sendVerificationCode(String email, int companyId, int purpose, String newPassword);
    boolean verifyCode(String email, String code, int companyId);
}
