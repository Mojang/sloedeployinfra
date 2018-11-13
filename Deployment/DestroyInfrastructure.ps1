$scriptPath = $(get-location).Path
$subscription = "Microsoft Minecraft Azure"
$tenantId = "72f988bf-86f1-41af-91ab-2d7cd011db47"
$env = "prod"
$group = "sloe"
$service = "infra"
$serviceName = $group+$service+$env
$region = "East US"

#Set the variables
$resourceGroupName = $serviceName+"rg"
$storageName = $serviceName+"sa"
$vaultName = $serviceName+"vault"

Connect-AzureRmAccount
Get-AzureRmSubscription

#Select the subscription
Set-AzureRmContext -SubscriptionName $subscription -Tenant $tenantId

#Create Azure Resource Group if not exists.
Get-AzureRmResourceGroup -Name $resourceGroupName -ev notPresent -ea 0
if ($notPresent) 
{
    Write-Host "Azure Resource Group Not Present. Skipping..."
}
else 
{
    Write-Host "Preparing to destroy the azure resource group [$($resourceGroupName)]"
    Remove-AzureRmResourceGroup -Name $resourceGroupName -Verbose -Force
}
