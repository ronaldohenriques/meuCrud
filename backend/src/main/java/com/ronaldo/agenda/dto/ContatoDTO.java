package com.ronaldo.agenda.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ContatoDTO(
        Long id,

        @NotBlank(message = "Nome é obrigatório")
        @Size(min = 2, max = 100, message = "Nome deve ter entre 2 e 100 caracteres")
        String nome,

        @NotBlank(message = "Telefone é obrigatório")
        @Size(max = 15, message = "Telefone deve ter até 15 caracteres")
        String telefone,

        @NotBlank(message = "Email é obrigatório")
        @Email(message = "Email deve ser válido")
        String email) {

}
