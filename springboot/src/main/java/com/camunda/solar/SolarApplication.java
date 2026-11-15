package com.camunda.solar;

import io.camunda.zeebe.spring.client.annotation.Deployment;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
@Deployment(resources = {"classpath*:models/*.bpmn", "classpath*:models/*.dmn", "classpath*:models/*.form"})
public class SolarApplication {

    public static void main(String[] args) {
        SpringApplication.run(SolarApplication.class, args);
    }
}
