package com.example.Sapo_Clone.DTO.Response.User.LoginSignUp;

import com.example.Sapo_Clone.DTO.Response.User.UserResponse;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LoginResponse {
    private String token;
    private UserResponse user;
}