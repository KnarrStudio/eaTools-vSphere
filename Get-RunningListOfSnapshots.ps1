function Get-RunningListOfSnapshots
{
  <#
    .SYNOPSIS
    Short Description
    .DESCRIPTION
    Detailed Description
    .EXAMPLE
    Get-Something
    explains how to use the command
    can be multiple lines
    .EXAMPLE
    Get-Something
    another example
    can have as many examples as you like
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(Position=1)]
    [String]
    $Report = "$env:HOMEDRIVE\temp\snap.txt",
    
    [Parameter(Position=0)]
    [String[]]$Hosts = 'server1'

  )

  Foreach($ViServer in $Hosts){
    Connect-VIServer $ViServer
    Get-VM | Get-Snapshot | Format-List Created,vm | Out-file $Report -Append
    Disconnect-VIServer -Confirm:$False

  }
  
  If (!(Get-Content $Report)) {
    'No snapshots'
  }
  
  Else
  {
    $MailBody= (Get-Content $Report) -join '<BR>'
    $MailSubject= 'VMware Snapshots on all ESX Servers'
    $SmtpClient = New-Object system.net.mail.smtpClient
    $SmtpClient.host = 'smtp.fil_in_yourself.com'
    $MailMessage = New-Object system.net.mail.mailmessage
    $MailMessage.from = 'vmware_snapshots@fill_in_yourself.com'
    $MailMessage.To.add('fill_in@yourself.com')
    $MailMessage.Subject = $MailSubject
    $MailMessage.IsBodyHtml = 1
    $MailMessage.Body = $MailBody
    $SmtpClient.Send($MailMessage)
  }
  Remove-Item $Report
}

