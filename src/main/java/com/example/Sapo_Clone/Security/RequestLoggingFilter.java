package com.example.Sapo_Clone.Security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.lang.NonNull;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
@Order(Ordered.LOWEST_PRECEDENCE)
@Slf4j
public class RequestLoggingFilter extends OncePerRequestFilter {

    @Override
    protected boolean shouldNotFilter(@NonNull HttpServletRequest request) {
        String uri = request.getRequestURI();
        return !uri.startsWith("/api") && !uri.startsWith("/ws");
    }

    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain
    ) throws ServletException, IOException {
        long startedAt = System.currentTimeMillis();

        try {
            filterChain.doFilter(request, response);
        } finally {
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            String principal = authentication != null && authentication.isAuthenticated()
                    ? String.valueOf(authentication.getPrincipal())
                    : "anonymous";
            String authorities = authentication != null ? String.valueOf(authentication.getAuthorities()) : "[]";
            boolean hasAuthorization = request.getHeader("Authorization") != null;
            long durationMs = System.currentTimeMillis() - startedAt;

            log.info(
                    "HTTP {} {} -> status={} durationMs={} authorizationHeader={} principal={} authorities={}",
                    request.getMethod(),
                    request.getRequestURI(),
                    response.getStatus(),
                    durationMs,
                    hasAuthorization,
                    principal,
                    authorities
            );
        }
    }
}
