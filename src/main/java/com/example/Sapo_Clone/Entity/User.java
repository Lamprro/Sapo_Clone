package com.example.Sapo_Clone.Entity;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldDefaults;

import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "users", uniqueConstraints = {
        @UniqueConstraint(columnNames = { "username", "company_id" }),
        @UniqueConstraint(columnNames = { "user_email", "company_id" }),
        @UniqueConstraint(columnNames = { "user_phone", "company_id" })
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = lombok.AccessLevel.PRIVATE)
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    int id;

    @Column(name = "user_full_name", nullable = false, columnDefinition = "NVARCHAR(255)")
    String userFullName;

    @Column(name = "user_email", columnDefinition = "NVARCHAR(255)")
    String userEmail;

    @Column(name = "username", nullable = false, columnDefinition = "NVARCHAR(255)")
    String username;

    @Column(name = "password", nullable = false, columnDefinition = "NVARCHAR(255)")
    String password;

    @Column(name = "user_phone", columnDefinition = "NVARCHAR(255)")
    String userPhone;

    @Column(name = "user_address", columnDefinition = "NVARCHAR(255)")
    String userAddress;

    @Column(name = "user_status", nullable = false)
    int userStatus = 1;

    @Column(name = "created_at", updatable = false)
    LocalDateTime createdAt;

    @Column(name = "updated_at")
    LocalDateTime updatedAt;

    @EqualsAndHashCode.Exclude
    @ToString.Exclude
    @ManyToOne
    @JoinColumn(name = "roles_id", nullable = false)
    Roles roles;

    @EqualsAndHashCode.Exclude
    @ToString.Exclude
    @OneToOne(cascade = CascadeType.ALL, orphanRemoval = true, mappedBy = "user")
    Point point;

    @EqualsAndHashCode.Exclude
    @ToString.Exclude
    @ManyToOne
    @JoinColumn(name = "company_id")
    Company company;

    @EqualsAndHashCode.Exclude
    @ToString.Exclude
    @ManyToOne
    @JoinColumn(name = "store_id")
    Store store;

    @EqualsAndHashCode.Exclude
    @ToString.Exclude
    @OneToOne(mappedBy = "user", cascade = CascadeType.ALL, orphanRemoval = true)
    Cart cart;

    @EqualsAndHashCode.Exclude
    @ToString.Exclude
    @OneToMany(mappedBy = "user")
    List<Rating> ratings;

    @EqualsAndHashCode.Exclude
    @ToString.Exclude
    @OneToMany(mappedBy = "customer")
    List<Order> customerOrders;

    @EqualsAndHashCode.Exclude
    @ToString.Exclude
    @OneToMany(mappedBy = "employee")
    List<Order> employeeOrders;

    @EqualsAndHashCode.Exclude
    @ToString.Exclude
    @OneToMany(mappedBy = "user")
    List<PurchaseOrder> purchaseOrders;

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