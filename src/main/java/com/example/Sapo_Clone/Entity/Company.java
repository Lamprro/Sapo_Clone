package com.example.Sapo_Clone.Entity;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldDefaults;

import java.util.List;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = lombok.AccessLevel.PRIVATE)
public class Company {
    @Id
    @GeneratedValue (strategy = GenerationType.IDENTITY)
    int id;

    @Column (name = "company_name")
    String companyName;

    @OneToMany(mappedBy = "company")
    List<Store> storeList;

     @OneToMany(mappedBy = "company")
     List<User> userList;

}
