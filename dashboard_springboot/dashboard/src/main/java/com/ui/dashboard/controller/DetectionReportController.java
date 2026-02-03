package com.ui.dashboard.controller;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

import java.util.List;
import java.util.Map;

@Controller
@RequestMapping("/detection-report")
public class DetectionReportController {

    private final JdbcTemplate jdbcTemplate;

    public DetectionReportController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping
    public String showReport(Model model) {

        // TIME column is a TIMESTAMP. We split into DATE and TIME strings for UI.
        // Note: If your column name TIME causes issues, use "TIME" with double quotes in SQL.
        String sql = """
            SELECT
              ID,
              DETECTED_TEMP,
              DETECTED_MQ2,
              TO_CHAR(TIME, 'YYYY-MM-DD') AS DETECT_DATE,
              TO_CHAR(TIME, 'HH:MI:SS AM') AS DETECT_TIME,
              DETECTED_STATUS
            FROM TBL_DETECTION_REPORT
            ORDER BY ID DESC
            """;

        List<Map<String, Object>> rows = jdbcTemplate.queryForList(sql);
        model.addAttribute("rows", rows);

        return "detection-report";
    }
}
