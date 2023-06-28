#1-27-2023, Snoel

#Update Source Folder Location
$SourceVersion = "NA"
$AppName = "Packer-PreReqs"
$AppVersion = "NA"
$Version = "NA"
$LogPath = "C:\Windows\MDT"

Start-Transcript -Path $LogPath\$AppName.PSLog.Txt
Try {
    
    Write-host "Waiting for RdAgent Service"
    while ((Get-Service RdAgent).Status -ne 'Running') {Start-Sleep -s 5}
    Write-host "Waiting for WindowsAzureGuestAgent Service"
    while ((Get-Service WindowsAzureGuestAgent).Status -ne 'Running') {Start-Sleep -s 5}
    
    Write-host "Logged in user is $($env:username)"

    Write-host "Setting Timezone to CST"
    Set-TimeZone "Central Standard Time" -PassThru

    # Configure UAC to allow privilege elevation in remote shells
    Write-Host "Configuring UAC"
    $Key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
    $Setting = 'LocalAccountTokenFilterPolicy'
    Set-ItemProperty -Path $Key -Name $Setting -Value 1 -Force

    Write-Host "Disable UAC"
    reg.exe ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 0 /f

    # Set administrator password
    Write-Host "Setting Admin Account"
    New-LocalUser -name Administrator -Password ($env:AZURE_LOCALUSER | ConvertTo-SecureString -AsPlainText -Force) -PasswordNeverExpires -Description "Temp Admin"
    Add-LocalGroupMember -Name Administrators -Member Administrator

    Write-host "Local Admins are:"
    get-localgroupmember -Group Administrators

    Write-Host "Disable IPv6"
    reg.exe add HKLM\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters /v DisabledComponents /t REG_DWORD /d 0x000000FF /f

    Write-Host "Disable System Restore"
    Reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v DisableSR /t REG_DWORD /d 1 /f

    Write-Host "Set Screen to Never turn Off"
    powercfg -change -monitor-timeout-ac 0

    Write-Host "Disable Task Offload"
    reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\TCPIP\Parameters" /v DisableTaskOffload /t REG_DWORD /d 0x1 /f

    Write-host "Disable File Security Checks"
    [Environment]::SetEnvironmentVariable("SEE_MASK_NOZONECHECKS","1","Machine")

    Write-Host "Disable MaintenanceMode-TiWorker"
    Reg.exe add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" /v MaintenanceDisabled /t REG_DWORD /d 1 /f

    Write-Host "Disable Shutdown Tracker"
    reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Reliability" /v ShutDownReasonOn /t REG_DWORD /d 0 /f

    Write-Host "Enable File and Print Sharing"
    netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes

    Write-Host "Packer-PreReqs DONE!!"
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