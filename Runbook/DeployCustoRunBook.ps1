#Parameters needed by the script.
Param(     
	[Parameter(Mandatory=$True)]
    [string] $AutomationAccountName,
    [Parameter(Mandatory=$True)]
    [string] $ResourceGroupName,
	[Parameter(Mandatory=$True)]
    [string] $clusterName
)

Function ImportRunBook($automationAccountName, $runbookName, $scriptPath, $resourceGroupName) {
	Import-AzAutomationRunbook -Name $runbookName -Path $scriptPath -ResourceGroupName $resourceGroupName -AutomationAccountName $automationAccountName -Type PowerShellWorkflow -Force
	Write-Host "Completed importing $runbookName ."
}

Function PublishRunBook($automationAccountName, $runbookName, $resourceGroupName) {
	Publish-AzAutomationRunbook -AutomationAccountName $automationAccountName -Name $runbookName -ResourceGroupName $resourceGroupName
	Write-Host "Completed publishing $runbookName ."
}

Function ScheduleCustoRunBook($automationAccountName, $runbookName, $resourceGroupName, $scheduleName, $params) {
	try
	{
		$existingSchedule = Get-AzAutomationSchedule -AutomationAccountName $automationAccountName -Name $scheduleName -ResourceGroupName $resourceGroupName -ErrorAction Stop
		Write-Host "Schedule $scheduleName already exists."
	}
	catch [Microsoft.Azure.Commands.Automation.Common.ResourceNotFoundException]
	{
		$startTime = (Get-Date).AddMinutes(7)
		New-AzAutomationSchedule -AutomationAccountName $automationAccountName -Name $scheduleName -StartTime $startTime -ResourceGroupName $resourceGroupName -HourInterval 3
		Write-Host "Completed adding schedule $scheduleName ."
		Register-AzAutomationScheduledRunbook –AutomationAccountName $automationAccountName –Name $runbookName –ScheduleName $scheduleName –Parameters $params -ResourceGroupName $resourceGroupName
		Write-Host "Completed linking runbook $runbookName to schedule $scheduleName ."
	}		
}

$deps1 = @("Az.Accounts", "Az.Kusto", "Invoke-SqlCmd2")

foreach($dep in $deps1){
    $module = Find-Module -Name $dep
    $link = $module.RepositorySourceLocation + "/package/" + $module.Name + "/" + $module.Version
    New-AzAutomationModule -AutomationAccountName $AutomationAccountName -Name $module.Name -ContentLinkUri $link -ResourceGroupName $ResourceGroupName
}


$runbookName = "Stop-ADXCluster"
$scriptPath = "Runbook/Stop-ADXCluster.ps1"
ImportRunBook $AutomationAccountName $runbookName $scriptPath $ResourceGroupName
PublishRunBook $AutomationAccountName $runbookName $ResourceGroupName 

$scheduleName = "StopADXClusterSchedule"
$params = @{"resourceGroupName"=$ResourceGroupName;"clusterName"=$clusterName}
ScheduleCustoRunBook $AutomationAccountName $runbookName $ResourceGroupName $scheduleName $params