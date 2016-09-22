# Setup output directory
If (!(Test-Path "bin")) {
    New-Item "bin" -ItemType Directory > $null
}
Push-Location "bin"

if (Test-Path "windows") {
    Remove-Item -Recurse -Force "windows"
}

New-Item "windows" -ItemType Directory > $null
Set-Location "windows"

New-Item "x64" -ItemType Directory > $null
Push-Location x64
New-Item "Debug" -ItemType Directory > $null
New-Item "Release" -ItemType Directory > $null
New-Item "Deploy" -ItemType Directory > $null
Pop-Location

New-Item "x86" -ItemType Directory > $null
Push-Location x86
New-Item "Debug" -ItemType Directory > $null
New-Item "Release" -ItemType Directory > $null
New-Item "Deploy" -ItemType Directory > $null
Pop-Location

Pop-Location

##################################
# Ensure rust is updated

$Rust64 = "nightly-x86_64-pc-windows-msvc"
$Rust32 = "nightly-i686-pc-windows-msvc"

rustup update $Rust64
rustup update $Rust32

##################################
# Build path-helper library

# x64
Push-Location src\native-helpers\path-helper
rustup run $Rust64 cargo clean
rustup run $Rust64 cargo build --release
Pop-Location
Copy-Item -Path ".\src\native-helpers\path-helper\target\release\path_helper.*" -Destination "bin\windows\x64\Debug"
Copy-Item -Path ".\src\native-helpers\path-helper\target\release\path_helper.*" -Destination "bin\windows\x64\Release"
Copy-Item -Path ".\src\native-helpers\path-helper\target\release\path_helper.*" -Destination "bin\windows\x64\Deploy"

# x86
Push-Location src\native-helpers\path-helper
rustup run $Rust32 cargo clean
rustup run $Rust32 cargo build --release
Pop-Location
Copy-Item -Path ".\src\native-helpers\path-helper\target\release\path_helper.*" -Destination "bin\windows\x86\Debug"
Copy-Item -Path ".\src\native-helpers\path-helper\target\release\path_helper.*" -Destination "bin\windows\x86\Release"
Copy-Item -Path ".\src\native-helpers\path-helper\target\release\path_helper.*" -Destination "bin\windows\x86\Deploy"
