package com.ui.dashboard.controller;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.List;
import java.util.Map;

@Controller
@RequestMapping("/register")
public class RegisteredUserController {

    private final JdbcTemplate jdbcTemplate;

    public RegisteredUserController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping("/users")
    public String showRegisteredUsers(Model model) {

        String sql = "SELECT EMAIL, FULL_NAME FROM TBL_USER ORDER BY EMAIL";
        List<Map<String, Object>> rows = jdbcTemplate.queryForList(sql);

        model.addAttribute("rows", rows);
        return "registered-users";
    }

    @PostMapping("/users/delete")
    public String deleteUser(@RequestParam("email") String email,
                         RedirectAttributes ra) {
    try {
        String sql = "DELETE FROM TBL_USER WHERE EMAIL = ?";
        int affected = jdbcTemplate.update(sql, email);

        if (affected > 0) {
            ra.addFlashAttribute("message", "Deleted user: " + email);
        } else {
            ra.addFlashAttribute("error", "No user found for email: " + email);
        }

    } catch (Exception e) {
        ra.addFlashAttribute("error", "Delete failed: " + e.getMessage());
    }
        return "redirect:/register/users";
    }

}
