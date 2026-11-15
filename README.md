# Smart Grid Solar Microgenerator Connection Approval (`smart_grid_solar_microgenerator`)

[![Camunda 8](https://img.shields.io/badge/Camunda-8.8-orange.svg)](https://camunda.com/)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.2.4-brightgreen.svg)](https://spring.io/projects/spring-boot)
[![Java](https://img.shields.io/badge/Java-21-blue.svg)](https://www.oracle.com/java/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

An enterprise-grade, end-to-end full-stack workflow automation solution inspired by German Distribution System Operator (**Netze BW / EnBW**) statutory guidelines under **EEG § 8** and technical standard **VDE-AR-N 4105**.

---

## 1. Project Overview

This repository satisfies both **Milestone 1** (BPMN Design & Architecture) and **Milestone 2** (Full-Stack Integration, Spring Boot & Frontend Submission).

* **Applicant / Installer Lane**: Technical Documentation preparation, digital Netzanfrage REST API submission, solar PV installation, VDE-AR-N 4105 safety verification, and Federal Marktstammdatenregister (MaStR) legal registration.
* **Distribution System Operator (Netze BW DSO) Lane**: Automated application validation, DMN grid feeder capacity & voltage rise assessment, automated approval/rejection email notifications, commissioning review, bidirectional smart meter (iMSys) deployment, and grid energization.

---

## 2. Repository Structure

```
smart_grid_solar_microgenerator/
├── bpmn/
│   ├── smart_grid_solar_microgenerator.bpmn          # Core BPMN 2.0 collaboration model
│   ├── smart_grid_solar_microgenerator_real_mail.bpmn# Real Mail Send Task BPMN model
│   ├── grid_capacity_rules.dmn                       # VDE-AR-N 4105 DMN Decision Table
│   └── forms/                                        # Camunda 8 Forms schemas
│       ├── form_prepare_technical_docs.form
│       ├── form_install_pv_modules.form
│       ├── form_verify_safety_compliance.form
│       ├── form_verify_commissioning_protocols.form
│       ├── form_mastr_registration.form
│       └── form_install_smart_meter.form
├── springboot/                                       # Spring Boot 3 Backend
│   ├── pom.xml
│   └── src/main/
│       ├── java/com/camunda/solar/
│       │   ├── SolarApplication.java                 # Main Spring Boot Runner
│       │   ├── controller/SolarMicrogeneratorController.java # REST APIs
│       │   ├── worker/SolarGridWorkers.java          # External Zeebe Job Workers
│       │   └── service/EmailNotificationService.java # Notification Tracker
│       └── resources/
│           ├── application.properties
│           └── static/index.html                     # Embedded Web Dashboard
├── frontend/
│   └── index.html                                    # Standalone Web Dashboard UI
├── test-scripts/                                     # PowerShell automated tests
│   ├── test-approval-flow.ps1                        # Tests full approval path to "Microgenerator Active"
│   ├── test-rejection-flow.ps1                       # Tests feeder overload rejection path
│   ├── test-exception-flow.ps1                       # Tests REST API error boundary event
│   ├── test-real-mail-flow.ps1                       # Tests live email dispatch flow
│   └── test-real-mail-rejection-flow.ps1
├── start-app.bat                                     # 1-Click Spring Boot & Frontend launcher
├── push-to-github.bat                                # 1-Click GitHub push script
└── README.md
```

---

## 3. DMN Feasibility Rules (`grid_capacity_rules.dmn`)

| Rule | PV Peak Capacity (`systemCapacityKwp`) | Transformer Utilization (`transformerUtilizationPercent`) | Feeder Voltage Rise (`voltageRisePercent`) | Result (`approvalStatus`) | Grid Feasible |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Rule 1 (Approved)** | $\le 30 \text{ kWp}$ | $\le 80\%$ | $\le 3.0\%$ | `"APPROVED"` | `true` |
| **Rule 2 (Reject Overload)** | `-` | $> 80\%$ | `-` | `"REJECTED"` | `false` |
| **Rule 3 (Reject Voltage)** | `-` | `-` | $> 3.0\%$ | `"REJECTED"` | `false` |
| **Rule 4 (Reject Large Scale)**| $> 30 \text{ kWp}$ | `-` | `-` | `"REJECTED"` | `false` |

---

## 4. How to Run the Application

### 1-Click Startup
Double-click `start-app.bat` or run:
```bash
cd springboot
mvn spring-boot:run
```

Open your browser to:
* **Web Dashboard**: [http://localhost:8085](http://localhost:8085)
* **Camunda Operate**: [http://localhost:8080/operate](http://localhost:8080/operate) (`demo` / `demo`)
* **Camunda Tasklist**: [http://localhost:8080/tasklist](http://localhost:8080/tasklist) (`demo` / `demo`)

---

## 5. Author & Evaluation
* **Student**: Vishnu (`vishnu564-eb`)
* **Repository**: `https://github.com/vishnu564-eb/smart_grid_solar_microgenerator`
* **Course**: Workflow Automation & BPMN Integration
* **Instructor**: Kishore Anthuvan Sahayaraj K
* **Submissions**: Milestone 1 (BPMN/DMN) & Milestone 2 (Full-Stack Spring Boot + Frontend)
