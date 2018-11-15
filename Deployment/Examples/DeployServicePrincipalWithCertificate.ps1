#Powershell Create Service Principal with Certificate
#https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-authenticate-service-principal-powershell

#https://stackoverflow.com/questions/45080489/service-principal-set-azurermkeyvaultaccesspolicy-insufficient-privileges-to
#Set-AzureRmKeyVaultAccessPolicy -VaultName $name -ObjectId $oId -PermissionsToSecrets get
#returns error
#Set-AzureRmKeyVaultAccessPolicy : Insufficient privileges to complete the operation. 
#Solution is to add additional parameter -BypassObjectIdValidation
#Set-AzureRmKeyVaultAccessPolicy -BypassObjectIdValidation -VaultName $name -ObjectId $oId -PermissionsToSecrets get
#Solution looks like a hack, but it works for me. After this, object with $oId have got access to keyVault. (For checks access polices use Get-AzureRmKeyVault -VaultName $vaultName)

#The solution was to move the configuration of the permission to the ARM template instead of trying to do it using PowerShell. As soon as i did that all permission issues got solved. 

#Please ensure your Service Principal has Contributor or Owner permission. More information about this please refer to this link.
#https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-create-service-principal-portal#assign-application-to-role
#az role assignment create --assignee d7d167ca-ad2a-4b31-ab64-7d5b714b7d8d --role Owner

#Get-Module -ListAvailable -Name Azure -Refresh

#http://innerdot.com/azure/a-gaffers-guide-to-azure-service-principals-and-applications
#azure login -u cliadmin@spielmitcloudoutlook.onmicrosoft.com
#azure ad app create --name "climanager" --home-page "http://localhost/climanager" --identifier-uris "http://localhost/climanager" --password "spielpassword"
#azure ad sp create 1b283f2a-6e7f-4d64-9cc5-d08986fbd2c9
#azure logout v-davidk@microsoft.com
#azure login -u "1b283f2a-6e7f-4d64-9cc5-d08986fbd2c9" -p "spielpassword" --service-principal --tenant "b368fad9-3955-72a3-8f16-340743cefdd7"

#Portal
#https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal


Clear-Host
Import-Module Azure
Import-Module AzureRM.Resources

Add-AzureRmAccount
Get-AzureRmSubscription
Set-AzureRmContext -SubscriptionId <Your subscription id goes here>

$ServicePrincipalDisplayName = "myServicePrincipalName"
$CertificateName = "CN=SomeCertName" 

$cert = New-SelfSignedCertificate -CertStoreLocation "cert:\CurrentUser\My" -Subject $CertificateName -KeySpec KeyExchange
$keyValue = [Convert]::ToBase64String($cert.GetRawCertData())

$ResouceGroupName = "myRessourceGroup"
$location = "North Central US"

# Create the resource group
New-AzureRmResourceGroup -Name $ResouceGroupName -Location $location

$ResouceGroupNameScope = (Get-AzureRmResourceGroup -Name $ResouceGroupName -ErrorAction Stop).ResourceId

# Create the Service Principal that logs in with a certificate
New-AzureRMADServicePrincipal -DisplayName $ServicePrincipalDisplayName -CertValue $keyValue -EndDate $cert.NotAfter -StartDate $cert.NotBefore

$myServicePrincipal = Get-AzureRmADServicePrincipal -SearchString $ServicePrincipalDisplayName
Write-Host "myServicePrincipal.ApplicationId " $myServicePrincipal.ApplicationId -ForegroundColor Green
Write-Host "myServicePrincipal.DisplayName " $myServicePrincipal.DisplayName

# Sleep here for a few seconds to allow the service principal application to become active (should only take a couple of seconds normally)
Write-Host "Waiting 10 seconds"
Start-Sleep -s 10

Write-Host "Make the Service Principal owner of the resource group " $ResouceGroupName

$NewRole = $null
$Retries = 0
 While ($NewRole -eq $null -and $Retries -le 6)
 {  
    New-AzureRMRoleAssignment -RoleDefinitionName Owner -ServicePrincipalName $myServicePrincipal.ApplicationId  -Scope $ResouceGroupNameScope -ErrorAction SilentlyContinue    
    $NewRole = Get-AzureRMRoleAssignment -ServicePrincipalName $myServicePrincipal.ApplicationId
    Write-Host "NewRole.DisplayName " $NewRole.DisplayName
    Write-Host "NewRole.Scope: " $NewRole.Scope
    $Retries++

    Start-Sleep -s 10
 }

Write-Host "Service principal created" -ForegroundColor Green