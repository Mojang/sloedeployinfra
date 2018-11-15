#Required Variables
$env = "prod"
$group = "sloe"
$service = "cmts"
$region = "East US"

#Scope variables
$scriptPath = $(get-location).Path
$sourceDir=$env:BUILD_SOURCESDIRECTORY
$regionLower = $region.ToLower().Replace(" ","");
$serviceName = $group+$service+$env
$resourceGroupName = $serviceName+"rg"
$appName = $serviceName+"app"
$appKey = $appName+"key"
$vaultName = $group+"inf"+$env+"vault"
$appTemplate = "$($sourceDir)\Deployment\Templates\AzureFunctionOnAppServicePlan.json"


#Create Azure Resource Group if not exists.
Get-AzureRmResourceGroup -Name $resourceGroupName -ev notPresent -ea 0
if ($notPresent) 
{
    Write-Host "Azure Resource Group [$($resourceGroupName)] Not Present. Deploying Infrastructure..."
    Write-Host "Creating Azure Resource Group [$($resourceGroupName)] in [$($region)]"
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $region

    Write-Host "Creating Azure [$($serviceName)] Function using App Service Plan in [$($region)]"

    Write-Host "Validating ARM Template for [$($serviceName)] Function using App Service Plan in [$($region)]" 
    Test-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $appTemplate -location $region -appName $serviceName 

    Write-Host "Creating Azure [$($serviceName)] Function using App Service Plan in [$($region)]"
    New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $appTemplate -location $region -appName $serviceName

    
    Write-Host "Azure Function [$($serviceName)] was created!"
}
else 
{
    Write-Host "Azure Resource Group [$($resourceGroupName)] Exists. Azure Function [$($serviceName)] already Exists!" -ForegroundColor Yellow
}
