param(
    [Parameter(Mandatory = $true)][string]$Firstname,
    [Parameter(Mandatory = $true)][string]$Lastname
)

Write-Output "Output by $Firstname $Lastname"