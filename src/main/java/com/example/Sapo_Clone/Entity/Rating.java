package com.example.Sapo_Clone.Entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

@Entity
@Data
@AllArgsConstructor
@NoArgsConstructor
@Table(name = "rating")
@FieldDefaults(level = lombok.AccessLevel.PRIVATE)
public class Rating {
    @Id
    @GeneratedValue (strategy = GenerationType.IDENTITY)
    int id;

    @Column(name = "rating")
    int rating;

    @ManyToOne
    @JoinColumn(name = "user_id")
    User user;

    @Column(name = "comment")
    String comment;

    @ManyToOne
    @JoinColumn(name = "product_id")
    Product product;

}
