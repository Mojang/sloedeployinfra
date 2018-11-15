Clear-Host

Import-Module Azure
Import-Module AzureRM.Resources    

$ServicePrincipalApplicationId = "xxx"
$TenantId = "yyy"
$SubscriptionId = "zzz"
$CertificateName = "CN=SomeCertName"
$ResouceGroupName = "myRessourceGroup"
$location = "North Central US"
$VaultName = "MyVault" + (Get-Random -minimum 10000000 -maximum 1000000000)
$MySecret = ConvertTo-SecureString -String "MyValue" -AsPlainText -Force

$Cert = Get-ChildItem cert:\CurrentUser\My\ | Where-Object {$_.Subject -match $CertificateName }
Write-Host "cert.Thumbprint " $cert.Thumbprint
Write-Host "cert.Subject " $cert.Subject

Add-AzureRmAccount -ServicePrincipal -CertificateThumbprint $cert.Thumbprint -ApplicationId $ServicePrincipalApplicationId -TenantId $TenantId
Get-AzureRmSubscription
Set-AzureRmContext -SubscriptionId $SubscriptionId

Write-Host ""
Write-Host "Creating vault" -ForegroundColor Yellow

New-AzureRmResourceGroupDeployment -ResourceGroupName $ResouceGroupName -vaultName $vaultName -vaultlocation $location -isenabledForDeployment $true -TemplateFile ".\keyvault2.template.json"  -TemplateParameterFile ".\keyvault2.parameters.json"

Write-Host ""
Write-Host "Key Vault " $vaultName " deployed" -ForegroundColor green

Write-Host "Wait 5 seconds"
Start-Sleep -Seconds 5

Write-Host "Write Secret" -ForegroundColor Yellow    
Set-AzureKeyVaultSecret -VaultName $VaultName -Name "MyKey" -SecretValue $MySecret

Write-Host "Wait 10 seconds"
Start-Sleep -Seconds 10

Write-Host "Read secret"
Get-AzureKeyVaultSecret -VaultName $VaultName -Name "MyKey"