package com.example.Sapo_Clone.Security;

import com.example.Sapo_Clone.Security.Jwt.JwtFilter;
import com.example.Sapo_Clone.Service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.http.HttpMethod;
import org.springframework.web.cors.CorsConfiguration;

import java.util.Arrays;
import java.util.List;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity // CRITICAL: Enables @PreAuthorize on controllers
@RequiredArgsConstructor
public class SecurityConfiguration {

    private final JwtFilter jwtFilter;
    private final UserService userService;

    @Value("${app.security.allowed-origins:http://localhost:3000,http://localhost:5173}")
    private List<String> allowedOrigins;

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public AuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider authProvider = new DaoAuthenticationProvider();
        authProvider.setUserDetailsService(userService);
        authProvider.setPasswordEncoder(passwordEncoder());
        return authProvider;
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {

        // 1. CORS
        http.cors(cors -> cors.configurationSource(request -> {
            CorsConfiguration corsConfig = new CorsConfiguration();
            corsConfig.setAllowedOriginPatterns(allowedOrigins);
            corsConfig.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
            corsConfig.addAllowedHeader("*");
            corsConfig.setAllowCredentials(true);
            return corsConfig;
        }));

        // 2. Disable CSRF (stateless JWT — no sessions)
        http.csrf(AbstractHttpConfigurer::disable);

        // 3. Authorization rules
        http.authorizeHttpRequests(auth -> auth
                // Public: login and signup — no token required
                .requestMatchers("/api/auth/**").permitAll()
                .requestMatchers("/ws/**").permitAll() // WebSocket endpoint
                .requestMatchers(("/api/**")).permitAll()
//                .requestMatchers("/api/auth/**").permitAll()
//                .requestMatchers(HttpMethod.GET,"/api/company").permitAll()
//
//                // User management
//                .requestMatchers(HttpMethod.PUT, "/api/user/profile").authenticated()
//                .requestMatchers(HttpMethod.PATCH, "/api/user/password").authenticated()
//                .requestMatchers(HttpMethod.POST, "/api/user").hasAnyRole("ADMIN", "MANAGER", "EMPLOYEE")
//                .requestMatchers(HttpMethod.GET, "/api/user").hasAnyRole("ADMIN", "MANAGER", "EMPLOYEE")
//                .requestMatchers(HttpMethod.PATCH, "/api/user/*").hasAnyRole("ADMIN", "MANAGER")
//
//                // Order management
//                .requestMatchers(HttpMethod.POST, "/api/order").hasAnyRole("ADMIN", "MANAGER", "EMPLOYEE", "CUSTOMER")
//                .requestMatchers(HttpMethod.GET, "/api/order/**").hasAnyRole("ADMIN", "MANAGER", "EMPLOYEE", "CUSTOMER")
//                .requestMatchers(HttpMethod.PUT, "/api/order/**").hasAnyRole("ADMIN", "MANAGER", "EMPLOYEE")
//                .requestMatchers(HttpMethod.PATCH, "/api/order/*/status").hasAnyRole("ADMIN", "MANAGER", "EMPLOYEE","CUSTOMER")
//                .requestMatchers(HttpMethod.PATCH, "/api/order/*/payment").hasAnyRole("ADMIN", "MANAGER", "EMPLOYEE")
//
//                // Purchase order management
//                .requestMatchers("/api/purchase_order/**").hasAnyRole("ADMIN", "MANAGER", "EMPLOYEE")
//
//                // Rating moderation
//                .requestMatchers(HttpMethod.PATCH, "/api/rating/*/status").hasAnyRole("ADMIN", "MANAGER")
//                .requestMatchers(HttpMethod.DELETE, "/api/rating/*").hasAnyRole("ADMIN", "MANAGER", "EMPLOYEE","CUSTOMER")

                // Everything else requires a valid JWT. Specific role checks are handled via
                // @PreAuthorize in controllers.
                .anyRequest().authenticated());

        // 4. Stateless session — no HttpSession
        http.sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS));

        // 5. Custom auth provider (DaoAuthenticationProvider + BCrypt)
        http.authenticationProvider(authenticationProvider());

        // 6. Run JwtFilter before Spring's UsernamePasswordAuthenticationFilter
        http.addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}
