package com.example.Sapo_Clone.Service;

import com.example.Sapo_Clone.DTO.Request.Rating.RatingCreateDTO;
import com.example.Sapo_Clone.DTO.Request.Rating.RatingUpdateDTO;
import com.example.Sapo_Clone.DTO.Response.Rating.RatingResponse;
import org.springframework.data.domain.Page;

import java.util.List;

public interface RatingService {
    RatingResponse createRating(RatingCreateDTO dto);
    
    RatingResponse updateRating(int ratingId, RatingUpdateDTO dto);
    
    RatingResponse changeStatus(int ratingId, int status);
    
    Page<RatingResponse> getByProduct(int productId, int page, int size);
    
    List<RatingResponse> getByUser();
    
    void deleteRating(int ratingId);
    
    void updateProductAverageStar(int productId);
}
