Function Migrate-Plugins($sourceJenkinsServer, $sourceUsername, $sourceAPIToken, $destJenkinsServer, $destUsername, $destAPIToken) {
    $sourceAuthValue = $($sourceUsername + ":" + $sourceAPIToken)
    $destAuthValue = $($destUsername + ":" + $destAPIToken)
    $pluginsToBeUpdated = @()
    Invoke-RestMethod -Method Get -Uri $($sourceJenkinsServer + "/jnlpJars/jenkins-cli.jar") -OutFile "jenkins-cli.jar" -ContentType "application/octet-stream"

    Write-Output "`nHere are the currently installed plugins`n"

    cmd /c java -jar jenkins-cli.jar -s $sourceJenkinsServer -auth $sourceAuthValue list-plugins '2>&1' | Tee-Object -Variable output 

    foreach ($item in $output) {
        If ($item -match '\([\d\.\-brc]+\)') {
            $name = Select-String -InputObject $item -Pattern '[\w-]+' | %{$_.Matches} | %{$_.Value}
            $pluginsToBeUpdated += $name
        }
    }

    Write-Output "`r`n"

    $pluginsToBeUpdated | ForEach-Object {
        cmd /c java -jar jenkins-cli.jar -s $destJenkinsServer -auth $destAuthValue install-plugin $($_) -deploy '2>&1' | Write-Output
    }

    If ($pluginsToBeUpdated.Count -eq 0){
        Write-Output "There were no plugins to be migrated!"
    } Else {
        Write-Output "Restarting Jenkins"
        cmd /c java -jar jenkins-cli.jar -s $destJenkinsServer restart '2>&1' | Write-Output
    }
}

$results = Migrate-Plugins -sourceJenkinsServer "http://jenkins:1234" -sourceUsername "user" -sourceAPIToken "123456789" -destJenkinsServer "http://jenkins:1234" -destUsername "user" -destAPIToken "123456789"

$to = "recipient@mail.com"
$subject = "Updating Jenkins results for $(Get-Date -Format g)"
$body = "<pre>" + ($results -join "`r`n" ) + "</pre>"
Send-MailMessage -To $to -From "jenkins_noreply@mail.com" -Body $body -Subject $subject -SmtpServer "smtp.com" -BodyAsHtml
