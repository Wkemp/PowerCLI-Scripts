Function Remove-VMScheduledTask {
<#
 .SYNOPSIS
    Removes a scheduled task with the specified Task name from VIServer  
 .DESCRIPTION
    Removes a scheduled task with the specified Task name from VIServer 
 .PARAMETER TaskName
    Name of the Task you wish to remove.
 .EXAMPLE
    Remove-VMScheduledTask -TaskName "Test Scheduled Snapshot"  
 .NOTES
    General notes
  #>
PARAM ([string]$taskName)
  (Get-View -Id ((Get-VMScheduledTasks -Full | Where-Object {$_.Name -eq $TaskName}).ScheduledTask)).RemoveScheduledTask()
}