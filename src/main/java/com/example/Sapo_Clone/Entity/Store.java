package com.example.Sapo_Clone.Entity;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldDefaults;

import java.util.List;

@Entity
@NoArgsConstructor
@AllArgsConstructor
@Data
@Table(name = "store")
@FieldDefaults(level = lombok.AccessLevel.PRIVATE)
public class Store {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    int id;

    @Column(name = "store_name")
    String storeName;

    @ManyToOne
    @JoinColumn(name = "company_id")
    Company company;

    @OneToMany(mappedBy = "store")
    List<Product> productList;

    @OneToMany(mappedBy = "store")
    List<User> userList;

    @OneToMany(mappedBy = "store")
    List<Inventory> inventories;

    @OneToMany(mappedBy = "store")
    List<Order> orders;

    @OneToMany(mappedBy = "store")
    List<PurchaseOrder> purchaseOrders;
}
