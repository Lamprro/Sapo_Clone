package com.example.Sapo_Clone.Config;

import com.example.Sapo_Clone.Entity.PaymentMethod;
import com.example.Sapo_Clone.Repository.PaymentMethodRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@Slf4j
public class DatabaseSeeder implements CommandLineRunner {

    private final PaymentMethodRepository paymentMethodRepository;

    @Override
    public void run(String... args) throws Exception {
        log.info("Checking database seed data...");
        if (!paymentMethodRepository.existsById(0)) {
            paymentMethodRepository.save(new PaymentMethod(0, "Money"));
            log.info("Seeded PaymentMethod: 0 -> Money");
        }
        if (!paymentMethodRepository.existsById(1)) {
            paymentMethodRepository.save(new PaymentMethod(1, "Banking"));
            log.info("Seeded PaymentMethod: 1 -> Banking");
        }
    }
}
