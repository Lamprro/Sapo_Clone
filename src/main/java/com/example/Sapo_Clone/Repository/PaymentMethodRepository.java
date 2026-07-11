package com.example.Sapo_Clone.Repository;

import com.example.Sapo_Clone.Entity.PaymentMethod;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface PaymentMethodRepository extends JpaRepository<PaymentMethod, Integer> {
    Optional<PaymentMethod> findByName(String name);
}
