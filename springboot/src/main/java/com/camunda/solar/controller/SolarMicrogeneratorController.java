package com.camunda.solar.controller;

import com.camunda.solar.service.EmailNotificationService;
import io.camunda.zeebe.client.ZeebeClient;
import io.camunda.zeebe.client.api.response.ProcessInstanceEvent;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api/solar")
@CrossOrigin(origins = "*")
public class SolarMicrogeneratorController {

    @Autowired(required = false)
    private ZeebeClient zeebeClient;

    @Autowired
    private EmailNotificationService emailService;

    public static class ConnectionRequestPayload {
        public String installerName;
        public String applicantEmail;
        public Double systemCapacityKwp;
        public Double transformerUtilizationPercent;
        public Double voltageRisePercent;
        public String processDefinitionId;
    }

    @PostMapping("/connection-request")
    public ResponseEntity<Map<String, Object>> submitConnectionRequest(@RequestBody ConnectionRequestPayload payload) {
        String procDefId = (payload.processDefinitionId != null && !payload.processDefinitionId.isEmpty())
                ? payload.processDefinitionId
                : "Process_Applicant_RealMail";

        Map<String, Object> variables = new HashMap<>();
        variables.put("installerName", payload.installerName != null ? payload.installerName : "Hans Mueller Solar GmbH");
        variables.put("applicantEmail", payload.applicantEmail != null ? payload.applicantEmail : "installer@solarpv.de");
        variables.put("systemCapacityKwp", payload.systemCapacityKwp != null ? payload.systemCapacityKwp : 9.8);
        variables.put("transformerUtilizationPercent", payload.transformerUtilizationPercent != null ? payload.transformerUtilizationPercent : 65.0);
        variables.put("voltageRisePercent", payload.voltageRisePercent != null ? payload.voltageRisePercent : 1.8);

        Map<String, Object> response = new HashMap<>();
        try {
            if (zeebeClient != null) {
                ProcessInstanceEvent instance = zeebeClient.newCreateInstanceCommand()
                        .bpmnProcessId(procDefId)
                        .latestVersion()
                        .variables(variables)
                        .send()
                        .join();

                response.put("success", true);
                response.put("processInstanceKey", instance.getProcessInstanceKey());
                response.put("processDefinitionKey", instance.getProcessDefinitionKey());
                response.put("bpmnProcessId", instance.getBpmnProcessId());
                response.put("version", instance.getVersion());
                response.put("message", "Solar microgenerator application initiated successfully in Camunda 8");
            } else {
                response.put("success", true);
                response.put("processInstanceKey", System.currentTimeMillis());
                response.put("message", "Simulated launch (mock mode)");
            }
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("success", false);
            response.put("error", e.getMessage());
            return ResponseEntity.status(500).body(response);
        }
    }

    @GetMapping("/emails")
    public ResponseEntity<List<EmailNotificationService.EmailMessage>> getEmails() {
        return ResponseEntity.ok(emailService.getSentEmails());
    }

    @PostMapping("/tasks/{taskId}/complete")
    public ResponseEntity<Map<String, Object>> completeTask(@PathVariable String taskId, @RequestBody Map<String, Object> variables) {
        Map<String, Object> response = new HashMap<>();
        try {
            String baseUrl = "http://localhost:8080/v2/user-tasks/" + taskId + "/completion";
            org.springframework.web.client.RestTemplate restTemplate = new org.springframework.web.client.RestTemplate();
            
            org.springframework.http.HttpHeaders headers = new org.springframework.http.HttpHeaders();
            headers.setContentType(org.springframework.http.MediaType.APPLICATION_JSON);
            headers.setBasicAuth("demo", "demo");

            Map<String, Object> body = new HashMap<>();
            body.put("variables", variables);

            org.springframework.http.HttpEntity<Map<String, Object>> entity = new org.springframework.http.HttpEntity<>(body, headers);
            restTemplate.postForEntity(baseUrl, entity, String.class);

            response.put("success", true);
            response.put("message", "Task " + taskId + " completed successfully");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("success", false);
            response.put("error", e.getMessage());
            return ResponseEntity.status(500).body(response);
        }
    }
}
