package com.ronaldo.agenda.repository;

import com.ronaldo.agenda.model.ContatoEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;


public interface ContatoRepository extends JpaRepository<ContatoEntity, Long> {
   // List<ContatoEntity> findByNomeIgnoreCase(String nome); para nome completo


    List<ContatoEntity> findByNomeContainingIgnoreCase(String nome); // Para partes do nome

    boolean existsByEmailIgnoreCase(String email);

    // Alternativa: encontra contato pelo email (útil se precisar dos dados)
    Optional<ContatoEntity> findByEmailIgnoreCase(String email);
}
