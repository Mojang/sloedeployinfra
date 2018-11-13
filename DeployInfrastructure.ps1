$scriptPath = $(get-location).Path
$subscription = "Microsoft Minecraft Azure"
$tenantId = "72f988bf-86f1-41af-91ab-2d7cd011db47"
$env = "prod"
$group = "sloe"
$service = "infra"
$serviceName = $group+$service+$env
$region = "East US"
$regionLower = $region.ToLower().Replace(" ","");


#Set the variables
$resourceGroupName = $serviceName+"rg"
$storageName = $serviceName+"sa"
$vaultName = $serviceName+"vault"

Write-Host "Executing DeployInfrastructure via principle" -ForegroundColor Yellow
$azureContext = Get-AzureRmContext
Write-Host "$($azureContext)" -ForegroundColor Yellow


#Create Azure Resource Group if not exists.
Get-AzureRmResourceGroup -Name $resourceGroupName -ev notPresent -ea 0
if ($notPresent) 
{
    Write-Host "Azure Resource Group Not Present. Deploying Infrastructure..." -ForegroundColor Green
    Write-Host "Creating Azure Resource Group [$($resourceGroupName)] in [$($region)]" -ForegroundColor Green
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $region
    $resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName

    #New-AzureRmResourceGroupDeployment -Name ExampleDeployment -ResourceGroupName ExampleResourceGroup -TemplateFile "$($scriptPath)\storage.json" -storageAccountType Standard_GRS
    Write-Host "Creating Azure Storage Account [$($storageName)] in [$($region)]" -ForegroundColor Green
    New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageName -SkuName Standard_LRS -Location $region
    
    Write-Host "Creating Azure KeyVault [$($vaultName)] in [$($regionLower)]" -ForegroundColor Green
    New-AzureRmKeyVault -ResourceGroupName $resourceGroup.ResourceGroupName -Name $vaultName -Location $regionLower
    $vault = Get-AzureRmKeyVault -ResourceGroupName $resourceGroup.ResourceGroupName -VaultName $vaultName

    $AADApplicationName =”dev-mc-Minecraft-0f4f1cf7-6423-415c-9f9c-599eb36bdf4f”
    Write-Host "Getting Azure Active Directory App Context for [$($AADApplicationName)]" -ForegroundColor Green
    $AADApp = Get-AzureRmADApplication -DisplayNameStartWith $AADApplicationName  
    Write-Host "Getting Service Principle Context for [$($AADApp.DisplayName)]" -ForegroundColor Green
    $servicePrincipal = Get-AzureRmADServicePrincipal -SearchString $AADApp.DisplayName  

    Write-Host "Test Granting Permissions to KeyVault for [$($servicePrincipal.ServicePrincipalNames[0])]" -ForegroundColor Green
    Set-AzureRmKeyVaultAccessPolicy -VaultName $vaultName -ServicePrincipalName $servicePrincipal.ServicePrincipalNames[0] -PermissionsToSecrets 'Get,Set,Delete' -PermissionsToKeys create,import,delete,list -PermissionsToSecrets 'All'

    Write-Host "Test Granting Permissions to KeyVault for [v-davidk@microsoft.com]" -ForegroundColor Green
    Set-AzureRmKeyVaultAccessPolicy -VaultName $vaultName -UserPrincipalName 'v-davidk@microsoft.com' -PermissionsToKeys create,import,delete,list -PermissionsToSecrets 'Get,Set,Delete'

    $Secret = ConvertTo-SecureString -String 'Password' -AsPlainText -Force
    Write-Host "Test Setting Secret [TestSecret] to KeyVault [$($vaultName)]" -ForegroundColor Green
    Set-AzureKeyVaultSecret -VaultName $vaultName -Name 'TestSecret' -SecretValue $Secret
    Write-Host "Test Adding Key [TestCertSoftwareKey] to KeyVault [$($vaultName)] in [Software] destination." -ForegroundColor Green
    Add-AzureKeyVaultKey –VaultName $vaultName –Name ‘TestCertSoftwareKey’ –Destination ‘Software’

    Write-Host "Deploying Infrastructure Completed - All Done" -ForegroundColor Yellow
}
else 
{
    Write-Host "Azure Resource Group Exists. Skipping" -ForegroundColor Yellow
}

