#requires -Version 1.0

function Move-TaggedVmServers
{
  <#
      .SYNOPSIS
      Quick Script to move tagged VMs to a single host.

      .EXAMPLE
      Move-TaggedVmServers -TaggedVm MyTag -DestinationHost TempHost -Verbose

      This will move all of the vms tagged with "MyTag" to the "TempHost"

      .LINK
      'https://github.com/KnarrStudio/eaTools-vSphere'
  #>
  
  [CmdletBinding(HelpUri = 'https://github.com/KnarrStudio/eaTools-vSphere',
  ConfirmImpact = 'Medium')]

  param
  (
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$VmTag = 'host_18',
    [Parameter(Mandatory = $false, Position = 1)]
    [string]$DestinationHost = '192.168.1.18'
  )
  
  $TaggedVms = (get-vm -tag $VmTag)
  foreach($SingleVm in $TaggedVms)
  {
    Write-Verbose -Message ('Moving {0} to {1}' -f $SingleVm, $DestinationHost)
    move-vm -name $SingleVm -Destination $DestinationHost
  }
}

