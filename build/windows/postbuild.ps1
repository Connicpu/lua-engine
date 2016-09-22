Copy-Item -Path ".\vendor\bin\windows_x64\*" -Destination ".\bin\windows\x64\Debug"
Copy-Item -Path ".\vendor\bin\windows_x64\*" -Destination ".\bin\windows\x64\Release"
Copy-Item -Path ".\vendor\bin\windows_x64\*" -Destination ".\bin\windows\x64\Deploy"

Copy-Item -Path ".\vendor\bin\windows_x86\*" -Destination ".\bin\windows\x86\Debug"
Copy-Item -Path ".\vendor\bin\windows_x86\*" -Destination ".\bin\windows\x86\Release"
Copy-Item -Path ".\vendor\bin\windows_x86\*" -Destination ".\bin\windows\x86\Deploy"
