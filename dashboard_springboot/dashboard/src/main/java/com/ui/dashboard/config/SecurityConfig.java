package com.ui.dashboard.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.web.SecurityFilterChain;

import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;

import java.nio.charset.StandardCharsets;

@Configuration
public class SecurityConfig {

    @Value("${app.jwt.secret}")
    private String SECRET;

    @Bean
    public JwtDecoder jwtDecoder() {
        byte[] keyBytes = SECRET.getBytes(StandardCharsets.UTF_8);
        SecretKey key = new SecretKeySpec(keyBytes, "HmacSHA256");
        return NimbusJwtDecoder.withSecretKey(key).build();
    }

    @Bean
    @Order(1)
    public SecurityFilterChain apiChain(HttpSecurity http) throws Exception {
        http.securityMatcher("/api/**");

        http.csrf(csrf -> csrf.disable());

        http.authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/auth/login").permitAll()

                // ✅ public detection report API (no JWT needed)
                .requestMatchers("/api/detection-report/**").permitAll()

                // existing
                .requestMatchers("/api/esp/status").authenticated()

                .anyRequest().authenticated()
        );

        // Bearer token validate
        http.oauth2ResourceServer(oauth2 -> oauth2.jwt(j -> {}));

        // JSON 401
        http.exceptionHandling(e -> e.authenticationEntryPoint((req, res, ex) -> {
            res.setStatus(401);
            res.setContentType("application/json");
            res.getWriter().write("{\"error\":\"Unauthorized\"}");
        }));

        return http.build();
    }

    @Bean
    @Order(2)
    public SecurityFilterChain publicChain(HttpSecurity http) throws Exception {
        http.csrf(csrf -> csrf.disable());
        http.authorizeHttpRequests(auth -> auth.anyRequest().permitAll());
        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder(12);
    }
}
