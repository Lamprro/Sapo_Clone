package com.example.Sapo_Clone.DTO.Request.User;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class UserCreationRequest {
    @NotBlank(message = "Full name is required")
    String userFullName;

    @NotBlank(message = "Email is required")
    @Email(message = "Invalid email format")
    String userEmail;

    @Size(min = 3, message = "Username must be at least 5 characters")
    @NotBlank(message = "Username is required")
    String userName;

    @NotBlank(message = "Password is required")
    @Size(min = 6, message = "Password must be at least 6 characters")
    @Pattern(
            regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[@$!%*?&#])[A-Za-z\\d@$!%*?&#]{8,}$",
            message = "Password must contain at least 1 uppercase letter, 1 lowercase letter, 1 number, and 1 special character"
    )
    String userPassword;

    @NotBlank(message = "Phone is required")
    @Size(min = 10, message = "Phone number must be at least 10 digits")
    @Pattern(
            regexp = "^(0|\\+84)(\\s|\\.)?((3[2-9])|(5[689])|(7[06-9])|(8[1-689])|(9[0-46-9]))(\\d)(\\s|\\.)?(\\d{3})(\\s|\\.)?(\\d{3})$",
            message = "Invalid phone number format"
    )
    String userPhone;

    @NotBlank(message = "Address is required")
    String userAddress;

    int userStatus = 0;
    int rolesId;
    int companyId;
    int storeId;

}
