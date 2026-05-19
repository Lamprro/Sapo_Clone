package com.example.Sapo_Clone.Utils;

import com.example.Sapo_Clone.Security.UserPrincipal;
import org.springframework.security.core.context.SecurityContextHolder;
public class SecurityUtils {

    public static UserPrincipal getCurrentUser() {
        if (SecurityContextHolder.getContext().getAuthentication() == null) {
            return null;
        }
        Object principal = SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        if (principal instanceof UserPrincipal) {
            return (UserPrincipal) principal;
        }
        return null;
    }

    public static int getCurrentCompanyId() {
        UserPrincipal user = getCurrentUser();
        return (user != null && user.getCompanyId() != null) ? user.getCompanyId() : 0;
    }

    public static int getCurrentUserId() {
        UserPrincipal user = getCurrentUser();
        return user != null ? user.getId() : 0;
    }

    public static String getCurrentRole() {
        UserPrincipal user = getCurrentUser();
        // Trả về chuỗi rỗng thay vì null để an toàn cho các biểu thức SpEL
        return user != null && user.getRole() != null ? user.getRole() : "";
    }

    public static int getCurrentStoreId(){
        UserPrincipal user = getCurrentUser();
        return (user != null && user.getStoreId() != null) ? user.getStoreId() : 0;
    }
}
