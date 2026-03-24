package com.example.Sapo_Clone.Entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

import java.util.List;

@Entity
@Data
@AllArgsConstructor
@NoArgsConstructor
@Table(name = "unit")
@FieldDefaults(level = lombok.AccessLevel.PRIVATE)
public class Unit {
    @Id
    @GeneratedValue (strategy = GenerationType.IDENTITY)
    int id;

    @Column(name = "unit_name")
    String unitName;

    @OneToMany(mappedBy = "unit")
    List<Product> products;
}
