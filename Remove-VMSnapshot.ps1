Function Remove-VMSnapshot {
    <#
    .SYNOPSIS
        Connect to a specified vCenter and Delete/Commit a specific snapshot or all snapshots for the specified Virtual Machine(s).
    
    .DESCRIPTION
        Connect to vCenter using shorthand names MSU, NKU, or PAD. Then, select one or multiple Virtual machines
         and gather a specified snapshot or all associated snapshots for each Virtual machine and delete/committ them. Confirmation
         is required to complete the removal of a snapshot
    .PARAMETER vCenter
        The shorthand name for a Valid vCenter.
            MSU : msu-ucs-vcenter.msunet2k.edu
            NKU : nkuvcenter.msunet2k.edu
            PAD : padvcenter.msunet2k.edu
    .PARAMETER VMList
        The Name of the Virtual machines that need a snapshot committed/deleted.  Comma separate the names entered 
        or create an array of strings if multiple Virtual machines will have snapshots to remove.
    .PARAMETER SnapName
        Name of the snapshot to be removed.
    
    .INPUTS
    
    .OUTPUTS
    
    .NOTES
        Version:        1.3
        Author:         Sean Mitchuson, Will Kemp
        Creation Date:  02-09-2018
        Purpose/Change: v1.3 - - - - - - - 
                            -Added more Checks for Remove ALL
                            -Added confirmation that snapshots are removed for both single snap removal and all snap removal
                            -Added Verbosity to script
                            
    .EXAMPLE
        To delete ALL snapshot from server donatello on msu-ucs-vcenter.msunet2k.edu
      
        Remove-VMSnapshot MSU Donatello 
    
    .EXAMPLE
        To delete Snapshots titled "Snapshot-1" from Donatello
    
        Remove-VMSnapshot MSU Donatello Snapshot-1
    
    .EXAMPLE
        To remove Snapshots titled "Snapshot-1" from Donatello,Thrall,and Robinhood on msu-ucs-vcenter.msunet2k.edu.
        
         Remove-VMSnapshot MSU Donatello,Thrall,Robinhood Snapshot-1
    
         OR
    
         $VMachines = @("Donatello","Thrall","Robinhood")
    
         Remove-VMSnapshot MSU $VMachines Snapshot-1
    
    .EXAMPLE
        To Delete All snapshots from all servers listed in Servers.txt on msu-ucs-vcenter.msunet2k.edu 
    
        $VMachines = (Get-Content -Path "...\servers.txt")
    
        Remove-VMSnapshot MSU $VMachines
    #>
    
    #region Parameters
    [cmdletbinding()]
    Param(
       [parameter(Mandatory=$true,Position=0,Helpmessage="vCenter to connect to")][ValidateSet('MSU','NKU','PAD')][String]$vCenter,
       [parameter(Mandatory=$true,Position=1,Helpmessage="VMs to Remove Snapshots From")][Alias('VMs')][String[]]$VMlist,
       [parameter(Mandatory=$false,Position=2,Helpmessage="Snapshot to remove")][Alias('Name')][string]$SnapName="$Null" #set to Null value by default
       )
    #endregion Parameters
    
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
        Write-Verbose "Connection established with $VIServer"
    }
    Catch {    
        write-error "Unable to connect to $VIServer.`n$_" #prints error message to console window
        Break
        }
    #endregion vCenter Connect
    
    #region Snapshot Removal
    #For each listed vm attempt to find a vm of the entered name, then Remove the snapshot with the specified parameters.
    #If unable to remove the snapshot, write an error to the console then continue to the next vm.
    $removedlist=@()
    Foreach($VM in $VMlist){
        TRY {
            If($SnapName -ne "$Null"){          #If a snapshot name is included, Run removal of just that snapshot.  If there is more than one snapshot by that name, remove the oldest snapshot by that name
                $removal = (Get-VM -Name $VM -ErrorAction Stop |Get-Snapshot -Name $SnapName| Select-Object -First 1 | Remove-Snapshot -Confirm:$False -RunAsync)
                Write-Verbose "$(Get-Date -f 'MM/dd/yyy hh:mm:ss tt')  Snapshot Removal Started Successfully...Continuing script." 
                $removedlist += $removal
                }
            Else{     #If no snapshot name is included, remove all snapshots.  Before removal list snapshots and confirm that user wants to do this.
                $snapshots = @(Get-VM -Name $VM -ErrorAction Stop | Get-Snapshot  | Select-Object @{N='VM';E={"$($_.VM)"}},@{N='Name';E={"$($_.Name)"}},@{N='Description';E={"$($_.Description)"}},@{N='Parent';E={IF($_.ParentSnapshot){"$($_.ParentSnapshot)"}Else{""}}},@{N='Created';E={"$($_.Created)"}})
                Write-Warning "The following Snapshots will be removed."
                $snapshots | Select-Object VM,Name,Description,Parent,Created |Format-Table
                $removal = (Get-VM -Name $VM -ErrorAction Stop|Get-Snapshot | Sort-Object -Property Created | Select-Object -First 1 | Remove-Snapshot -RemoveChildren -Confirm:$True -RunAsync)
                Write-Verbose "$(Get-Date -f 'MM/dd/yyy hh:mm:ss tt')  Snapshot Removal Started Successfully...Continuing script."
                $removedlist += $removal
                
            }
        }
        CATCH{
            Write-error "Unable to Remove snapshot on $VM.`n$_"
        }
    }
    #endregion Snapshot Removal
    
    #region Remove Snapshot Status Check
    #Create status array that is the state of the tasks.  This will be Running,Queued, or Complete.
    #While loop to check if there are any still running or queued tasks, wait 2 seconds, update the status and check again until none contain Running or Queued Status.
    Write-Verbose "$(Get-Date -f 'MM/dd/yyy hh:mm:ss tt') Checking Status of Create Snapshot Tasks"
    $status = $removedlist | ForEach-Object{ $(Get-Task -Id $_.ID).State }
    Write-Verbose "$status"
    
    While(($status -contains 'Running') -or ($status -contains 'Queued')){ 
       Start-Sleep -Seconds 2
       $status = $removedlist | ForEach-Object{ $(Get-Task -Id $_.ID).State }
       Write-Verbose "$(Get-Date -f 'MM/dd/yyy hh:mm:ss tt') Updated Status: `n $status"
    }
    
    #endregion Remove Snapshot Status Check
    
    #region Confirm Snapshot Removed
    #Checks to see that the snapshot with name saved in $snapname has been removed from the listed machines.
    #If SnapName is empty, it checks to make sure all Snapshots were removed from the listed machines.
    #If something is found it prints an error.  If no snapshots meet the criteria it prints confirmation snap has been removed.
    Write-Verbose "$(Get-Date -f 'MM/dd/yyy hh:mm:ss tt') All Remove Snapshot Tasks have completed."
    
    If($SnapName -ne "$Null"){ 
        $removedlist | ForEach-Object { 
                If (!(Get-VM -ID $_.ObjectID | Get-Snapshot -Name $SnapName -ErrorAction SilentlyContinue)){ 
                    Write-Host "$((Get-VM -ID $_.ObjectID).Name) : Snapshot [ $SnapName ] Deleted " -ForegroundColor Green
                    }
                Else {
                    Write-Host "$((Get-VM -ID $_.ObjectID).Name) : Snapshot [ $SnapName ] still found. " -ForegroundColor Red
                    }
                }
        }
    Else{
         $removedlist | ForEach-Object { 
                If (!(Get-VM -ID $_.ObjectID | Get-Snapshot -ErrorAction SilentlyContinue)){ 
                    Write-Host "$((Get-VM -ID $_.ObjectID).Name) : All Snapshots Deleted " -ForegroundColor Green
                    }
                Else {
                    Write-Host "$((Get-VM -ID $_.ObjectID).Name) : All Snapshots NOT Deleted.  Please check this Virtual Machine. " -ForegroundColor Red
                    }
                }
        }    
    #endregion Confirm Snapshot Removed
    
    #disconnet from vcenter
    Write-Verbose "Disconnecting from $VIServer"
    Disconnect-VIServer $VIServer -Confirm:$false
    
    }#End of Remove-VMSnapshot Function.