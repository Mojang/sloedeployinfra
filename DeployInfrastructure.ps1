$subscription = "Microsoft Minecraft Azure"
$tenantId = "72f988bf-86f1-41af-91ab-2d7cd011db47"
$env = "prod"
$group = "sloe"
$service = $group+"infra"+$env
$region = "East US"


#Set the variables
$resourceGroupName = $service+"rg"
$storageName = $service+"sa"
$vaultName = $service+"vault"

Get-AzureRmSubscription

#Select the subscription
Set-AzureRmContext -SubscriptionName $subscription -Tenant $tenantId


#Create Azure Resource Group if not exists.
Get-AzureRmResourceGroup -Name $resourceGroupName -ev notPresent -ea 0
if ($notPresent) 
{
    Write-Host "Azure Resource Group Not Present. Deploying Infrastructure..."
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $region
    $resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName
    New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageName -SkuName Standard_LRS
    New-AzureRmKeyVault -ResourceGroupName $resourceGroup.ResourceGroupName -Name $vaultName -Location $region #"eastus"
    $vault = Get-AzureRmKeyVault -ResourceGroupName $resourceGroup.ResourceGroupName -VaultName $vaultName

    #Retrieve Service Principle
    $AADApplicationName =”dev-mc-Minecraft-0f4f1cf7-6423-415c-9f9c-599eb36bdf4f”  
    $AADApp = Get-AzureRmADApplication -DisplayNameStartWith $AADApplicationName  
    $servicePrincipal = Get-AzureRmADServicePrincipal -SearchString $AADApp.DisplayName  

    #Add Service Principle to Vault
    Set-AzureRmKeyVaultAccessPolicy -VaultName 'KeyVaultTestResource' -ServicePrincipalName $servicePrincipal.ServicePrincipalNames[0] -PermissionsToSecrets 'Get,Set,Delete'

    #Add Specific User to Vault
    Set-AzureRmKeyVaultAccessPolicy -VaultName 'KeyVaultTestResource' -UserPrincipalName 'v-davidk@microsoft.com' -PermissionsToKeys create,import,delete,list -PermissionsToSecrets 'All'

    $Secret = ConvertTo-SecureString -String 'Password' -AsPlainText -Force
    Set-AzureKeyVaultSecret -VaultName $vaultName -Name 'TestSecret' -SecretValue $Secret
    Add-AzureKeyVaultKey –VaultName $vaultName –Name ‘CertSoftwareKey’ –Destination ‘Software’
}
else 
{
    Write-Host "Azure Resource Group Exists. Skipping"
}

