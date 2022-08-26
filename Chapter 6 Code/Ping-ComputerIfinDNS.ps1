param(
$serverName = 'buffalo'
)

$ipaddress = @{
  IPAddress = $false
}

try
{
  $ipaddress = Resolve-DnsName -Name $serverName -Type A -ErrorAction Stop
}
catch
{
  $ipaddress.IPAddress = $false
}

if($ipaddress.IPAddress)
{
  $pingresult = Test-Connection -ComputerName $ipaddress.IPAddress -Count 1 -Quiet
  if($pingresult -eq $true)
  {
    Write-Host -Object $true
  }
}
else
{
  Write-Warning -Message $false
}

