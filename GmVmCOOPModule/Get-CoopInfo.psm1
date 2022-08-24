Function script:Get-VmPowerStateSnapInfo 
{
  <#
      .SYNOPSIS
      Returns a information about the VMs and Snapshots 

      .OUTPUTS
      Snapshot information of all VM's in our vsphere.
      Servers with the Power ON.
      VM's with the Power turned OFF.

  #>
  function Select-VMs
  {
    param
    (
      [Parameter(Mandatory = $true, ValueFromPipeline = $true, HelpMessage = 'Data to filter')]
      [Object]$InputObject,
      [Parameter(Mandatory = $true,HelpMessage = 'Powerstate to filter')]
      [ValidateSet('PoweredOff','PoweredOn')]
      [Object]$PowerState
    )
    process
    {
      if (($InputObject.PowerState -eq $PowerState))
      {
        $InputObject
      }
    }
  }

  #Set variables
  $DoubleLineBoarder = '============================='
  $NewLine = "`n"
  
  #Get All
  $AllVmHosts = Get-VmHost
  $AllVMs = Get-Vm
  $PoweredOffVM = $AllVMs | Select-VMs -PowerState PoweredOff
  $PoweredOnVM = $AllVMs | Select-VMs -PowerState PoweredOn
  $AllSnapshots = $AllVMs | Get-Snapshot
  $AllVmTags = Get-Tag
  
  # Get Counts
  $VmCountOff = 5#$PoweredOffVM.count 
  $VmCountOn = $PoweredOnVM.count
  $AllVmHosts = $AllVmHosts.count
  $SnapshotDateWindow = 5


  $Snapshotinfo = $AllSnapshots | Select-Object -Property VM, Name, Created,SizeGB 

  $MsgOut = @{
    Heading             = 'Heading'
    PoweredOff          = "Regular VM's with the Power turned OFF:"
    PoweredOn           = "Regular VM's with the Power turned On:"
    SnapshotInformation = 'Snapshot information.'
  }
 
  $MessageHeading = $MsgOut.PoweredOff
  
  Function Write-MsgHeader 
  {
    param
    (
      [Parameter(Mandatory)]
      [String]$MessageHeading,
      [Parameter(Mandatory = $false)]
      [int]$MessageCount = ''
    )
    (@'
=============================
{0} {1}
=============================
'@ -f $MessageHeading, $MessageCount)
  }
  
  
  If ($PoweredOnVM.count -gt 0)
  {
    Write-MsgHeader -MessageHeading $MsgOut.PoweredOn -MessageCount $VmCountOn
  }

  If ($PoweredOffVM.count -gt 0)
  {
    Write-MsgHeader -MessageHeading $MsgOut.PoweredOff -MessageCount $VmCountOff
  }

   # Display Snapshot information
  If ($Snapshotinfo.count -gt 0)
  {
     Write-MsgHeader -MessageHeading $MsgOut.SnapshotInformation
  foreach($Snapshot in $AllSnapshots)
    {
      $Snapshotinfo = $Snapshot | Select-Object -Property VM, Name, Created, @{
        n = 'SizeGb'
        e = {
          '{0:N2}' -f $_.SizeGb
        }
      }
      if($Snapshot.Created -lt $((Get-Date).AddDays(-$SnapshotDateWindow)))
      {
        Write-Host $Snapshotinfo -BackgroundColor Red
      }
      else
      {
        Write-Host $Snapshotinfo -BackgroundColor Green
      }
    }
  }
  Write-Host $DoubleLineBoarder -foregroundcolor Yellow
}


Get-VmPowerStateSnapInfo



