<#
.PARAMETER resourceGroupName
    Name of the resource group to which the server is assigned.

.PARAMETER clusterName
    Azure Data Explorer Cluster name.

.EXAMPLE
    -environmentName AzureCloud
    -resourceGroupName myResourceGroup
    -clusterName mycluster


.NOTES
    Author: Sai Nageshwaran
    Last Update: Nov 2021
#>

param(
[parameter(Mandatory=$true)]
[string] $resourceGroupName,

[parameter(Mandatory=$true)]
[string] $clusterName
)

Write-Output "Begin Stop-ADXClusterWF"
   
    # Ensures you do not inherit an AzContext in your runbook
    Disable-AzContextAutosave -Scope Process

    # Connect to Azure with user-assigned managed identity
    $AzureContext = (Connect-AzAccount -Identity).context

    # set and store context
    $AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext
    
    Write-Output "Successfully connected with Automation account's Managed Identity"

"***** Azure Data Explorer Cluster settings"
    "Resource Group: " + $resourceGroupName
    "Cluster Name : " + $clusterName

    $count = 1

# Display Azure Data Explorer Cluster information
    "***** Display Azure Data Explorer Cluster information"
    $adx = Get-AzKustoCluster -ResourceGroupName $resourceGroupName -Name $clusterName
    $adx

 while ($adx.State -ne "Stopped" -and $count -ne 31) {
        $adx = Get-AzKustoCluster -ResourceGroupName $resourceGroupName -Name $clusterName
        "Attempt $($count)"
        "Current Status: $($adx.State)"
        Start-Sleep -s 10
        $count++
    }
    If ($adx.State -eq "Running") {
        # Stop Azure Data Explorer Cluster
        "***** Stopping Azure Data Explorer Cluster"
        Stop-AzKustoCluster -ResourceGroupName $resourceGroupName -Name $clusterName
    }

    Write-Output "End Stop-ADXClusterWF"