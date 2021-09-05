function Get-ListOfRunningSnapshots {
  <#
    .SYNOPSIS
    Sends a list of running snapshots to email. 

    .DESCRIPTION
    This sends a list of running snapshots to email.  
    You will have to edit the script to ensure that the SMTP server (or Relay) has been idenitified and that the 'From' address has been filled in.  
    The other options such as the "To" address and the subject can be change using parameters.

    .PARAMETER Vcenter
    Mandatory: True
    Default: N/A
    Custom Setting: At run time
    Vcenter to connect to and interrogate

    .PARAMETER SortOn
    Mandatory: False
    Default: VM
    Custom Setting: At run time
    How the list is sorted.  By default it is the name of the server (VM)

    .PARAMETER MailTo
    Mandatory: False
    Default: Requires code editing
    The user or group that the email will be sent to.

    .PARAMETER MailSubject
    Mandatory: False
    Default: // 05-Sep-2021 / VMware Snapshots / All ESX Servers
    Can be changed at runtime
    Provides a subject for your email report

    .EXAMPLE
    Get-RunningListOfSnapshots -Vcenter VcenterServerName
    The simplest form of this will provide a list of snapshots sorted by the server they are attached in an email with a date stamped subject line.
    
    .EXAMPLE
    Get-RunningListOfSnapshots -Vcenter VcenterServerName -SortOn NameOfSnapshot -MailTo GroupToReceiveReport@mail.mail -MailSubject "List of Snapshots'  
    Once the settings have been baked into the code then you might want to use this for a second run or send to someone else.

    .NOTES
    This will not run without initial editing and setting some variables.
    Must be changed:
        $MailServer = 'Enter your mail server here' #### 
        $MailFrom = 'Enter Sending Address here' ###
    Should be changed:
        [string]$MailTo = 'Name or group email address'
  #>

  [CmdletBinding()]
  param(
    [Parameter(Mandatory, HelpMessage = 'Vcenter to connect to and interrogate', Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    $Vcenter,
    [Parameter(Mandatory = $false, HelpMessage = 'Sort Snapshot list by', Position = 1)]
    [ValidateSet('VM', 'Name', 'Created', 'SizeMB')] 
    [string]$SortOn = 'VM',
    [Parameter(Mandatory = $false, HelpMessage = 'Who to send report to')]
    [string]$MailTo = 'Name or group email address',
    [Parameter(Mandatory = $false, HelpMessage = 'Email Subject Line')]
    [string]$MailSubject = $('// {0} / VMware Snapshots / All ESX Servers' -f $(Get-Date -Format 'dd-MMM-yyyy'))
  )

  #### Edit Here
  $MailServer = 'Enter your mail server here' #### 
  $MailFrom = 'Enter Sending Address here' ###
  #### Edit Here

  # Set Variables
  $Report = New-TemporaryFile
    
  #Connect VCenter
  Connect-VIServer $Vcenter

  # Get all of the Snapshot
  $AllSnapshots = get-vm |
  get-snapshot  |
  Sort-Object -Property $SortOn | 
  Select-Object -Property VM, Name, Created, SizeMB, id
  
  # Disconnect from vCenter
  Disconnect-VIServer -Confirm:$False

  # Display a list of Snapshots
  Write-Verbose -Message ('Total Snapshots: {0}' -f $AllSnapshots.count)
  $AllSnapshots | Out-Host

  # Create Report
  $AllSnapshots | Out-file $Report -Append

  If (!(Get-Content $Report)) {
    'No snapshots' | Out-File $Report
  }
  
  $MailBody = (Get-Content $Report) -join '<BR>'
  $SmtpClient = New-Object system.net.mail.smtpClient
  $SmtpClient.host = $MailServer
  $MailMessage = New-Object system.net.mail.mailmessage
  $MailMessage.from = $MailFrom
  $MailMessage.To.add($MailTo)
  $MailMessage.Subject = $MailSubject
  $MailMessage.IsBodyHtml = 1
  $MailMessage.Body = $MailBody
  $SmtpClient.Send($MailMessage)
  
  Remove-Item $Report
}

