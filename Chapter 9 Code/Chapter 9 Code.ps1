################################################################
# Listing 9.1: Convert text to objects 
################################################################
$searchString = "(\S+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)%\s+(\S+)"
$splat = @{
    'Computer'=$vm.Guest.IPAddress[0]
    'Credential'=$creds
    'ScriptText'="df"
}
Invoke-SSH @splat | Where-Object { $_ -match $searchString} |
  ForEach-Object {
      New-Object PSObject -Property @{
          "FileSystem" = $matches[1]
          "1kBlocks" = [int64]$matches[2]
          "Used" = [int64]$matches[3]
          "Available" = [int64]$matches[4]
          "PercentUsed" = [Decimal]$matches[5]
          "MountPoint" = $matches[6]
      }
  } | Where-Object {$_.Available -lt (50MB/1KB) } |
  ForEach-Object {
    Write-Warning "Free space on volume $($_.MountPoint) is low"
  }

################################################################
# Listing 9.2: Report the status of a service using PowerShell remoting
################################################################
Function Check-Service {
<#
.SYNOPSIS
  Checks the state of a service using PowerShell remoting
.DESCRIPTION
  This function checks the state of a service using
  PowerShell remoting. The optional restart switch can be used
  to restart a service if it is stopped.
.PARAMETER Computer
  One or more computer names to check the service on
.PARAMETER Service
  One or more service names to check
.PARAMETER Start
  Optional parameter to start a stopped service
.PARAMETER Restart
  Optional parameter to restart a service
.EXAMPLE
  PS> Check-Service -Computer VM001 -Service wuauserv
#>

  Param(
    [parameter(mMandatory = $true)]
    [string]$Computer
  ,
    [parameter(mMandatory = $true)]
    [string]$Service
  ,
    [switch]$Start
  ,
    [switch]$Restart
  )
  #establish a persistent connection
  $session = New-PSSession $Computer
  $remoteService = Invoke-Command –Session $session -ScriptBlock {
    param($ServiceName)
    $localService = Get-Service $ServiceName
    $localService
  } -ArgumentList $Service
  if ($Start -and $remoteService.Status -eq “Stopped”) {
    Invoke-Command –Session $session -ScriptBlock {
        $localService.Start()
    }
    $remoteService | Add-Member -MemberType NoteProperty -Name Started -Value $True
  }
  if ($Restart) {
    Invoke-Command –Session $session -ScriptBlock {
      $localService.Stop()
      $localService.WaitForStatus(“Stopped”)
      $localService.Start()
    }
    $remoteService | Add-Member -MemberType NoteProperty -Name Restarted -Value $True
  }
  #close persistent connection
  Remove-PSSession $session
  Write-Output $remoteService
}


################################################################
# Listing 9.3: Evacuate ESX host
################################################################
Function Evacuate-VMHost {
<#
.SYNOPSIS
  Puts host into maintenance mode and moves all VMs on the host
  to other members in the same cluster
.DESCRIPTION
  This function puts a host in maintenance mode and moves all
  VMs from the VMHost randomly to other hosts in the cluster.
  If -TargetHost is specified, all VMs are moved to this
  TargetHost instead of random cluster members.
.PARAMETER VMHost
  The source host to put into maintenance mode
.PARAMETER TargetHost
  Optional target host
.EXAMPLE
  PS> Evacuate-VMHost -VMHost vSphere01
.EXAMPLE
  PS> Evacuate-VMHost -VMHost vSphere01 -TargetHost vSphere02
#>
  Param(
    [parameter(Mandatory = $true,
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)]
    [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VMHostImpl]$VMHost
  ,
    [parameter(Mandatory = $false,
        ValueFromPipelineByPropertyName=$true)]
    [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VMHostImpl]$TargetHost
  )

  if (-Not $TargetHost) 
  {
    $cluster = Get-Cluster -VMHost $VMHost
    if (-Not $cluster) 
    {
      throw “No cluster found”
    }
    $clusterHosts = $cluster | Get-VMHost | 
        Where-Object {$_.Name -ne $VMHost.Name -and `
          $_.ConnectionState -eq “Connected”}
    if (-Not $clusterHosts) 
    {
      throw “No valid cluster members found”
    }
  }
  #Evacuate all VMs from host
  foreach ($vm in ($VMHost | Get-VM)) 
  {
    $splat = @{
        'VM'=$VM
        'RunAsync'=$true
        'Confirm'=$false
    }
    if ($TargetHost) 
    {
      $splat.Destination = $TargetHost
    }
    else 
    {
      $splat.Destination = $clusterHosts | Get-Random
    }
    Move-VM @splat | Out-Null
  }

  #Put host into maintenance mode
  $VMHost | Set-VMHost -State “Maintenance” -RunAsync:$true
}
################################################################
# Listing 9.4	Using Storage vMotion using Datastore Clusters and affinity rules
################################################################
$VM = Get-VM -Name 'App01'
$vmdks = Get-Harddisk -VM $VM
$DatastoreCluster = Get-DatastoreCluster -Name 'DatastoreCluster'
$vmdkAntiAffinityRule = New-Object VMware.VimAutomation.ViCore.Types.V1.DatastoreManagement.SdrsVMDiskAntiAffinityRule -ArgumentList $vmdks
Move-VM -VM $VM -Datastore $DatastoreCluster -AdvancedOption $vmdkAntiAffinityRule

################################################################
# Listing 9.5: Move all VMs from one datastore to another
################################################################
Function Move-Datastore {
<#
.SYNOPSIS
  Moves all registered .vmx and .vmdk files to another datastore
.DESCRIPTION
  This function moves all registered vms from the source
  datastore to the target datastore
.PARAMETER Source
  The source datastore 
.PARAMETER Destination
  The target datastore 
.EXAMPLE
  Move-Datastore -Source (Get-Datastore datastore1) -Destination (Get-Datastore datastore2)
#>

  [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='Medium')]
  param(
    [parameter(mandatory = $true)]
    [VMware.VimAutomation.ViCore.Impl.V1.DatastoreManagement.DatastoreImpl]$Source
  ,
    [parameter(mandatory = $true)]
    [VMware.VimAutomation.ViCore.Impl.V1.DatastoreManagement.DatastoreImpl]$Destination
  )
  Process
  {
    Foreach ($vm in ($Source | Get-VM)) 
    {
      $configFile = $vm.ExtensionData.Config.Files.VmPathName -match `
          '\[(?<ds>\S+)\]\s(?<path>.+)' |
          ForEach-Object {
              New-Object PSObject -Property @{
                'DataStore'=$Matches.ds
                'Path' = $Matches.path
                'VMPathName' = $Matches.0
              }
          }
      if ($configFile.Datastore -eq $Source.Name) 
      {
          $configDatastoreName = $Destination.Name
      }
      else
      {
        $configDatastoreName = $configFile.DataStore
      }
      $spec = New-Object VMware.Vim.VirtualMachineRelocateSpec
      $spec.Datastore = (Get-Datastore $configDatastoreName | 
         Get-View -Property name).MoRef
      $spec.Disk = Foreach ($disk in ($vm | Get-HardDisk)) 
      {
        $DiskFile = $disk.FileName -match '\[(?<ds>\S+)\]\s(?<path>.+)'|
          ForEach-Object {
            New-Object PSObject -Property @{
              'DataStore'=$Matches.ds
              'Path' = $Matches.path
              'VMPathName' = $Matches.0
            }
          }
        if ($DiskFile.DataStore -eq $Source.Name) 
        {
          $diskDatastoreName = $Destination.Name
        }
        else
        {
          $diskDatastoreName = $DiskFile.DataStore
        }
        $objDisk = New-Object VMware.Vim.VirtualMachineRelocateSpecDiskLocator
        $objDisk.DiskID = $disk.Id.Split(‘/’)[1]
        $objDisk.DataStore = (Get-Datastore $diskDatastoreName | 
            Get-View -Property Name).MoRef
        $objDisk
      }
      if ($pscmdlet.ShouldProcess($VM, "Moved to ${diskDatastoreName}"))
      {
        $vm.ExtensionData.RelocateVM_Task($spec, “defaultPriority”)
      }
    }
  }
}
################################################################
# Listing 9.6: Cross vCenter vMotion
################################################################
<#
.SYNOPSIS
   Move a VM to another vCenter instance.  Supports both SSO and none-SSO 
   integrated vCenter instances.  The VMs networking cannot be migrated 
   from Standard to vDS, or from vDS to Standard.
.NOTES
   Refactored version of the demo originaly posted:
   virtuallyghetto.com/2015/02/did-you-know-of-an-additional-cool-vmotion-capability-in-vsphere-6-0.html
.Example
    $vc2 = Connect-VIServer -Server VC2 -Credential $creds -NotDefault
    $VMHost = Get-VMHost  -Server $vc2 | Get-Random
    $Datastore = Get-Datastore -Name Datastore4 -Server $vc2
    $Cluster = Get-Cluster -Name Prod01 -Server $vc2
    $pg = Get-VirtualPortGroup -Standard -Server $vc2 -Name VLAN1107

    Move-VMCrossVC -VMName VM001 `
        -VMHost $VMHost `
        -Datastore $Datastore `
        -PortGroup $pg `
        -DestinationVC $VC2 `
        -DestinationCredential $creds 
        -cluster $Cluster

    Migrate VM001 to VC2 relocating the VM to Datastore4, and all the VMs
    network adapaters to VLAN1107
.Example
    $vc2 = Connect-VIServer -Server VC2 -Credential $creds -NotDefault
    $VMHost = Get-VMHost  -Server $vc2 | Get-Random
    $Datastore = Get-Datastore -Name Datastore4 -Server $vc2
    $Cluster = Get-Cluster -Name Prod01 -Server $vc2
    $AdvancedNetworkMap = @{
        '00:50:56:ba:54:2c'=(Get-VirtualPortGroup -Standard -Server $vc2 -Name VLAN1107)
        '00:50:56:ba:24:9c'=(Get-VDPortgroup -Server $vc2 -Name VLAN2206)
        '00:50:56:ba:d2:26'=(Get-VDPortgroup -Server $vc2 -Name VLAN2206)
    }
    Move-VMCrossVC -VMName VM001 `
        -VMHost $VMHost 
        -Datastore $Datastore 
        -AdvancedNetworkMap $AdvancedNetworkMap 
        -DestinationVC $VC2 
        -DestinationCredential $creds 
        -cluster $Cluster

    Migrate VM001 to VC2 relocating the VM to Datastore4, and targeting each VMNic to a specific portgroup.
#>
Function Move-VMCrossVC
{
    [CmdletBinding(DefaultParameterSetName='easyNetwork', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  ConfirmImpact='Medium')]
    param
    (
        # Name of the VM to be migrated
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='easyNetwork')]
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='hardNetwork')]
        [Alias("Name")] 
        [string]
        $VMName
    ,
        # Desitination resource pool or cluster to relocate vm to
        [Parameter(Mandatory=$false,ValueFromPipeline=$true,ParameterSetName='easyNetwork')]
        [Parameter(Mandatory=$false,ValueFromPipeline=$true,ParameterSetName='hardNetwork')]
        [VMware.VimAutomation.ViCore.Types.V1.Inventory.VIContainer]
        $Cluster
    ,
        # Desitination VMHost to relocate vm to
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName='easyNetwork')]
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName='hardNetwork')]
        [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VMHostImpl]
        $VMHost    
    ,
        # Desitination Datastore to relocate vm to
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName='easyNetwork')]
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName='hardNetwork')]
        [VMware.VimAutomation.ViCore.Impl.V1.DatastoreManagement.DatastoreImpl]
        $Datastore
    ,
        # Destination PortGroup to migrate VM Networking to
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName='easyNetwork')]
        [VMware.VimAutomation.ViCore.Types.V1.Host.Networking.VirtualPortGroupBase]
        $PortGroup
    ,
        # Hashtable containing key=value pairs of <VM Mac Address>=<VirtualPortGroupBase>
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName='hardNetwork')]
        [System.Collections.Hashtable]
        $AdvancedNetworkMap
    ,
        # Specifies the destination vCenter Server systems
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName='easyNetwork')]
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName='hardNetwork')]
        [VMware.VimAutomation.ViCore.Impl.V1.VIServerImpl]
        $DestinationVC
    ,
        # Destination vCenter Server Credentials.
        [Parameter(Mandatory=$false,ValueFromPipeline=$true,ParameterSetName='easyNetwork')]
        [Parameter(Mandatory=$false,ValueFromPipeline=$true,ParameterSetName='hardNetwork')]
        [System.Management.Automation.PSCredential]
        $DestinationCredential
    ,
        # Specifies the Source vCenter Server systems default is to use the current context.
        [Parameter(Mandatory=$false,ParameterSetName='easyNetwork')]
        [Parameter(Mandatory=$false,ParameterSetName='hardNetwork')]
        [VMware.VimAutomation.ViCore.Impl.V1.VIServerImpl]
        $SourceVC
    ,
        # Indicates that the command returns immediately without waiting for the task to complete.
        [Parameter(Mandatory=$false,ParameterSetName='easyNetwork')]
        [Parameter(Mandatory=$false,ParameterSetName='hardNetwork')]
        [switch]
        $RunAsync
    )
    Begin
    {
        Function Get-SSLThumbprint
        {  
            # Function original location: http://en-us.sysadmins.lv/Lists/Posts/Post.aspx?List=332991f0-bfed-4143-9eea-f521167d287c&ID=60  
            [CmdletBinding()]  
            param(  
                [Parameter(Mandatory = $true, ValueFromPipeline = $true)]  
                [string]$URL,  
                [Parameter(Position = 1)]  
                [ValidateRange(1,65535)]  
                [int]$Port = 443,  
                [Parameter(Position = 2)]  
                [Net.WebProxy]$Proxy,  
                [Parameter(Position = 3)]  
                [int]$Timeout = 15000,  
                [switch]$UseUserContext  
            )  
            $ConnectString = "https://$url`:$port"  
            $WebRequest = [Net.WebRequest]::Create($ConnectString)  
            $WebRequest.Proxy = $Proxy  
            $WebRequest.Credentials = $null  
            $WebRequest.Timeout = $Timeout  
            $WebRequest.AllowAutoRedirect = $true  
            [Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}  
            try {$Response = $WebRequest.GetResponse()}  
            catch {}
            finally { $Response.Close() }  
            if ($WebRequest.ServicePoint.Certificate -ne $null) {  
                $Cert = [Security.Cryptography.X509Certificates.X509Certificate2]$WebRequest.ServicePoint.Certificate.Handle  
                try {$SAN = ($Cert.Extensions | Where-Object {$_.Oid.Value -eq "2.5.29.17"}).Format(0) -split ", "}  
                catch {$SAN = $null}  
                [System.Security.Cryptography.X509Certificates.X509Certificate2]$certificate = $WebRequest.ServicePoint.Certificate;  
            } else {  
                Write-Error $Error[0]  
            }
            $ssltumbraw = $certificate.Thumbprint
            $ssltumb = $(for ($i=0;(($i+2) -le $ssltumbraw.Length);$i = $i + 2) { 
                            $ssltumbraw.Substring($i,2)}) -join ':'  
            return $ssltumb
        }
        # connect to the destination VC
        # Set source VC context
        if ($SourceVC)
        {
            $splat = @{'Server'=$SourceVC}
        }
        else
        {
            $splat = @{'Server'=$global:DefaultVIServer}
        }
    }
    Process
    {
        # Source VM to migrate
        $vm  = Get-View (Get-VM -Name $VMName @splat) -Property Config.Hardware.Device
        
        # determine the destination pool to migrate VM to
        if (-Not $Cluster)
        {
            $DestinationID = (Get-ResourcePool -Server $DestinationVC -Name Resources).ExtensionData.MoRef
        }
        else
        {
            switch ($Cluster.GetType().Name)
            {
                "ClusterImpl" {
                    $DestinationID = $Cluster.ExtensionData.ResourcePool
                }
                "ResourcePoolImpl" {
                    $DestinationID = $Cluster.ExtensionData.MoRef
                }
            }
        }
        # build the SLP connection only needed if migrating to a VC outside of SSO
        if ($DestinationCredential)
        {
            $credential = New-Object VMware.Vim.ServiceLocatorNamePassword -Property @{
                'username' = $DestinationCredential.UserName
                'password' = $DestinationCredential.GetNetworkCredential().Password
            }
            $ServiceLocator = New-Object VMware.Vim.ServiceLocator -Property @{
                'credential' = $credential
                'instanceUuid' = $DestinationVC.InstanceUuid
                'sslThumbprint' = Get-SSLThumbprint -URL $DestinationVC.Name
                'url' = "https://$($DestinationVC.Name)"
            }
        }
        # build the relocation spec
        $spec = New-Object VMware.Vim.VirtualMachineRelocateSpec
        $spec.datastore = $Datastore.Id
        $spec.host = $VMHost.Id
        $spec.pool = $DestinationID
        $spec.service = $ServiceLocator
        
        # Find Ethernet Device on VM to change VM Networks
        foreach ($device in $vm.Config.Hardware.Device|?{$_ -is [VMware.Vim.VirtualEthernetCard]}) 
        {
            # if using easy then all adapters go to the same network
            # if using hard find the network that matches the mac address
            if ($AdvancedNetworkMap)
            {
                Try
                {
                    [VMware.VimAutomation.ViCore.Types.V1.Host.Networking.VirtualPortGroupBase]$destinationNetwork = $AdvancedNetworkMap[$device.MacAddress]
                }
                catch
                {
                    Write-Warning "Advance Network Mapping error: $_.exception.message"
                    Write-Warning "Unable to continue with cross-vc vmotion"
                    break;
                }
            }
            else
            {
                $destinationNetwork = $PortGroup
            }
	        $dev = New-Object VMware.Vim.VirtualDeviceConfigSpec
	        $dev.operation = "edit"
	        $dev.device = $device
	        # Determine backing type
            if (($device.Backing.GetType().Name -eq 'VirtualEthernetCardNetworkBackingInfo' -and 
                $destinationNetwork.GetType().Name -eq 'VirtualPortGroupImpl') -or `
                ($device.Backing.GetType().Name -eq 'VirtualEthernetCardDistributedVirtualPortBackingInfo' -and 
                $destinationNetwork.GetType().Name -eq 'VmwareVDPortgroupImpl'))
            {
	            switch($destinationNetwork.GetType().Name)
	            {
		            "VirtualPortGroupImpl" {
			            $dev.device.backing = New-Object VMware.Vim.VirtualEthernetCardNetworkBackingInfo
			            $dev.device.backing.deviceName = $destinationNetwork.Name
		            }
		            "VmwareVDPortgroupImpl" {
                        $dvs= get-view -ViewType VmwareDistributedVirtualSwitch -Server $DestinationVC `
                            -Property @("uuid","Summary.PortgroupName") |
                            ? { $_.Summary.PortgroupName -contains $destinationNetwork.Name }
			            $dev.device.Backing = New-Object VMware.Vim.VirtualEthernetCardDistributedVirtualPortBackingInfo
			            $dev.device.backing.port = New-Object VMware.Vim.DistributedVirtualSwitchPortConnection
			            $dev.device.backing.port.switchUuid = $dvs.uuid
			            $dev.device.backing.port.portgroupKey = $destinationNetwork.Key
		            }
	            }
                $spec.deviceChange += $dev
            }
            else
            {
                Write-Warning "Cross vCenter vMotion does not support vMotion between Standard and Distributed Swiches"
                break;
            }
        }
        if ($pscmdlet.ShouldProcess("Cross VC vMotion", 
            "Migrating $vmname to $DestinationVC "))
        {
            # Issue Cross VC-vMotion 
            $task = $vm.RelocateVM_Task($spec,"defaultPriority") 
            $task1 = Get-Task -Id ("Task-$($task.value)") @splat
            if ($RunAsync)
            {
                Write-Output $task1
            }
            else
            {
                $task1 | Wait-Task 
                Get-VM -Name $VMName -Server $DestinationVC
            }
        }
    }
}
################################################################
# Listing 9.7: Find snapshot creator
################################################################
function Get-SnapshotCreator
{
    Param(
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [VMware.VimAutomation.ViCore.Impl.V1.VM.SnapshotImpl]$Snapshot
    )
    Begin
    {
        function Get-SnapshotTree
        {
          param($tree, $target)
          $found = $null
          foreach($elem in $tree){
            if($elem.Snapshot.Value -eq $target.Value)
            {
              $found = $elem
              continue
            }
          }
          if($found -eq $null -and $elem.ChildSnapshotList -ne $null)
          {
            $found = Get-SnapshotTree $elem.ChildSnapshotList $target
          }
          return $found
        }
    }
    Process
    {
      $guestName = $Snapshot.VM.Name
      $tasknumber = 999 
      $tMgr = Get-View TaskManager
      #Create hash table. Each entry is a create snapshot task
      $report = @{}
      
      $filter = New-Object VMware.Vim.TaskFilterSpec
      $filter.Time = New-Object VMware.Vim.TaskFilterSpecByTime
      $filter.Time.beginTime = $Snapshot.Created.AddDays(-5)
      $filter.Time.timeType = “startedTime”
      
      $collectionImpl = Get-View ($tMgr.CreateCollectorForTasks($filter))
      $collectionImpl.RewindCollector | Out-Null
      $collection = $collectionImpl.ReadNextTasks($tasknumber)
      while($collection -ne $null)
      {
       $collection | 
        ? { $_.DescriptionId -eq “VirtualMachine.createSnapshot”} |
        ? { $_.State -eq “success” }|
        ? { $_.EntityName -eq $guestName} | 
        ForEach-Object {
          $row = New-Object PsObject -Property @{
            'User'=$_.Reason.UserName
          }
        
          $vm = Get-View $_.Entity
          if($vm -ne $null)
          {
            $snapshottree = Get-SnapshotTree -target $_.Result `
                -tree $vm.Snapshot.RootSnapshotList 
            if($snapshottree -ne $null)
            {
                $key = "{0}&{1}" -f $_.EntityName, 
                    $snapshottree.CreateTime.ToFileTimeUtc()
                $report[$key] = $row
            }
          }
       }
       $collection = $collectionImpl.ReadNextTasks($tasknumber)
    }
    $collectionImpl.DestroyCollector()
    # Get the guest’s snapshots and add the user
    Foreach ($snap in $snapshot) 
    {
      $key ="{0}&{1}" -f $snap.vm.Name, $snap.Created.ToFileTimeUtc()
      if($report.ContainsKey($key))
      {
          $snap | Add-Member -MemberType NoteProperty -Name Creator `
              -Value $report[$key].User -PassThru
      }
    }
  }
}