$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
$Name = "DisableWindowsConsumerFeatures"
$value = "1"
if(!(Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force | Out-Null
    New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
}else {
    New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType DWORD -Force | Out-Null
}
