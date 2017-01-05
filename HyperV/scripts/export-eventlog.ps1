# Loading config and utils

$scriptLocation = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)
 . "$scriptLocation\config.ps1"
 . "$scriptLocation\utils.ps1"

dumpeventlog $openstackLogs
exporthtmleventlog $openstackLogs

