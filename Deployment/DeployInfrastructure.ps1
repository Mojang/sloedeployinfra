﻿#Required Variables
$scriptPath = $(get-location).Path
$subscription = "Microsoft Minecraft Azure"
$tenantId = "72f988bf-86f1-41af-91ab-2d7cd011db47"
$env = "prod"
$group = "sloe"
$service = "infra"
$serviceName = $group+$service+$env
$region = "East US"
$servicePrincipal = "dev-mc-Minecraft-0f4f1cf7-6423-415c-9f9c-599eb36bdf4f"
$servicePrincipalID = "9e1d118d-a4ff-449a-8186-0a46d3e6decf"

#Scope variables
$regionLower = $region.ToLower().Replace(" ","");
$resourceGroupName = $serviceName+"rg"
$storageName = $serviceName+"sa"
$vaultName = $serviceName+"vault"

Write-Host "Executing at path $($scriptPath) via Service Principle $($servicePrincipal)" -ForegroundColor Yellow
Get-AzureRmContext


#Create Azure Resource Group if not exists.
Get-AzureRmResourceGroup -Name $resourceGroupName -ev notPresent -ea 0
if ($notPresent) 
{
    Write-Host "Azure Resource Group Not Present. Deploying Infrastructure..."
    Write-Host "Creating Azure Resource Group [$($resourceGroupName)] in [$($region)]" -ForegroundColor Green
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $region
    $resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName

    #New-AzureRmResourceGroupDeployment -Name ExampleDeployment -ResourceGroupName ExampleResourceGroup -TemplateFile "$($scriptPath)\storage.json" -storageAccountType Standard_GRS
    Write-Host "Creating Azure Storage Account [$($storageName)] in [$($region)]" -ForegroundColor Green
    New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageName -SkuName Standard_LRS -Location $region
    
    Write-Host "Creating Azure KeyVault [$($vaultName)] in [$($regionLower)]" -ForegroundColor Green
    New-AzureRmKeyVault -ResourceGroupName $resourceGroup.ResourceGroupName -VaultName $vaultName -Location $regionLower
    $vault = Get-AzureRmKeyVault -ResourceGroupName $resourceGroup.ResourceGroupName -VaultName $vaultName

    Write-Host "Granting Service Principle permissions to KeyVault for [$($servicePrincipalId)]" -ForegroundColor Green
    Set-AzureRmKeyVaultAccessPolicy -VaultName $vaultName -ObjectId $servicePrincipalId -PermissionsToKeys create,import,delete,list -PermissionsToSecrets 'all' -ErrorAction SilentlyContinue

    Write-Host "Granting Service Principle permissions to KeyVault for [$($servicePrincipal)]" -ForegroundColor Green
    Set-AzureRmKeyVaultAccessPolicy -VaultName $vaultName -ServicePrincipalName $servicePrincipal -PermissionsToKeys create,import,delete,list -PermissionsToSecrets 'all' -ErrorAction SilentlyContinue
    
    Write-Host "Test Granting permissions to KeyVault for [v-davidk@microsoft.com]" -ForegroundColor Green
    Set-AzureRmKeyVaultAccessPolicy -VaultName $vaultName -UserPrincipalName 'v-davidk@microsoft.com' -PermissionsToKeys create,import,delete,list -PermissionsToSecrets 'all' -ErrorAction SilentlyContinue
    
    $Secret = ConvertTo-SecureString -String 'Password' -AsPlainText -Force
    Write-Host "Test Setting Secret [TestSecret] to KeyVault [$($vaultName)]" -ForegroundColor Green
    Set-AzureKeyVaultSecret -VaultName $vaultName -Name 'TestSecret' -SecretValue $Secret -ErrorAction Continue
    Write-Host "Test Adding Key [TestCertSoftwareKey] to KeyVault [$($vaultName)] in [Software] destination." -ForegroundColor Green
    Add-AzureKeyVaultKey –VaultName $vaultName –Name ‘TestCertSoftwareKey’ –Destination ‘Software’ -ErrorAction Continue

    Write-Host "Deploying Infrastructure Completed - All Done" -ForegroundColor Yellow
}
else 
{
    Write-Host "Azure Resource Group Exists. Skipping" -ForegroundColor Yellow
}

