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
    [string]
    $TaggedVm = 'host_18',

    [Parameter(Mandatory = $false, Position = 1)]
    [string]
    $DestinationHost = '192.168.1.18'
  )
  
  $TaggedOne = (get-vm -tag $TaggedVm)
  
  foreach($server in $TaggedOne)
  {
    Write-Verbose -Message ('Moving {0} to Host-18' -f $server)
    move-vm -name $server -Destination $DestinationHost
  }
}

