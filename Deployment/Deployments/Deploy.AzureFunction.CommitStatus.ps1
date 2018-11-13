Import-Module "C:\Program Files (x86)\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Azure.psd1"
#Required Variables
$env = "prod"
$group = "sloe"
$service = "cmts"
$vaultName = $group+"inf"+$env+"vault"
$region = "East US"

#Scope variables
$scriptPath = $(get-location).Path
$regionLower = $region.ToLower().Replace(" ","");
$serviceName = $group+$service+$env
$resourceGroupName = $serviceName+"rg"
$appName = $serviceName+"app"
$appKey = $appName+"key"
$appTemplate = $scriptPath+"\..\templates\AzureFunctionOnAppServicePlan.json"

Write-Host "Executing at path $($scriptPath)"
Write-Host "Service Principal dev-mc-Minecraft-0f4f1cf7-6423-415c-9f9c-599eb36bdf4f"
Write-Host "Application ID 06297832-089a-4452-ac9e-a518e448ba90"

Get-AzureRmContext

#Create Azure Resource Group if not exists.
Get-AzureRmResourceGroup -Name $resourceGroupName -ev notPresent -ea 0
if ($notPresent) 
{
    Write-Host "Azure Resource Group Not Present. Deploying Infrastructure..."
    Write-Host "Creating Azure Resource Group [$($resourceGroupName)] in [$($region)]" -ForegroundColor Green
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $region
    $resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName
    Write-Host "Creating Azure AD App [$($appName)] URI [https://$($appName)]"
    $NewApp=New-AzureADApplication -DisplayName "$($appName)" -IdentifierUris "https://$($appName)"
    Write-Host "Creating Service Principal for AD App [$($appName)]"
    $NewAppPrincipal = New-AzureADServicePrincipal -AppId $NewApp.AppId
    Write-Host "Creating Service Principal Password for AD App [$($appName)]"
    $secret=New-AzureADApplicationPasswordCredential -ObjectId $NewApp.ObjectId
    Write-Host "Getting Context of the Service Principal for AD App [$($appName)]"
    $principal = Get-AzureADServicePrincipal -Filter "DisplayName eq '$($appName)'"
    Write-Host "Granting Keyvault Access to [$($vaultName)] for AD App [$($appName)]"
    Set-AzureRmKeyVaultAccessPolicy -VaultName $vaultName -ObjectId $principal.ObjectId -PermissionsToSecrets get,set
    $ss = ConvertTo-SecureString -String $secret.Value -AsPlainText -Force
    Write-Host "Storing Service Principal Password to Secret [$($appKey)] in vault [$($vaultName)]"
    Set-AzureKeyVaultSecret -VaultName $vaultName -Name $($appKey) -SecretValue $ss

    Write-Host "Creating Azure Resource Group [$($resourceGroupName)] in [$($region)]"
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $region

    Write-Host "Creating Azure [$($serviceName)] Function using App Service Plan in [$($region)]"

    Write-Host "Creating Azure [$($serviceName)] Function using App Service Plan in [$($region)]"
    New-AzureRmResourceGroupDeployment -Name $serviceName -ResourceGroupName $resourceGroupName -TemplateFile $appTemplate

    
    Write-Host "Environment Created - Please make sure to add the service principal permission to the keyvault"
}
else 
{
    Write-Host "Azure Resource Group Exists. Skipping" -ForegroundColor Yellow
}
