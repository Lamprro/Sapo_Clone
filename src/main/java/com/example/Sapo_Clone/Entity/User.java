package com.example.Sapo_Clone.Entity;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldDefaults;

import java.util.List;

@Entity
@Table(name = "users")
@Data
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = lombok.AccessLevel.PRIVATE)
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    int id;

    @Column(name = "user_full_name")
    String userFullName;

    @Column(name = "user_email")
    String userEmail;

    @Column(name = "user_name")
    String userName;

    @Column(name = "user_password")
    String userPassword;

    @Column(name = "user_phone")
    String userPhone;

    @Column(name = "user_address")
    String userAddress;

    @Column(name = "user_status")
    int userStatus;


    @ManyToOne
    @JoinColumn(name = "roles_id")
    Roles roles;

    @OneToOne
    @JoinColumn(name = "point_id")
    Point point;

    @ManyToOne
    @JoinColumn(name = "company_id")
    Company company;

    @ManyToOne
    @JoinColumn(name = "store_id")
    Store store;


    @OneToMany(mappedBy = "user")
    List<Cart> cartList;

    @OneToMany(mappedBy = "user")
    List<Rating> ratings;

    @OneToMany(mappedBy = "customer")
    List<Order> customerOrders;

    @OneToMany(mappedBy = "employee")
    List<Order> employeeOrders;

    @OneToMany(mappedBy = "user")
    List<PurchaseOrder> purchaseOrders;
}
