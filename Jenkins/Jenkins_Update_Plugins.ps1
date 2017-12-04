Function Update-Plugins($jenkinsServer, $username, $authToken) {
    $authValue = $($username+":"+$authtoken)
    $pluginsToBeUpdated = @()
    Invoke-RestMethod -Method Get -Uri $($jenkinsServer + "/jnlpJars/jenkins-cli.jar") -OutFile "jenkins-cli.jar" -ContentType "application/octet-stream"

    Write-Output "`nHere are the currently installed plugins`n"

    cmd /c java -jar jenkins-cli.jar -s $jenkinsServer -auth $authValue list-plugins '2>&1' | Tee-Object -Variable output 

    foreach ($item in $output) {
        If ($item -match '\([\d\.\-brc]+\)') {
            $name = Select-String -InputObject $item -Pattern '[\w-]+' | %{$_.Matches} | %{$_.Value}
            $pluginsToBeUpdated += $name
            Write-Output "Going to update $name"
        }
    }

    Write-Output "`r`n"

    $pluginsToBeUpdated | ForEach {
        cmd /c java -jar jenkins-cli.jar -s $jenkinsServer -auth $authValue install-plugin $($_) -deploy '2>&1' | Write-Output
    }

    If ($pluginsToBeUpdated.Count -eq 0){
        Write-Output "There were no updates for any of the Jenkins plugins!"
    } Else {
        Write-Output "Restarting Jenkins"
        cmd /c java -jar jenkins-cli.jar -s $jenkinsServer -auth $authValue restart '2>&1' | Write-Output
    }
}

$results = Update-Plugins -jenkinsServer "http://jenkins:1234" -username "user" -authToken "123456789"

$to = "recipient@mail.com"
$subject = "Updating Jenkins results for $(Get-Date -Format g)"
$body = "<pre>" + ($results -join "`r`n" ) + "</pre>"
Send-MailMessage -To $to -From "jenkins_noreply@mail.com" -Body $body -Subject $subject -SmtpServer "smtp.com" -BodyAsHtml
