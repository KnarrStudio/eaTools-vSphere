function Start-BalanceVmServers
{
  <#
      .SYNOPSIS
      An easy way "Balance" VMs between two hosts using tags

      .EXAMPLE
      Start-BalanceVmServers

      .LINK
      'https://github.com/KnarrStudio/eaTools-vSphere'

  #>
  [CmdletBinding(HelpUri = 'https://github.com/KnarrStudio/eaTools-vSphere',
  ConfirmImpact = 'Medium')]

  param
  (
    [Parameter(Mandatory = $false, Position = 0)]
    [System.String]
    $host18 = '192.168.1.18',
    
    [Parameter(Mandatory = $false, Position = 1)]
    [System.String]
    $host19 = '192.168.1.19',
    
    [Parameter(Mandatory = $false, Position = 2)]
    [Object]
    $tagged18 = (get-vm -tag 'host_18'),
    
    [Parameter(Mandatory = $false, Position = 3)]
    [Object]
    $tagged19 = (get-vm -tag 'host_19')
  )
  
  
  foreach($server in $tagged18)
  {
    if($server.vmhost.name -ne $host18)
    {
      Write-Verbose -Message ('Moving {0} to Host-18' -f $server)
      move-vm $server -Destination $host18 #-whatif
    }
  }
  
  foreach($server in $tagged19)
  {
    if($server.vmhost.name -ne $host19)
    {
      Write-Verbose -Message ('Moving {0} to Host-19' -f $server)
      move-vm $server -Destination $host19 #-whatif
    }
  }
}

