package com.ui.dashboard.security;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.userdetails.*;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class DbUserDetailsService implements UserDetailsService {
    private final JdbcTemplate jdbcTemplate;

    public DbUserDetailsService(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        try {
            return jdbcTemplate.queryForObject(
                "SELECT EMAIL, PASSWORD FROM TBL_USER WHERE LOWER(TRIM(EMAIL)) = LOWER(TRIM(?))",
                (rs, rowNum) -> User.withUsername(rs.getString("EMAIL"))
                        .password(rs.getString("PASSWORD"))
                        .roles("USER")
                        .build(),
                email
            );
        } catch (Exception e) {
            throw new UsernameNotFoundException("User not found");
        }
    }
}
