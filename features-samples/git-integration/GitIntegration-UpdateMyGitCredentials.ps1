# This sample script calls the Fabric API to programmatically update my Git credentials.

# For documentation, please see:
# https://learn.microsoft.com/en-us/rest/api/fabric/core/git/update-my-git-credentials

# Instructions:
# 1. Install PowerShell (https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell)
# 2. Install Azure PowerShell Az module (https://learn.microsoft.com/en-us/powershell/azure/install-azure-powershell)
# 3. Run PowerShell as an administrator
# 4. Fill in the parameters below
# 5. Change PowerShell directory to where this script is saved
# 6. > ./GitIntegration-UpdateMyGitCredentials.ps1

# Parameters - fill these in before running the script!
# =====================================================

$workspaceName = "<WORKSPACE NAME>"      # The name of the workspace

# ConfiguredConnection GitCredentials
$configuredConnectionGitCredentials = @{
    source = "ConfiguredConnection"
    connectionId = "<CONNECTION ID>"
}

# Automatic GitCredentials
$automaticGitCredentials = @{
    source = "Automatic"
}

# None GitCredentials
$noneGitCredentials = @{
    source = "None"
}

$myGitCredentials = @{} # <Replace with $configuredConnectionGitCredentials or $automaticGitCredentials or $noneGitCredentials>

# End Parameters =======================================

$global:baseUrl = "<Base URL>" # Replace with environment-specific base URL. For example: "https://api.fabric.microsoft.com/v1"

$global:resourceUrl = "https://api.fabric.microsoft.com"

$global:fabricHeaders = @{}

function SetFabricHeaders() {

    #Login to Azure
    Connect-AzAccount | Out-Null

    # Get authentication
    $fabricToken = (Get-AzAccessToken -ResourceUrl $global:resourceUrl).Token

    $global:fabricHeaders = @{
        'Content-Type' = "application/json"
        'Authorization' = "Bearer {0}" -f $fabricToken
    }
}

function GetWorkspaceByName($workspaceName) {
    # Get workspaces    
    $getWorkspacesUrl = "{0}/workspaces" -f $global:baseUrl
    $workspaces = (Invoke-RestMethod -Headers $global:fabricHeaders -Uri $getWorkspacesUrl -Method GET).value

    # Try to find the workspace by display name
    $workspace = $workspaces | Where-Object {$_.DisplayName -eq $workspaceName}

    return $workspace
}

function GetErrorResponse($exception) {
    # Relevant only for PowerShell Core
    $errorResponse = $_.ErrorDetails.Message

    if(!$errorResponse) {
        # This is needed to support Windows PowerShell
        $result = $exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($result)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $errorResponse = $reader.ReadToEnd();
    }

    return $errorResponse
}

try {
    SetFabricHeaders

    $workspace = GetWorkspaceByName $workspaceName 
    
    # Verify the existence of the requested workspace
	if(!$workspace) {
	  Write-Host "A workspace with the requested name was not found." -ForegroundColor Red
	  return
	}
	
    # Update Git Credentials
    Write-Host "Updating the Git credentials for the current user in the workspace '$workspaceName'."

    $updateMyGitCredentialsUrl = "{0}/workspaces/{1}/git/myGitCredentials" -f $global:baseUrl, $workspace.Id

    $updateMyGitCredentialsBody = $myGitCredentials | ConvertTo-Json

    Invoke-RestMethod -Headers $global:fabricHeaders -Uri $updateMyGitCredentialsUrl -Method PATCH -Body $updateMyGitCredentialsBody

    Write-Host "The Git credentials has been successfully updated for the current user in the workspace '$workspaceName'." -ForegroundColor Green

} catch {
    $errorResponse = GetErrorResponse($_.Exception)
    Write-Host "Failed to update the Git credentials for the current user in the workspace '$workspaceName'. Error reponse: $errorResponse" -ForegroundColor Red
}