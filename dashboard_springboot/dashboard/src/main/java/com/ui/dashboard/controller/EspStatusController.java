package com.ui.dashboard.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ui.dashboard.api.EspReading;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.reactive.function.client.WebClient;

import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
public class EspStatusController {

    private final JdbcTemplate jdbcTemplate;
    private final WebClient webClient = WebClient.builder().build();
    private final ObjectMapper objectMapper = new ObjectMapper();

    public EspStatusController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping(value = "/api/esp/status", produces = MediaType.APPLICATION_JSON_VALUE)
    public List<Map<String, Object>> status(@AuthenticationPrincipal Jwt jwt) {

        // endpoint authenticated()
        try {
            // last URL from DB
            String url = jdbcTemplate.queryForObject(
                    "SELECT IP FROM TBL_ESP_IP WHERE ID = (SELECT MAX(ID) FROM TBL_ESP_IP)",
                    String.class
            );

            if (url == null || url.trim().isEmpty()) {
                return List.of(err("No URL in TBL_ESP_IP last row"));
            }
            url = url.trim();

            if (!url.startsWith("http://") && !url.startsWith("https://")) {
                url = "http://" + url;
            }

            // call ESP URL
            String body = webClient.get()
                    .uri(url)
                    .accept(MediaType.APPLICATION_JSON)
                    .retrieve()
                    .bodyToMono(String.class)
                    .timeout(Duration.ofSeconds(6))
                    .block();

            if (body == null || body.isBlank()) {
                Map<String, Object> m = err("Empty response from ESP URL");
                m.put("url", url);
                return List.of(m);
            }

            String trimmed = body.trim();
            if (looksLikeHtml(trimmed)) {
                Map<String, Object> m = err("ESP URL returned HTML, not JSON");
                m.put("url", url);
                m.put("preview", preview(trimmed, 250));
                return List.of(m);
            }

            EspReading reading = objectMapper.readValue(trimmed, EspReading.class);

            // last thresholds
            Map<String, Object> th = jdbcTemplate.queryForMap(
                    "SELECT THRESH_TEMP, THRESH_MQ2 FROM TBL_THRESHOLD WHERE ID = (SELECT MAX(ID) FROM TBL_THRESHOLD)"
            );

            Double threshTemp = toDouble(th.get("THRESH_TEMP"));
            Double threshMq2  = toDouble(th.get("THRESH_MQ2"));

            Double currentTemp = reading.getTemperature();
            Double currentHum  = reading.getHumidity();
            Double currentMq2  = reading.getMq2();

            int statusTemp = (currentTemp != null && threshTemp != null && currentTemp > threshTemp) ? 1 : 0;
            int statusMq2  = (currentMq2  != null && threshMq2  != null && currentMq2  > threshMq2)  ? 1 : 0;

            Map<String, Object> out = new LinkedHashMap<>();
            out.put("current_temparature", currentTemp);
            out.put("current_humidity", currentHum);
            out.put("current_mq2", currentMq2);

            out.put("threshold_temparature", threshTemp);
            out.put("threshold_mq2", threshMq2);

            out.put("status_temparature", statusTemp);
            out.put("status_mq2", statusMq2);

            // optional: user email
            out.put("user", jwt.getSubject());

            return List.of(out);

        } catch (Exception e) {
            Map<String, Object> m = err("ESP status failed");
            m.put("message", e.getMessage());
            return List.of(m);
        }
    }

    private boolean looksLikeHtml(String s) {
        String x = s.toLowerCase();
        return x.startsWith("<!doctype") || x.startsWith("<html") || x.contains("<head") || x.contains("<body");
    }

    private String preview(String s, int max) {
        String clean = s.replace("\n", " ").replace("\r", " ");
        return clean.length() <= max ? clean : clean.substring(0, max) + "...";
    }

    private Map<String, Object> err(String msg) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("error", "ESP status failed");
        m.put("message", msg);
        return m;
    }

    private Double toDouble(Object v) {
        if (v == null) return null;
        if (v instanceof Number n) return n.doubleValue();
        try { return Double.parseDouble(v.toString()); }
        catch (Exception e) { return null; }
    }
}
