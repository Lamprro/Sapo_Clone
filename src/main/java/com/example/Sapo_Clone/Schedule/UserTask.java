package com.example.Sapo_Clone.Schedule;

import com.example.Sapo_Clone.Entity.EmailVerification;
import com.example.Sapo_Clone.Entity.User;
import com.example.Sapo_Clone.Repository.EmailVerificationRepository;
import com.example.Sapo_Clone.Repository.NotificationRepository;
import com.example.Sapo_Clone.Repository.OrderDetailRepository;
import com.example.Sapo_Clone.Repository.OrderRepository;
import com.example.Sapo_Clone.Repository.PurchaseOrderDetailRepository;
import com.example.Sapo_Clone.Repository.PurchaseOrderRepository;
import com.example.Sapo_Clone.Repository.RatingRepository;
import com.example.Sapo_Clone.Repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Component
@Slf4j
@RequiredArgsConstructor
public class UserTask {

    private final UserRepository userRepository;
    private final EmailVerificationRepository emailVerificationRepository;
    private final NotificationRepository notificationRepository;
    private final RatingRepository ratingRepository;
    private final OrderDetailRepository orderDetailRepository;
    private final OrderRepository orderRepository;
    private final PurchaseOrderDetailRepository purchaseOrderDetailRepository;
    private final PurchaseOrderRepository purchaseOrderRepository;

    @Scheduled(fixedRate = 900000)
    @Transactional
    public void deleteUserNotActiveAfter15() {
        log.info("Running the deleteUserNotActiveAfter15min");
        List<EmailVerification> list = emailVerificationRepository.findAll();
        for (EmailVerification e : list) {
            if (e.getExpiresAt().isBefore(LocalDateTime.now())) {
                if (userRepository.existsByUserEmailAndCompany_Id(e.getEmail(), e.getCompany().getId())) {
                    User user = userRepository.findByUserEmailAndCompany_Id(e.getEmail(), e.getCompany().getId()).get();
                    if (user.getUserStatus() == 2) {
                        deleteExpiredUnverifiedUserData(user);
                        userRepository.delete(user);
                        log.warn("Deleted expired unverified user id={}", user.getId());
                    }
                    emailVerificationRepository.delete(e);
                } else {
                    emailVerificationRepository.delete(e);
                }
            }
        }
    }

    private void deleteExpiredUnverifiedUserData(User user) {
        int userId = user.getId();
        log.warn("Deleting expired unverified user id={}, email={}, companyId={}",
                userId,
                user.getUserEmail(),
                user.getCompany() != null ? user.getCompany().getId() : null);

        int notifications = notificationRepository.deleteByTargetUserId(userId);
        int ratings = ratingRepository.deleteByUserId(userId);
        int orderDetails = orderDetailRepository.deleteByOrderCustomerOrEmployeeId(userId);
        int orders = orderRepository.deleteByCustomerOrEmployeeId(userId);
        int purchaseOrderDetails = purchaseOrderDetailRepository.deleteByPurchaseOrderUserId(userId);
        int purchaseOrders = purchaseOrderRepository.deleteByUserId(userId);

        log.warn("Deleted related data for expired unverified user id={}: notifications={}, ratings={}, orderDetails={}, orders={}, purchaseOrderDetails={}, purchaseOrders={}",
                userId,
                notifications,
                ratings,
                orderDetails,
                orders,
                purchaseOrderDetails,
                purchaseOrders);
    }

}
