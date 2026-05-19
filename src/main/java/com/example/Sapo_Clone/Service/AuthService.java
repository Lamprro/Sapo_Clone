package com.example.Sapo_Clone.Service;

import com.example.Sapo_Clone.DTO.Request.LoginSignup.LoginRequest;
import com.example.Sapo_Clone.DTO.Request.LoginSignup.SignUpRequest;
import com.example.Sapo_Clone.DTO.Response.User.LoginSignUp.LoginResponse;
import com.example.Sapo_Clone.DTO.Response.User.UserResponse;

public interface AuthService {

    LoginResponse login(LoginRequest dto);

    UserResponse signup(SignUpRequest dto);

    void logout(String token);
}
