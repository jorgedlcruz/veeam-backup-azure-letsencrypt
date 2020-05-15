#!/bin/bash
##      .SYNOPSIS
##      SSL Certificate for Veeam Backup for Azure with Let's Encrypt
## 
##      .DESCRIPTION
##      This Script will take the most recent Let's Encrypt certificate and push it to the Veeam Backup for Azure Web Server 
##      The Script, and the whole Let's Encrypt it is provided as it is, and bear in mind you can not open support Tickets regarding this project. It is a Community Project
##	
##      .Notes
##      NAME:  veeam_azure_ssl.sh
##      ORIGINAL NAME: veeam_azure_ssl.sh
##      LASTEDIT: 15/05/2020
##      VERSION: 1.0
##      KEYWORDS: Veeam, SSL, Let's Encrypt
   
##      .Link
##      https://jorgedelacruz.es/
##      https://jorgedelacruz.uk/

# Configurations
##
# Endpoint URL for login action
veeamDomain="YOURVEEAMAZUREAPPLIANCEDOMAIN"
veeamSSLPassword="YOURVEEAMSSLPASSWORD" #Introduce a password that will be use to merge the SSL into a .PFX
veeamOutputPFXPath="/tmp/bundle.pfx"
veeamOutputPFX64Path="/tmp/bundle64.pfx"
veeamUsername="YOURVEEAMBACKUPUSER"
veeamPassword="YOURVEEAMBACKUPPASS"
veeamBackupAzureServer="https://YOURVEEAMBACKUPIP"
veeamBackupAzurePort="443" #Default Port

veeamBearer=$(curl -X POST --header "Content-Type: application/x-www-form-urlencoded" --header "Accept: application/json" -d "Username=$veeamUsername&Password=$veeamPassword&refresh_token=&grant_type=Password&mfa_token=&mfa_code=" "$veeamBackupAzureServer:$veeamBackupAzurePort/api/oauth2/token" -k --silent | jq -r '.access_token')

##
# Veeam Backup for Azure SSL PFX Certificate Creation. This part will combine Let's Encrypt SSL files into a valid .pfx for Microsoft for Azure
##
openssl pkcs12 -export -out $veeamOutputPFXPath -inkey /root/.acme.sh/$veeamDomain/$veeamDomain.key -in /root/.acme.sh/$veeamDomain/fullchain.cer -password pass:$veeamSSLPassword
openssl base64 -in $veeamOutputPFXPath -out $veeamOutputPFX64Path

##
# Veeam Backup for Azure SSL Certificate Push. This part will retrieve last Let's Encrypt Certificate and push it
##
veeamVBAURL="$veeamBackupAzureServer:$veeamBackupAzurePort/api/v1/settings/certificates/webServer"
veeamOutputPFX=`cat $veeamOutputPFX64Path`

curl -X PUT "$veeamVBAURL" -H "accept: */*" -H "Authorization: Bearer $veeamBearer" -H "Content-Type: application/json" -d "{\"webServerCertificatePfxBase64\":\"data:application/x-pkcs12;base64,$veeamOutputPFX\",\"webServerCertificatePfxPassword\":\"$veeamSSLPassword\"}" -k

echo "Your Veeam Backup for Azure SSL Certificate has been replaced with a valid Let's Encrypt one. Go to https://$veeamDomain"