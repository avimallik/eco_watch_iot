package com.ui.dashboard.controller;

import com.ui.dashboard.api.LoginRequest;
import com.ui.dashboard.api.LoginResponse;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class FlutterAuthController {
     private final JdbcTemplate jdbcTemplate;
    private final PasswordEncoder passwordEncoder;

    @Value("${app.jwt.secret}")
    private String SECRET;

    @Value("${app.jwt.expSeconds:28800}")
    private long EXP_SECONDS;

    public FlutterAuthController(JdbcTemplate jdbcTemplate, PasswordEncoder passwordEncoder) {
        this.jdbcTemplate = jdbcTemplate;
        this.passwordEncoder = passwordEncoder;
    }

    @PostMapping(value = "/login", consumes = MediaType.APPLICATION_JSON_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
    public LoginResponse login(@RequestBody LoginRequest req) {

        String email = req.getEmail() == null ? "" : req.getEmail().trim();
        String password = req.getPassword() == null ? "" : req.getPassword();

        if (email.isEmpty() || password.isEmpty()) {
            throw new RuntimeException("Email and password required");
        }

        // get hashed password from DB
        Map<String, Object> row = jdbcTemplate.queryForMap(
                "SELECT PASSWORD FROM TBL_USER WHERE EMAIL = ?",
                email
        );

        String dbHash = row.get("PASSWORD") == null ? "" : row.get("PASSWORD").toString();

        // match raw password vs bcrypt hash
        if (!passwordEncoder.matches(password, dbHash)) {
            throw new RuntimeException("Invalid email or password");
        }

        // create JWT token using SAME secret as EspStatusController
        byte[] key = SECRET.getBytes(StandardCharsets.UTF_8);
        long now = System.currentTimeMillis();

        String token = Jwts.builder()
                .subject(email)
                .issuedAt(new Date(now))
                .expiration(new Date(now + (EXP_SECONDS * 1000)))
                .signWith(Keys.hmacShaKeyFor(key), Jwts.SIG.HS256)
                .compact();

        return new LoginResponse(token);
    }
}
