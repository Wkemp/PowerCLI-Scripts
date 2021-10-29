Function Get-VMClusterInfo{
    <#
    .SYNOPSIS
        Gathers and displays basic information about UCS Clusters/Hosts
    .DESCRIPTION
        Gathers and displays basic information about UCS Clusters/Hosts
    .EXAMPLE
        Connect-VIServer vcenter.domain.edu
        Get-ClusterInfo
    
        Get information about vcenter.domain.edu and display to console.
    .NOTES
    General notes
    #>
        $Clusters = Get-Cluster | Select-Object Name
        Foreach($cluster in $Clusters){
            $ClusterInfo = @( Get-View -ViewType HostSystem -Property Name, Summary, OverallStatus, config , Hardware | 
                ForEach-Object{
                    [pscustomobject] @{
                        'DataCenter' = $(Get-Datacenter -Cluster $($cluster.Name)).Name
                        'Cluster' =$cluster.name
                        'Host' = $_.Name
                        'ManagementIP' = $_.Summary.ManagementServerIP
                        'SerialNumber' = ($_.Hardware.SystemInfo.OtherIdentifyingInfo | Where-Object {$_.identifierType.Key -eq "ServiceTag"}).IdentifierValue |Select-Object -Last 1
                        'Vendor' = $_.Hardware.SystemInfo.Vendor
                        'Model' = $_.Hardware.SystemInfo.Model
                        'CurrentEVCMode' = $_.Summary.CurrentEVCModeKey
                        'CPUModel' = $($_.Hardware.CpuPkg.Description |Select-Object -First 1)
                        'NumberOfCpu' = [int]$_.Hardware.CpuPkg.count
                        'TotalCores' = [int]$($_.Hardware.CpuInfo.NumCpuCores)
                        'TotalThreads' = [int]$($_.Hardware.CpuInfo.NumCpuThreads)
                        'TotalMemoryGB' = [int][Math]::Round($vmhost.Hardware.MemorySize/1GB)
                        'Hypervisor' = $_.config.Product.FullName
                        'BIOSVersion' = $_.Hardware.BiosInfo.BiosVersion
                        'BIOSDate' = [datetime]$_.Hardware.BiosInfo.releaseDate
                    }
                }
            )
            $ClusterInfo 
        }
        
}