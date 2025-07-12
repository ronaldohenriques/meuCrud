package com.ronaldo.agenda.controller;

import com.ronaldo.agenda.dto.ContatoDTO;
import com.ronaldo.agenda.service.ContatoService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.ErrorResponse;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.net.URI;
import java.util.List;


@RestController
@RequestMapping("/api/contatos")
@Tag(name = "Contatos", description = "API para gerenciamento de contatos")
public class ContatoController {

    private final ContatoService service;

    @Autowired
    public ContatoController(final ContatoService service) {
        this.service = service;
    }


    /**
     * Recupera todos os contatos cadastrados no sistema.
     *
     * @return ResponseEntity contendo a lista de todos os contatos
     */
    @GetMapping
    @Operation(summary = "Listar todos os contatos", description = "Retorna uma lista com todos os contatos cadastrados no sistema")
    @ApiResponse(responseCode = "200", description = "Contatos encontrados com sucesso")
    public ResponseEntity<List<ContatoDTO>> getTodosContatos() {
        return ResponseEntity.ok(service.findAll());
    }

    /**
     * Recupera um contato específico pelo seu ID.
     *
     * @param id O identificador único do contato
     * @return ResponseEntity contendo o contato solicitado
     */
    @GetMapping("/{id}")
    @Operation(summary = "Buscar contato por ID", description = "Retorna um contato específico com base no ID fornecido")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Contato encontrado com sucesso"),
            @ApiResponse(responseCode = "404", description = "Contato não encontrado",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    public ResponseEntity<ContatoDTO> getContatoPorId(
            @Parameter(description = "ID do contato a ser buscado", required = true)
            @PathVariable final Long id) {
        return ResponseEntity.ok(service.findById(id));
    }

    /**
     * Cria um novo contato no sistema.
     *
     * @param contatoDTO Dados do contato a ser criado
     * @return ResponseEntity contendo o contato criado e a URI para acessá-lo
     */
    @PostMapping
    @Operation(summary = "Criar novo contato", description = "Cria um novo contato com os dados fornecidos")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "201", description = "Contato criado com sucesso"),
            @ApiResponse(responseCode = "400", description = "Dados inválidos fornecidos",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    public ResponseEntity<ContatoDTO> criarContato(
            @Parameter(description = "Dados do contato a ser criado", required = true)
            @Valid @RequestBody final ContatoDTO contatoDTO) {
        ContatoDTO novoContato = service.save(contatoDTO);
        URI location = ServletUriComponentsBuilder
                .fromCurrentRequest()
                .path("/{id}")
                .buildAndExpand(novoContato.id())
                .toUri();
        return ResponseEntity.created(location).body(novoContato);
    }

    /**
     * Atualiza um contato existente.
     *
     * @param id         ID do contato a ser atualizado
     * @param contatoDTO Novos dados do contato
     * @return ResponseEntity contendo o contato atualizado
     */
    @PutMapping("/{id}")
    @Operation(summary = "Atualizar contato", description = "Atualiza os dados de um contato existente")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Contato atualizado com sucesso"),
            @ApiResponse(responseCode = "404", description = "Contato não encontrado",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class))),
            @ApiResponse(responseCode = "400", description = "Dados inválidos fornecidos",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    public ResponseEntity<ContatoDTO> atualizarContato(
            @Parameter(description = "ID do contato a ser atualizado", required = true)
            @PathVariable final Long id,
            @Parameter(description = "Novos dados do contato", required = true)
            @Valid @RequestBody ContatoDTO contatoDTO) {
        return ResponseEntity.ok(service.update(id, contatoDTO));
    }

    /**
     * Remove um contato do sistema.
     *
     * @param id ID do contato a ser removido
     * @return ResponseEntity sem conteúdo, indicando que a operação foi bem-sucedida
     */
    @DeleteMapping("/{id}")
    @Operation(summary = "Remover contato", description = "Exclui permanentemente um contato do sistema")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "204", description = "Contato removido com sucesso"),
            @ApiResponse(responseCode = "404", description = "Contato não encontrado",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    public ResponseEntity<Void> deletarContato(
            @Parameter(description = "ID do contato a ser removido", required = true)
            @PathVariable final Long id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }

    /**
     * Busca contatos pelo nome.
     *
     * @param nome Nome ou parte do nome a ser pesquisado
     * @return ResponseEntity contendo a lista de contatos que correspondem ao critério de busca
     */
    @GetMapping("/busca")
    @Operation(summary = "Buscar contatos por nome",
            description = "Retorna uma lista de contatos cujos nomes contenham o texto informado (busca case-insensitive)")
    @ApiResponse(responseCode = "200", description = "Busca realizada com sucesso")
    public ResponseEntity<List<ContatoDTO>> buscarPorNome(
            @Parameter(description = "Nome ou parte do nome a ser pesquisado", required = true)
            @RequestParam final String nome) {
        return ResponseEntity.ok(service.findByNome(nome));
    }
}


