<#
.SYNOPSIS
Script para execução de tarefas Maven com estrutura padronizada.

.DESCRIPTION
Executa comandos Maven e gera relatórios em estrutura compatível com outros scripts.
#>

# =================================================
# CONFIGURAÇÕES GLOBAIS (PADRÃO)
# =================================================
$BACKUP_ROOT = "C:\dev\docs\tarefas"
$TIMESTAMP = Get-Date -Format "yyyyMMdd_HHmmss"

# =================================================
# FUNÇÕES UTILITÁRIAS (PADRÃO)
# =================================================

function Show-Error {
    param([string]$message)
    Write-Host "ERRO: $message" -ForegroundColor Red
    exit 1
}

function Show-Warning {
    param([string]$message)
    Write-Host "AVISO: $message" -ForegroundColor Yellow
}

function Show-Success {
    param([string]$message)
    Write-Host $message -ForegroundColor Green
}

function Get-ProjectInfo {
    <#
    .SYNOPSIS
    Obtém informações do projeto (padronizado)
    #>
    try {
        $projectName = (Get-Item -Path ".").Name
        $repoRoot = git rev-parse --show-toplevel 2>$null

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

        return @{
            ProjectName = $projectName
            BranchName  = $branchName
            RepoRoot    = $repoRoot
        }
    }
    catch {
        return @{
            ProjectName = (Get-Item -Path ".").Name
            BranchName  = "unknown"
            RepoRoot    = $null
        }
    }
}

function Initialize-ReportDir {
    <#
    .SYNOPSIS
    Cria diretório de relatórios padronizado
    #>
    param([hashtable]$projectInfo)

    <#
    $reportDir = if ($projectInfo.RepoRoot) {
       #  Join-Path $BACKUP_ROOT $projectInfo.ProjectName $projectInfo.BranchName "maven" $TIMESTAMP
       $NewPath1 = Join-Path $BACKUP_ROOT $projectInfo.ProjectName
       $NewPath2 = Join-Path $NewPath1 $projectInfo.BranchName
       Join-Path $NewPath2 $TIMESTAMP
    } else {
        Join-Path $BACKUP_ROOT $projectInfo.ProjectName "maven" $TIMESTAMP
    } #>

    $reportDir = if ($projectInfo.RepoRoot) {
        $BACKUP_ROOT, $projectInfo.ProjectName, $projectInfo.BranchName, $TIMESTAMP -join '\'
    }
    else {
        $BACKUP_ROOT, $projectInfo.ProjectName, $TIMESTAMP -join '\'
    }

    try {
        if (-not (Test-Path $reportDir)) {
            New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
        }
        return $reportDir
    }
    catch {
        Show-Error "Falha ao criar diretório de relatórios: $_"
    }
}

# =================================================
# FUNÇÕES ESPECÍFICAS DE MAVEN
# =================================================

function Get-MavenPath {
    <#
    .SYNOPSIS
    Localiza o executável do Maven
    #>
    $mavenHome = "c:\dev\java\maven3"
    $mavenPath = Join-Path $mavenHome "bin\mvn.cmd"

    if (-not (Test-Path $mavenHome)) {
        Show-Error "Diretório do Maven não encontrado: $mavenHome"
    }

    if (-not (Test-Path $mavenPath)) {
        Show-Error "Executável do Maven não encontrado: $mavenPath"
    }

    return $mavenPath
}

function Invoke-MavenCommand {
    <#
    .SYNOPSIS
    Executa um comando Maven e registra o log
    #>
    param (
        [Parameter(Mandatory)]
        [string]$ReportDir,

        [Parameter(Mandatory)]
        [string]$CommandName,

        [Parameter(Mandatory)]
        [string[]]$Goals,

        [Parameter()]
        [string[]]$AdditionalArgs
    )

    $logFile = Join-Path $ReportDir "${CommandName}.log"
    $mavenPath = Get-MavenPath

    $mavenArgs = @($Goals) + $AdditionalArgs
    Write-Host "Executando: mvn $($mavenArgs -join ' ')" -ForegroundColor Cyan

    & $mavenPath $mavenArgs *> $logFile

    if ($LASTEXITCODE -ne 0) {
        Show-Error "Falha no comando Maven: $CommandName. Verifique: $logFile"
    }

    Write-Host "Comando Maven concluído: $CommandName" -ForegroundColor Green
    Write-Host "Log: $logFile" -ForegroundColor Green
}

# =================================================
# LÓGICA PRINCIPAL
# =================================================

try {
    # 1. Obter informações do projeto (padronizado)
    $projectInfo = Get-ProjectInfo

    # 2. Inicializar diretório de relatórios (padronizado)
    $reportDir = Initialize-ReportDir $projectInfo

    # 3. Iniciar log geral (padronizado)
    $mainLog = Join-Path $reportDir "relatorioMaven.log"
    "============== RELATORIO MAVEN ==============" | Out-File $mainLog
    "Project:    $($projectInfo.ProjectName)" | Out-File $mainLog -Append
    "Branch:     $($projectInfo.BranchName)" | Out-File $mainLog -Append
    "Timestamp:  $(Get-Date)" | Out-File $mainLog -Append
    "=============================================" | Out-File $mainLog -Append

    # 4. Executar comandos Maven
    $mavenPath = Get-MavenPath
    $mavenVersion = & $mavenPath --version | Select-Object -First 1
    "Maven:      $mavenVersion" | Out-File $mainLog -Append

    $commands = @(
        @{
            CommandName = "clean_install"
            Goals       = @("clean", "install")
        },
        @{
            CommandName = "effective_pom"
            Goals       = @("help:effective-pom")
        },
        @{
            CommandName    = "dependency_tree"
            Goals          = @("dependency:tree")
            AdditionalArgs = @("-Dverbose")
        },
        @{
            CommandName    = "dependency_analyze"
            Goals          = @("dependency:analyze")
            AdditionalArgs = @("-Dverbose")
        },
        @{
            CommandName = "dependency_updates"
            Goals       = @("versions:display-dependency-updates")
        }
    )

    foreach ($cmd in $commands) {
        "Executando: $($cmd.CommandName)" | Out-File $mainLog -Append
        Invoke-MavenCommand @cmd -ReportDir $reportDir
    }

    # 5. Buscar problemas de dependências
    "Verificando problemas de dependencias" | Out-File $mainLog -Append
    $dependenciesLog = Join-Path $reportDir "dependency_tree.log"
    $issuesFile = Join-Path $reportDir "problemasDependencias.log"

    if (Test-Path $dependenciesLog) {
        Get-Content $dependenciesLog |
        Select-String -Pattern "jakarta.activation" |
        Out-File $issuesFile
    }

    # 6. Finalização (padronizada)
    Show-Success "Processo Maven concluído"
    "Status: Sucesso" | Out-File $mainLog -Append
    "=============================================" | Out-File $mainLog -Append
    "Relatorios disponiveis em: file:///$reportDir" | Out-File $mainLog -Append
}
catch {
    Show-Error "Erro durante o processo: $_"
}