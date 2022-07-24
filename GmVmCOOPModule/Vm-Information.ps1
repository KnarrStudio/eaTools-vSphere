# This is a modified Get-DJInfo Function.  It does not have any functional value.

function get-OurVMInfo
{
  [CmdletBinding(SupportsShouldProcess,ConfirmImpact = 'Low')]

  param(
    [Parameter(Mandatory,HelpMessage = 'Add one or more computer names',
        ValueFromPipeline,
    ValueFromPipelineByPropertyName)]
    [Alias('hostname')]
    [ValidateLength(3, 14)]
    [ValidateCount(1, 10)]
    [string[]]$computername,

    [switch]$namelog
  )

  BEGIN {

    if($namelog)
    {
      Write-Verbose -Message 'Finding: Log file' 
      $i = 0
      Do 
      { 
        $logFile = ('names-{0}.txt' -f $i)
        $i ++
      } While (Test-Path -Path $logFile)
      Write-Verbose -Message ('Log file: {0}' -f $logFile)
    }
    else
    {
      Write-Verbose -Message 'Logging: OFF'
    }
  }

  PROCESS {
    Write-Debug -Message 'Starting: Process Block'
      
    Write-Debug -Message 'Starting: For Loop'

    foreach ($computer in $computername)
    {
      if($PSCmdlet.ShouldProcess($computer))
      {
        Write-Verbose -Message ('Connecting to: {0}' -f $computer)
        Write-Debug -Message ('All computers: {0}' -f $computername)

        if ($namelog)
        {
          $computer | Out-File -FilePath $logFile -Append
        }

        try
        {
          $continue = $true
          Get-WmiObject -ErrorAction 'Stop' -Class win32_bios | Select-Object -Property serialnumber
        }
        catch
        {
          $continue = $false
          $computer | Out-File -FilePath .\ErrorLog.txt
        }
      }
    }
  }
  END {

  }
}



get-OurVMInfo -computername localhost, test2 -Verbose -Debug

