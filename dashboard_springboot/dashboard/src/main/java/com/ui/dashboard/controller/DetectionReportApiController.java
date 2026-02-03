package com.ui.dashboard.controller;

import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
public class DetectionReportApiController {

    private final JdbcTemplate jdbcTemplate;

    public DetectionReportApiController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping(value = "/api/detection-report", produces = MediaType.APPLICATION_JSON_VALUE)
    public List<Map<String, Object>> getDetectionReport() {

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

        // clean JSON keys
        return rows.stream().map(r -> {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", r.get("ID"));
            m.put("detected_temp", r.get("DETECTED_TEMP"));
            m.put("detected_mq2", r.get("DETECTED_MQ2"));
            m.put("date", r.get("DETECT_DATE"));   // YYYY-MM-DD
            m.put("time", r.get("DETECT_TIME"));   // 12-hr + AM/PM
            m.put("status", r.get("DETECTED_STATUS"));
            return m;
        }).toList();
    }
}
