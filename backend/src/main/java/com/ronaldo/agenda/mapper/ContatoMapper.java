package com.ronaldo.agenda.mapper;

import com.ronaldo.agenda.dto.ContatoDTO;
import com.ronaldo.agenda.model.ContatoEntity;
import org.mapstruct.Mapper;
import org.mapstruct.MappingConstants;

import java.util.List;


@Mapper(componentModel = MappingConstants.ComponentModel.SPRING)
public interface ContatoMapper {
    ContatoDTO toDTO(ContatoEntity contatoEntity);
    ContatoEntity toEntity(ContatoDTO contatoDTO);
    List<ContatoDTO> toDTOList(List<ContatoEntity> contatoEntities);
    List<ContatoEntity> toEntityList(List<ContatoDTO> dtos);
}
