# =====================================================================================================================
# Title:   Deploy the Studios Live Operations Engineering Infrastructure to Azure.
# =====================================================================================================================
param
(
    [string] [Parameter(Mandatory=$true)] $Environment = "Prod", # Default to error if not set.
    [string] [Parameter(Mandatory=$true)] $Region = "East US", # Default to East US if not set.
	[string] [Parameter(Mandatory=$true)] $Service,
	[string] [Parameter(Mandatory=$false)] $SPClientID,
	[string] [Parameter(Mandatory=$false)] $SPKey,
	[string] [Parameter(Mandatory=$false)] $SPTenantID
)

# ---------------------------------------------------------------------------------------------------------------------
# Set all of the parameters for this install.
# ---------------------------------------------------------------------------------------------------------------------
$DeploymentRegion = $Region
$DeploymentUser = $env:USERNAME
$ParentScriptName  = $myInvocation.MyCommand
#$PathToInfrastructureDeploymentDirectory = "$($SourceDirectory)Core\"
#$PathToServicesDeploymentDirectory  = "$($SourceDirectory)Services\"

# Validate the environment name
$DeploymentEnvironment = $DeploymentEnvironment.ToLower()
if (($DeploymentEnvironment.Length -gt 4) -or ($DeploymentEnvironment -match '[^a-z0-9]'))
{
	throw New-Object System.ArgumentException "The DeploymentEnvironment variable is not valid. Custom environment names must be <= 4 characters, and can only contain alphanumberic characters. You provided the value: [$Environment]."
}

# Validate the environment name
$Service = $Service.ToLower()
if (($Service.Length -gt 4) -or ($Service -match '[^a-z0-9]'))
{
	throw New-Object System.ArgumentException "The Service variable is not valid. Custom service names must be <= 4 characters, and can only contain alphanumberic characters. You provided the value: [$Service]."
}

switch ($DeploymentRegion)
{
	"Central US" { $DeploymentRegionAbbreviation = "cus" }
	"East US" { $DeploymentRegionAbbreviation = "eus" }
	"East US 2" { $DeploymentRegionAbbreviation = "eus2" }
	"North Central US" { $DeploymentRegionAbbreviation = "ncus" }
	"South Central US" { $DeploymentRegionAbbreviation = "scus" }
	"West US" { $DeploymentRegionAbbreviation = "wus" }
	"North Europe" { $DeploymentRegionAbbreviation = "neu" }
	"West Europe" { $DeploymentRegionAbbreviation = "weu" }
	"East Asia" { $DeploymentRegionAbbreviation = "ea" }
	"Southeast Asia" { $DeploymentRegionAbbreviation = "sea" }
	"Japan East" { $DeploymentRegionAbbreviation = "je" }
	"Japan West" { $DeploymentRegionAbbreviation = "jw" }
	"Brazil South" { $DeploymentRegionAbbreviation = "bz" }
	"Australia East" { $DeploymentRegionAbbreviation = "aue" }
	"Australia Southeast" { $DeploymentRegionAbbreviation = "ause" }
	"Central India" { $DeploymentRegionAbbreviation = "cin" }
	"South India" { $DeploymentRegionAbbreviation = "sin" }
	"West India" { $DeploymentRegionAbbreviation = "win" }
	default { Log-Invalid; Write-Error "Invalid Deployment Region specified."; return -1;}
}

#Scope variables
$serviceName = $DeploymentTeam+$Service+$DeploymentEnvironment
$regionLower = $DeploymentRegion.ToLower().Replace(" ","");
$resourceGroupName = $serviceName+"rg"
$storageName = $serviceName+"sa"
$vaultName = $serviceName+"vault"

#$SLOEServicePrincipalCertificateFileName         = "$($SourceDirectory)..\Certs\sloeserviceprincipal.pfx"
#$spcreds = New-Object System.Management.Automation.PSCredential($SPClientID,$SecureKey)
#$addAzureRmSuccess = Add-AzureRMAccount -ServicePrincipal -Credential $spcreds -Tenant $SPTenantID
#f($null -ne $adAzureRmSuccess){Log-Success} else { Log-Failure; throw "Azure RM Account authentication failed."}
#$KeyVaultCertificatePassword = (Get-AzureKeyVaultSecret -VaultName $SourceKeyVaultName -SecretName "$KeyVaultCertificateVaultKey").SecretValueText

#if($null -ne $KeyVaultCertificatePassword)
#{
#	Write-Host "Attempting to import KeyVault Service Principal Certificate [$KeyVaultCertificateFilename]"
#	# Certificate Objects
#	$KeyVaultServicePrincipalCertificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
#	$KeyVaultServicePrincipalCertificate.Import($KeyVaultCertificateFilename, (ConvertTo-SecureString -String $KeyVaultCertificatePassword -Force –AsPlainText), [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::DefaultKeySet);
#	Log-Success
#} 
#else
#{
#	Write-Host -ForegroundColor Black -BackgroundColor Red "The KeyVault certificate password is null, importing service principal cert failed!"
#	throw "Certificate password for KeyVault Service Prinicpal was not provided."
#}

Wirte-Host "Starting Deployment of $($serviceName) as principal $($DeploymentUser)"
#Create Azure Resource Group if not exists.
Get-AzureRmResourceGroup -Name $resourceGroupName -ev notPresent -ea 0
if ($notPresent) 
{
    Write-Host "Azure Resource Group Not Present. Deploying Infrastructure..."
    Write-Host "Creating Azure Resource Group [$($resourceGroupName)] in [$($DeploymentRegion)]" -ForegroundColor Green
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $DeploymentRegion
    $resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName

    Write-Host "Creating Azure Storage Account [$($storageName)] in [$($DeploymentRegion)]" -ForegroundColor Green
    New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageName -SkuName Standard_LRS -Location $DeploymentRegion
    
    Write-Host "Creating Azure KeyVault [$($vaultName)] in [$($regionLower)]" -ForegroundColor Green
    New-AzureRmKeyVault -ResourceGroupName $resourceGroup.ResourceGroupName -VaultName $vaultName -Location $regionLower
    
    Write-Host "Deploying Infrastructure Completed - Please make sure to add the service principal permission to the keyvault" -ForegroundColor Yellow
}
else 
{
    Write-Host "Azure Resource Group Exists. Skipping" -ForegroundColor Yellow
}
