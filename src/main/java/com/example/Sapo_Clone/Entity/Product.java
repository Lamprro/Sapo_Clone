package com.example.Sapo_Clone.Entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

import java.util.Date;
import java.util.List;

@Entity
@Table(name = "product")
@Data
@AllArgsConstructor
@NoArgsConstructor
@FieldDefaults(level = lombok.AccessLevel.PRIVATE)
public class Product {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    int id;

    @Column(name = "product_name")
    String productName;

    @Column(name = "description")
    String description;

    @Column(name = "barcode")
    String barcode;

    @Column(name = "avgstar")
    String avgstar;

    @Temporal(TemporalType.TIMESTAMP)
    @Column(name = "created_date")
    Date createdDate;

    @Temporal(TemporalType.TIMESTAMP)
    @Column(name = "updated_date")
    Date updatedDate;

    @Column(name = "import_price")
    Double importPrice;

    @Column(name = "sell_price_orginal")
    Double sellPriceOrginal;

    @Column(name = "sell_price")
    Double sellPrice;

    @Column(name = "quantity")
    int quantity;

    @ManyToOne
    @JoinColumn(name = "store_id")
    Store store;

    @Column(name = "status")
    int status;

    @ManyToMany
    @JoinTable(
            name = "product_categorie",
            joinColumns = @JoinColumn(name = "product_id"),
            inverseJoinColumns = @JoinColumn(name = "categorie_id")
    )
    List<Categorie> categorieList;

    @ManyToOne
    @JoinColumn(name = "unit_id")
    Unit unit;

    @OneToMany(mappedBy = "product")
    List<ProductImage> productImages;

    @OneToMany(mappedBy = "product")
    List<Rating> ratingList;

    @OneToMany(mappedBy = "product")
    List<CartItem> cartItems;

    @OneToMany(mappedBy = "product")
    List<Inventory> inventories;

    @OneToMany(mappedBy = "product")
    List<OrderDetail> orderDetails;

    @OneToMany(mappedBy = "product")
    List<PurchaseOrderDetail> purchaseOrderDetails;

    @ManyToMany(mappedBy = "products")
    List<Promotion> promotions;

    @PrePersist
    protected void onCreate() {
        createdDate = new Date();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedDate = new Date();
    }
}
