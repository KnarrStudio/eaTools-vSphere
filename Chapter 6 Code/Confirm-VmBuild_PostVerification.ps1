[CmdletBinding(SupportsShouldProcess)]
param(
  [Parameter(Mandatory)]
  [String]$VM
)
$GuestCreds = Get-Credential


<#bookmark Administrator Name #>
Write-Verbose -Message 'Testing Administrator Name Change'
$SplatLocalAdmin = @{
  VM              = $VM
  GuestCredential = $GuestCreds
  ScriptType      = powershell.exe
  ScriptText      = @'
    (Get-LocalGroupMember -Member erika -Group Administrators).Name.split('\') -contains 'erika'
'@
}

$LocalAdmin = Invoke-VMScript @SplatLocalAdmin
Write-Warning -Message ('Administrator Renamed: {0}' -f $LocalAdmin)

<#bookmark CD Drive Letter #>
Write-Verbose -Message 'Testing CD Drive Letter'
$SplatDriveLttr = @{
  VM              = $VM
  GuestCredential = $GuestCreds
  ScriptType      = powershell.exe
  ScriptText      = @'
      $Drive = Get-CimInstance -ClassName Win32_Volume -Filter "DriveType = '5'"
      if($Drive.DriveLetter -notMatch 'X')
      {
        $Drive | Set-CimInstance -Property @{
          DriveLetter = 'X:'
        }
      }
      Get-Volume | ?{ $_.DriveType -eq 'CD-ROM'}|
        Select-Object -ExpandProperty DriveLetter
'@
}

$DrvLetter = Invoke-VMScript @SplatDriveLttr
if($($DrvLetter.ScriptOutput.Split()) -notcontains 'X') 
{
  Write-Warning -Message ('{0} CD-Drive out of compliance' -f $VM)
}

<#bookmark NIC Information #>

$SplatNICInfo = @{
  VM              = $VM
  GuestCredential = $GuestCreds
  ScriptType      = powershell.exe
  ScriptText      = @'
      $NICs = Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object {
        ($_.IPEnabled) -and ($_.DNSDomain)
      }
      foreach ($Network in $NICs) 
      {
        $IPAddress  = $Network.IpAddress[0]
        $SubnetMask  = $Network.IPSubnet[0]
        $DefaultGateway = $Network.DefaultIPGateway
        $DNSServers  = $Network.DNSServerSearchOrder
        $MACAddress  = $Network.MACAddress
        $DHCPServer  = $Network.DHCPServer

        $OutputObj  = New-Object -TypeName PSObject
        $OutputObj | Add-Member -MemberType NoteProperty -Name IPAddress -Value $IPAddress
        $OutputObj | Add-Member -MemberType NoteProperty -Name SubnetMask -Value $SubnetMask
        $OutputObj | Add-Member -MemberType NoteProperty -Name Gateway -Value $DefaultGateway
        $OutputObj | Add-Member -MemberType NoteProperty -Name DNSServers -Value $DNSServers
        $OutputObj | Add-Member -MemberType NoteProperty -Name MACAddress -Value $MACAddress
        $OutputObj | Add-Member -MemberType NoteProperty -Name DHCPServer -Value $DHCPServer
        $OutputObj
      }

      $OutputObj 
'@
}
$NICinformation = Invoke-VMScript @SplatNICInfo 

Write-Warning -Message $NICinformation





