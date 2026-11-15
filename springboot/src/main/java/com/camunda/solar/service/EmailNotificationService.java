package com.camunda.solar.service;

import org.springframework.stereotype.Service;
import java.time.Instant;
import java.util.*;
import java.util.concurrent.CopyOnWriteArrayList;

@Service
public class EmailNotificationService {

    public static class EmailMessage {
        private String id;
        private String recipient;
        private String subject;
        private String body;
        private String timestamp;
        private String type;

        public EmailMessage(String id, String recipient, String subject, String body, String type) {
            this.id = id;
            this.recipient = recipient;
            this.subject = subject;
            this.body = body;
            this.timestamp = Instant.now().toString();
            this.type = type;
        }

        public String getId() { return id; }
        public String getRecipient() { return recipient; }
        public String getSubject() { return subject; }
        public String getBody() { return body; }
        public String getTimestamp() { return timestamp; }
        public String getType() { return type; }
    }

    private final List<EmailMessage> sentEmails = new CopyOnWriteArrayList<>();

    public void recordEmail(String recipient, String subject, String body, String type) {
        EmailMessage msg = new EmailMessage(UUID.randomUUID().toString(), recipient, subject, body, type);
        sentEmails.add(0, msg);
    }

    public List<EmailMessage> getSentEmails() {
        return Collections.unmodifiableList(sentEmails);
    }

    public void clear() {
        sentEmails.clear();
    }
}
