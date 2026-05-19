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
@Table(name = "orders") // Changed to "orders" because "order" is a reserved keyword in SQL
@Data
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class Order {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    int id;

    @Column(name = "total_amount", nullable = false)
    double totalAmount = 0.0;

    @Column(name = "earn_point")
    int earnPoint;

    @Column(name = "redeem_point")
    int redeemPoint;

    @Column(name = "status", nullable = false)
    int status = 0; // 0: PENDING, 1: CONFIRMED, 2: SHIPPING, 3: COMPLETED, 4: CANCELLED

    @Column(name = "payment_status", nullable = false)
    int paymentStatus = 0; // 0: UNPAID, 1: PAID, 2: FAILED, 3: REFUNDED

    @Column(name = "payment_method", nullable = false)
    String paymentMethod;

    @Column(name = "shipping_address", columnDefinition = "NVARCHAR(MAX)")
    String shippingAddress;

    @Column(name = "note", columnDefinition = "NVARCHAR(MAX)")
    String note;

    @Column(name = "created_at", updatable = false)
    LocalDateTime createdAt;

    @Column(name = "updated_at")
    LocalDateTime updatedAt;

    @EqualsAndHashCode.Exclude
    @ToString.Exclude
    @ManyToOne
    @JoinColumn(name = "customer_id", nullable = false)
    User customer; // User placing the order

    @EqualsAndHashCode.Exclude
    @ToString.Exclude
    @ManyToOne
    @JoinColumn(name = "employee_id") // Can be null if order is placed online by customer
    User employee; // Employee who processed the order (if placed in store)

    @EqualsAndHashCode.Exclude
    @ToString.Exclude
    @ManyToOne
    @JoinColumn(name = "store_id", nullable = false) // An order must belong to a store
    Store store;

    @EqualsAndHashCode.Exclude
    @ToString.Exclude
    @ManyToOne
    @JoinColumn(name = "promotion_id")
    Promotion promotion;

    @EqualsAndHashCode.Exclude
    @ToString.Exclude
    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, orphanRemoval = true)
    List<OrderDetail> orderDetails;

    @PrePersist
    public void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    public void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}