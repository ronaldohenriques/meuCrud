package com.ronaldo.agenda.service;

import com.ronaldo.agenda.dto.ContatoDTO;
import com.ronaldo.agenda.exceptions.ResourceNotFoundException;
import com.ronaldo.agenda.mapper.ContatoMapper;
import com.ronaldo.agenda.model.ContatoEntity;
import com.ronaldo.agenda.repository.ContatoRepository;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;


@Service
public class ContatoService {

    private final ContatoRepository repository;
    private final ContatoMapper mapper;

    @Autowired
    public ContatoService(ContatoRepository repository, ContatoMapper mapper) {
        this.repository = repository;
        this.mapper = mapper;
    }

    public List<ContatoDTO> findAll() {
        return repository.findAll().stream()
                .map(mapper::toDTO).collect(Collectors.toList());
    }

    public ContatoDTO findById(Long id) {
        if (id == null) {
            throw new IllegalArgumentException("ID não pode ser nulo");
        }
        ContatoEntity contatoEntity = repository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Contato não encontrado", id));
        return mapper.toDTO(contatoEntity);
    }

    public List<ContatoDTO> findByNome(String nome) {
        if (nome == null) {
            // throw new IllegalArgumentException("Nome de busca não pode ser nulo");
            return Collections.emptyList();
        }
        return repository.findByNomeContainingIgnoreCase(nome).stream()
                .map(mapper::toDTO)
                .collect(Collectors.toList());
    }

    public Optional<ContatoDTO> buscarPorEmail(String email) {
        return repository.findByEmailIgnoreCase(email)
                .map(mapper::toDTO);
    }

    @Transactional
    public ContatoDTO save(ContatoDTO contatoDTO) {
        if (contatoDTO.email() != null && repository.existsByEmailIgnoreCase(contatoDTO.email())) {
            throw new IllegalArgumentException("Email já cadastrado: " + contatoDTO.email());
        }

        ContatoEntity contatoEntity = mapper.toEntity(contatoDTO);
        contatoEntity = repository.save(contatoEntity);
        return mapper.toDTO(contatoEntity);
    }

    @Transactional
    public ContatoDTO update(Long id, ContatoDTO contatoDTO) {
        // Verifica se o contato existe
        ContatoEntity contatoEntityExistente = repository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Contato com ID " + id + " não encontrado", id));

        // Atualiza os campos do contato existente com os valores do DTO
        contatoEntityExistente.setNome(contatoDTO.nome());
        contatoEntityExistente.setEmail(contatoDTO.email());
        contatoEntityExistente.setTelefone(contatoDTO.telefone());

        // Salva as alterações no banco de dados
        ContatoEntity atualizado = repository.save(contatoEntityExistente);
        return mapper.toDTO(atualizado);
    }

    @Transactional
    public void delete(Long id) {
/*        ContatoEntity contatoEntity = repository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Contato não encontrado", id));
        repository.delete(contatoEntity);*/
        repository.deleteById(id);
    }
}
