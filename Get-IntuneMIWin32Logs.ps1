
<#PSScriptInfo

.VERSION 1.14

.GUID 0f5a4a8f-a301-4933-9b08-da09bc38b401

.AUTHOR PiotrG

.COMPANYNAME 

.COPYRIGHT 

.TAGS 

.LICENSEURI 

.PROJECTURI 

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES


#>

<# 

.DESCRIPTION 
 Sample script to get Win32App entries from IntuneManagedInstaller.log 

#> 
Param(
    [Parameter(Mandatory = $false,
        HelpMessage = "The name of the logfile. IntuneManagedExtension.log is used by default")]
    [String]$LogFileName = "IntuneManagementExtension.log",
    
    [Parameter(Mandatory = $false,
        HelpMessage = "The number of last lines to return")]
    [Int]$LinesNumber = 100,
    
    [Parameter(Mandatory = $false,
        HelpMessage = "Tai mode enabled")]
    [Bool]$TailModeEnabled = $true
)
$LogFilePath = "c:\ProgramData\Microsoft\IntuneManagementExtension\Logs\$($LogFileName)"
Function ShowCMLog ($sLine) {
    $reLine = ([regex]'<!\[LOG\[(.+)\]LOG\]!>').matches($sLine); 
    if ($reline.count -gt 0 ) { $body = $reLine[0].Groups[1].Value } 
    $reLine = ([regex]'<time="(.+)" date="(.+)" component').matches($sLine); 
    if ($reline.count -gt 0 ) { $DateTime = $reLine[0].Groups[2].Value + " " + $reLine[0].Groups[1].Value }  
    $oLog = New-Object System.Object;
    $oLog | Add-Member -type NoteProperty -name DateTime -value $DateTime;
    $oLog | Add-Member -type NoteProperty -name Message -value  $body
    $oLog = $oLog | Sort-Object 'DateTime'
    if ($reline.count -gt 0 ) {
        "$($oLog.DateTime) $($oLog.Message)"
    }
}
Function ShowFilteredContent {
    $global:content = $global:content | select-string -Pattern "BackgroundWorker is checking at" -NotMatch
    $global:content = $global:content | select-string -Pattern "Total valid AAD User session count is" -NotMatch 
    $global:content = $global:content | select-string -Pattern "ESP checker found 0 session for user" -NotMatch
    $global:content = $global:content| select-string -Pattern "active user sessions" -NotMatch
    $global:content = $global:content | Select-Object -last $LinesNumber
    $global:content3 = Compare-Object -ReferenceObject $global:content -DifferenceObject $global:content2
    #$content =( $content | Where-Object { $_ -like  } )
    foreach ($line in ($global:content3.InputObject) ) {
        ShowCMLog $line
    }
    $global:content2 = $global:content
} 
$global:content2 = @()
if (Test-Path $LogFilePath) {
    if ($TailModeEnabled) {
        while (1) {
            $global:content3 = @()
            $global:content = get-content $LogFilePath | Select-String -pattern "\[Win32App\]" 
            ShowFilteredContent
            start-sleep -Seconds 1
        } 
    } else {
        $global:content3 = @()
        $global:content = get-content $LogFilePath | Select-String -pattern "\[Win32App\]" 
        ShowFilteredContent
    }
}
else {
   "File $($LogFilePath) doesn't exist"
}