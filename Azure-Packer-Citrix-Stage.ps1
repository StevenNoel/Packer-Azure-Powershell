#1-25-2023, Created by Steve Noel
#This is building a Citrix Image using Packer

#Install Azure Module
Install-Module -Name Az -AllowClobber -Scope CurrentUser -Force

#Packer service account
#set up path and user variables
    $AESKeyFilePath = "\\ServerName\Share\folder\aeskey.txt" # location of the AESKey                
    $SecurePwdFilePath = "\\ServerName\Share\folder\credpassword.txt" # location of the file that hosts the encrypted password                
    $userUPN = "DomainA\Username" # User account login 

    #use key and password to create local secure password
    $AESKey = Get-Content -Path $AESKeyFilePath 
    $pwdTxt = Get-Content -Path $SecurePwdFilePath
    $securePass = $pwdTxt | ConvertTo-SecureString -Key $AESKey

    #crete a new psCredential object with required username and password
    $scriptCreds = New-Object System.Management.Automation.PSCredential($userUPN, $securePass)
    $MDTpacker = $scriptcreds.GetNetworkCredential().password

$AdminUser = "SuperSecretPassword"

#Auth to Azure
$profilepath = "C:\Users\<username>\MyAzureProfile.JSON"    
$profile = Import-AzContext -Path $profilePath
$SubscriptionID = $profile.Context.Subscription.SubscriptionId
Set-AzContext -SubscriptionId $SubscriptionID

#Get Values for Packer
$Vault = "<Azure Vault>" #Vault where Service Principle Secret is stored
$ClientID = "<Service Principle Client ID>"
Get-AzKeyVault -VaultName $Vault #Verify Vault
$ClientSecret = Get-AzKeyVaultSecret -VaultName $Vault -Name $ClientID -AsPlainText

#Computername for Packer
$PackerCompName = "ctxaz" + $(Get-Date -Format "yyMMddHHmm")

#Image Name in Azure
$managed_image_name = "Citrix-Azure-Image-" + $(Get-Date -Format "yyMMdd-HHmm")

#Set Values as Env Variables
[System.Environment]::SetEnvironmentVariable('AZURE_CLIENT_ID',"$ClientID",[System.EnvironmentVariableTarget]::User)
[System.Environment]::SetEnvironmentVariable('AZURE_CLIENT_SECRET',"$ClientSecret",[System.EnvironmentVariableTarget]::User)
[System.Environment]::SetEnvironmentVariable('AZURE_PackerCompName',"$PackerCompName",[System.EnvironmentVariableTarget]::User)
[System.Environment]::SetEnvironmentVariable('AZURE_ManagedImageName',"$managed_image_name",[System.EnvironmentVariableTarget]::User)
[System.Environment]::SetEnvironmentVariable('AZURE_MDT',"$MDTPacker",[System.EnvironmentVariableTarget]::User)
[System.Environment]::SetEnvironmentVariable('AZURE_LOCALUSER',"$AdminUser",[System.EnvironmentVariableTarget]::User)


#Set the location of where Packer and Azure config is stored
#Packer
set-location -path "\\ServerName\Share\folder"
./packer.exe validate .\Packer-CTXAZPK-VDA-Citrix.pkr.hcl  #Validate Packer HCL/JSON
./packer.exe build .\Packer-CTXAZPK-VDA-Citrix.pkr.hcl     #Build from Packer HCL/JSON

#Remove Envivronment Varible Values
[Environment]::SetEnvironmentVariable("AZURE_CLIENT_ID", $null ,"User")
[Environment]::SetEnvironmentVariable("AZURE_CLIENT_SECRET", $null ,"User")
[Environment]::SetEnvironmentVariable("AZURE_PackerCompName", $null ,"User")
[Environment]::SetEnvironmentVariable("AZURE_ManagedImageName", $null ,"User")
[Environment]::SetEnvironmentVariable("AZURE_MDT", $null ,"User")
[Environment]::SetEnvironmentVariable("AZURE_LOCALUSER", $null ,"User")