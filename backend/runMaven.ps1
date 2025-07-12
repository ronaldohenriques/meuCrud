<#
.SYNOPSIS
Script para execucao automatizada de tarefas Maven com geracao de relatorios padronizados.
.DESCRIPTION
Executa uma serie de comandos Maven essenciais e gera relatorios estruturados em diretorios organizados por projeto, branch e timestamp. Inclui analise de dependencias e validacao de configuracoes.
.PARAMETER BackupRoot
Diretorio base para armazenamento dos relatorios (padrao: "C:\dev\docs\tarefas")
.PARAMETER MavenHome
Caminho da instalacao do Maven (padrao: "c:\dev\java\maven3")
.EXAMPLE
.\maven-script.ps1
Executa todos os comandos padrao no diretorio atual
.EXAMPLE
.\maven-script.ps1 -BackupRoot "D:\reports" -MavenHome "C:\apache-maven-3.8.6"
Executa com configuracoes personalizadas
.NOTES
# Novos comandos
mvn org.codehaus.mojo:versions-maven-plugin:2.16.0:display-dependency-updates  # acho que vai precisar
mvn versions:display-dependency-updates # Para mostrar pacotes desatualizados
mvn versions:display-plugin-updates # Para mostrar plugins desatualizados
mvn versions:use-latest-versions  # Para atualizar as dependencias para as mais recentes
mvn versions:update-properties # Para atualizar so as propriedades
#>
[CmdletBinding()]
param(
    [string]$BackupRoot = "C:\dev\docs\tarefas",
    [string]$MavenHome = "c:\dev\java\maven3"
)

# =================================================
# CONFIGURACOES GLOBAIS
# =================================================
$ErrorActionPreference = "Stop"
$TIMESTAMP = Get-Date -Format "yyyyMMdd_HHmmss"
$SCRIPT_VERSION = "1.2"

# =================================================
# FUNCOES UTILITARIAS
# =================================================
function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error", "Success")]
        [string]$Level = "Info",
        [string]$LogFile
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $formattedMessage = "[$timestamp] [$Level] $Message"
    switch ($Level) {
        "Info"    { Write-Host $formattedMessage -ForegroundColor Cyan }
        "Warning" { Write-Host $formattedMessage -ForegroundColor Yellow }
        "Error"   { Write-Host $formattedMessage -ForegroundColor Red }
        "Success" { Write-Host $formattedMessage -ForegroundColor Green }
    }
    if ($LogFile) {
        try {
            Add-Content -Path $LogFile -Value $formattedMessage -ErrorAction Stop
        }
        catch {
            Write-Host "Falha ao escrever no log: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

function Get-ProjectInfo {
    try {
      # $projectName = (Get-Item -Path ".").Name
      # $projectName = (Get-Item -Path "$PWD").Name
      # $projectName = Split-Path -Leaf (Get-Location)
        $repoRoot = git rev-parse --show-toplevel 2>$null
        $commitHash = git rev-parse --short HEAD 2>$null
        if ($repoRoot) {
            $branchName = git rev-parse --abbrev-ref HEAD 2>$null
            if (-not $branchName -or $branchName -eq "HEAD") {
                $branchName = "detached_head"
            }
            $branchName = $branchName -replace '[\\/:*?"<>|]', '_' -replace '\s+', '_'
            $branchName = $branchName.Substring(0, [Math]::Min(50, $branchName.Length))
        }
        else {
            $branchName = "no_git"
        }
        return [PSCustomObject]@{
            ProjectName = $projectName
            BranchName  = $branchName
            RepoRoot    = $repoRoot
            CommitHash  = $commitHash
        }
    }
    catch {
        return [PSCustomObject]@{
            ProjectName = (Get-Item -Path ".").Name
            BranchName  = "unknown"
            RepoRoot    = $null
            CommitHash  = "unknown"
        }
    }
}

function Initialize-ReportDir {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$ProjectInfo
    )
    # $reportPath = Join-Path $BackupRoot $ProjectInfo.ProjectName $ProjectInfo.BranchName "maven" $TIMESTAMP
    $reportPath = Join-Path $BackupRoot $ProjectInfo.ProjectName
$reportPath = Join-Path $reportPath $ProjectInfo.BranchName
$reportPath = Join-Path $reportPath "maven"
$reportPath = Join-Path $reportPath $TIMESTAMP
    try {
        if (-not (Test-Path $reportPath)) {
            New-Item -ItemType Directory -Path $reportPath -Force | Out-Null
        }
        return $reportPath
    }
    catch {
        throw "Falha ao criar diretorio de relatorios: $_"
    }
}

# =================================================
# FUNCOES DE MAVEN
# =================================================
function Test-MavenInstallation {
    param(
        [Parameter(Mandatory)]
        [string]$MavenHome
    )
    $mavenPath = Join-Path $MavenHome "bin\mvn.cmd"
    if (-not (Test-Path $mavenPath)) {
        throw "Maven nao encontrado em: $mavenPath"
    }
    return $mavenPath
}

function Invoke-MavenCommand {
    param(
        [Parameter(Mandatory)]
        [string]$MavenPath,
        [Parameter(Mandatory)]
        [string]$ReportDir,
        [Parameter(Mandatory)]
        [string]$CommandName,
        [Parameter(Mandatory)]
        [array]$Goals,
        [array]$Arguments = @(),
        [string]$MainLog
    )
    $logFile = Join-Path $ReportDir "${CommandName}.log"
    $commandLine = "mvn $($Goals -join ' ') $($Arguments -join ' ')"
    Write-Log "Executando: $commandLine" -Level Info -LogFile $MainLog
    try {
        $startTime = Get-Date
        & $MavenPath $Goals $Arguments *> $logFile
        if ($LASTEXITCODE -ne 0) {
            throw "Comando falhou com codigo $LASTEXITCODE"
        }
        $duration = (Get-Date) - $startTime
        $durationFormatted = "{0:mm} min {0:ss} seg" -f $duration
        Write-Log "Comando concluido em $durationFormatted" -Level Success -LogFile $MainLog
        return $true
    }
    catch {
        Write-Log "Falha no comando '$CommandName': $_" -Level Error -LogFile $mainLog
        Write-Log "Consulte o log: $logFile" -Level Error -LogFile $MainLog
        return $false
    }
}

# =================================================
# LOGICA PRINCIPAL
# =================================================
$mainLog = $null
$reportDir = $null
Write-Host "Diretório atual: $(Get-Location)" -ForegroundColor DarkGray
$projectName = Split-Path -Leaf (Get-Location)
Write-Host "Nome do projeto: $projectName" -ForegroundColor Green
try {
    # 1. Inicializacao
    Write-Log "Iniciando script de analise Maven (v$SCRIPT_VERSION)" -Level Info

    # 2. Obter informacoes do projeto
    $projectInfo = Get-ProjectInfo
    Write-Log "Projeto: $($projectInfo.ProjectName)" -Level Info
    Write-Log "Branch: $($projectInfo.BranchName)" -Level Info
    if ($projectInfo.CommitHash) {
        Write-Log "Commit: $($projectInfo.CommitHash)" -Level Info
    }

    # 3. Inicializar diretorio de relatorios
    $reportDir = Initialize-ReportDir $projectInfo
    Write-Log "Relatorios serao salvos em: $reportDir" -Level Info

    # 4. Configurar log principal
    $mainLog = Join-Path $reportDir "relatorioMaven.log"
    @"
============== RELATORIO MAVEN ==============
Script Version: $SCRIPT_VERSION
Project:       $($projectInfo.ProjectName)
Branch:        $($projectInfo.BranchName)
Commit:        $($projectInfo.CommitHash)
Timestamp:     $(Get-Date)
Report Dir:    $reportDir
==============================================
"@ | Out-File $mainLog

    # 5. Verificar instalacao do Maven
    $mavenPath = Test-MavenInstallation -MavenHome $MavenHome
    $mavenVersion = & $mavenPath --version | Select-Object -First 1
    Write-Log "Usando Maven: $mavenVersion" -Level Info -LogFile $mainLog

    # 6. Definir comandos Maven
    $mavenCommands = @(
        [PSCustomObject]@{CommandName="clean_install"; Goals=@("clean", "install")},
        [PSCustomObject]@{CommandName="effective_pom"; Goals=@("help:effective-pom")},
        [PSCustomObject]@{CommandName="dependency_tree"; Goals=@("dependency:tree"); Arguments=@("-Dverbose")},
        [PSCustomObject]@{CommandName="dependency_analyze"; Goals=@("dependency:analyze"); Arguments=@("-Dverbose")},
        [PSCustomObject]@{CommandName="dependency_updates"; Goals=@("versions:display-dependency-updates")},
        [PSCustomObject]@{CommandName="plugin_updates"; Goals=@("versions:display-plugin-updates")}
    )

    # 7. Executar comandos
    $results = @{}
    foreach ($cmd in $mavenCommands) {
        $success = Invoke-MavenCommand -MavenPath $mavenPath -ReportDir $reportDir `
            -CommandName $cmd.CommandName -Goals $cmd.Goals `
            -Arguments $cmd.Arguments -MainLog $mainLog
        $results[$cmd.CommandName] = $success
    }

    # 8. Analise pos-processamento
    $issuesFile = Join-Path $reportDir "problemasDependencias.log"
    $dependenciesLog = Join-Path $reportDir "dependency_tree.log"
    if ($results["dependency_tree"] -and (Test-Path $dependenciesLog)) {
        Write-Log "Analisando problemas de dependencias..." -Level Info -LogFile $mainLog
        $patterns = @("jakarta.activation", "outdated", "conflict", "omitted")
        Get-Content $dependenciesLog | Where-Object {
            $line = $_
            $patterns | Where-Object { $line -match $_ }
        } | Out-File $issuesFile
        if (Test-Path $issuesFile) {
            $issueCount = (Get-Content $issuesFile).Count
            Write-Log "Encontrados $issueCount problemas de dependencias" -Level Warning -LogFile $mainLog
        }
    }

    # 9. Gerar relatorio de resumo
    $summaryFile = Join-Path $reportDir "resumo_execucao.txt"
    $summaryContent = @"
RESUMO DA EXECUCAO
==================
Projeto:      $($projectInfo.ProjectName)
Branch:       $($projectInfo.BranchName)
Commit:       $($projectInfo.CommitHash)
Data/Hora:    $(Get-Date)
Maven:        $mavenVersion
COMANDOS EXECUTADOS:
"@
    foreach ($cmd in $mavenCommands) {
        $status = if ($results[$cmd.CommandName]) { "SUCESSO" } else { "FALHA" }
        $summaryContent += "• $($cmd.CommandName.PadRight(25)) $status`n"
    }
    $summaryContent += @"
RELATORIOS DISPONIVEIS:
- Diretorio completo: $reportDir
- Log principal: $(Split-Path $mainLog -Leaf)
- Problemas de dependencias: $(if (Test-Path $issuesFile) { (Split-Path $issuesFile -Leaf) } else { "Nenhum encontrado" })
"@
    $summaryContent | Out-File $summaryFile

    # 10. Finalizacao
    Write-Log "Processo concluido com sucesso!" -Level Success -LogFile $mainLog
    Write-Log "Resumo da execucao: $summaryFile" -Level Info

    # Exibir caminhos importantes
    Write-Host "`n=== RELATORIOS GERADOS ===" -ForegroundColor Cyan
    Write-Host "Diretorio principal: file:///$reportDir" -ForegroundColor Yellow
    Write-Host "Resumo da execucao: file:///$summaryFile" -ForegroundColor Yellow
    if (Test-Path $issuesFile) {
        Write-Host "Problemas encontrados: file:///$issuesFile" -ForegroundColor Yellow
    }

    exit 0
}
catch {
    $errorMessage = $_.Exception.Message
    Write-Host "`nERRO FATAL: $errorMessage" -ForegroundColor Red
    if ($mainLog) {
        try {
            "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [ERROR] $errorMessage" | Out-File $mainLog -Append
        }
        catch {
            Write-Host "Falha ao registrar erro no log: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    if ($reportDir) {
        Write-Host "Relatorios parciais disponiveis em: $reportDir" -ForegroundColor Yellow
    }
    exit 1
}