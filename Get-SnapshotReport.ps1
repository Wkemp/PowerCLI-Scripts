Function Get-SnapshotReport {

  <#
.SYNOPSIS
    Connect to one or multiple vCenter and check for snapshots, then email a report of findings to the named email addresses.

.DESCRIPTION
    Connect to one or multiple vCenter and check for snapshots, then email a report of findings to the named email addresses.
    This report sends back Virtual Machine Name, Snapshot Name, Size of Snapshot, Age of Snapshot, Date Snapshot was created, 
    User who Created Snapshot, Power State, and vCenter instance the VM is hosted by.
.PARAMETER VIServer
    List of names for the vCenter instances you want included in the report.
.PARAMETER MailTo
    List of email address to send the report information to.
.PARAMETER SMTP
    Address of SMTP server to send mail through
.PARAMETER Title
    The subject line of the email and title above the report table.

.INPUTS

.OUTPUTS
    Email to accounts listed in TO Field of messageinfo variable.

.NOTES
    Version:        1.5
    Author:         Will Kemp
    Modified On:    04-23-2018
    Purpose/Change: 01-29-2017 - Script development/Documentation
                    04-23-2018 - Adding $start and $end variables to gather snapshot event username more accurately.
                               - Moved many settings from mail send to be variables that are able to be changed as needed.
                                 $mailto
                                 $SMTP
                                 $Title
                    01-31-2020 - Removed Snapshot Created by field due to inconsistently being filled and lack of usefulness
                               - Changed formatting of PSObject to allow checking for Parent snapshots and If snapshot is
                                 the current snapshot.
  
.EXAMPLE
    To run for all vCenter instances.
  
    .\Get-SnapshotReport.ps1 

.EXAMPLE
    To run for vCenter instance MSU-UCS-VCENTER.MSUNET2k.EDU
  
    .\Get-SnapshotReport.ps1 -VIServers "MSU-UCS-VCENTER.MSUNET2k.EDU"

#>

  [cmdletbinding()]
  PARAM(
    [parameter(Mandatory = $false, Position = 0, Helpmessage = "vcenters to connect to")]
    [String[]]$VIServers = @('msu-ucs-vcenter.msunet2k.edu', 'nkuvcenter.msunet2k.edu', 'padvcenter.msunet2k.edu'),

    [parameter(Mandatory = $false, Position = 1, HelpMessage = "Email Address to send to")]
    [string[]]$MailTo = "msu.sysadminnotify@murraystate.edu",

    [parameter(Mandatory = $false, HelpMessage = "SMTP server to send report through")]
    [string]$SMTP = "mail.murraystate.edu",

    [parameter(Mandatory = $false, HelpMessage = "Report Header/Title")]
    [string]$Title = "Snapshots Found on Campus vCenter Clusters [$(Get-Date -f D)]"
  )

  #import modules necessary
  Import-Module VMware.VimAutomation.Core

  #set Variables
  $Snapshotlist = @()
  $date = (get-date)

  #connect to each vCenter server listed in VIServer variable and perform commands
  Foreach ($Server in $VIServers) {
    TRY {
      Connect-VIServer $Server -ErrorAction stop | Out-Null
      Write-Verbose "Connection established with $Server"
    }
    Catch {    
      write-error "Unable to connect to $VIServer.`n$_" #prints error message to console window
      Break
    }

    [VMware.VimAutomation.ViCore.Types.V1.Inventory.Cluster]$vCluster = Get-Cluster

    Foreach ($ClustObj in $vCluster) {

      [Array] $vmList = @( Get-VM -Location $ClustObj | Sort-Object Name )

      foreach ( $vmItem in $vmList )
      {
          [Array] $vmSnapshotList = @( Get-Snapshot -VM $vmItem )
      
          foreach ( $snapshotItem in $vmSnapshotList )
          {
              $snapshotSizeGB       = [Math]::Round( $snapshotItem.SizeGB,       2 )
              $snapshotAgeDays      = ((Get-Date) - $snapshotItem.Created).Days;
      
              $output = New-Object -TypeName PSObject
      
              $output | Add-Member -MemberType NoteProperty -Name "VCenter"            -Value $Server;
              $output | Add-Member -MemberType NoteProperty -Name "VM"                 -Value $vmItem;
              $output | Add-Member -MemberType NoteProperty -Name "Name"               -Value $snapshotItem.Name;
              $output | Add-Member -MemberType NoteProperty -Name "Description"        -Value $snapshotItem.Description;
              $output | Add-Member -MemberType NoteProperty -Name "Created"            -Value $snapshotItem.Created;
              $output | Add-Member -MemberType NoteProperty -Name "AgeDays"            -Value $snapshotAgeDays;
              $output | Add-Member -MemberType NoteProperty -Name "ParentSnapshot"     -Value $snapshotItem.ParentSnapshot.Name;
              $output | Add-Member -MemberType NoteProperty -Name "IsCurrentSnapshot"  -Value $snapshotItem.IsCurrent;
              $output | Add-Member -MemberType NoteProperty -Name "SnapshotSizeGB"     -Value $snapshotSizeGB;
              $output | Add-Member -MemberType NoteProperty -Name "PowerState"         -Value $snapshotItem.PowerState;
              $output | Add-Member -MemberType NoteProperty -Name "Cluster"            -Value $ClustObj.Name;
      
              $SnapshotList += $output
          }
      }
    }
    Disconnect-VIServer $Server -confirm:$false
  }
  #CSS code to format the table created from $Snapshotlist
  $Css = @"
<style>
h1 {
  font-size: 18px;
  line-height: 48px;
  letter-spacing: 0;
  font-weight: 300;
  color: #212121;
  text-transform: inherit;
  margin-bottom: 16px;
  text-align: center;
}
h2 {
  font-size: 24px ;
  line-height: 44px ;
  letter-spacing: 0.01rem;
  font-weight: 400;
  color: #212121;
  text-align: center;
}
table {
  font-family: Arial, Helvetica, sans-serif;
  border: 1px solid #FFFFFF;
  text-align: center;
  border-collapse: collapse;
}
table td, table th {
  border: 1px solid #FFFFFF;
  padding: 6px 6px;
}
table td {
  font-size: 12px;
}
table tr:nth-child(Odd) td {
  background: #E8E8E8;
}
table th {
  background: #00BBED;
  border-bottom: 5px solid #FFFFFF;
}
table th {
  font-size: 16px;
  font-weight: bold;
  color: #FFFFFF;
  text-align: center;
  border-left: 2px solid #FFFFFF;
}
table th:first-child {
  border-left: none;
}
</style>
"@

  #Set value of notline to include information at the foot of the email message.
  $NoteLine = "Vcenters included in query: $($VIServers -join ' | ') `n Generated on $(Get-date -Format G )"

  #Set HTML beginning of the BODY of the message.  This generates the div for holding the table and header
  $PreContent = "<H1>$Title</H1>"

  #Closes the body and div and attaches the Noteline variable
  $PostContent = "<br><p><font size='2'><i>$NoteLine</i></font>"

  #Converts Snapshotlist info into an HTML Table sorted by vCenter then by VM while also combining the CSS,beginning of the Body and end of the body of HTML.  Then converts to a string for use in the email message.
  [string]$body = ($Snapshotlist | Sort-Object VCenter, VM | ConvertTo-Html -Head $Css -PreContent $PreContent -PostContent $PostContent)

  #Input all the values for the message that will be sent.
  $messageinfo = @{
    To         = $MailTo
    From       = 'Snapshot.Report@murraystate.edu'
    Subject    = $Title
    Body       = $body
    SMTPServer = $SMTP
    BodyAsHtml = $true
  }

  #Splat message into Send-MailMessage command.
  Send-MailMessage @messageinfo

}