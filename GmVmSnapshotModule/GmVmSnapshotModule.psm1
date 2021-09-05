#R equires - Module vmware.vimautomation.core
if ($global:DefaultVIServers.Count -eq 0) 
{
  Connect-VIServer -menu
}
Function New-VmSnapshot 
{
  <#
      .SYNOPSIS
      Creates Snapshots of the selected VM or all powered on VM's and gives the Snapshot a common Name

      .DESCRIPTION
      Add a more complete description of what the function does.

      .PARAMETER VMServers
      One or many server names separated by ","

      .PARAMETER SnapshotName
      Standard name of the snapshot ('Updates', 'Troubleshooting', 'SoftwareInstallation','Other').  This will be added to the date stamp.

      .PARAMETER SnapshotDescription
      By default 'Created by Script New-VmSnapshot.ps1' Run by "Username".  You can change this as required.

      .PARAMETER All
      Switch to run against all of the powered on servers.  You can also add the servername 'All' to snapshot all of the powered on servers.  Adding this to the command will disregard any and all servers listed.

      .EXAMPLE
      New-VmSnapshot -VMServers Value -SnapshotName Value -SnapshotDescription Value
      This will create snapshots of each VmServers listed
    
      .NOTES
      Copy of this located in onenote search for the script name: "NewVmSnapshots.psm1"
      Author Name: Erik Arnesen
      Contact : 5276

  #>
  [Cmdletbinding()]
  Param(
    [Parameter(Mandatory = $false, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [Alias('computername', 'hostname')]
    [ValidateLength(3, 14)]
    [AllowEmptyString()]
    [string[]]$VMServers,
    [Parameter(Mandatory, HelpMessage = 'Reason for Snapshot')]
    [ValidateSet('Updates', 'Troubleshooting', 'SoftwareInstallation', 'Other')] 
    [string]$SnapshotName,    
    [Parameter(Mandatory, HelpMessage = 'VMs in what powerstate')]
    [ValidateSet('PoweredOn', 'PoweredOff', 'Any')] 
    [string]$PowerState,
    [string]$SnapshotDescription = 'Created by Script New-VmSnapshot.ps1',
    [Switch]$All,
    [String[]]$SkipSnapshotOf
  )
  begin {
    Write-Verbose -Message ('Start Begin Section')
    function Select-VMServers 
    {
      param
      (
        [Parameter(Mandatory = $false, Position = 0)]
        [Object[]]$SkipSnapshotOf = @('dc'),
        [Parameter(Mandatory = $false, Position = 1)]
        [string]
        $PowerState = 'on',
        [Parameter(Mandatory = $false, Position = 2)]
        [string]
        $VMServers = 'server'
      )
      if ($PowerState -ne 'Any') 
      {
        $VMServers = get-VM | Where-Object -FilterScript {
          (
          $_.PowerState -eq $PowerState)
        }
        else {
          $VMServers = get-VM
        }
        $SelectedServers = $VMServers | Where-Object -FilterScript {
          #$found = $false 
          foreach ($Exclusion in $SkipSnapshotOf) 
          {
            if ($_.contains($Exclusion)) 
            {
              return $_
            }
          }
        }
      }
      Return $SelectedServers
    }
    # Write-Verbose ('VMservers {0}' -f $VMServers)
    <#    if($VMServers -eq 'All') 
        {
        Write-Verbose -Message ('All Selected')

        $VMServers = @()
        $VMServers = get-vm | Get-AllPoweredOnVms 
        Write-Information -MessageData 'Creating Snapshots of all systems' -InformationAction Continue
    }#>
    #Create Time/Date Stamp
    $TDStamp = Get-Date -UFormat '%Y%m%d'
    #Get User Information
    [String]$SysAdmIntl = $env:USERNAME
    #Name of Snapshot
    [String]$SnapName = ('{0}-{1}' -f $TDStamp, $SnapshotName)
    # Description of Snapshot
    [String]$SnapDesc = ('{0} -- Run by: {1}' -f $SnapshotDescription, $SysAdmIntl)
    #Write-Verbose -Message ('Using Server List: {0}' -f $VMServers)
    Write-Verbose -Message ('Naming Snapshots: {0}' -f $SnapName)
  }
  process {
    if ( -not $VMServers) 
    {
      $VMServers = Select-VMServers -SkipSnapshotOf $SkipSnapshotOf -PowerState $PowerState
    }
    Write-Verbose -Message ('Start Process Section')
    if ($SnapshotName -eq ('SoftwareInstallation' -or 'Troubleshooting')) 
    {
      foreach ($Server in $VMServers) 
      {
        Write-Verbose -Message ('New Snapshot of {0}' -f $Server)
        New-Snapshot -vm $Server -Name $SnapName -Description $SnapDesc -Quiesce:$true
      }
    }
    else 
    {
      foreach ($Server in $VMServers) 
      {
        Write-Verbose -Message ('New Snapshot of {0}' -f $Server)
        New-Snapshot -vm $Server -Name $SnapName -Description $SnapDesc -runasync
      }
    }
  }
  end { }
}
Function Remove-VMSnapshots 
{
  Param(
    [Parameter(Mandatory, HelpMessage = 'Add help message for user', ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [Alias('computername', 'hostname')]
    [ValidateLength(3, 14)]
    [string[]]$VMServers,
    [Parameter(Mandatory, HelpMessage = 'Reason for Snapshot')]
    [ValidateSet('Updates', 'Troubleshooting', 'SoftwareInstallation', 'Other')] 
    [string]$SnapshotName,
    [string]$SnapshotDescription = 'Created by Script New-VmSnapshot.ps1',
    [Switch]$All
  )
  #      An easy way to bulk remove Snapshots that have the same Snapshot Name
  $AllSnapshots = get-vm | get-snapshot  
  #Print list of all Snapshots on all VM's (ver1.3 edit done here)
  $RemoveSnapshots = $AllSnapshots |
  Select-Object -Property Name, VM, Created, @{
    n = 'SizeGb'
    e = {
      '{0:N2}' -f $_.SizeGb
    }
  }, id |
  Out-GridView -PassThru -Title 'Select snapshots to delete and press OK'
  # Write-Host ('Based on the Snapshot name you entered: {0}' -f $RemoveSnapshots)
  Write-Host -Object "The following VM's have snapshots that will be removed: " 
  $RemoveSnapshots
  $Okay = 'N'
  $Okay = Read-Host -Prompt 'If this is Okay? Y/[N]'
  #Actual working part of code
  If ($Okay -eq 'Y') 
  {
    $RemoveSnapshots | Remove-Snapshot -confirm:$false -runasync #-whatif
  }
}
Function Show-VmSnapshots 
{
  param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('VM', 'Name', 'Created', 'SizeMB')] 
    [string]$SortOn = 'VM'
  )
  # Get all of the Snapshot
  $AllSnapshots = get-vm |
  get-snapshot  |
  Sort-Object -Property $SortOn |
  Select-Object -Property VM, Name, Created, SizeMB, id
  # Display a list of Snapshots
  Write-Verbose -Message ('Total Snapshots: {0}' -f $AllSnapshots.count)
  $AllSnapshots | Format-Table -AutoSize
}
#Export-ModuleMember -Function Show-VmSnapshots, New-VmSnapshot, Remove-VMSnapshots
