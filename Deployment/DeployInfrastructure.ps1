#Required Variables
$env = "prod"
$group = "sloe"
$service = "infra"
$region = "East US"

#Scope variables
$serviceName = $group+$service+$env
$regionLower = $region.ToLower().Replace(" ","");
$resourceGroupName = $serviceName+"rg"
$storageName = $serviceName+"sa"
$vaultName = $serviceName+"vault"

#Create Azure Resource Group if not exists.
Get-AzureRmResourceGroup -Name $resourceGroupName -ev notPresent -ea 0
if ($notPresent) 
{
    Write-Host "Azure Resource Group Not Present. Deploying Infrastructure..."
    Write-Host "Creating Azure Resource Group [$($resourceGroupName)] in [$($region)]" -ForegroundColor Green
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $region
    $resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName

    Write-Host "Creating Azure Storage Account [$($storageName)] in [$($region)]" -ForegroundColor Green
    New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageName -SkuName Standard_LRS -Location $region
    
    Write-Host "Creating Azure KeyVault [$($vaultName)] in [$($regionLower)]" -ForegroundColor Green
    New-AzureRmKeyVault -ResourceGroupName $resourceGroup.ResourceGroupName -VaultName $vaultName -Location $regionLower
    
    Write-Host "Deploying Infrastructure Completed - Please make sure to add the service principal permission to the keyvault" -ForegroundColor Yellow
}
else 
{
    Write-Host "Azure Resource Group Exists. Skipping" -ForegroundColor Yellow
}
