function Get-VmHostsAndServers
{
  <#
      .SYNOPSIS
      Short Description
      .DESCRIPTION
      Detailed Description
      .EXAMPLE
      Get-VmHostsAndServers
      explains how to use the command
      can be multiple lines
      .EXAMPLE
      Get-VmHostsAndServers
      another example
      can have as many examples as you like
  #>
  param
  (
    [Parameter(Position=0)]
    [Switch]
    $VMServers,
    
    [Parameter(Position=1)]
    [Switch]
    $VMHosts,
    
    [Parameter(Position=2)]
    [Switch]
    $VMSnapshots,
    
    [Parameter(Position=3)]
    [Switch]
    $VMPoweredOff,
    
    [Parameter(Position=4)]
    [Switch]    $VMPoweredOn
  )
  
  #$VMServers = Get-vm
  Write-Debug -Message $PSBoundParameters.Keys
  
  Switch($PSBoundParameters.Keys){
    # Get list of all VM's
    'VMServers'  {5}#$$VMServers}

    # Get list of All Hosts 
    'VMHosts' {$ComputerList = Get-VMhosts}

    # Get list of all snapshots
    'VMSnapshots' {$ComputerList = $VMServers | Get-Snapshots}

    # Get list of all powered off servers
    'VMPoweredOff' {$ComputerList = $VMServers | Where-Object {$_.PowerState -eq "PoweredOff"}}

    # Get list of all powered on servers
    'VMPoweredOn' {$ComputerList = $VMServers | Where-Object {$_.PowerState -eq "PoweredOn"}}
  } 
  Return $PSBoundParameters.Keys
}

