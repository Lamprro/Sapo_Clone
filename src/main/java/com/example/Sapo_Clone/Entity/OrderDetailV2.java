package com.example.Sapo_Clone.Entity;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.EqualsAndHashCode;
import lombok.ToString;
import lombok.experimental.FieldDefaults;

@Entity
@Table(name = "order_details_v2")
@Data
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class OrderDetailV2 {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    int id;

    @Column(name = "quantity", nullable = false)
    int quantity;

    @Column(name = "price", nullable = false)
    double price;

    @Column(name = "subtotal", nullable = false)
    double subtotal;

    @Column(name = "import_price", nullable = false)
    Double importPrice = 0.0;

    @EqualsAndHashCode.Exclude
    @ToString.Exclude
    @ManyToOne
    @JoinColumn(name = "order_id", nullable = false)
    OrderV2 order;

    @EqualsAndHashCode.Exclude
    @ToString.Exclude
    @ManyToOne
    @JoinColumn(name = "product_id", nullable = false)
    Product product;
}
