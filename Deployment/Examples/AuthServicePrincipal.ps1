param
(
	[string] [Parameter(Mandatory=$true)] $clientId,
	[string] [Parameter(Mandatory=$true)] $clientSecret,
	[string] [Parameter(Mandatory=$true)] $tenantId
)
Install-Module -Name AzureADPreview -Force
Get-Module -ListAvailable -Name Azure -Refresh

# Workaround to use AzureAD in this task. Get an access token and call Connect-AzureAD
$adTokenUrl = "https://login.microsoftonline.com/$tenantId/oauth2/token"
$resource = "https://graph.windows.net/"
 
$body = @{
    grant_type    = "client_credentials"
    client_id     = $clientId
    client_secret = $clientSecret
    resource      = $resource
}
 
$response = Invoke-RestMethod -Method 'Post' -Uri $adTokenUrl -ContentType "application/x-www-form-urlencoded" -Body $body
$token = $response.access_token
 
Write-Verbose "Login to AzureAD with same application as endpoint"
Connect-AzureAD -AadAccessToken $token -AccountId $clientId -TenantId $tenantId

#Write-Host "Azure Resource Group Not Present. Deploying Infrastructure..."
#Write-Host "Creating Azure Resource Group [$($resourceGroupName)] in [$($region)]" -ForegroundColor Green
#New-AzureRmResourceGroup -Name $resourceGroupName -Location $region
#$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName
#Write-Host "Creating Azure AD App [$($appName)] URI [https://$($appName)]"
#$NewApp=New-AzureADApplication -DisplayName "$($appName)" -IdentifierUris "https://$($appName)"
#Write-Host "Creating Service Principal for AD App [$($appName)]"
#$NewAppPrincipal = New-AzureADServicePrincipal -AppId $NewApp.AppId
#Write-Host "Creating Service Principal Password for AD App [$($appName)]"
#$secret=New-AzureADApplicationPasswordCredential -ObjectId $NewApp.ObjectId
#Write-Host "Getting Context of the Service Principal for AD App [$($appName)]"
#$principal = Get-AzureADServicePrincipal -Filter "DisplayName eq '$($appName)'"
#Write-Host "Granting Keyvault Access to [$($vaultName)] for AD App [$($appName)]"
#Set-AzureRmKeyVaultAccessPolicy -VaultName $vaultName -ObjectId $principal.ObjectId -PermissionsToSecrets get,set
#$ss = ConvertTo-SecureString -String $secret.Value -AsPlainText -Force
#Write-Host "Storing Service Principal Password to Secret [$($appKey)] in vault [$($vaultName)]"
#Set-AzureKeyVaultSecret -VaultName $vaultName -Name $($appKey) -SecretValue $ss