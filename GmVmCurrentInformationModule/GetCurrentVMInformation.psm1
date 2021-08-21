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
  $report = @()
  
  
  #Get All
  $AllVmHosts = Get-VmHost
  $AllVMs = Get-Vm
  $PoweredOffVM = $AllVMs | Select-VMs -PowerState PoweredOff
  $PoweredOnVM = $AllVMs | Select-VMs -PowerState PoweredOn
  $AllSnapshots = $AllVMs | Get-Snapshot
  $AllVmTags = Get-Tag
  
  # Get Counts
  $VmCountOff = $PoweredOffVM.count 
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
      $MessageCount = $null
    )
    (@'
=============================
{0} {1}
=============================
'@ -f $MessageHeading, $MessageCount)
  }
  
  ########

  foreach($vm in Get-View -ViewType Virtualmachine){

    $vms = "" | Select-Object VMName,VMState, TotalCPU, CPUShare, TotalMemory, Datastore, UsedSpaceGB, ProvisionedSpaceGB, Tags

    $vms.VMName = $vm.Name

    $vms.VMState = $vm.summary.runtime.powerState

    $vms.TotalCPU = $vm.summary.config.numcpu

    $vms.CPUShare = $vm.Config.CpuAllocation.Shares.Level

    $vms.TotalMemory = $vm.summary.config.memorysizemb

    $vms.Datastore = $vm.Config.DatastoreUrl[0].Name

    $vms.UsedSpaceGB = [math]::Round($vm.Summary.Storage.Committed/1GB,2)

    $vms.ProvisionedSpaceGB = [math]::Round($vm.Summary.Storage.UnCommitted/1GB,2)

    $vms.Tags = (Get-TagAssignment -Entity (Get-VIObjectByVIView -VIView $vm) -Category "customer").Tag.Name

    $report += $vms

  }

  $report
  
  ########
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


Export-ModuleMember -function Get-VmPowerStateSnapInfo



