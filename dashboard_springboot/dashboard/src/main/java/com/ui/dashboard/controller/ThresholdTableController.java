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
@RequestMapping("/threshold")
public class ThresholdTableController {

    private final JdbcTemplate jdbcTemplate;

    public ThresholdTableController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping("/table")
    public String showThresholdTable(Model model) {
        String sql = "SELECT ID, THRESH_TEMP, THRESH_MQ2 FROM TBL_THRESHOLD ORDER BY ID DESC";
        List<Map<String, Object>> rows = jdbcTemplate.queryForList(sql);

        model.addAttribute("rows", rows);
        return "threshold-table";
    }

    @PostMapping("/delete")
    public String deleteThreshold(@RequestParam("id") Long id,
                                RedirectAttributes ra) {
        try {
            String sql = "DELETE FROM TBL_THRESHOLD WHERE ID = ?";
            int affected = jdbcTemplate.update(sql, id);

            if (affected > 0) {
                ra.addFlashAttribute("message",
                        "Threshold entry deleted (ID=" + id + ")");
            } else {
                ra.addFlashAttribute("error",
                        "No threshold found for ID=" + id);
            }

        } catch (Exception e) {
            ra.addFlashAttribute("error",
                    "Delete failed: " + e.getMessage());
        }
        return "redirect:/threshold/table";
    }

}
