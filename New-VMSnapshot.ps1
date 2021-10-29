Function New-VMSnapshot {
    <#
    .SYNOPSIS
        Connect to a specified vCenter and create a new snapshot for the specified VM.
    
    .DESCRIPTION
        Connect to vCenter using shorthand names MSU, NKU, or PAD. Then, select one or multiple Virtual machines
         and create a new snapshot for each Virtual machine with the specified Name and Description.
    
    .PARAMETER vCenter
        The shorthand name for a Valid vCenter.
            MSU : msu-ucs-vcenter.msunet2k.edu
            NKU : nkuvcenter.msunet2k.edu
            PAD : padvcenter.msunet2k.edu
    
    .PARAMETER VMList
        The Name of the Virtual machines that need a snapshot created.  Comma separate the names entered 
        or create an array of strings if multiple Virtual machines will have snapshots created.
    
    .PARAMETER SnapName
        Name of the created snapshot.
    
    .PARAMETER SnapDescription
        Description to be entered for the created snapshot. If left blank it will default to "Snapshot Created by $env:USERNAME"
    
    .INPUTS
    
    .OUTPUTS
    
    .NOTES
        Version:         1.4
        Author:          Sean Mitchuson, Will Kemp
        Updated:         02-9-2018
        Purpose/Changes:  v1.4 - - - - - - -  - - - 
                            -Added Status check while loop
                            -Added Completion Print out
                            -Added more verbosity to script
      
    .EXAMPLE
        To take a snapshot of server donatello on msu-ucs-vcenter.msunet2k.edu with the name Snapshot-1 and description "Pre-installation of Patch"
      
        New-Snap MSU Donatello Snapshot-1 "Pre-installation of Patch"
    
    .EXAMPLE
        To take snapshots of Donatello,Thrall,and Robinhood on msu-ucs-vcenter.msunet2k.edu with the name Snapshot-1 and description "Pre-installation of Patch"
        
         New-Snap MSU Donatello,Thrall,Robinhood Snapshot-1 "Pre-installation of Patch"
    
         OR
    
         $VMachines = @("Donatello","Thrall","Robinhood")
    
         New-Snap MSU $VMachines Snapshot-1 "Pre-installation of Patch"
    
    .EXAMPLE
        To Take snapshots of all servers listed in Servers.txt on msu-ucs-vcenter.msunet2k.edu with the name Snapshot-1 and description "Pre-installation of Patch"
    
        $VMachines = (Get-Content -Path "...\servers.txt")
    
        New-Snap MSU $VMachines Snapshot-1 "Pre-installation of Patch"
    #>
    
    #region Parameters
    [cmdletbinding()]
    Param(
       [parameter(Mandatory=$true,Position=0,Helpmessage="vcenter to connect to")][ValidateSet('MSU','NKU','PAD')][String]$vCenter,
       [parameter(Mandatory=$true,Position=1,Helpmessage="vm to snapshot")][Alias('VMs')][String[]]$VMList,
       [parameter(Mandatory=$true,Position=2,Helpmessage="Snapshot Name")][Alias('Name')][String]$SnapName,
       [parameter(Position=3,Helpmessage="Snapshot Description")][Alias('Description')][String]$SnapDescription = "Snapshot Created by $env:USERNAME"
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
        Connect-VIServer $VIServer -ErrorAction stop |Out-Null
        Write-Verbose "$(Get-Date -f 'MM/dd/yyy hh:mm:ss tt') Connection established with $VIServer"
    }
    Catch {    
        write-error "Unable to connect to $VIServer.`n$_" #prints error message to console window
        Break
        }
    #endregion vCenter Connect
    
    #region Snapshot Creation
    #For each listed vm attempt to find a vm of the entered name, the create the snapshot with the specified parameters.
    #If unable to create the snapshot, write an error to the console then continue to the next vm.
    Write-Verbose "$(Get-Date -f 'MM/dd/yyy hh:mm:ss tt') Creating variable Snaplist and beginning Snapshot Creation Tasks Foreach loop."
    $snaplist = @()
    Foreach($VM in $VMlist){
        TRY {
            $snap = (Get-VM -Name $VM -ErrorAction Stop | New-Snapshot -Name $SnapName -Description $SnapDescription -RunAsync -WarningAction SilentlyContinue)
            Write-Verbose "$(Get-Date -f 'MM/dd/yyy hh:mm:ss tt')  Snapshot Creation Started Successfully for $VM `n...Continuing script."
            $snaplist += $snap
        }
        CATCH{
            Write-error "Unable to create snapshot on $VM.`n$_"
        }
    }
    #endregion Snapshot Creation
    
    #region Create Snapshot Status Check
    #Create status array that is the state of the task.  This will be Running,Queued, or Complete.
    #While loop to check if there are any still running or queued tasks, wait 2 seconds, update the status and check again until none contain Running or Queued Status.\
    Write-Verbose "$(Get-Date -f 'MM/dd/yyy hh:mm:ss tt') Checking Status of Create Snapshot Tasks"
    $status = $snaplist | ForEach-Object{ $(Get-Task -Id $_.ID).State }
    Write-Verbose "$status"
    
    While(($status -contains 'Running') -or ($status -contains 'Queued')){ 
       Start-Sleep -Seconds 2
       $status = $snaplist | ForEach-Object{ $(Get-Task -Id $_.ID).State }
       Write-Verbose "$(Get-Date -f 'MM/dd/yyy hh:mm:ss tt') Updated Status: `n $status"
    }
    
    #endregion Create Snapshot Status Check
    
    Write-Verbose "$(Get-Date -f 'MM/dd/yyy hh:mm:ss tt') All Snapshot Creation Tasks have completed."
    
    #region Print Results
    #Alerts that all tasks are completed, then displays the information for each VM snapshot taken listing VM,Snap Name, Snap Description, Creation date, and Size in GB. 
    write-host "All Create Snapshot Tasks completed! `n" -ForegroundColor Green
    
    Write-Verbose "$(Get-Date -f 'MM/dd/yyy hh:mm:ss tt') Printing created snapshot information...."
    
    $VMList| ForEach-Object { Get-snapshot -VM $_ -Name $SnapName | 
        Select-Object VM,@{ N = 'Snapshot Name';E = { "$($_.Name)" } },Description,Created,@{N = 'Size GB';E = { '{0:N2}' -f $($_.SizeGB) } } } |
        Format-Table -AutoSize
    #endregion Print Results
    
    Write-Verbose "$(Get-Date -f 'M/dd/yyy hh:mm:ss tt') Beginning Disconnect from VIServer $VIServer"
    
    #region Disconnect VIServer
    Write-Verbose "Disconnecting from $VIServer"
    Disconnect-VIServer $VIServer -Confirm:$false
    #endregion Disconnect VIServer
    
    Write-Verbose "$(Get-Date -f 'MM/dd/yyy hh:mm:ss tt') Disconnect Complete. Ending New-Snap Function"
    
    }#End of New-Snap Function.
    