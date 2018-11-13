﻿Install-Module -Name AzureADPreview -Force
Get-Module -ListAvailable -Name Azure -Refresh

# Workaround to use AzureAD in this task. Get an access token and call Connect-AzureAD
$serviceNameInput = Get-VstsInput -Name ConnectedServiceNameSelector -Require
$serviceName = Get-VstsInput -Name $serviceNameInput -Require
$endPointRM = Get-VstsEndpoint -Name $serviceName -Require
 
$clientId = $endPointRM.Auth.Parameters.ServicePrincipalId
$clientSecret = $endPointRM.Auth.Parameters.ServicePrincipalKey
$tenantId = $endPointRM.Auth.Parameters.TenantId

$adTokenUrl = "https://login.microsoftonline.com/$tenantId/oauth2/token"
$resource = "https://graph.windows.net/"
 
$body = @{
    grant_type    = "client_credentials"
    client_id     = $clientId
    client_secret = $clientSecret
    resource      = $resource
}
 
$response = Invoke-RestMethod -Method 'Post' -Uri $adTokenUrl -ContentType "application/x-www-form-urlencoded" -Body $body
$token = $response.access_token
 
Write-Verbose "Login to AzureAD with same application as endpoint"
Connect-AzureAD -AadAccessToken $token -AccountId $clientId -TenantId $tenantId

#Required Variables
$env = "prod"
$group = "sloe"
$service = "cmts"
$vaultName = $group+"inf"+$env+"vault"
$region = "East US"
$servicePrincipal = "sloeinfrastructureserviceprinciple"
$applicationId = "06297832-089a-4452-ac9e-a518e448ba90"

#Scope variables
$scriptPath = $(get-location).Path
$regionLower = $region.ToLower().Replace(" ","");
$serviceName = $group+$service+$env
$resourceGroupName = $serviceName+"rg"
$appName = $serviceName+"app"
$appKey = $appName+"key"
$appTemplate = $scriptPath+"\..\templates\AzureFunctionOnAppServicePlan.json"

Write-Host "Executing at path $($scriptPath)"
Write-Host "Service Principal $($servicePrincipal)"
Write-Host "Application ID $($applicationId)"

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

    Write-Host "Validating ARM Template for [$($serviceName)] Function using App Service Plan in [$($region)]"
    Test-AzureRmResourceGroupDeployment -ResourceGroupName testgroup -TemplateFile $appTemplate

    Write-Host "Creating Azure [$($serviceName)] Function using App Service Plan in [$($region)]"
    New-AzureRmResourceGroupDeployment -Name $serviceName -ResourceGroupName $resourceGroupName -TemplateFile $appTemplate

    
    Write-Host "Environment Created - Please make sure to add the service principal permission to the keyvault"
}
else 
{
    Write-Host "Azure Resource Group [$($resourceGroupName)] Exists. Skipping" -ForegroundColor Yellow
}
