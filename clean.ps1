param(
    [switch]$single
)

$Script:unrarName =  "c:\Program Files\WinRAR\UnRAR.exe"
  
# borrowed from http://heazlewood.blogspot.com.au/2011/07/first-blog.html  
function Extract-RAR-File([string]$FilePath, [bool]$RemoveSuccessful= $false) 
{
<#
    .Synopsis
        unrars a file or set of rar files, then if "all ok"
        removes or moves the original rar files
    .Example
        Extract-RAR-File c:\temp\foo.rar
        Extracts contents of foo.rar to folder temp.
    .Parameter FilePath
        path to rar file 
    .Parameter RemoveSuccessful
        remove rar files if successful otherwise move files to folder called trash
    .Link
        http://heazlewood.blogspot.com
#>
     
    # Verify we can access UNRAR.EXE .
 if ([string]::IsNullOrEmpty($unrarName) -or (Test-Path -LiteralPath $unrarName) -ne $true)
 {
     Write-Error "Unrar.exe path does not exist '$unrarPath'."
        return
    }
  
    [string]$unrarPath = $(Get-Command $unrarName).Definition
    if ( $unrarPath.Length -eq 0 )
    {
        Write-Error "Unable to access unrar.exe at location '$unrarPath'."
        return
    }
 
   # Verify we can access to the compressed file.
 if ([string]::IsNullOrEmpty($FilePath) -or (Test-Path -LiteralPath $FilePath) -ne $true)
 {
     Write-Error "Compressed file does not exist '$FilePath'."
        return
    }
  
    [System.IO.FileInfo]$Compressedfile = get-item -LiteralPath $FilePath
     
    #set Destination to basepath folder
    #$fileBaseName = [System.IO.Path]::GetFileNameWithoutExtension($Compressedfile.Name)
    #$DestinationFolder = join-path -path $Compressedfile.DirectoryName -childpath $fileBaseName
     
    #set Destination to parent folder
    $DestinationFolder = $Compressedfile.DirectoryName 
 
    # If the extract directory does not exist, create it.
    CreateDirectoryIfNeeded ( $DestinationFolder ) | out-null
 
    Write-Output "Extracting files into $DestinationFolder"
    &$unrarPath x -y  $FilePath $DestinationFolder | tee-object -variable unrarOutput 
     
    #display the output of the rar process as verbose
    $unrarOutput | ForEach-Object {Write-Verbose $_ }
      
    if ( $LASTEXITCODE -ne 0 )
    { 
        # There was a problem extracting. 
        #Display error
        Write-Error "Error extracting the .RAR file"
    }
    else
    {
        # check $unrarOutput to remove files
        Write-Verbose "Checking output for OK tag" 
        if ($unrarOutput -match "^All OK$" -ne $null) {
            if ($RemoveSuccessful) {
                Write-Verbose "Removing files" 
                 
                #remove rar files listed in output.
                $unrarOutput -match "(?<=Extracting\sfrom\s)(?<rarfile>.*)$" | 
                ForEach-Object {$_ -replace 'Extracting from ', ''} | 
                ForEach-Object { get-item -LiteralPath $_ } | 
                remove-item
                 
            } else {
                Write-Verbose "Moving files to trash folder`n$trashPath" 
         
                [string]$trashPath = join-path -path $DestinationFolder "Trash"
                 
                #create trash folder to move rars to
                CreateDirectoryIfNeeded ($trashPath)
                 
                #move rar files listed in output.
                $unrarOutput -match "(?<=Extracting\sfrom\s)(?<rarfile>.*)$" | 
                ForEach-Object {$_ -replace 'Extracting from ', ''} | 
                foreach-object { get-item -LiteralPath $_ } | 
                move-item -destination $trashPath
            }
        }
    }
}
 
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
        New-Item $Directory-type -type directory | out-null
         
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

function extract-rars {
	param([string]$path)
	
	get-childitem -path $path\*part001.rar | foreach-object {Extract-RAR-File $_.fullname -RemoveSuccessful $true}
	get-childitem -path $path\*part01.rar | foreach-object {Extract-RAR-File $_.fullname -RemoveSuccessful $true}
	get-childitem -path $path\*.rar | foreach-object {Extract-RAR-File $_.fullname -RemoveSuccessful $true}
	get-childitem -path $path\*.sfv | foreach-object { remove-item $_.fullname }
	if(test-path $path\subs)
	{
		get-childitem -path $path\subs\*.rar | foreach-object { Extract-RAR-File $_.fullname -RemoveSuccessful $true }	
		get-childitem -path $path\subs\*.sfv | foreach-object { remove-item $_.fullname }
	}
}
function clean-folder {
	param([string]$path)

	if(test-path $path\sample)
	{
		remove-item $path\sample -recurse
	}
	if(test-path $path\screens)
	{
		remove-item $path\screens -recurse
	}
	if(test-path $path\proof)
	{
		remove-item $path\proof -recurse
	}

	get-childitem -path $path\* -include *sample.avi,*sample.mp4,*sample.mkv | foreach-object { remove-item $_.fullname }
	
	extract-rars $path
	if(test-path $path\CD1) {
		extract-rars $path\CD1
	}
	if(test-path $path\CD2) {
		extract-rars $path\CD2
	}
	if(test-path $path\CD3) {
		extract-rars $path\CD3
	}	
}

if($args.count -lt 1) {
	Write-error "Require at least 1 path to clean up"
} else {
    if($single) {
        clean-folder $args[0]
    }
    else {
    	foreach($i in $args) {
    		get-childitem -path $i | where {$_.PSIsContainer} | foreach($_) { clean-folder $_.fullname }		
    	}
    }
}

