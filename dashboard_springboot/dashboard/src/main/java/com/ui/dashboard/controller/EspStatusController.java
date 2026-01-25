package com.ui.dashboard.controller;

import com.ui.dashboard.api.EspReading;
import com.ui.dashboard.api.StatusResponse;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
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

    public EspStatusController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping(value = "/api/esp/status", produces = MediaType.APPLICATION_JSON_VALUE)
    public List<Map<String, Object>> status() {

       
        String espIp = jdbcTemplate.queryForObject(
                "SELECT IP FROM TBL_ESP_IP WHERE ID = (SELECT MAX(ID) FROM TBL_ESP_IP)",
                String.class
        );
        if (espIp == null || espIp.trim().isEmpty()) {
            throw new RuntimeException("No ESP IP found in TBL_ESP_IP");
        }
        espIp = espIp.trim();


        String url = espIp ;

        EspReading reading = webClient.get()
                .uri(url)
                .accept(MediaType.APPLICATION_JSON)
                .retrieve()
                .bodyToMono(EspReading.class)
                .timeout(Duration.ofSeconds(3))
                .block();

        if (reading == null) {
            throw new RuntimeException("ESP returned empty response");
        }

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

        return List.of(out); 
    }

    private Double toDouble(Object v) {
        if (v == null) return null;
        if (v instanceof Number n) return n.doubleValue();
        try { return Double.parseDouble(v.toString()); }
        catch (Exception e) { return null; }
    }
}
