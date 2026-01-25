package com.ui.dashboard.api;

public class StatusResponse {
    private Double currentTemperature;
    private Double currentHumidity;
    private Double currentMq2;

    private Double thresholdTemperature;
    private Double thresholdMq2;

    private Integer statusTemperature; // 1 or 0
    private Integer statusMq2;         // 1 or 0

    public Double getCurrentTemperature() { return currentTemperature; }
    public void setCurrentTemperature(Double v) { this.currentTemperature = v; }

    public Double getCurrentHumidity() { return currentHumidity; }
    public void setCurrentHumidity(Double v) { this.currentHumidity = v; }

    public Double getCurrentMq2() { return currentMq2; }
    public void setCurrentMq2(Double v) { this.currentMq2 = v; }

    public Double getThresholdTemperature() { return thresholdTemperature; }
    public void setThresholdTemperature(Double v) { this.thresholdTemperature = v; }

    public Double getThresholdMq2() { return thresholdMq2; }
    public void setThresholdMq2(Double v) { this.thresholdMq2 = v; }

    public Integer getStatusTemperature() { return statusTemperature; }
    public void setStatusTemperature(Integer v) { this.statusTemperature = v; }

    public Integer getStatusMq2() { return statusMq2; }
    public void setStatusMq2(Integer v) { this.statusMq2 = v; }
}
