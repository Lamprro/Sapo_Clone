package com.example.Sapo_Clone.DTO.Request.User;

import jakarta.validation.constraints.NotBlank;

import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

@Data
@AllArgsConstructor
@NoArgsConstructor
@FieldDefaults(level = lombok.AccessLevel.PRIVATE)
public class ChangePasswordRequest {
    int id;
    @NotBlank(message = "Old password is required")
    String oldPassword;

    @NotBlank(message = "New password cannot be blank")
    String newPassword;

    @NotBlank(message = "Confirm password is required")
    String confirmPassword;

}
