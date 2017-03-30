Set-ExecutionPolicy Bypass -Force

choco feature enable -n allowGlobalConfirmation

# Don't forget to ensure ExecutionPolicy above
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

choco install javaruntime

choco install git