package com.example.Sapo_Clone.DTO.Request.User;

import jakarta.validation.constraints.*;
import lombok.Data;

@Data
public class UserCreateDTO {

    @NotBlank(message = "Full name cannot be blank")
    private String fullName;

    @NotBlank(message = "Phone number cannot be blank")
    @Pattern(regexp = "^(0[35789][0-9]{8})$", message = "Invalid Vietnamese phone number format (must start with 03, 05, 07, 08, 09)")
    private String phone;

    @NotBlank(message = "Email cannot be blank")
    @Email(message = "Invalid email format")
    private String email;

    @NotBlank(message = "Username cannot be blank")
    private String username;

    @NotBlank(message = "Password cannot be blank")
    private String password;

    @NotNull(message = "Company Id cannot be blank")
    private Integer companyId;

    @NotBlank(message = "Address cannot be blank")
    private String address;

    private Integer storeId;

    private Integer roleId;

}