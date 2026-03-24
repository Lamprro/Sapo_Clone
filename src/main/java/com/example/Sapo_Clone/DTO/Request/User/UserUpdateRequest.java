package com.example.Sapo_Clone.DTO.Request.User;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class UserUpdateRequest {
    int id;
    String userFullName;
    String userEmail;
    String userPhone;
    String userAddress;
    int userStatus;
}
