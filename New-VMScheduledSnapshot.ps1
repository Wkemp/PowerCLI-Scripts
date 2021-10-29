Function New-VMScheduledSnapshot {

    <#
    .SYNOPSIS
        Create a new Scheduled task for the specified VM to take a snapshot of the VM at the specified Date and Time.
    
    .DESCRIPTION
        Creates a Scheduled Task for a VM that will generate a snapshot on the date and time specified with the name specified.  
        Returns information on the Scheduled Snapshot Task when sucessful.  Allows for user to setup notification email to be
        sent to multiple users upon running the scheduled task to alert of success of failures.

    .PARAMETER VM
        Virtual machine that will have a snapshot scheduled
    
    .PARAMETER Runtime
        Date and time to run scheduled snapshot creation.
    
    .PARAMETER NotifyEmail
        Email address to send alerts and task completion emails to.
    
    .PARAMETER SnapName
        Snapshot Name to use.
    
    .PARAMETER TaskName
        Sets the name of the Scheduled snapshot task in vcenter.
    
    .PARAMETER TicketID
        Ticket ID from TeamDynamix requesting the snapshot that is being scheduled.
    
    .INPUTS
    .OUTPUTS
    
    .NOTES
      Version:        v1.0
      Author:         Will Kemp
      Creation Date:  02-12-2018
      Purpose/Change: Initial script development
      
    .EXAMPLE
    New-VMScheduledSnapshot -VM cent7learning -RunTime "2/20/2018 10:30 PM" -NotifyEmail user@murraystate.edu -SnapName "Snap for Snap" -TicketID 489232232 
    #>
    
    
    [cmdletbinding()]
    PARAM (
      [parameter(Position=0,Mandatory=$true,HelpMessage="Virtual machine to snapshot")][string]$VM,
      [parameter(Position=1,Mandatory=$true,HelpMessage="Time to run create snapshot command")][string]$RunTime,
      [parameter(Position=2,Mandatory=$true,HelpMessage="Email to notifying snapshot task ran")][string[]]$NotifyEmail=$null,
      [parameter(Position=3,Mandatory=$true,HelpMessage="Virtual machine to snapshot")][string]$SnapName,
      [parameter(Position=4,Mandatory=$false,HelpMessage="Snapshot Name")][string]$TaskName="$VM Scheduled Snapshot",
      [parameter(Position=5,Mandatory=$false,HelpMessage="Ticket ID requesting snapshot")][string]$TicketID=$null
    )
    
    #Import vmware modules
    Get-Module -Name "*VMWare*" -ListAvailable | Import-Module
    
    #region Helper Functions
    
    #used to check that no other snapshots tasks match the parameters chosen
    Function Get-VMScheduledSnapshots {
      Get-VMScheduledTasks | Where-Object{$_.ActionName -eq 'CreateSnapshot_Task'} |
        Select-Object @{N="VMName";E={$_.EntityName}}, Name, NextRunTime, Notification
    }
    #endregion Helper Functions
    
    #Check and Import VMware modules.
    #If PowerCLI module exists, Import modules
    if(Get-Module -ListAvailable -Name "VMware.Vim*"){                
        Get-Module -ListAvailable -Name "VMware.Vim*" | Import-Module
        }
    #Else, warn user that PowerCLI module is missing and must be installed.
    Else{                                                                   
        Write-Warning "PowerCLI Modules not found.`n`nPlease check for Up-to-date PowerCLI module has been downloaded and installed from Powershell Gallery or another source before rerunning this script"
        Break
        }    
    
    # Verify that it found a single VM
    $VMachine = (Get-View -ViewType VirtualMachine -Property Name -Filter @{"Name"="^$($VM)$"}).MoRef
    if (($VMachine | Measure-Object).Count -ne 1 ) { 
        Write-warning "Unable to locate a specific VM $VM"
        Break
        }
    
    # Validate datetime value and convert to UTC
    try { 
        $CastRunTime = ([datetime]$RunTime).ToUniversalTime()
        } 
    catch { 
        Write-Warning "Unable to convert runtime parameter to date time value.`n`nPlease use format dd/MM/yyyy hh:mm tt"
        Break 
        }
    if ( [datetime]$RunTime -lt (Get-Date) ) { 
        Write-Warning "Single run tasks can not be scheduled to run in the past.  Please adjust start time and try again."
        Break 
        }
    
    # Verify the scheduled task name is not already in use
    if ( (Get-VMScheduledTasks | Where-Object{$_.Name -eq $taskName } | Measure-Object).Count -eq 1 ) { 
        "Task Name `"$taskName`" already exists.  Please try again and specify the taskname parameter"
        Break 
    }
    
    $spec = New-Object VMware.Vim.ScheduledTaskSpec
    $spec.name = $TaskName
    $spec.description = "Snapshot of $VM scheduled for $runTime. Created by: $env:USERDOMAIN\$Env:USERNAME"
    $spec.enabled = $true
    
    #if notification email was listed, add this field to the task
    if ( $notifyEmail ) {
        $spec.notification = $notifyEmail
        }
    ($spec.scheduler = New-Object VMware.Vim.OnceTaskScheduler).runAt = $castRunTime
    ($spec.action = New-Object VMware.Vim.MethodAction).Name = "CreateSnapshot_Task"
    $spec.action.argument = New-Object VMware.Vim.MethodActionArgument[] (4)
    ($spec.action.argument[0] = New-Object VMware.Vim.MethodActionArgument).Value = "$SnapName"
    ($spec.action.argument[1] = New-Object VMware.Vim.MethodActionArgument).Value = "Scheduled Snapshot for $RunTime.   TicketID: $TicketID"
    ($spec.action.argument[2] = New-Object VMware.Vim.MethodActionArgument).Value = $false # Snapshot memory
    ($spec.action.argument[3] = New-Object VMware.Vim.MethodActionArgument).Value = $false # quiesce guest file system (requires VMware Tools)
    
    [Void](Get-View -Id 'ScheduledTaskManager-ScheduledTaskManager').CreateScheduledTask($Vmachine, $spec)
    Get-VMScheduledSnapshots | Where-Object{$_.Name -eq $taskName }
    }
    