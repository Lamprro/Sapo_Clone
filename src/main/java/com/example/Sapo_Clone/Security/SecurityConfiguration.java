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
                // Public: login, signup, websockets
                .requestMatchers("/api/auth/**").permitAll()
                .requestMatchers("/ws/**").permitAll()
                
                // Public GET endpoints for registration/lookup
                .requestMatchers(HttpMethod.GET, "/api/company").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/company/**").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/category/**").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/unit/**").permitAll()

                // User management
                // forgot-password: PUBLIC — user chưa đăng nhập nên không có token
                .requestMatchers(HttpMethod.PATCH, "/api/user/forgot-password").permitAll()
                .requestMatchers(HttpMethod.PUT, "/api/user/profile").authenticated()
                .requestMatchers(HttpMethod.PATCH, "/api/user/password").authenticated()
                .requestMatchers(HttpMethod.POST, "/api/user/**").hasAnyRole("ADMIN", "MANAGER")
                .requestMatchers(HttpMethod.GET, "/api/user/**").hasAnyRole("ADMIN", "MANAGER", "EMPLOYEE")
                .requestMatchers(HttpMethod.PATCH, "/api/user/**").hasAnyRole("ADMIN", "MANAGER")

                // Company management
                .requestMatchers(HttpMethod.POST, "/api/company/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.PUT, "/api/company/**").hasRole("ADMIN")
                .requestMatchers(HttpMethod.DELETE, "/api/company/**").hasRole("ADMIN")

                // Store management
                .requestMatchers(HttpMethod.GET, "/api/store/**").authenticated()
                .requestMatchers(HttpMethod.POST, "/api/store/**").hasAnyRole("ADMIN", "MANAGER")
                .requestMatchers(HttpMethod.PUT, "/api/store/**").hasAnyRole("ADMIN", "MANAGER")
                .requestMatchers(HttpMethod.DELETE, "/api/store/**").hasAnyRole("ADMIN", "MANAGER")

                // Product management
                .requestMatchers(HttpMethod.GET, "/api/product/**").authenticated()
                .requestMatchers(HttpMethod.POST, "/api/product/**").hasAnyRole("ADMIN", "MANAGER", "EMPLOYEE")
                .requestMatchers(HttpMethod.PUT, "/api/product/**").hasAnyRole("ADMIN", "MANAGER", "EMPLOYEE")
                .requestMatchers(HttpMethod.DELETE, "/api/product/**").hasAnyRole("ADMIN", "MANAGER", "EMPLOYEE")
                .requestMatchers(HttpMethod.POST, "/api/product_image/**").hasAnyRole("ADMIN", "MANAGER", "EMPLOYEE")

                // Order management
                .requestMatchers(HttpMethod.POST, "/api/order/**").hasAnyRole("ADMIN", "MANAGER", "EMPLOYEE", "CUSTOMER")
                .requestMatchers(HttpMethod.GET, "/api/order/**").hasAnyRole("ADMIN", "MANAGER", "EMPLOYEE", "CUSTOMER")
                .requestMatchers(HttpMethod.PUT, "/api/order/**").hasAnyRole("ADMIN", "MANAGER", "EMPLOYEE")
                .requestMatchers(HttpMethod.PATCH, "/api/order/*/status").hasAnyRole("ADMIN", "MANAGER", "EMPLOYEE", "CUSTOMER")
                .requestMatchers(HttpMethod.PATCH, "/api/order/*/payment").hasAnyRole("ADMIN", "MANAGER", "EMPLOYEE")

                // Purchase order, provider & inventory management
                .requestMatchers("/api/purchase_order/**").hasAnyRole("ADMIN", "MANAGER", "EMPLOYEE")
                .requestMatchers("/api/provider/**").hasAnyRole("ADMIN", "MANAGER", "EMPLOYEE")
                .requestMatchers("/api/inventory/**").hasAnyRole("ADMIN", "MANAGER", "EMPLOYEE")

                // Rating moderation
                .requestMatchers(HttpMethod.PATCH, "/api/rating/*/status").hasAnyRole("ADMIN", "MANAGER")
                .requestMatchers(HttpMethod.DELETE, "/api/rating/*").hasAnyRole("ADMIN", "MANAGER", "EMPLOYEE", "CUSTOMER")

                // All other endpoints require authentication
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
