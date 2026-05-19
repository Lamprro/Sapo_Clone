package com.example.Sapo_Clone.Repository;

import com.example.Sapo_Clone.Entity.Roles;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface RoleRepository extends JpaRepository<Roles, Integer> {
    Optional<Roles> findByRolesName(String rolesName);
}



