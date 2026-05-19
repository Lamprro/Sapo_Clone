package com.example.Sapo_Clone.Service;

import com.example.Sapo_Clone.DTO.Response.Coordinates;
import com.example.Sapo_Clone.DTO.Response.GoongGeocodingResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

@Service
@Slf4j
public class MapService {
    @Autowired
    private WebClient goongWebClient;

    @Value("${map.api.key}")
    private String apiKey;

    public Coordinates getCoordinatesFromAddress(String address) {
        try {
            GoongGeocodingResponse response = goongWebClient.get()
                .uri(uriBuilder -> uriBuilder
                    .path("/geocode")
                    .queryParam("address", address)
                    .queryParam("api_key", apiKey)
                    .build())
                .retrieve()
                .bodyToMono(GoongGeocodingResponse.class)
                .block(); // Đợi kết quả để phục vụ logic nghiệp vụ ngay lập tức

            if (response != null && response.getResults() != null && !response.getResults().isEmpty()) {
                var loc = response.getResults().get(0).getGeometry().getLocation();
                return new Coordinates(loc.getLat(), loc.getLng());
            }
        } catch (Exception e) {
            log.error("Lỗi gọi Goong API: {}", e.getMessage());
        }
        return null;
    }
}