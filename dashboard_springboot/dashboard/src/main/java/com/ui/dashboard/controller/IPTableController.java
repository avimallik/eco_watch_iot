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
@RequestMapping("/esp-ip")
public class IPTableController {

    private final JdbcTemplate jdbcTemplate;

    public IPTableController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping("/table")
    public String showIpTable(Model model) {

        String sql = "SELECT * FROM TBL_ESP_IP ORDER BY 1 DESC";

        List<Map<String, Object>> rows = jdbcTemplate.queryForList(sql);
        model.addAttribute("rows", rows);

        return "ip-table";
    }

    @PostMapping("/delete")
    public String deleteIp(@RequestParam("ip") String ip, RedirectAttributes ra) {
        try {
            String sql = "DELETE FROM TBL_ESP_IP WHERE IP = ?";
            int affected = jdbcTemplate.update(sql, ip);

            if (affected > 0) {
                ra.addFlashAttribute("message", "Deleted: " + ip);
            } else {
                ra.addFlashAttribute("error", "No row found for IP: " + ip);
            }

        } catch (Exception e) {
            ra.addFlashAttribute("error", "Delete failed: " + e.getMessage());
        }

        return "redirect:/esp-ip/table";
    }
    
}
