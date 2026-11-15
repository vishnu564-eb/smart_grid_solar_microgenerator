package com.camunda.solar.worker;

import com.camunda.solar.service.EmailNotificationService;
import io.camunda.zeebe.client.api.response.ActivatedJob;
import io.camunda.zeebe.spring.client.annotation.JobWorker;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.Map;

@Component
public class SolarGridWorkers {

    private static final Logger log = LoggerFactory.getLogger(SolarGridWorkers.class);

    @Autowired
    private EmailNotificationService emailService;

    @JobWorker(type = "submit-connection-request", autoComplete = true)
    public Map<String, Object> handleConnectionRequest(final ActivatedJob job) {
        Map<String, Object> vars = job.getVariablesAsMap();
        String installer = (String) vars.getOrDefault("installerName", "Certified Solar Partner");
        Object cap = vars.getOrDefault("systemCapacityKwp", 9.8);

        log.info("[Solar Worker] Digital Netzanfrage submitted for installer '{}', peak capacity: {} kWp", installer, cap);

        Map<String, Object> output = new HashMap<>();
        output.put("requestSubmitted", true);
        output.put("submissionTimestamp", java.time.Instant.now().toString());
        return output;
    }

    @JobWorker(type = "send-email", autoComplete = true)
    public Map<String, Object> handleSendEmail(final ActivatedJob job) {
        Map<String, Object> vars = job.getVariablesAsMap();
        String recipient = (String) vars.getOrDefault("applicantEmail", "installer@solarpv.de");
        String approvalStatus = (String) vars.getOrDefault("approvalStatus", "APPROVED");
        String elementId = job.getElementId();

        String subject;
        String body;
        String type;

        if ("task_Mail_Rejection".equalsIgnoreCase(elementId) || "REJECTED".equalsIgnoreCase(approvalStatus)) {
            type = "REJECTION";
            subject = "Netze BW: Technical Connection Rejection (Grid Feeder Constraints)";
            body = "Dear Applicant, your solar PV connection request could not be approved due to local distribution transformer or voltage rise limitations pursuant to VDE-AR-N 4105.";
        } else if ("task_Mail_Escalate".equalsIgnoreCase(elementId)) {
            type = "ESCALATION";
            subject = "Netze BW: Response SLA Escalation Reminder (7-Day Evaluation Window)";
            body = "Automated escalation notification: Evaluation window for Netzanfrage has exceeded statutory 7 days.";
        } else if ("task_Mail_Activation".equalsIgnoreCase(elementId)) {
            type = "ACTIVATION";
            subject = "Netze BW: Solar PV Connection Active & Energized in Smart Grid";
            body = "Congratulations! Your solar PV microgenerator is successfully energized with a bidirectional intelligent metering system (iMSys). Feed-in tariff metering is active.";
        } else {
            type = "APPROVAL";
            subject = "Netze BW: Netzanschlusszusage (Grid Connection Approval Certificate)";
            body = "Official connection confirmation: Point of common coupling approved for feed-in under standard low-voltage criteria.";
        }

        emailService.recordEmail(recipient, subject, body, type);
        log.info("[Email Worker] Sent '{}' email to '{}'", type, recipient);

        Map<String, Object> output = new HashMap<>();
        output.put("mailSent", true);
        output.put("mailType", type);
        return output;
    }

    @JobWorker(type = "arrange-smart-meter", autoComplete = true)
    public Map<String, Object> handleSmartMeter(final ActivatedJob job) {
        log.info("[Solar Worker] Deploying bidirectional smart meter (iMSys)...");
        Map<String, Object> output = new HashMap<>();
        output.put("smartMeterInstalled", true);
        output.put("smartMeterId", "IMS-BW-2026-" + System.currentTimeMillis() % 100000);
        return output;
    }
}
