###################################################################################
# Listing 6.1: Cmdlets to create a New-VM
###################################################################################
$newvmtxt = Import-Csv .\NewComputer.txt


$NewVmSplat = @{
Name              = $newvmtxt.Name
DiskMB            = $newvmtxt.DiskMB
DiskStorageFormat = $newvmtxt.DiskStorageFormat
MemoryMB          = $newvmtxt.MemoryMB
GuestId           = $newvmtxt.GuestId
StartConnected    = $newvmtxt.StartConnected
Confirm           = $newvmtxt.Confirm
}

$result = try{Get-VDPortgroup -Name $newvmtxt.VLAN -ea Stop}catch{$null}
if($result -ne $null){$NewVmSplat.Portgroup = $result}

New-VM @NewVmSplat
-CD | Get-CDDrive |
Set-CDDrive -IsoPath '[datastore0] /rhel-server-6.5-x86_64-boot.iso' `




###################################################################################
# Listing 6.2: Querying vCenter for operating systems and Guest IDs
###################################################################################
Function Get-VMGuestId
{
  <#
      .SYNOPSIS
      Query VMHost for a list of the supported Operating systems, and their
      GuestIds.
      .DESCRIPTION
      Query VMHost for a list of the supported Operating systems, and their
      GuestIds.
      .PARAMETER VMHost
      VMHost to query for the list of Guest Id's
      .PARAMETER Version
      Virtual Machine Hardware version, if not supplied the default for that
      host will be returned. I.E. ESX3.5 = 4, vSphere = 7
      .EXAMPLE
      Get-VMGuestId -VMHost vSphere1
      .EXAMPLE
      Get-VMGuestId -VMHost vSphere1 | Where {$_.family -eq 'windowsGuest'} 
  #>
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory = $true,   
    HelpMessage = 'VMHost object to scan for suppported Guests.',   
    ValueFromPipeline = $true
    )]
    [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VMHostImpl]
    $VMHost
    ,
    [Parameter(Mandatory = $true)][int]
    $Version
  )
  Process
  {
    $HostSystem = Get-View -VIObject $VMHost -Property Parent
    $compResource = Get-View -Id $HostSystem.Parent -Property EnvironmentBrowser
    $EnvironmentBrowser = Get-View -Id $compResource.EnvironmentBrowser
    $VMConfigOptionDescriptors = $EnvironmentBrowser.QueryConfigOptionDescriptor()

    if ($Version)
    {
      $Key = $VMConfigOptionDescriptors |
      Where-Object -FilterScript {
        $_.key -match ('{0}$' -f ($Version))
      } |
      Select-Object -ExpandProperty Key
    }
    Else
    {
      $Key = $VMConfigOptionDescriptors |
      Where-Object -FilterScript {
        $_.DefaultConfigOption
      } |
      Select-Object -ExpandProperty Key
    }
    $EnvironmentBrowser.QueryConfigOption($Key, $HostSystem.MoRef) |
    Select-Object -ExpandProperty GuestOSDescriptor | 
    Select-Object -Property @{
      Name       = 'GuestId'
      Expression = {
        $_.Id
      }
    }, 
    @{
      Name       = 'GuestFamily'
      Expression = {
        $_.Family
      }
    }, 
    @{
      Name       = 'FullName'
      Expression = {
        $_.FullName
      }
    }
  }
}

###################################################################################
# Listing 6.3: Creating a complex virtual machine
###################################################################################
$Cluster = Get-Cluster -Name 'Cluster1'
$ResourcePool = Get-ResourcePool -Name 'SQL' -Location $Cluster
$NewVmSplat = @{
Name              = $newvmtxt.Name
NumCpu            = $newvmtxt.NumCpu 
MemoryGB          = $newvmtxt.MemoryMB
DiskStorageFormat = $newvmtxt.DiskStorageFormat
DiskGB            = $newvmtxt.DiskMB
GuestId           = $newvmtxt.GuestId
StartConnected    = $newvmtxt.StartConnected
Location          = $newvmtxt.Folder
Confirm           = $newvmtxt.Confirm

}

$VM = New-VM @NewVmSplat
-VMHost (Get-VMHost -Location $Cluster -State Connected |Get-Random) `
-ResourcePool $ResourcePool `
-Portgroup (Get-VDPortgroup -Name $newvmtxt.VLAN)
<#Add additional e1000e Network Adapters
New-NetworkAdapter -Portgroup (Get-VDPortgroup -Name $newvmtxt.VLAN) `
-StartConnected `
-Type 'e1000e' `
-VM $VM
#>
#Add additional hard drives
New-HardDisk -CapacityGB 100 -VM $VM
New-HardDisk -CapacityGB 10 -VM $VM


###################################################################################
# Listing 6.4: Deploying a virtual machine from a template
###################################################################################
# Get source Template
$Template = Get-Template -Name 'RHEL6.5'
# Get a host within the development cluster
$VMHost = Get-Cluster -Name 'dev01' |
Get-VMHost -State Connected |
Get-Random
# Deploy our new VM
New-VM -Template $Template -Name 'RHEL_01' -VMHost $VMHost


###################################################################################
# Listing 6.5: Deploying a virtual machine using a template and CustomizationSpecs
###################################################################################
# Get source Template
$Template = Get-Template -Name 'RHEL6.5'
# Get a host within the development cluster
$VMHost = Get-Cluster -Name 'dev01' |
Get-VMHost -State Connected |
Get-Random
# Get the OS CustomizationSpec
$Spec = Get-OSCustomizationSpec -Name 'RHEL6.5'
# Deploy our new VM
New-VM -Template $Template -Name 'RHEL_01' -VMHost $VMHost -OSCustomizationSpec $Spec

###################################################################################
# Listing 6.6: Deploying using a template, CustomizationSpec, and checks for 
# sufficient free space
###################################################################################
# Get source Template
$Template = Get-Template -Name 'REHL6.5'
# Get the OS CustomizationSpec
$OSCustomizationSpec = Get-OSCustomizationSpec -Name 'REHL6.5'
# Get a host within the development cluster
$VMHost = Get-Cluster -Name 'dev01' |
Get-VMHost |
Get-Random
# Determine the capacity requirements of this VM
$CapacityKB = Get-HardDisk -Template $Template | 
Select-Object -ExpandProperty CapacityKB |
Measure-Object -Sum |
Select-Object -ExpandProperty Sum
# Find a datastore with enough room
$Datastore = Get-Datastore -VMHost $VMHost| 
Where-Object -FilterScript {
  ($_.FreeSpaceMB * 1mb) -gt (($CapacityKB * 1kb) * 1.1 )
} |
Select-Object -First 1
# Deploy our Virtual Machine
$VM = New-VM -Name 'REHL_01' `
-Template $Template `
-VMHost $VMHost `
-Datastore $Datastore `
-OSCustomizationSpec $OSCustomizationSpec

###################################################################################
# Listing 6.7: Searching a Datastore for any file matching a pattern
###################################################################################
Function Search-Datastore
{
  <#
      .SYNOPSIS
      Search Datastore for anyfile that matched
      the specified pattern.
      .DESCRIPTION
      Search Datastore for anyfile that matched
      the specified pattern.
      .PARAMETER Pattern
      Pattern To search for
      .PARAMETER Datastore
      Datastore Object to search
      .EXAMPLE
      Search-DataStore -Pattern *.vmx -Datastore (Get-Datastore Datastore1)
      .EXAMPLE
      Get-Datastore | Search-Datastore *.vmdk
  #>
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory = $true
        ,    HelpMessage = 'Pattern to search for'
    )]
    [String]
    $Pattern
    ,
    [Parameter(Mandatory = $true
        ,   ValueFromPipeline = $true
        ,   ValueFromPipeLineByPropertyName = $true
    )]
    [VMware.VimAutomation.ViCore.Impl.V1.DatastoreManagement.DatastoreImpl]
    $Datastore
  )
  Process
  {
    $DSObject = Get-View -VIObject $Datastore -Property Name, Browser, Parent
    $DSBrowser = Get-View -Id $DSObject.Browser -Property Datastore

    $Datacenter = Get-View -Id $DSObject.Parent
    #Walk up the tree until you find the Datacenter
    while($Datacenter.MoRef.Type -ne 'Datacenter')
    {
      $Datacenter = Get-View -VIObject $Datacenter.Parent
    }

    $DSPath  = '[{0}]' -f $DSObject.Name

    $Spec = New-Object -TypeName VMware.Vim.HostDatastoreBrowserSearchSpec
    $Spec.MatchPattern = $Pattern

    $TaskMoRef = $DSBrowser.SearchDatastoreSubFolders_Task($DSPath, $Spec)
    $Task = Get-View -Id $TaskMoRef -Property Info

    while ('running', 'queued' -contains $Task.Info.State)
    {
      Start-Sleep -Milliseconds 500
      $Task.UpdateViewData('Info.State')
    }

    $Task.UpdateViewData('Info.Result')
    $Task.Info.Result |
    Where-Object -FilterScript {
      $_.FolderPath -match '\[(?<DS>[^\]]+)\]\s(?<Folder>.+)'
    } |
    Select-Object -ExpandProperty File |
    Select-Object -Property @{
      Name       = 'Datastore'
      Expression = {
        $DSObject.Name
      }
    }, 
    @{
      Name       = 'Path'
      Expression = {
        '[{0}] {1}{2}' -f $Matches.DS, $Matches.Folder, 
        $_.Path
      }
    }
  }
}



###################################################################################
# Listing 6.8: Re-registering virtual machines
###################################################################################
# Get every VM registered in vCenter
$RegisteredVMs = Get-VM | 
Select-Object -ExpandProperty ExtensionData |
Select-Object -ExpandProperty Summary |
Select-Object -ExpandProperty Config |
Select-Object -ExpandProperty VmPathName

# Now find every .vmx on every datastore.  If it's not part of vCenter
# then add it back in.

Get-Datastore | 
Search-Datastore -Pattern *.vmx|
Where-Object -FilterScript {
  $RegisteredVMs -notcontains $_.path
} |
Where-Object -FilterScript {
  $_.Path -match '(?<Name>\w+).vmx$'
} |
ForEach-Object -Process {
  $VMHost = Get-Datastore -Name $_.Datastore |
  Get-VMHost -State Connected |
  Get-Random
  New-VM -Name $Matches.Name `
  -VMHost $VMHost  `
  -VMFilePath $_.Path
}

###################################################################################
# Listing 6.9: Mass deploying blank virtual machines
###################################################################################
1..1000 |
ForEach-Object -Process {
  New-VM -Name ('RHEL6_{0}' -f $_ ) `
  -VMHost (Get-VMHost | Get-Random) `
  -DiskGB 10 `
  -DiskStorageFormat thin `
  -MemoryGB 1 `
  -GuestId rhel6_64Guest `
  -Portgroup (Get-VDPortgroup -Name VLAN22) `
  -CD
}

###################################################################################
# Listing 6.10: Mass deploying from a template
###################################################################################
$Template = 'WIN8.1'
$Datastore = Get-Datastore -Name 'Datastore1'
$OSCustomizationSpec = Get-OSCustomizationSpec -Name WIN8.1
$VMHost = Get-Cluster -Name PROD_01 |
Get-VMHost |
Get-Random
1..500 |
ForEach-Object -Process {
  New-VM -Name WIN_$_ `
  -Template $Template `
  -Host $VMHost `
  -Datastore $Datastore `
  -OSCustomizationSpec $OSCustomizationSpec
}



###################################################################################
#Listing 6.11: Importing a CSV and creating an object
###################################################################################
$Datastore = Get-Datastore -Name 'Datastore1'
$VMHost = Get-Cluster -Name PROD_01 |
Get-VMHost -State Connected |
Get-Random
Import-Csv -Path .\massVM.CSV |
ForEach-Object -Process {
  New-VM -Name $_.Name `
  -Host $VMHost `
  -Datastore $Datastore `
  -NumCpu $_.CPU `
  -MemoryGB $_.Memory `
  -DiskGB $_.HardDisk `
  -Portgroup (Get-VDPortgroup -Name $_.Nic)
}



###################################################################################
# Listing 6.12: Sychronously deploy four virtual machines
###################################################################################
$Datastores = Get-Cluster -Name 'Cluster1' |
Get-VMHost |
Get-Datastore
$i = 1
While ($i -le 4)
{
  Foreach ($Datastore in $Datastores)
  {
    New-VM -Name ('VM0{0}' -f $i) `
    -Host ($Datastore |
      Get-VMHost -State Connected |
    Get-Random) `
    -Datastore $Datastore
    $i++
  }
}


###################################################################################
# Listing 6.13: Asynchronous deployment of new virtual machines
###################################################################################
$Datastores = Get-Cluster -Name Cluster1 |
Get-VMHost |
Get-Datastore
$i = 1
$Task = While ($i -le 4)
{
  Foreach ($Datastore in $Datastores)
  {
    if ($i -le 4)
    {
      New-VM -Name ('VM0{0}' -f $i) `
      -Host ($Datastore |
        Get-VMHost |
      Get-Random) `
      -Datastore $Datastore `
      -RunAsync
    }
    $i++
  }
}
Wait-Task -Task $Task


###################################################################################
# Listing 6.14: Post build verification script.
###################################################################################
$GuestCreds = Get-Credential
$HostCreds = Get-Credential
$DrvLetter = Invoke-VMScript -VM $VM `
-GuestCredential $GuestCreds `
-HostCredential $HostCreds `
-ScriptType PowerShell `
-ScriptText @'
    Get-Volume | ?{ $_.DriveType -eq 'CD-ROM'}|
        Select-Object -ExpandProperty DriveLetter
'@
if ($DrvLetter.ScriptOutput.Split() -notcontains 'X') 
{
  Write-Warning -Message ('{0} CD-Drive out of compliance' -f $VM)
}


###################################################################################
# Listing 6.15: Windows Silent Install
###################################################################################
$GuestCred = Get-Credential -UserName Administrator
$VM = Get-VM -Name 'Win2k8R2'

# Mount vmware tools media
Mount-Tools -VM $VM 

# Find the drive letter of the mounted media
$DrvLetter = Get-WmiObject -Class 'Win32_CDROMDrive' `
-ComputerName $VM.Name `
-Credential $GuestCred |
Where-Object -FilterScript {
  $_.VolumeName -match 'VMware Tools'
} |
Select-Object -ExpandProperty Drive

#Build our cmd line
$cmd = "$($DrvLetter)\setup.exe /S /v`"/qn REBOOT=ReallySuppress ADDLOCAL=ALL`""
# spawn a new process on the remote VM, and execute setup
$go = Invoke-WmiMethod -Path win32_process `
-Name Create `
-Credential $GuestCred `
-ComputerName $VM.Name `
-ArgumentList $cmd 

if ($go.ReturnValue -ne 0)
{
  Write-Warning -Message ('Installer returned code {0} unmounting media!' -f $go.ReturnValue)
  Dismount-Tools -VM $VM
}
Else
{
  Write-Verbose -Message ('Tool installation successfully triggered on {0} media will be ejected upon completion.' -f $VM.Name)
}



###################################################################################
#Listing 6.16: Linux Silent Install
<###################################################################################
    #!/bin/bash

    echo -n "Executing preflight checks    "
    # make sure we are root
    if [ `id -u` -ne 0 ]; then
    echo "You must be root to install tools!"
    exit 1;
    fi

    # make sure we are in RHEL, CentOS or some reasonable facsimilie
    if [ ! -s /etc/redhat-release ]; then
    echo "You must be using RHEL or CentOS for this script to work!"
    exit 1;
    fi
    echo "[  OK  ]"
    echo -n "Mounting Media                "
    # check for the presence of a directory to mount the CD to
    if [ ! -d /media/cdrom ]; then
    mkdir -p /media/cdrom
    fi

    # mount the cdrom, if necessary...this is rudimentary
    if [ `mount | grep -c iso9660` -eq 0 ]; then
    mount -o loop /dev/cdrom /media/cdrom
    fi

    # make sure the cdrom that is mounted is vmware tools
    MOUNT=`mount | grep iso9660 | awk '{ print $3 }'`
    if [ `ls -l $MOUNT/VMwareTools* | wc -l` -ne 1 ]; then
    # there are no tools here
    echo "No tools found on CD-ROM!"
    exit 1;
    fi
    echo "[  OK  ]"
    echo -n "Installing VMware Tools       "
    # extract the installer to a temporary location
    tar xzf $MOUNT/VMwareTools*.tar.gz -C /var/tmp

    # install the tools, accepting defaults, capture output to a file
    ( /var/tmp/vmware-tools-distrib/vmware-install.pl --default ) > ~/vmware-tools_install.log

    # remove the unpackaging directory
    rm -rf /var/tmp/vmware-tools-distrib
    echo "[  OK  ]"
    echo -n "Restarting Network:"
    # the vmxnet kernel module may need to be loaded/reloaded...
    service network stop
    rmmod pcnet32
    rmmod vmxnet
    modprobe vmxnet
    service network start

    # or just reboot after tools install
    # shutdown -r now


#>##################################################################################
#Listing 6.17: Function Invoke SSH 
###################################################################################
Function Invoke-SSH
{
  <#
      .SYNOPSIS
      Execute a command via SSH on a remote system.
      .DESCRIPTION
      Execute a command via SSH on a remote system.
      .PARAMETER Computer
      Computer to execute script/command against.
      .PARAMETER Credential
      PSCredential to use for remote authentication
      .PARAMETER Username
      Username to use for remote authentication
      .PARAMETER Password
      Password to use for remote authentication
      .PARAMETER FilePath
      Path to a script to execute on the remote machine
      .PARAMETER ScriptText
      ScriptText to execute on the remote system
      .EXAMPLE
      Invoke-SSH -Credential $Creds -Computer 10.1.1.2 -FilePath .\installtools.sh
      .EXAMPLE
      Invoke-SSH -Credential $Creds -Computer $VM.name -ScriptText 'rpm -qa' | Select-String ssh
  #>
  [CmdletBinding(DefaultParameterSetName = 'Command')]
  Param(
    [Parameter(Mandatory = $true
        ,   ValueFromPipeline = $true
        ,   ValueFromPipelineByPropertyName = $true
        ,   HelpMessage = 'ip or hostname of remote computer'
        ,   ParameterSetName = 'Script'
    )]
    [Parameter(Mandatory = $true
        ,   ValueFromPipeline = $true
        ,   ValueFromPipelineByPropertyName = $true
        ,   HelpMessage = 'ip or hostname of remote computer'
        ,   ParameterSetName = 'Command'
    )]
    [string]
    $Computer
    ,
    [Parameter(Mandatory = $true        ,   ValueFromPipeline = $true        ,   ParameterSetName = 'Script'    )]
    [Parameter(Mandatory = $False        ,   ValueFromPipeline = $true        ,   ParameterSetName = 'Command'    )]
    [System.Management.Automation.PSCredential]
    $Credential
    ,
    [Parameter(Mandatory = $true,ParameterSetName = 'Script')]
    [Parameter(ParameterSetName = 'Command')]
    [string]
    $Username
    , 
    [Parameter(Mandatory = $true,ParameterSetName = 'Script')]
    [Parameter(ParameterSetName = 'Command')]
    [AllowEmptyString()]
    [string]
    $Password
    ,
    [Parameter(Mandatory = $true        ,   ParameterSetName = 'Script'        ,   ValueFromPipelineByPropertyName = $true        ,   HelpMessage = 'Path to shell script'    )]
    [ValidateScript({
          Test-Path -Path $_
    })]
    [alias('PSPath','FullName')]
    [string]
    $FilePath
    ,
    [Parameter(Mandatory = $true        ,   ParameterSetName = 'Command'        ,   ValueFromRemainingArguments = $true        ,   HelpMessage = 'Command to execute'
    )]
    [string]
    $ScriptText
  )
  Begin
  {
    $PLink = "${env:ProgramFiles(x86)}\PuTTY\plink.exe", 'plink.exe' |
    Get-Command -ErrorAction SilentlyContinue | 
    Select-Object -First 1 -ExpandProperty Definition
    If (-Not $PLink)
    {
      throw 'PLink could not be found, please install putty!'
      exit 1
    }

    if ($Credential)
    {
      $Cred = $Credential.GetNetworkCredential()
      $Username = $Cred.UserName
      $Password = $Cred.Password
    }
  }
  Process
  {
    switch ($PSCmdlet.ParameterSetName)
    {
      'Script'
      {
        & $PLink -l $Username -pw $Password $Computer -m $FilePath
      }
      'Command'
      {
        & $PLink -l $Username -pw $Password $Computer $ScriptText
      }
    }
  }
}

###################################################################################
# Listing 6.18: Remote install Linux VMware tools
###################################################################################
$VM = Get-VM -Name CentOS5
Mount-Tools -VM $VM
Invoke-SSH -Username root `
-Password 'Pa$$word' `
-Computer 10.10.10.63 `
-FilePath .\InstallTools.sh
Dismount-Tools -VM $VM

###################################################################################
# Listing 6.19: Install VMware tools in mass
###################################################################################
Get-View -ViewType 'VirtualMachine' `
-Property Guest, name `
-Filter @{
  'Guest.GuestFamily' = 'windowsGuest'
  'Guest.ToolsStatus' = 'ToolsOld'
  'Guest.GuestState' = 'running'
} |
Get-VIObjectByVIView |
Update-Tools -NoReboot

###################################################################################
# Listing 6.20: Update VMware tools Linux guest 
###################################################################################
$cmd = Get-Content -Path .\installTools.sh | Out-String
Invoke-VMScript -VM $VM `
-GuestCredential $GuestCreds `
-HostCredential $HostCreds `
-ScriptText $cmd

###################################################################################
# Listing 6.20: Set the tools upgrade policy to upgrade at power cycle
###################################################################################
$Spec = New-Object -TypeName VMware.Vim.VirtualMachineConfigSpec 
$Spec.tools = New-Object -TypeName VMware.Vim.ToolsConfigInfo 
$Spec.tools.toolsUpgradePolicy = 'upgradeAtPowerCycle'
$VM = Get-VM -Name App04
$VM.ExtensionData.ReconfigVM($Spec)
