-- https://docs.spring.io/spring-boot/how-to/data-initialization.html

-- SET SCHEMA 'PUBLIC';

-- Verifica se a tabela contatoEntities já existe e a cria se não existir
CREATE TABLE IF NOT EXISTS contato
(
    id       BIGINT AUTO_INCREMENT PRIMARY KEY,
    nome     VARCHAR(50) NOT NULL,
    telefone VARCHAR(20),
    email    VARCHAR(50)
);