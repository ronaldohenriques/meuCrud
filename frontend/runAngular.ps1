<#
.SYNOPSIS
Script para execução automatizada de tarefas em projetos Angular.
.DESCRIPTION
Executa comandos essenciais do Angular CLI e gera relatórios estruturados por projeto, branch e timestamp.
Inclui análise de qualidade, build e validação de configurações.
.PARAMETER BackupRoot
Diretório base para armazenamento dos relatórios (padrão: "C:\dev\docs\tarefas")
.PARAMETER AngularCliPath
Caminho do ng.cmd (padrão: "C:\Users\<seu-user>\AppData\Roaming\npm\ng.cmd")
.EXAMPLE
.\runAngular.ps1
Executa os comandos padrão no diretório atual
.EXAMPLE
.\runAngular.ps1 -BackupRoot "D:\relatorios" -AngularCliPath "C:\npm-global\ng.cmd"
Executa com configurações personalizadas
#>
[CmdletBinding()]
param(
    [string]$BackupRoot = "C:\dev\docs\tarefas",
    [string]$AngularCliPath = "$env:APPDATA\npm\ng.cmd"
)

# =================================================
# CONFIGURAÇÕES GLOBAIS
# =================================================
$ErrorActionPreference = "Stop"
$TIMESTAMP = Get-Date -Format "yyyyMMdd_HHmmss"
$SCRIPT_VERSION = "1.1"

# =================================================
# FUNÇÕES UTILITÁRIAS
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
        $projectName = Split-Path -Leaf (Get-Location)
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
            ProjectName = Split-Path -Leaf (Get-Location)
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
   #  $reportPath = Join-Path $BackupRoot $ProjectInfo.ProjectName $ProjectInfo.BranchName "angular" $TIMESTAMP
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
        throw "Falha ao criar diretório de relatórios: $_"
    }
}

function Test-AngularInstallation {
    param(
        [Parameter(Mandatory)]
        [string]$AngularCliPath
    )
    if (-not (Test-Path $AngularCliPath)) {
        throw "Angular CLI não encontrado em: $AngularCliPath"
    }
    return $AngularCliPath
}

function Invoke-AngularCommand {
    param(
        [Parameter(Mandatory)]
        [string]$AngularCliPath,
        [Parameter(Mandatory)]
        [string]$ReportDir,
        [Parameter(Mandatory)]
        [string]$CommandName,
        [Parameter(Mandatory)]
        [array]$Args,
        [string]$MainLog
    )
    $logFile = Join-Path $ReportDir "${CommandName}.log"
    $commandLine = "ng $($Args -join ' ')"
    Write-Log "Executando: $commandLine" -Level Info -LogFile $MainLog
    try {
        $startTime = Get-Date
        & $AngularCliPath $Args *> $logFile
        if ($LASTEXITCODE -ne 0) {
            throw "Comando falhou com código $LASTEXITCODE"
        }
        $duration = (Get-Date) - $startTime
        $durationFormatted = "{0:mm} min {0:ss} seg" -f $duration
        Write-Log "Comando concluído em $durationFormatted" -Level Success -LogFile $MainLog
        return $true
    }
    catch {
        Write-Log "Falha no comando '$CommandName': $_" -Level Error -LogFile $mainLog
        Write-Log "Consulte o log: $logFile" -Level Error -LogFile $mainLog
        return $false
    }
}

# =================================================
# LÓGICA PRINCIPAL
# =================================================
$mainLog = $null
$reportDir = $null

try {
    Write-Log "Iniciando script de análise Angular (v$SCRIPT_VERSION)" -Level Info

    # Obter info do projeto
    $projectInfo = Get-ProjectInfo
    Write-Log "Projeto: $($projectInfo.ProjectName)" -Level Info
    Write-Log "Branch: $($projectInfo.BranchName)" -Level Info
    
    if ($projectInfo.CommitHash) {
        Write-Log "Commit: $($projectInfo.CommitHash)" -Level Info
    }

    # Inicializar diretório de relatórios
    $reportDir = Initialize-ReportDir $projectInfo
    Write-Log "Relatórios serão salvos em: $reportDir" -Level Info

    # Configurar log principal
    $mainLog = Join-Path $reportDir "relatorioAngular.log"
    @"
============== RELATÓRIO ANGULAR ==============
Script Version: $SCRIPT_VERSION
Projeto:       $($projectInfo.ProjectName)
Branch:        $($projectInfo.BranchName)
Commit:        $($projectInfo.CommitHash)
Timestamp:     $(Get-Date)
Diretório:     $reportDir
==============================================
"@ | Out-File $mainLog

    # Verificar instalação do Angular
    $angularPath = Test-AngularInstallation -AngularCliPath $AngularCliPath
    $angularVersion = & $angularPath --version | Select-Object -First 1
    Write-Log "Usando Angular CLI: $angularVersion" -Level Info -LogFile $mainLog

    # Definir comandos do Angular
    $angularCommands = @(
        [PSCustomObject]@{CommandName="build"; Args=@("build")},
        [PSCustomObject]@{CommandName="lint"; Args=@("lint")},
        [PSCustomObject]@{CommandName="test"; Args=@("test", "--watch=false", "--code-coverage")}
    )

    # Executar comandos
    $results = @{}
    foreach ($cmd in $angularCommands) {
        $success = Invoke-AngularCommand -AngularCliPath $angularPath `
                                         -ReportDir $reportDir `
                                         -CommandName $cmd.CommandName `
                                         -Args $cmd.Args `
                                         -MainLog $mainLog
        $results[$cmd.CommandName] = $success
    }

    # Processar relatórios de cobertura
    $coverageDir = Join-Path (Get-Location) "coverage"
    if (Test-Path $coverageDir) {
        $coverageReportDir = Join-Path $reportDir "coverage"
        Copy-Item -Path $coverageDir -Destination $coverageReportDir -Recurse -Force
        Write-Log "Relatório de cobertura copiado para: $coverageReportDir" -Level Info -LogFile $mainLog
    }

    # Gerar resumo da execução
    $summaryFile = Join-Path $reportDir "resumo_execucao.txt"
    $summaryContent = @"
RESUMO DA EXECUÇÃO
==================
Projeto:      $($projectInfo.ProjectName)
Branch:       $($projectInfo.BranchName)
Commit:       $($projectInfo.CommitHash)
Data/Hora:    $(Get-Date)
Angular CLI:  $angularVersion
COMANDOS EXECUTADOS:
"@

    foreach ($cmd in $angularCommands) {
        $status = if ($results[$cmd.CommandName]) { "SUCESSO" } else { "FALHA" }
        $summaryContent += "• $($cmd.CommandName.PadRight(10)) $status`n"
    }

    $summaryContent += @"
RELATÓRIOS DISPONÍVEIS:
- Diretório completo: $reportDir
- Log principal: $(Split-Path $mainLog -Leaf)
- Relatório de cobertura: $(if (Test-Path $coverageReportDir) { (Split-Path $coverageReportDir -Leaf) } else { "N/A" })
"@

    $summaryContent | Out-File $summaryFile

    # Finalização
    Write-Log "Processo concluído com sucesso!" -Level Success -LogFile $mainLog
    Write-Host "`n=== RELATÓRIOS GERADOS ===" -ForegroundColor Cyan
    Write-Host "Diretório principal: file:///$reportDir" -ForegroundColor Yellow
    Write-Host "Resumo da execução: file:///$summaryFile" -ForegroundColor Yellow

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
        Write-Host "Relatórios parciais disponíveis em: file:///$reportDir" -ForegroundColor Yellow
    }
    
    exit 1
}