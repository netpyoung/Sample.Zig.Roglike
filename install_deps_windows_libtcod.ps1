$tcod_version="2.2.2"

$u="https://github.com/libtcod/libtcod/releases/download/${tcod_version}/libtcod-${tcod_version}-x64-windows.zip"
$z="$PWD\libtcod.zip"
$d="$PWD\libtcod"

Invoke-WebRequest $u -OutFile $z
Expand-Archive $z -DestinationPath $d -Force


$inner=Get-ChildItem $d | Where-Object {$_.PSIsContainer} | Select-Object -First 1
Get-ChildItem $inner.FullName | Move-Item -Destination $d -Force
Remove-Item $inner.FullName -Recurse -Force
Remove-Item $z