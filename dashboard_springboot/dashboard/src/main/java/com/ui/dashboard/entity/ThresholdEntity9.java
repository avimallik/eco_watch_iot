package com.ui.dashboard.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "TBL_THRESHOLD")
public class ThresholdEntity9 {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ID")
    private Long id;

    @Column(name = "THRESH_TEMP")
    private Double threshTemp;

    @Column(name = "THRESH_MQ2")
    private Double threshMq2;

    public Long getId() { return id; }

    public Double getThreshTemp() { return threshTemp; }
    public void setThreshTemp(Double threshTemp) { this.threshTemp = threshTemp; }

    public Double getThreshMq2() { return threshMq2; }
    public void setThreshMq2(Double threshMq2) { this.threshMq2 = threshMq2; }

}
