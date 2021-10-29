Function Get-VMScheduledSnapshots {
<#
.SYNOPSIS
    Finds all Create Snapshot Scheduled Tasks for a VIServer

.DESCRIPTION
    Finds Scheduled Tasks then filters them according to their action name being "CreateSnapshot_Task"
    The results are then given headers: VMName,Name,Description,Modified/Created,PrevRunTime,NextRunTime,Notification,Enabled,LastModifiedUser,State

.EXAMPLE
    Connect-VIServer vcenter.domain.edu

    Get-VMScheduledSnapshots

    Connect to vcenter and find all scheduled snapshot tasks.
.EXAMPLE
    Connect-VIServer vcenter.domain.edu

    Get-VMScheduledSnapshots | Where-Object {$_.VMName -eq "NameOfVM"} 

    Show all Scheduled snapshots for VM NameOfVM

.NOTES
General notes
#>
    Get-VIScheduledTasks | 
    Where-Object{$_.ActionName -eq 'CreateSnapshot_Task'} |
    Select-Object @{N="VMName";E={$_.EntityName}},Name,Description,`
        @{Name='Modified/Created';E={$_.LastModifiedTime}},`
        PrevRunTime,NextRunTime,Notification,Enabled,LastModifiedUser,State
}
