package com.example.Sapo_Clone.DTO.Response.User;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class UserInfoResponse{
    int id;
    String userFullName;
    String userEmail;
    String userName;
    String userPhone;
    String userAddress;
    int userStatus;
    String roleName;
}