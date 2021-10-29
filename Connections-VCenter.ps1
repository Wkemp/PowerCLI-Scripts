Function Connect-Vcenter{
<#
.SYNOPSIS
    Connect to one of the three Vcenters available
.DESCRIPTION
    Connect to one of the valid vcenters.  Current Valid vcenters(MSU,PAD,NKU)
.EXAMPLE
An example

.NOTES
General notes
#>
#region Parameter
[cmdletbinding()]
PARAM(
    [parameter(Mandatory=$true,Position=0,Helpmessage="vcenter to connect to")][ValidateSet('MSU','NKU','PAD')][String]$vCenter    
)

#endregion Parameter

#switch to convert shorthand name to proper VCenter name.
Switch ($vCenter) {   
   MSU {$VIServer = "msu-ucs-vcenter.msunet2k.edu"
        Write-Verbose "$(Get-Date -f 'MM/dd/yyy hh:mm:ss tt') Using Vcenter: $VIServer"} #Main campus
   NKU {$VIServer = "nkuvcenter.msunet2k.edu"
        Write-Verbose "$(Get-Date -f 'MM/dd/yyy hh:mm:ss tt') Using Vcenter: $VIServer"} #Northern Kentucky University vcenter
   PAD {$VIServer = "padvcenter.msunet2k.edu"
        Write-Verbose "$(Get-Date -f 'MM/dd/yyy hh:mm:ss tt') Using Vcenter: $VIServer"} #Paducah campus vcenter
   }

#region vCenter Connect
#Attempt to connect to vcenter. If connection fails, print error to console and exit. Out-Null to silence console output on success.
TRY {
    Connect-VIServer -Server $VIServer -ErrorAction stop
    Write-Verbose "$(Get-Date -f 'MM/dd/yyy hh:mm:ss tt') Connection established with $VIServer"
}
Catch {    
    write-error "Unable to connect to $VIServer.`n$_" #prints error message to console window
    Break
    }

}


Function Disconnect-VCenter{
<#
.SYNOPSIS
Disconnect from the Selected vcenter
.DESCRIPTION
Disconnect from a viServer.  This is setup to only accept values of MSU,PAD, or NKU.
.PARAMETER vCenter
shorthand for the available vcenters (MSU,PAD,NKU are the set of accepted current values.)
.EXAMPLE
Disconnect-VCenter PAD

Disconnects from pad vcenter 
.NOTES
General notes
#>
#Region Paramter
    [cmdletbinding()]
    PARAM(
        [parameter(Mandatory=$true,Position=0,Helpmessage="vcenter to connect to")][ValidateSet('MSU','NKU','PAD')][String]$vCenter    
    )
    
#Endregion Parameter
    
    #switch to convert shorthand name to proper VCenter name.
    Switch ($vCenter) {   
       MSU {$VIServer = "msu-ucs-vcenter.msunet2k.edu"
            Write-Verbose "$(Get-Date -f 'MM/dd/yyy hh:mm:ss tt') Using Vcenter: $VIServer"} #Main campus
       NKU {$VIServer = "nkuvcenter.msunet2k.edu"
            Write-Verbose "$(Get-Date -f 'MM/dd/yyy hh:mm:ss tt') Using Vcenter: $VIServer"} #Northern Kentucky University vcenter
       PAD {$VIServer = "padvcenter.msunet2k.edu"
            Write-Verbose "$(Get-Date -f 'MM/dd/yyy hh:mm:ss tt') Using Vcenter: $VIServer"} #Paducah campus vcenter
       }
Disconnect-VIServer -Server $VIServer -Confirm:$false
}