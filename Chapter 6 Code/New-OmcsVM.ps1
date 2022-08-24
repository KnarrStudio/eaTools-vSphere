#requires -Version 2.0 -Modules VMware.VimAutomation.Core, VMware.VimAutomation.Vds

# Another Open minded common sense script to create a vm based on parameters in a CSV

param(
  [Parameter(Mandatory,HelpMessage='Path to the inputfile')]
  [String]$InputCsv,
  [Parameter(Mandatory,HelpMessage='Name of the Tenent Folder from vCenter')]
  [String]$TenentFolder,
  [Parameter(Mandatory,HelpMessage='Resorce Pool for Tenent')]
  [String]$ResourcePool,
  [Parameter(Mandatory,HelpMessage='Name of cluster tenent is part of in vCenter')]
  [String]$ClusterName,
  [Parameter(Mandatory=$false,HelpMessage='Path to ISO for CD')]
  [String]$IsoDatastore = '[datastore0] /rhel-server-6.5-x86_64-boot.iso'
)

$InputCsv  = Import-Csv -Path .\NewComputer.txt
$InputCsv | ConvertTo-Html | Out-File NewComputer.html
$NewVmSplat = @{
  Name              = $InputCsv.Name
  NumCpu            = $InputCsv.NumCpu
  MemoryGB          = $InputCsv.MemoryGB
  DiskStorageFormat = $InputCsv.DiskStorageFormat
  DiskGB            = $InputCsv.DiskGB0
  GuestId           = $InputCsv.GuestId
  StartConnected    = $InputCsv.StartConnected
  Location          = $InputCsv.Folder
  Confirm           = $InputCsv.Confirm
}

Get-Folder -Name $TenentFolder

#$Cluster = Get-Folder $TenentFolder | Get-Cluster -Name $ClusterName
$Cluster = Get-Folder -Name $TenentFolder | Get-Cluster -Name $ClusterName
$ResourcePool = Get-ResourcePool -Name $ResourcePool -Location $Cluster


$VM = New-VM @NewVmSplat -VMHost (Get-VMHost -Location $Cluster -State Connected |
Get-Random) `
-ResourcePool $ResourcePool `
-Portgroup (Get-VDPortgroup -Name $InputCsv.VLAN) `
-CD |
Get-CDDrive |
#Set-CDDrive -IsoPath '[datastore0] /rhel-server-6.5-x86_64-boot.iso' 
Set-CDDrive -IsoPath$IsoDatastore


<#Add additional e1000e Network Adapters
    New-NetworkAdapter -Portgroup (Get-VDPortgroup -Name $newvmtxt.VLAN) `
    -StartConnected `
    -Type 'e1000e' `
    -VM $VM
#>


#Add additional hard drives
for ($i = 1; $i -lt 3; $i++)
{ 
  $diskNum = ('DiskGB{0}' -f $i)
  if($InputCsv.$diskNum -gt 0)
  {
    New-HardDisk -CapacityGB $InputCsv.$diskNum -VM $VM
  }  
}

