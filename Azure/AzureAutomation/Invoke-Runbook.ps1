<#
    .SYNOPSIS
        Start an Azure Automation Runbook with the Runbook 'Start-AzureAutomationRunbookByWebhook'
    .DESCRIPTION
        This Script will call a Azure Automation Runbook Webhook of the Runbook 'Start-AzureAutomationRunbookByWebhook'
        The Runbook itself will start the runbook specified in the Body below
        Determined to be used with the Runbook 'Start-AzureAutomationRunbookByWebhook'

        All Parameters in the Body below with the Prefix rbp_ will be passed to the Runbook to call
        All Parameters in the Body below without the Prefix rbp_ will be used by the Runbook 'Start-AzureAutomationRunbookByWebhook'
        
        Start-AzureAutomationRunbookByWebhook.ps1 - https://gist.github.com/Burbert/f5929bb66fed57eda2dc1397181380eb
    .PARAMETER WebhookURL
        Specifies the URL of the Webhook to call
        Mandatory
    .EXAMPLE
        Invoke-Runbook.ps1 -WebhookURL "https://s2events.azure-automation.net/webhooks?token=[token]"
#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)][String]$WebhookURL
)

# Entries that start with rbp_ will be passed to the runbook to call, not the one that is called by the Webhook
$Body = @{
    "AzureSubscriptionId" = "Subscription ID"
    "AzureResourceGroup" = "Name of ResourceGroup"
    "AzureAutomationAccountName" = "Name of Azure Automation Account"
    "Runbookname" = "Name of the runbook you want to execute"
    "runOn" = "Name of Hybrid Worker Group"
    "rbp_LastName" = "Doe"
    "rbp_FirstName" = "John"
}

$params = @{
    ContentType = 'application/json'
    Headers = $Headers
    Body = ($Body | ConvertTo-Json)
    Method = 'Post'
    URI = $WebhookURL
}

try{
    Invoke-RestMethod @params -ErrorAction Stop
}catch{
    throw "$($($_.Exception).Message)"
}