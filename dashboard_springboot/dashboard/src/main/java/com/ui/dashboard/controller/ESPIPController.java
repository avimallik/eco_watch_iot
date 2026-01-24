package com.ui.dashboard.controller;

import com.ui.dashboard.web.EspIpForm;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

@Controller
@RequestMapping("/esp-ip")
public class ESPIPController {
    private final JdbcTemplate jdbcTemplate;

    public ESPIPController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping
    public String showForm(Model model) {
        model.addAttribute("espIpForm", new EspIpForm());
        return "esp-ip-form";
    }

    @PostMapping("/save")
    public String save(@ModelAttribute EspIpForm espIpForm, Model model) {
        try {
            String ip = espIpForm.getIp();

            // optional: whitespace trim
            if (ip != null) ip = ip.trim();

            String sql = "INSERT INTO TBL_ESP_IP (IP) VALUES (?)";
            jdbcTemplate.update(sql, ip);

            model.addAttribute("message", "ESP IP saved successfully!");
            model.addAttribute("espIpForm", new EspIpForm());
            return "esp-ip-form";

        } catch (Exception e) {
            model.addAttribute("error", "DB insert failed: " + e.getMessage());
            model.addAttribute("espIpForm", espIpForm);
            return "esp-ip-form";
        }
    }
}
