package com.example.Sapo_Clone.Entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

import java.util.List;

@Entity
@Table(name = "providers")
@Data
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = lombok.AccessLevel.PRIVATE)
public class Provider {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    int id;

    @Column(name = "provider_name")
    String providerName;

    @Column(name = "provider_phone")
    String providerPhone;

    @Column(name = "provider_address", columnDefinition = "TEXT")
    String providerAddress;

    @OneToMany(mappedBy = "provider")
    List<PurchaseOrder> purchaseOrders;
}
