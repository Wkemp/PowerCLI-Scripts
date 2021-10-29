Function Import-VMwareModules{
 #Imports All Modules in the VMware.Vim set
  get-module -ListAvailable | Where-Object {$_.name -like "VMware.Vim*"} | Import-Module
}

Function Remove-VMwareModules{
  #Remove all VMware.Vim Modules
  Get-Module | Where-Object {$_.Name -like "VMware.Vim*"} | Remove-Module
}