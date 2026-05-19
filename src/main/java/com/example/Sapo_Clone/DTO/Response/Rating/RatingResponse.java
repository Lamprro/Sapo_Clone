package com.example.Sapo_Clone.DTO.Response.Rating;

import com.example.Sapo_Clone.Entity.Rating;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

import java.time.LocalDateTime;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
@FieldDefaults(level = lombok.AccessLevel.PRIVATE)
public class RatingResponse {
    int id;
    int rating;
    String comment;
    int userId;
    String userFullName;
    LocalDateTime updatedAt;
    int productId;

    public static RatingResponse fromEntity(Rating rating) {
        if (rating == null) return null;
        return RatingResponse.builder()
                .id(rating.getId())
                .rating(rating.getRating())
                .comment(rating.getComment())
                .userId(rating.getUser().getId())
                .userFullName(rating.getUser().getUserFullName())
                .updatedAt(rating.getUpdatedAt())
                .productId(rating.getProduct().getId())
                .build();
    }
}
