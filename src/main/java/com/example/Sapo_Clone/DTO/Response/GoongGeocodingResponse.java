package com.example.Sapo_Clone.DTO.Response;

import lombok.Data;
import java.util.List;

@Data
public class GoongGeocodingResponse {
    private List<Result> results;
    private String status;

    @Data
    public static class Result {
        private Geometry geometry;
    }

    @Data
    public static class Geometry {
        private Location location;
    }

    @Data
    public static class Location {
        private Double lat;
        private Double lng;
    }
}
