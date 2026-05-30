package com.example.Sapo_Clone.Schedule;

import com.example.Sapo_Clone.Entity.EmailVerification;
import com.example.Sapo_Clone.Entity.User;
import com.example.Sapo_Clone.Repository.EmailVerificationRepository;
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

    @Scheduled(fixedRate = 900000)
    @Transactional
    public void deleteUserNotActiveAfter15 (){
        log.info("Running the deleteUserNotActiveAfter15min");
        List<EmailVerification> list = emailVerificationRepository.findAll();
        for (EmailVerification e : list){
            if (e.getExpiresAt().isBefore(LocalDateTime.now())){
            if (userRepository.existsByUserEmailAndCompany_Id(e.getEmail(), e.getCompany().getId())) {
                User user = userRepository.findByUserEmailAndCompany_Id(e.getEmail(), e.getCompany().getId()).get();
                if (user.getUserStatus() == 2) {
                    userRepository.delete(user);
                }
                emailVerificationRepository.delete(e);
                } else {
                emailVerificationRepository.delete(e);
            }
            }
            }
        }

}
