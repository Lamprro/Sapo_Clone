package com.example.Sapo_Clone.Config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.reactive.function.client.WebClient;

@Configuration
public class WebClientConfig {
    @Value("${goong.api.base-url:https://rsapi.goong.io}")
    private String baseUrl;

    @Bean
    public WebClient goongWebClient(WebClient.Builder builder) {
        return builder.baseUrl(baseUrl).build();
    }
}