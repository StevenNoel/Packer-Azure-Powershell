#1-27-2023, Snoel

$SourceVersion = "NA"
$AppName = "Packer-Base"
$AppVersion = "NA"

$Version = "V1"
$LogPath = "C:\Windows\MDT"

Start-Transcript -Path $LogPath\$Appname.$SourceVersion.$Version.PSLog.Txt
Try {

    Write-host "Sleep for 10"
    start-sleep -seconds 10 -Verbose

    #Drive Maps
    $psscripts = "\\server1.domain.com\share1$"
    $cmapps = "\\server3.domain.com\share3$"

    Write-Host "Mapping Drive to $psscripts"
    Net use N: "$psscripts" "$env:AZURE_MDT" /user:domain\service-account /p:yes
    if (Test-Path -Path "$psscripts") {Write-host "Network for $psscripts ps-scripts looks good"}

    Write-Host "Mapping Drive to $cmapps"
    Net use W: "$cmapps" /user:domain\service-account $env:AZURE_MDT /p:yes
    if (Test-Path -Path "$cmapps") {Write-host "Network for $cmapps looks good"}

    net use

    #MDT Log Directory
    Write-Host "Kicking off MDT Log Creation Script. $(Get-Date)"
    Start-Process "powershell.exe" -Wait -ArgumentList "-executionpolicy bypass -file ""$cmapps\CTX-Packer-Log.ps1"" -force" -NoNewWindow
    Write-Host "Finished Kicking off MDT Log Creation Script. $(Get-Date)"

    #Time Adjust
    Write-Host "Kicking off Time-Adjust. $(Get-Date)"
    Start-Process "powershell.exe" -Wait -ArgumentList "-executionpolicy bypass -file ""$psscripts\Packer\CTX-Packer-Time.ps1"" -force" -NoNewWindow
    Write-Host "Finished Kicking off Time-Adjust. $(Get-Date)"

    #Dot Net 3.5
    Write-Host "Kicking off dot Net 3.5. $(Get-Date)"
    Start-Process "powershell.exe" -Wait -ArgumentList "-executionpolicy bypass -file ""$cmapps\Packer\CTX-Packer-dotNET3.5.ps1"" -force" -NoNewWindow
    Write-Host "Finished Kicking off dot Net 3.5. $(Get-Date)"

    #Dot Net 4.8
    Write-Host "Kicking off dot Net 4.8. $(Get-Date)"
    Start-Process "powershell.exe" -Wait -ArgumentList "-executionpolicy bypass -file ""$cmapps\Packer\CTX-Packer-dotNET.ps1"" -force" -NoNewWindow
    Write-Host "Finished Kicking off dot Net 4.8. $(Get-Date)"

    #Roles and Features
    Write-Host "Kicking off Roles and Features. $(Get-Date)"
    Start-Process "powershell.exe" -Wait -ArgumentList "-executionpolicy bypass -file ""$psscripts\Packer\CTX-Packer-RSAT-Roles.ps1"" -force" -NoNewWindow
    Write-Host "Finished Kicking off Roles and Features. $(Get-Date)"

    #Installing the C++ Redistribs
    Write-Host "Kicking off C++ Redistributables. $(Get-Date)"
    Start-Process "powershell.exe" -Wait -ArgumentList "-executionpolicy bypass -file ""$cmapps\CTX-Packer-Redistribs.ps1"" -force" -NoNewWindow
    Write-Host "Finished Kicking off C++ Redistributables. $(Get-Date)"

    Write-Host "Packer-Base DONE!!!"
    Start-Sleep -Seconds 10 -Verbose
    $LASTEXITCODE

}
catch {
    "Start CATCH $(Get-Date)" | Tee-Object -FilePath $LogPath\Errors.txt -Append
    $($MyInvocation.MyCommand.path) | Tee-Object -FilePath $LogPath\Errors.txt -Append
    $_ | Tee-Object -FilePath $LogPath\Errors.txt -Append
    "END CATCH" | Tee-Object -FilePath $LogPath\Errors.txt -Append
}

Stop-Transcript
