Function Update-Plugins($jenkinsServer, $sshKeyPath) {
    $pluginsToBeUpdated = @()
    Invoke-RestMethod -Method Get -Uri $($jenkinsServer + "/jnlpJars/jenkins-cli.jar") -OutFile "jenkins-cli.jar" -ContentType "application/octet-stream"

    Write-Output "`nHere are the currently installed plugins`n"

    java -jar jenkins-cli.jar -s $jenkinsServer -i $sshKeyPath list-plugins | Tee-Object -Variable output 

    foreach ($item in $output) {
        If ($item -match '\([\d\.\-brc]+\)') {
            $name = Select-String -InputObject $item -Pattern '[\w-]+' | %{$_.Matches} | %{$_.Value}
            $pluginsToBeUpdated += $name
            Write-Output "Going to update $name"
        }
    }

    Write-Output "`r`n"

    $pluginsToBeUpdated | ForEach {
        java -jar jenkins-cli.jar -s $jenkinsServer -i $sshKeyPath install-plugin $($_) -deploy | Write-Output
    }

    If ($pluginsToBeUpdated.Count -eq 0){
        Write-Output "There were no updates for any of the Jenkins plugins!"
    } Else {
        Write-Output "Restarting Jenkins"
        java -jar jenkins-cli.jar -s $jenkinsServer restart | Write-Output
    }
}

$results = Update-Plugins -jenkinsServer "http://jenkins:1234" -sshKeyPath "C:\Users\jenkins\.ssh\id_rsa"

$to = "recipient@mail.com"
$subject = "Updating Jenkins results for $(Get-Date -Format g)"
$body = "<pre>" + ($results -join "`r`n" ) + "</pre>"
Send-MailMessage -To $to -From "jenkins_noreply@mail.com" -Body $body -Subject $subject -SmtpServer "smtp.com" -BodyAsHtml
