package com.example.Sapo_Clone.Exception;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum ErrorCode {

    // 400 - Bad Request
    CATCH(400, "Catch error"),
    VALIDATION_ERROR(400, "Invalid input data"),
    PASSWORD_MISMATCH(400, "Passwords do not match"),
    INVALID_STATUS(400, "Invalid status (0: inactive, 1: active, 2: banned)"),
    INVALID_PRODUCT_STATUS(400, "Invalid product status. Must be 0 (inactive) or 1 (active)"),
    OUT_OF_STOCK(400, "Product is out of stock in this store"),
    INSUFFICIENT_STOCK(400, "Insufficient stock available"),
    ORDER_LOCKED(400, "Order cannot be modified in its current status"),
    INSUFFICIENT_POINTS(400, "Insufficient loyalty points"),
    INVALID_IMAGE(400, "Invalid image format or size"),
    STORE_REQUIRED(400, "Store is required for employee accounts"),
    STORE_NOT_IN_COMPANY(400, "Store does not belong to the selected company"),
    INVALID_PASSWORD(400, "Incorrect password"),

    // 401 - Unauthorized
    UNAUTHORIZED(401, "You are not logged in or session has expired"),

    // 403 - Forbidden
    FORBIDDEN(403, "You do not have permission to perform this action"),
    USER_BANNED(403, "Account has been banned, please contact administrator"),
    EMAIL_CANNOT_BE_CHANGED(400, "Email address cannot be updated for customer accounts"),

    // 404 - Not Found
    LOGIN_NOT_FOUND(404, "Incorrect username or password, companyId"),
    USER_NOT_FOUND(404, "User not found"),
    ROLE_NOT_FOUND(404, "Role not found in system"),
    ALREADY_RATING(404, "You have already rated this product. Try again!"),
    PRODUCT_NOT_FOUND(404, "Product not found"),
    UNIT_NOT_FOUND(404, "Unit not found"),
    CATEGORY_NOT_FOUND(404, "One or more categories not found"),
    STORE_NOT_FOUND(404, "Store not found"),
    ADDRESS_NOT_FOUND(404, "Unable to resolve coordinates from address"),
    COMPANY_NOT_FOUND(404, "Company not found"),
    IMAGE_NOT_FOUND(404, "Image not found"),
    ORDER_NOT_FOUND(404, "Order not found"),
    PROMOTION_NOT_FOUND(404, "Promotion not found"),
    PROVIDER_NOT_FOUND(404, "Provider not found"),
    NOT_PURCHASED_YET(404, "Order haven't paid yet"),
    RATING_NOT_FOUND(404, "Rating not found"),
    PROMOTION_NOT_ACTIVE(404, "Promotion is not available"),
    EMAIL_NOT_MATCH(404, "Email not match"),
    EMAIL_NOT_VERIFIED(403, "Account not activated. Please verify your email."),

    // 409 - Conflict
    PHONE_ALREADY_EXISTS(409, "Phone number already in use"),
    EMAIL_ALREADY_EXISTS(409, "Email already in use"),
    USERNAME_ALREADY_EXISTS(409, "Username already in use"),
    BARCODE_ALREADY_EXISTS(409, "Barcode already exists"),
    PROVIDER_ALREADY_EXISTS(409, "Provider Code (UEI) or Phone already exists in the system"),
    USER_ALREADY_EXISTS(409, "User with this email already exists"),

    // 500 - Internal Server Error
    INTERNAL_SERVER_ERROR(500, "System error, please try again later"),
    CLOUD_UPLOAD_FAIL(500, "Failed to upload file to cloud storage");

    private final int httpCode;
    private final String message;
}
