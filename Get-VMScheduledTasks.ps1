Function Get-VMScheduledTasks {
    <#
.SYNOPSIS
    Gather Installed windows updates for a listed computer and searching by KBArticle and/or Security Bulletin.

.DESCRIPTION
    Information is gathered on one or more machines listed then stored in a folder as a csv for each machine.  The collected data
    can then be searched by KB Article and Security Bulletin and the results displayed in GridView.

.PARAMETER Full
    Switch to decide if all fields are displayed.
.NOTES
.EXAMPLE
    Get-VIScheduledTasks
    Returns list of scheduled tasks with common headers
.EXAMPLE
    Get-VIScheduledTasks -Full
    Returns list of scheduled tasks with all available headers.
#>
    PARAM ( [switch]$Full )
    if ($Full) {
      # Note: When returning the full View of each Scheduled Task, all date times are in UTC
      (Get-View ScheduledTaskManager).ScheduledTask | ForEach-Object{ (Get-View $_).Info } | Select-Object *
    } else {
      # By default, lets only return common headers and convert all date/times to local values
      (Get-View ScheduledTaskManager).ScheduledTask | ForEach-Object{ (Get-View $_ -Property Info).Info } |
      Select-Object Name, Description, Enabled, Notification, LastModifiedUser, State, Entity,
        @{N="EntityName";E={ (Get-View $_.Entity -Property Name).Name }},
        @{N="LastModifiedTime";E={$_.LastModifiedTime.ToLocalTime()}},
        @{N="NextRunTime";E={$_.NextRunTime.ToLocalTime()}},
        @{N="PrevRunTime";E={$_.LastModifiedTime.ToLocalTime()}}, 
        @{N="ActionName";E={$_.Action.Name}}
      }
    }