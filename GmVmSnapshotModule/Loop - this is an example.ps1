function Select-VMServers
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $false, Position = 0)]
    [Object]
    $SkipSnapshotOf = @('erv'),
    
    [Parameter(Mandatory = $false, Position = 1)]
    [System.String]
    $PowerState = 'on',
    
    [Parameter(Mandatory = $false, Position = 2)]
    [System.String]
    $VMServers = 'server'
  )

  if( -not $VMServers)
  {
    if ($PowerState -ne 'Any')
    {
      $VMServers = get-VM | Where-Object -FilterScript {
        (
        $_.PowerState -eq $PowerState)
      }
      else{
        $VMServers = get-VM
      }
      $SelectedServers = $VMServers | Where-Object -FilterScript {
        $found = $false 
        foreach ($Exlusion in $SkipSnapshotOf) 
        {
          if($_.contains($Exlusion))
          {
            return $_
          }
        }
      }
    }
  }
  Return $SelectedServers
}

