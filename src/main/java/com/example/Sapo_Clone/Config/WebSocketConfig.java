package com.example.Sapo_Clone.Config;

import com.example.Sapo_Clone.Security.Jwt.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.config.ChannelRegistration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

import java.security.Principal;

@Configuration
@EnableWebSocketMessageBroker
@RequiredArgsConstructor
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    private final JwtService jwtService;

    public static class StompPrincipal implements Principal {
        private final String name;

        public StompPrincipal(String name) {
            this.name = name;
        }

        @Override
        public String getName() {
            return name;
        }
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        // Raw WebSocket endpoint used by the STOMP clients.
        registry.addEndpoint("/ws")
                .setAllowedOriginPatterns("*");
    }

    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        // Topic for broadcasting and User-specific queue
        config.enableSimpleBroker("/topic", "/queue");
        config.setApplicationDestinationPrefixes("/app");
        config.setUserDestinationPrefix("/user");
    }

    @Override
    public void configureClientInboundChannel(ChannelRegistration registration) {
        registration.interceptors(new ChannelInterceptor() {
            @Override
            public Message<?> preSend(Message<?> message, MessageChannel channel) {
                StompHeaderAccessor accessor =
                        MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);

                if (accessor != null && StompCommand.CONNECT.equals(accessor.getCommand())) {
                    System.out.println("STOMP CONNECT frame intercepted");
                    String authHeader = accessor.getFirstNativeHeader("Authorization");
                    if (authHeader == null) {
                        authHeader = accessor.getFirstNativeHeader("authorization");
                    }
                    System.out.println("authHeader: " + authHeader);
                    if (authHeader != null && authHeader.startsWith("Bearer ")) {
                        String jwt = authHeader.substring(7);
                        try {
                            String username = jwtService.extractUsername(jwt);
                            if (username != null) {
                                int userId = jwtService.extractId(jwt);
                                accessor.setUser(new StompPrincipal(String.valueOf(userId)));
                                System.out.println("STOMP Principal set to userId: " + userId);
                            }
                        } catch (Exception e) {
                            System.out.println("STOMP Connection Auth Error: " + e.getMessage());
                        }
                    } else {
                        System.out.println("STOMP CONNECT - No Bearer token found!");
                    }
                }
                return message;
            }
        });
    }
}
