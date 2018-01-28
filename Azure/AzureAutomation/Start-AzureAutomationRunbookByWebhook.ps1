<#
    .SYNOPSIS
        Start any Runbook within your Automation Account from a Webhook
    .DESCRIPTION
        Azure Automation Runbooks can have a Webhook so they can be called by using a simple REST-Method
        but if your Runbook requires Parameters, you can either hardcode them into the Webhook or
        rewrite the Runbook so the can work with Webhookdata
        The concept of this is explained in the Blog-Post of Stefan Stranger below:

        https://blogs.technet.microsoft.com/stefan_stranger/2017/03/18/azure-automation-runbook-webhook-lesson-learned/

        With this Runbook you can call any Runbook within your Automation Account and there is no need to rewrite them.
        Create a Webhook for this runbook and call it by using the Script below:

        Invoke-Runbook.ps1 - https://gist.github.com/Burbert/b2d5a33a040a3bc3edccc74f42c24d11

        This Example is written to run on a Hybrid Runbook worker.
    .EXAMPLE
        Start-AzureAutomationRunbookByWebhook -WebhookData <Input from Script>
#>
[CmdletBinding()]
Param(
    [object]$WebhookData
)

#region getting Data from Webhookinput
$WebhookName = $WebHookData.WebhookName
$WebhookBody = $WebHookData.RequestBody

$WebhookInput = $WebhookBody | ConvertFrom-Json
Write-Output "Runbook '$($WebhookInput.Runbookname)' was started from Runbook 'Start-AzureAutomationRunbookByWebhook' using Webhook '$WebhookName'"
#endregion

#region Connect to Azure with certificate
$connectionName = "AzureRunAsConnection"
try {
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName

    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint   $servicePrincipalConnection.CertificateThumbprint | Out-Null
    # Switch Azure subscription
    Select-AzureRmSubscription -SubscriptionId $($WebhookInput.AzureSubscriptionId) | Out-Null
} catch {
    if (!$servicePrincipalConnection) {
        throw "Connection $connectionName not found."
    } else {
        throw $_.Exception
    }
}
#endregion

#region create Hashtable for Runbook Parameters
$AzureRunbookParameter = @{}

$WebhookInput.psobject.Properties | ForEach-Object {
    if($($_.Name) -match "^rbp_"){
        $Key = "$($_.Name)" -Replace "rbp_",""
        $Value = "$($_.Value)"
        $AzureRunbookParameter.Add($Key,$Value)
    }
}
#endregion

#region Start Runbook with params from a Runbook that is beeing called from a Webhook (Inception-Runbook :D)
try {
    Write-Output "Starting Runbook $($WebhookInput.Runbookname)"
    $AzureAutomationRunbook = $($WebhookInput.Runbookname)
    Start-AzureRmAutomationRunbook -Parameters $AzureRunbookParameter -AutomationAccountName $($WebhookInput.AzureAutomationAccountName) -Name $AzureAutomationRunbook -ResourceGroupName $($WebhookInput.AzureResourceGroup) -RunOn $($WebhookInput.runOn) | Out-Null
} catch {
    throw "$($($_.Exception).Message)"
}
#endregion