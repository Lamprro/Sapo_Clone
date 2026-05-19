package com.example.Sapo_Clone.Entity;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.EqualsAndHashCode;
import lombok.ToString;
import lombok.experimental.FieldDefaults;

import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "promotions")
@Data
@AllArgsConstructor
@NoArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class Promotion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    int id;

    @Column(name = "promotion_name", columnDefinition = "NVARCHAR(255)")
    String promotionName;

    @Column(name = "description", columnDefinition = "TEXT")
    String description;

    @Column(name = "scope")
    int scope; // 0: Invoice, 1: Specific Product

    @Column(name = "discount_type")
    int discountType; // 0: Flat amount, 1: Percentage

    @Column(name = "discount_value")
    double discountValue; // Ex: 10% or 50,000 VND

    @Column(name = "min_account")
    double minAccount; // Minimum purchase required to apply

    @Column(name = "max_account")
    double maxAccount; // Max discount allowed for percentage (e.g. 50k for 10%)

    @Column(name = "status")
    int status; // 0: Inactive, 1: Active, 2: Outdated

    @Column(name = "created_at")
    LocalDateTime createdAt;

    @Column(name = "started_at")
    LocalDateTime startedAt;

    @Column(name = "ended_at")
    LocalDateTime endedAt;

    @EqualsAndHashCode.Exclude
    @ToString.Exclude
    @ManyToOne
    @JoinColumn(name = "company_id")
    Company company;

    @EqualsAndHashCode.Exclude
    @ToString.Exclude
    @ManyToMany
    @JoinTable(name = "promotion_product", joinColumns = @JoinColumn(name = "promotion_id"), inverseJoinColumns = @JoinColumn(name = "product_id"))
    List<Product> products;

    @EqualsAndHashCode.Exclude
    @ToString.Exclude
    @OneToMany(mappedBy = "promotion")
    List<Order> orders;

    @PrePersist
    public void onCreate() {
        createdAt = LocalDateTime.now();
    }
}