Function Get-VMNetworkInfo{
<#
.SYNOPSIS
    Gather basic VIServer network information. VLANS
.DESCRIPTION
Long description

.PARAMETER empty
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>
    Param(
    [Parameter(Mandatory=$false,helpmessage="Switch to list all empty virtual vlan info")]
    [alias("noVM")]
    [switch]$empty
    )
    Switch ($empty){
       $true  {
               Write-Host "Listing empty virtual networks" -ForegroundColor Magenta
               Get-View -ViewType Network -Property Name,VM,Host | Select-Object Name,@{N="Host Count"; E={@($_.Host).Count}},@{N="VM Count";E={($_.VM).count}}|Where-Object {($_.'VM Count') -eq 0} | Sort-Object -Property @{E="VM Count"; Descending=$true},@{E="Name"}
              }
    
       $false {
               Write-Host "Listing All virtual Networks" -ForegroundColor Magenta
               Get-View -ViewType Network -Property Name,VM,Host | Select-Object Name,@{N="Host Count"; E={@($_.Host).Count}},@{N="VM Count";E={($_.VM).count}} | Sort-Object -Property @{E="VM Count"; Descending=$true},@{E="Name"}
              }
    }
    }