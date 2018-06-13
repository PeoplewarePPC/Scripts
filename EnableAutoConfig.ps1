#region logging
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
			'error'{"ERROR,$objDateTime,$Message" >> $strPPC_LOG_PAD
            throw [System.IO.FileNotFoundException] "$Message"}
			'ok'{"OK,$objDateTime,$Message" >> $strPPC_LOG_PAD}
		}
}
 

#Aanmaken van map C:\PPC_Logs (als deze nog niet bestaat) waar de logs worden weggeschreven.
$strPPC_LOG = "C:\Program Files\PeopleWare\PPC_Logs"
$strPPC_LOG_PAD = $strPPC_LOG + "\" + "EnableAutoConfig.txt" 


if(-not(Test-Path $strPPC_LOG)) {
    New-Item $strPPC_LOG -ItemType container
}
#endregion

$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive"
$Name = "SilentAccountConfig"
$value = "1"

Try {
    if(!(Test-Path $registryPath)) {
        New-Item -Path $registryPath -Force | Out-Null
        New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
    } else {
        New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
    }

    Log -Message "EnableAutoConfig.ps1 (eerste deel) is succesvol uitgevoerd. In HKLM:\SOFTWARE\Policies\Microsoft\OneDrive staat nu een key SilentAccountConfig met de waarde 1" -Type "ok"


} Catch {
    $strFoutmelding = $error[0]
    Log -Message "EnableAutoConfig.ps1 (eerste deel) is NIET succesvol uitgevoerd. In HKLM:\SOFTWARE\Policies\Microsoft\OneDrive staat nu GEEN key SilentAccountConfig met de waarde 1. Foutmelding: $strFoutmelding" -Type "error"
}



$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive"
$Name = "FilesOnDemandEnabled"
$value = "1"

Try {
    if(!(Test-Path $registryPath)) {
        New-Item -Path $registryPath -Force | Out-Null
        New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
    } else {
        New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
    }

    Log -Message "EnableAutoConfig.ps1 (tweede deel) is succesvol uitgevoerd. In HKLM:\SOFTWARE\Policies\Microsoft\OneDrive staat nu een key FilesOnDemandEnabled met de waarde 1" -Type "ok"

} Catch {
    $strFoutmelding = $error[0]
    Log -Message "EnableAutoConfig.ps1 (tweede deel) is NIET succesvol uitgevoerd. In HKLM:\SOFTWARE\Policies\Microsoft\OneDrive staat nu GEEN key FilesOnDemandEnabled met de waarde 1. Foutmelding: $strFoutmelding" -Type "error"
}
