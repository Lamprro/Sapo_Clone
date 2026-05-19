package com.example.Sapo_Clone.Service;

public interface TokenBlacklistService {
    void blacklistToken(String token, long remainingSeconds);
    boolean isBlacklisted(String token);
}
