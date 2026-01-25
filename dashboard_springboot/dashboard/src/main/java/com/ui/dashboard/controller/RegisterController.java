package com.ui.dashboard.controller;

import com.ui.dashboard.web.RegisterForm;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

@Controller
@RequestMapping("/register")
public class RegisterController {
   private final JdbcTemplate jdbcTemplate;
    private final PasswordEncoder encoder;

    public RegisterController(JdbcTemplate jdbcTemplate, PasswordEncoder encoder) {
        this.jdbcTemplate = jdbcTemplate;
        this.encoder = encoder;
    }

    @GetMapping
    public String show(Model model) {
        model.addAttribute("registerForm", new RegisterForm());
        return "register";
    }

    @PostMapping
    public String register(@ModelAttribute RegisterForm registerForm, Model model) {
        try {
            String fullName = safeTrim(registerForm.getFullName());
            String email = safeTrim(registerForm.getEmail());
            String password = registerForm.getPassword();

            if (fullName.isEmpty() || email.isEmpty() || password == null || password.isBlank()) {
                model.addAttribute("error", "All fields are required.");
                model.addAttribute("registerForm", registerForm);
                return "register";
            }

            Integer cnt = jdbcTemplate.queryForObject(
                    "SELECT COUNT(1) FROM TBL_USER WHERE LOWER(TRIM(EMAIL)) = LOWER(TRIM(?))",
                    Integer.class,
                    email
            );

            if (cnt != null && cnt > 0) {
                model.addAttribute("error", "This email is already registered.");
                model.addAttribute("registerForm", registerForm);
                return "register";
            }

            String hashedPassword = encoder.encode(password);

            jdbcTemplate.update(
                    "INSERT INTO TBL_USER (EMAIL, PASSWORD, FULL_NAME) VALUES (?, ?, ?)",
                    email, hashedPassword, fullName
            );

            // register করার পর login page এ পাঠালে convenient
            return "redirect:/login?registered";

        } catch (Exception e) {
            model.addAttribute("error", "Registration failed: " + e.getMessage());
            model.addAttribute("registerForm", registerForm);
            return "register";
        }
    }

    private String safeTrim(String s) {
        return s == null ? "" : s.trim();
    }
}
