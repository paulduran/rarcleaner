param(
    [string]$kind = "", 
    [string]$label = "",  
    [string]$dir = "",
    [string]$file = "",
    [string]$name = "",
	[string]$cleanupScript = ".\clean.ps1"
    )
Add-Type -AssemblyName System.Web

#
# This script is designed as a uTorrent post-process script. it copies all of the files to a separate area (so uTorrent can continue to seed)
# and then unrars/cleans up samples/screens etc and removes the rar files
# If the file is a tv show, we notify sickBeard to do its post-processing and move it into its tv show folder
# To call from utorrent
# powershell.exe -noprofile "& 'c:\path\postProcess.ps1' -kind '%K' -label '%L' -file '%F' -dir '%D' -name '%N'" -cleanupScript 'c:\path\to\clean.ps1'



$base = "D:\new"

function CreateDirectoryIfNeeded ( [string] $Directory ){
<#
    .Synopsis
        checks if a folder exists, if it does not it is created
    .Example
        CreateDirectoryIfNeeded "c:\foobar"
        Creates folder foobar in c:\
    .Link
        http://heazlewood.blogspot.com
#>
    if ((test-path -LiteralPath $Directory) -ne $True)
    {
        New-Item $Directory -type directory | out-null
         
        if ((test-path -LiteralPath $Directory) -ne $True)
        {
            Write-error ("Directory creation failed")
        }
        else
        {
            Write-verbose ("Creation of directory succeeded")
        }
    }
    else
    {
        Write-verbose ("Creation of directory not needed")
    }
}

function notify-sickbeard
{
	param(
		[string]$path
	)
	$encoded =  [System.Web.HttpUtility]::UrlEncode($path)
	$page = (New-Object System.Net.WebClient).DownloadString("http://localhost:8081/home/postprocess/processEpisode?dir=$encoded")
}

if($kind -eq "single")
{
	if($label -eq "") 
	{
		if($file -like "*tv*" )
		{
			$label = "tv shows"
		} 
	}
	$target = "$base\$label"
	CreateDirectoryIfNeeded $target
	$source = join-path $dir $file
	Copy-Item -LiteralPath $source -Destination $target  -Force
}
else 
{
	if($label -eq "")
	{
		if($dir -like "*tv*")
		{
			$label = "tv shows"
		}
	}
	$target = "$base\$label"
	$source = $dir
	CreateDirectoryIfNeeded $target
	Copy-Item -LiteralPath $source -Destination $target -recurse -Force	
	& "$cleanupScript" -single $target\$name
}

if($label -eq "tv shows")
{
	notify-sickbeard $target
}
