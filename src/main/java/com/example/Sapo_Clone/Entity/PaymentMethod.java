package com.example.Sapo_Clone.Entity;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

@Entity
@Table(name = "payment_methods")
@Data
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class PaymentMethod {
    @Id
    int id; // 0 for Money, 1 for Banking

    @Column(name = "name", nullable = false, length = 50)
    String name;
}
