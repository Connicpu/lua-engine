function New-DirZip( $zipfilename, $sourcedir )
{
   Add-Type -Assembly System.IO.Compression.FileSystem
   $compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
   [System.IO.Compression.ZipFile]::CreateFromDirectory($sourcedir,
        $zipfilename, $compressionLevel, $false)
}

msbuild lua-engine.sln /property:Configuration=Release
.\bin\windows\x64\Release\launcher.exe --build-bytecode
#.\bin\windows\x64\Release\launcher.exe --build-assets
msbuild lua-engine.sln /property:Configuration=Deploy

# Remove extra items that aren't needed later on
rm bin\windows\x64\Deploy\*.lib
rm bin\windows\x64\Deploy\*.exp
rm bin\windows\x64\Deploy\luajit.exe

if (TestPath "gamename.txt") {
    rename "bin\windows\x64\Deploy\launcher.exe" "bin\windows\x64\Deploy\$(cat gamename.txt).exe"
}

New-DirZip "$(pwd)\deploy.zip" "$(pwd)\bin\windows\x64\Deploy"
