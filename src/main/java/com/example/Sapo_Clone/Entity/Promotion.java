package com.example.Sapo_Clone.Entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "promotions")
@Data
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = lombok.AccessLevel.PRIVATE)
public class Promotion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    int id;

    @Column(name = "promotion_name")
    String promotionName;

    @Column(name = "discount_percent")
    double discountPercent;

    @Column(name = "created_at")
    LocalDateTime createdAt;

    @Column(name = "ended_at")
    LocalDateTime endedAt;

    @ManyToOne
    @JoinColumn(name = "company_id")
    Company company;

    @ManyToMany
    @JoinTable(
        name = "promotion_products",
        joinColumns = @JoinColumn(name = "promotion_id"),
        inverseJoinColumns = @JoinColumn(name = "product_id")
    )
    List<Product> products;

    @OneToMany(mappedBy = "promotion")
    List<Order> orders;
}
