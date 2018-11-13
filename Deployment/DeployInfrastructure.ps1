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

Write-Host "Executing at path $($scriptPath) via Service Principle" -ForegroundColor Yellow
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

