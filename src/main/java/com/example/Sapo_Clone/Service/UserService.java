package com.example.Sapo_Clone.Service;

import com.example.Sapo_Clone.DTO.Request.User.ChangePasswordRequest;
import com.example.Sapo_Clone.DTO.Request.User.ForgotPasswordRequest;
import com.example.Sapo_Clone.DTO.Request.User.UpdateUserDTO;
import com.example.Sapo_Clone.DTO.Request.User.UserCreateDTO;
import com.example.Sapo_Clone.DTO.Response.User.UserResponse;
import com.example.Sapo_Clone.Entity.User;
import org.springframework.data.domain.Page;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;

public interface UserService extends UserDetailsService {

    User findByUserName(String username);

    @Override
    UserDetails loadUserByUsername(String username) throws UsernameNotFoundException;

    UserResponse createUser(UserCreateDTO dto);

    UserResponse updateStatus(int id, int status);

    Page<UserResponse> getList(String keyword, int page, int size);

    UserResponse updateProfile(UpdateUserDTO dto);

    void changePassword(ChangePasswordRequest request);

    void forgotPassword(ForgotPasswordRequest forgotPasswordRequest);
}
