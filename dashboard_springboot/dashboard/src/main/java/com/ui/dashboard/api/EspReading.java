package com.ui.dashboard.api;

public class EspReading {
    private Double temperature;
    private Double humidity;
    private Double mq2;

    public Double getTemperature() { return temperature; }
    public void setTemperature(Double temperature) { this.temperature = temperature; }

    public Double getHumidity() { return humidity; }
    public void setHumidity(Double humidity) { this.humidity = humidity; }

    public Double getMq2() { return mq2; }
    public void setMq2(Double mq2) { this.mq2 = mq2; }
}
