package com.example.Sapo_Clone.DTO.Response.Unit;

import com.example.Sapo_Clone.Entity.Unit;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

import java.io.Serializable;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
@FieldDefaults(level = lombok.AccessLevel.PRIVATE)
public class UnitResponse implements Serializable {
    int id;
    String unitName;
    String description;

    public static UnitResponse fromEntity(Unit unit) {
        if (unit == null) return null;
        return UnitResponse.builder()
                .id(unit.getId())
                .unitName(unit.getUnitName())
                .description(unit.getDescription())
                .build();
    }
}
