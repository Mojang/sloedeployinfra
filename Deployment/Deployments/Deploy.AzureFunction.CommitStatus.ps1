#Required Variables
$env = "prod"
$group = "sloe"
$service = "cmts"
$region = "East US"

#Scope variables
$scriptPath = $(get-location).Path
$regionLower = $region.ToLower().Replace(" ","");
$serviceName = $group+$service+$env
$resourceGroupName = $serviceName+"rg"
$appName = $serviceName+"app"
$appKey = $appName+"key"
$vaultName = $group+"inf"+$env+"vault"

Write-Host "path is " + $scriptPath
$appTemplate = "..\Templates\AzureFunctionOnAppServicePlan.json"
Write-Host "template is " + $appTemplate

#Create Azure Resource Group if not exists.
Get-AzureRmResourceGroup -Name $resourceGroupName -ev notPresent -ea 0
if ($notPresent) 
{
    Write-Host "Azure Resource Group [$($resourceGroupName)] Not Present. Deploying Infrastructure..."
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
