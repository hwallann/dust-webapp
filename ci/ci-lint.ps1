#!/usr/bin/pwsh

# PowerShell can be installed on Ubuntu through the Microsoft APT repository!
# Checkout https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux
# Note the different instructions for the different Ubuntu versions.
# run `lsb_release -a` to show your ubuntu version number

[CmdletBinding()]
param()
process {
    . (Join-Path $PSScriptRoot LoggingCommandFunctions.ps1)

    function Join-Lines {
        [OutputType([string])]
        param (
            [Parameter(Mandatory=$true)]
            [object[]]$InputObject
        )
        [System.Text.StringBuilder]$wr = New-Object System.Text.StringBuilder
        foreach ($line in $InputObject) {
            $wr.AppendLine($line) | Out-Null
        }
        $wr.ToString().Trim()
    }

    $npxCmd = Get-Command -CommandType Application npx | Select-Object -First 1
    Write-Host (Write-TaskDebug_Internal -Message "Invoking '$npxCmd vue-cli-service lint'" -AsOutput)
    $lintOut = & $npxCmd vue-cli-service lint --no-fix --format json
    $lintLines = Join-Lines -InputObject $lintOut
    $completeMessage = "'$npxCmd vue-cli-service lint' exited with code $LASTEXITCODE"
    if ($LASTEXITCODE -eq 0) {
        Write-Host $lintLines
        Write-Host (Write-SetResult -Result Succeeded -Message $completeMessage -AsOutput)
        return
    }

    $lintResult = $lintLines | ConvertFrom-Json
    $hasErrors = $false
    foreach ($lintFile in $lintResult) {
        [string]$filePath = $lintFile.filePath
        foreach ($lintIssue in $lintFile.messages) {
            $issueType = "warning"
            if ($lintIssue.severity -ne 1) {
                $issueType = "error"
                $hasErrors = $true
            }
            $code = $lintIssue.ruleId
            $lineNumber = $lintIssue.line
            $columnNumber = $lintIssue.column
            $message = $lintIssue.message

            Write-Host (Write-LogIssue -Type $issueType -Message $message -ErrCode $code -SourcePath $filePath -LineNumber $lineNumber -ColumnNumber $columnNumber -AsOutput)
        }
    }

    if ($hasErrors) {
        Write-Host (Write-SetResult -Result Failed -Message $completeMessage -AsOutput)
    } else {
        Write-Host (Write-SetResult -Result SucceededWithIssues -Message $completeMessage -AsOutput)
    }
}