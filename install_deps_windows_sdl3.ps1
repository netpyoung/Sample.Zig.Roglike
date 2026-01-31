$SDL3_version="3.3.6"
$SDL3_ttf_version="3.2.2"

$u1="https://github.com/libsdl-org/SDL/releases/download/prerelease-${SDL3_version}/SDL3-devel-${SDL3_version}-VC.zip"
$u2="https://github.com/libsdl-org/SDL_ttf/releases/download/release-${SDL3_ttf_version}/SDL3_ttf-devel-${SDL3_ttf_version}-VC.zip"

$t="$PWD\SDL3_temp"
$d="$PWD\SDL3_lib"

New-Item -ItemType Directory -Force -Path $t | Out-Null
New-Item -ItemType Directory -Force -Path $d | Out-Null


function Download-And-Extract {
    param (
        [string]$Url,
        [string]$TempName,
        [string]$DestName
    )

    $zipPath = "$t\$TempName.zip"
    $extractPath = "$t\$TempName"

    # 다운로드
    Invoke-WebRequest -Uri $Url -OutFile $zipPath

    # 압축 해제
    Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

    # 압축 풀면 생기는 "한 단계 안쪽" 폴더 찾기
    $innerDir = Get-ChildItem $extractPath | Where-Object { $_.PSIsContainer } | Select-Object -First 1

    if (-not $innerDir) {
        throw "내부 폴더를 찾을 수 없습니다: $TempName"
    }

    $destPath = "$d\$DestName"

    # 기존 폴더 제거
    if (Test-Path $destPath) {
        Remove-Item -Recurse -Force $destPath
    }

    # 폴더 이동 + 이름 변경
    Move-Item $innerDir.FullName $destPath
}

Download-And-Extract -Url $u1 -TempName "SDL3" -DestName "SDL3"
Download-And-Extract -Url $u2 -TempName "SDL3_ttf" -DestName "SDL3_ttf"
# t1에 zip을 다운로드. 다운로드된걸 압축풀고 한단계 들어가서 폴더체로 $d에 SDL3폴더로 이름 바꿔서 이동
# t2에 zip을 다운로드. 다운로드된걸 압축풀고 한단계 들어가서 폴더체로 $d에 SDL3_ttf폴더로 이름 바꿔서 이동