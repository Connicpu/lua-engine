function Invoke-BatchFile
{
     param([string]$Path, [string]$Parameters)

     $tempFile = [IO.Path]::GetTempFileName()

     ## Store the output of cmd.exe.  We also ask cmd.exe to output
     ## the environment table after the batch file completes
     $command = " `"$Path`" $Parameters && set > `"$tempFile`" "
     cmd.exe /c $command

     ## Go through the environment variables in the temp file.
     ## For each of them, set the variable in our local environment.
     Get-Content $tempFile | Foreach-Object {
             if ($_ -match "^(.*?)=(.*)$")
             {
                     Set-Content "env:\$($matches[1])" $matches[2]  
             }
     }

     Remove-Item $tempFile
}

function Enable-VSPrompt($version = 14, $arch = "x64")
{
    Invoke-BatchFile "C:\Program Files (x86)\Microsoft Visual Studio $version.0\VC\vcvarsall.bat" $arch
}

Enable-VSPrompt
fxc.exe @args
