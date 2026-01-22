package com.ui.dashboard.controller;

import com.ui.dashboard.entity.ThresholdEntity9;
import com.ui.dashboard.repository.ThresholdRepository9;
import com.ui.dashboard.web.ThresholdForm;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

@Controller
@RequestMapping("/threshold")
public class ThresholdStorageController {

    
   private final JdbcTemplate jdbcTemplate;

    public ThresholdStorageController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping
    public String showForm(Model model) {
        model.addAttribute("thresholdForm", new ThresholdForm());
        return "threshold-form";
    }

    @PostMapping("/save")
    public String save(@ModelAttribute ThresholdForm thresholdForm, Model model) {
        try {
            String sql = "INSERT INTO TBL_THRESHOLD (THRESH_TEMP, THRESH_MQ2) VALUES (?, ?)";
            jdbcTemplate.update(sql,
                    thresholdForm.getTemperatureThreshold(),
                    thresholdForm.getMq2Threshold()
            );

            model.addAttribute("message", "Threshold saved successfully!");
            model.addAttribute("thresholdForm", new ThresholdForm());
            return "threshold-form";

        } catch (Exception e) {
            // Friendly error message
            model.addAttribute("error", "DB insert failed: " + e.getMessage());
            model.addAttribute("thresholdForm", thresholdForm);
            return "threshold-form";
        }
    }
    
}
