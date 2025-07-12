#!/bin/bash

# Configurações iniciais
data_log=$(date +"%Y%m%d")
timestamp=$(date +"%H:%M:%S")

# Verificação de parâmetros
if [ -z "$1" ]; then
    echo "  ----------------------------"
    echo "    Uso:                      "
    echo "    converte_utf8.sh <pasta_raiz> [padroes_arquivos]"
    echo "  ----------------------------"
    echo "  <pasta_raiz>: Diretório raiz para conversão"
    echo "  [padroes_arquivos]: Padrões de arquivos para substituir codificação no conteúdo (opcional)"
    echo "                     Padrão: '*.java,*.html,*.ts,*.js,*.json,*.xml,*.properties'"
    exit 1
fi

RUTE="$1"
nome_base=$(basename "$RUTE")
LOG_CONVERTE="${nome_base}_${data_log}.log"

# Limpar log anterior
> "$LOG_CONVERTE"

# Mostrar destino do log
echo "Log sendo salvo em: $PWD/$LOG_CONVERTE" | tee -a "$LOG_CONVERTE"

PADROES="${2:-*.java,*.html,*.ts,*.js,*.json,*.xml,*.properties}"

# Função para exibir e registrar mensagens
log() {
    local timestamp=$(date +"%H:%M:%S")
    local message="[$timestamp] $1"
    echo "$message" | tee -a "$LOG_CONVERTE"
}

# Função para converter codificação de arquivos
converte_arquivo() {
    local arquivo="$1"
    local codificacao="$2"
    
    log "Convertendo: $arquivo (detectado: $codificacao)"
    
    # Nome seguro para arquivo temporário
    local nome_limpo=$(echo "$arquivo" | sed -e 's/[^A-Za-z0-9._-]/_/g')
    local arquivo_tmp="/tmp/$nome_limpo"
    
    # Conversão com tratamento de erro
    if iconv -f "$codificacao" -t UTF-8//TRANSLIT "$arquivo" > "$arquivo_tmp" 2>> "$LOG_CONVERTE"; then
        # Preserva metadados originais
        local perms=$(stat -c "%a" "$arquivo")
        local owner=$(stat -c "%U:%G" "$arquivo")
        
        # Faz backup e substitui
        cp -p "$arquivo" "$arquivo.bak"
        mv "$arquivo_tmp" "$arquivo"
        chmod "$perms" "$arquivo"
        chown "$owner" "$arquivo"
        
        log "SUCESSO: $arquivo convertido para UTF-8"
        return 0
    else
        log "ERRO: Falha na conversão de $arquivo"
        rm -f "$arquivo_tmp"
        return 1
    fi
}

# Função para substituir referências à codificação
substitui_codificacao() {
    local arquivo="$1"
    
    log "Atualizando referências de codificação em: $arquivo"
    
    # Faz backup antes de modificar
    cp -p "$arquivo" "$arquivo.bak2"
    
    # Substitui todas as variações comuns
    sed -i -r \
        -e "s/(encoding|charset)[[:space:]]*=[[:space:]]*[\"']?([aA][nN][sS][iI]|[cC][pP]1252|windows-1252)[\"']?/\1=\"UTF-8\"/gi" \
        -e "s/(encoding|charset)[[:space:]]*=[[:space:]]*[\"']?[iI][sS][oO]-8859-1[\"']?/\1=\"UTF-8\"/gi" \
        -e "s/(encoding|charset)[[:space:]]*=[[:space:]]*[\"']?[lL]atin1[\"']?/\1=\"UTF-8\"/gi" \
        -e "s/(encoding|charset)[[:space:]]*=[[:space:]]*[\"']?[uU][tT][fF]-8[\"']?/\1=\"UTF-8\"/gi" \
        "$arquivo"
}

# Processamento principal
log "Iniciando conversão para UTF-8 em: $RUTE"
log "Padrões para substituição: $PADROES"

find "$RUTE" -type f -print0 | while IFS= read -r -d $'\0' arquivo; do
    # Exibir progresso em tempo real
    echo -n "."
    
    # Ignora arquivos binários e backups
    if [[ "$arquivo" == *.bak ]] || [[ "$arquivo" == *.bak2 ]] || file -b --mime-encoding "$arquivo" | grep -q "binary"; then
        log "Ignorado: $arquivo (binário ou backup)"
        continue
    fi

    # Passo 1: Converter codificação do arquivo
    codificacao=$(file -b --mime-encoding "$arquivo")
    case "$codificacao" in
        *windows-1252*|*cp1252*)
            converte_arquivo "$arquivo" "CP1252"
            ;;
        *iso-8859-1*)
            converte_arquivo "$arquivo" "ISO-8859-1"
            ;;
        *iso-8859-15*)
            converte_arquivo "$arquivo" "ISO-8859-15"
            ;;
        *us-ascii*)
            log "Compatível com UTF-8: $arquivo"
            ;;
        *utf-8*|*utf8*)
            log "Já em UTF-8: $arquivo"
            ;;
        *)
            log "Codificação não tratada ($codificacao): $arquivo"
            continue
            ;;
    esac

    # Passo 2: Substituir referências no conteúdo
    if [[ -f "$arquivo" ]]; then
        for padrao in ${PADROES//,/ }; do
            if [[ "$arquivo" == $padrao ]]; then
                substitui_codificacao "$arquivo"
                break
            fi
        done
    fi
done

echo -e "\n"  # Quebra de linha após os pontos de progresso
log "Processo concluído!"
log "Resumo final salvo em: $PWD/$LOG_CONVERTE"