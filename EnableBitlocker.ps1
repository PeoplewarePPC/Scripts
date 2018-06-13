Function Log {
	<#
	.EXAMPLE
		Log -Message "Test server" -Type "i"
#>
	 [CmdletBinding()]
        param(
            [parameter(Mandatory=$true,ValueFromPipeline=$true,HelpMessage='Line to write to log file.')][string]$Message,
            [Parameter(Mandatory=$true,ValueFromPipeline=$true,HelpMessage='<e/i/s Trace Type ERROR, INFO or SUCCESS')][ValidateSet('error','ok')][string]$Type
        )
		
        $objDateTime = Get-Date -Format ("yyyy-MM-dd hh:mm:ss")
		switch ($Type) {
			'error'{"ERROR,$objDateTime,$Message" >> $strPPC_LOG_Bitlocker}
			'ok'{"OK,$objDateTime,$Message" >> $strPPC_LOG_Bitlocker}
		}
}

$strPPC_LOG = "C:\Program Files\PeopleWare\PPC_Logs"
$strPPC_LOG_Bitlocker = $strPPC_LOG + "\" + "Bitlocker.txt"

if(-not(Test-Path $strPPC_LOG)) {
    New-Item $strPPC_LOG -ItemType container
}

Try {
    Enable-BitLocker -MountPoint "C:" -EncryptionMethod XtsAes128 -ErrorAction stop -UsedSpaceOnly -RecoveryPasswordProtector -SkipHardwareTest
    $BLV = Get-BitLockerVolume -MountPoint “C:” | select *
    $BackupPassword = $BLV.KeyProtector |Where {$_.KeyProtectorType -eq ‘RecoveryPassword’}
    BackupToAAD-BitLockerKeyProtector -MountPoint “C:” -KeyProtectorId $BackupPassword.KeyProtectorId -ErrorAction SilentlyContinue
    
    start-sleep -s 5
    
    $bitlockerStatus = Get-BitLockerVolume $env:SystemDrive -ErrorAction Stop | select -ExpandProperty VolumeStatus
    if ($bitlockerStatus -eq "EncryptionInProgress" -or $bitlockerStatus -eq "FullyEncrypted") { 
        Log -Message "Bitlocker geconfigureerd. Op de achtergrond zal hij gaan encrypten." -Type "ok"
    } else {
        Log -Message "Hij heeft een andere status dan fullyencrypted of encryptioninprogress. Status: $bitlockerStatus." -Type "ok"
    }

} Catch {
    $strFoutmelding = $error[0]
    Log -Message "Fout bij automatisch configureren van Bitlocker. Foutmelding: $strFoutmelding" -Type "error" 
}
