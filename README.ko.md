# macOS 설치 및 운영 안내

[프로젝트 소개와 리밋 사용법](README.md)

문서 수정일: 2026-11-26. 명령은 macOS 기본 터미널(zsh)과 SmartThings CLI **3.0.1**에서 확인한 형식을 기준으로 합니다.

아래 명령은 `config.yml`과 `src/`가 있는 프로젝트 최상위 폴더에서 실행합니다. 변수는 현재 터미널 창에만 유지됩니다. 새 창에서는 ID를 다시 입력하거나 대화형 배포를 사용하세요.

## 이미 설치한 드라이버 업데이트

소스를 수정한 뒤 같은 프로젝트 폴더에서 실행합니다.

```zsh
smartthings edge:drivers:package . --install
```

채널과 허브를 묻는 경우 사용 중인 채널(예: **Taeu Channel**)과 허브를 선택합니다. CLI에 기본 채널·허브를 저장해 두었다면 그 값을 사용할 수 있으므로 출력에 표시되는 배포 대상도 확인하세요. 기존 모터가 같은 드라이버를 사용하는 경우에는 채널 생성·허브 등록·드라이버 전환을 반복할 필요가 없습니다.

`config.yml`의 **`packageKey: "zm16b.personal.v1"`을 유지**하고 같은 삼성 계정으로 배포합니다. GitHub 태그와 이 패키지 식별자는 별도로 관리하세요.

## 최초 설치

### 1. CLI 준비

M 시리즈 맥에서 Homebrew가 설치되어 있다면:

```zsh
brew install smartthingscommunity/smartthings/smartthings
smartthings --version
```

Homebrew가 없다면 [공식 Homebrew 설치 안내](https://brew.sh/)를 따르고, 설치 출력의 `Next steps`에 있는 PATH 설정 명령까지 실행합니다. 현재 SmartThings의 공식 Homebrew 패키지는 arm64용입니다.

Intel 맥에서는 Node.js **24.22.1 이상** 환경에서 npm으로 설치합니다.

```zsh
npm install --global @smartthings/cli
smartthings --version
```

정확한 설치 조건은 [공식 CLI README](https://github.com/SmartThingsCommunity/smartthings-cli)와 [Homebrew formula](https://github.com/SmartThingsCommunity/homebrew-smartthings/blob/main/Formula/smartthings.rb)를 참고하세요.

배포에 사용하는 CLI 명령을 확인합니다.

```zsh
smartthings edge:drivers:package --help
```

Lua와 SDK 설치는 개발자 테스트를 로컬에서 실행할 때만 필요합니다.

### 2. 소스 위치 확인

GitHub에서 받은 저장소 또는 ZIP을 푼 폴더 중 `config.yml`이 있는 위치로 이동합니다.

```zsh
ls config.yml src/init.lua
```

두 파일의 경로가 출력되면 그 폴더에서 계속 진행하세요. 소스 ZIP은 압축을 푼 다음 패키징합니다. `--upload`는 CLI가 만든 배포 ZIP을 업로드할 때 사용하는 옵션입니다.

### 3. 로그인과 허브·모터 ID 확인

```zsh
smartthings devices --type HUB
```

최초 실행 시 열리는 브라우저에서 SmartThings 앱과 같은 삼성 계정으로 로그인하고 CLI 접근을 승인합니다. 이 흐름에서는 별도 PAT 발급이 필요하지 않습니다.

모터가 연결된 허브의 UUID를 입력합니다.

```zsh
read "hubId?허브 deviceId 붙여넣기: "
smartthings devices --type ZIGBEE
read "deviceId?ZM16B 모터 deviceId 붙여넣기: "
smartthings devices "$deviceId" --json
```

`zigbee.hubId`가 선택한 허브와 같은지 확인합니다. 되돌릴 때 사용할 기존 `zigbee.driverId`도 기록합니다.

```zsh
read "oldDriverId?기존 zigbee.driverId 붙여넣기: "
```

모터가 SmartThings 허브에 Zigbee로 직접 연결되어 있어야 합니다. 지원 식별값은 [README의 지원 기기](README.md)에 있습니다. Manufacturer Code와 Model은 [SmartThings 고급 페이지](https://my.smartthings.com/advanced/devices)의 기기 상세에서 확인합니다.

### 4. 채널 선택 또는 생성

#### 기존 채널 사용

이미 **Taeu Channel** 같은 개인 채널이 있다면 ID만 확인합니다.

```zsh
smartthings edge:channels
read "channelId?사용할 기존 channelId 붙여넣기: "
```

#### 새 채널이 필요한 경우

터미널에서 대화형 생성 명령을 실행합니다.

```zsh
smartthings edge:channels:create
```

질문에 다음처럼 답합니다.

| 질문 | 개인 개발용 입력 예시 |
| --- | --- |
| Channel name | Taeu Channel |
| Channel description | Personal SmartThings Edge drivers |
| Channel terms of service URL | https://example.com |

`type: DRIVER`는 CLI가 설정합니다. 예시 약관 URL은 공식 문서의 개인 개발용 예제이며, 채널을 공개 배포할 때는 실제 안내 URL을 사용하세요.

생성 결과의 ID를 입력합니다.

```zsh
read "channelId?생성된 channelId 붙여넣기: "
```

### 5. 허브를 채널에 등록

해당 허브를 이 채널에 처음 등록할 때 실행합니다.

```zsh
smartthings edge:channels:enroll "$hubId" --channel "$channelId"
```

### 6. 드라이버 업로드와 설치

프로젝트 최상위 폴더에서 실행합니다.

```zsh
smartthings edge:drivers:package . --channel "$channelId" --hub "$hubId"
read "driverId?출력된 ZM16B Personal의 driverId 붙여넣기: "
smartthings edge:drivers:installed --hub "$hubId"
```

CLI 3.0.1에서 **`--hub`와 `--install`은 함께 사용하지 않습니다.** ID를 직접 지정할 때는 위 형식을, 목록에서 선택할 때는 `smartthings edge:drivers:package . --install`을 사용합니다.

### 7. 기존 모터에 드라이버 적용

처음 이 드라이버로 전환할 때 실행합니다.

```zsh
smartthings edge:drivers:switch "$deviceId" --hub "$hubId" --driver "$driverId"
smartthings devices "$deviceId" --json
```

`zigbee.driverId`가 새 드라이버 ID와 같아졌는지 확인하고, 앱의 모터 화면을 닫았다가 다시 엽니다. 이후 설정의 **Limit Action**으로 리밋을 맞춥니다. 절차는 [README의 리밋 설정](README.md)에 있습니다.

## 로그 확인

맥과 허브가 서로 접근 가능한 같은 홈 네트워크에 있을 때:

```zsh
smartthings edge:drivers:logcat "$driverId"
```

허브 IP를 직접 지정하려면 실제 로컬 IP로 바꾸어 실행합니다.

```zsh
smartthings edge:drivers:logcat "$driverId" --hub-address "192.168.0.10"
```

첫 연결 시 인증서 확인이 나오면 대상 주소를 확인합니다. 종료는 `Control+C`입니다. `command SENT`는 송신 기록이며, 리밋 저장 결과는 모터의 실제 정지 위치로 확인합니다.

## 기존 드라이버로 되돌리기

기록해 둔 기존 드라이버가 허브에 설치되어 있는 경우:

```zsh
smartthings edge:drivers:switch "$deviceId" --hub "$hubId" --driver "$oldDriverId"
```

드라이버 전환만으로 모터의 물리적 리밋이 이전 값으로 돌아가지는 않습니다.

## 문제 해결

### `expected a document, but the input is empty`

CLI 3.0.1에서 관리 설정 파일이 주석만 포함할 때 이 오류를 재현했습니다. `--verbose-directory-logging`으로 확인한 파일이 아래 경로라면, 공백·주석만 있는 경우에 한해 백업 후 유효한 빈 YAML 객체로 바꿀 수 있습니다.

```zsh
stManagedConfig="$HOME/Library/Application Support/@smartthings/cli/config-managed.yaml"
stManagedBackup="${stManagedConfig}.bak.$(date +%Y%m%d-%H%M%S)"

if [ ! -f "$stManagedConfig" ]; then
  printf '관리 설정 파일을 찾지 못했습니다.\n'
elif awk '$0 !~ /^[[:space:]]*($|#)/ { exit 1 }' "$stManagedConfig"; then
  if cp -p "$stManagedConfig" "$stManagedBackup" &&
     printf '{}\n' > "$stManagedConfig"; then
    printf '수정 완료. 백업: %s\n' "$stManagedBackup"
  fi
else
  printf '실제 설정이 있거나 파일을 읽지 못해 수정하지 않았습니다.\n'
fi
```

채널 입력 파일 등 다른 YAML 문서에서도 발생할 수 있는 오류입니다. 위 검사에서 실제 설정이 발견되면 원인을 추가 확인합니다.

### HTTP 422: `definition.options.value` 길이 오류

옵션 표시 문구는 36자 이하여야 합니다. 최초 배포본의 상·하단 저장 문구는 각각 41자였고, 현재 소스에서는 다음처럼 각각 14자로 수정했습니다.

```yaml
set_up: "현재 위치를 상한으로 저장"
set_down: "현재 위치를 하한으로 저장"
```

### 기타 확인

| 증상 | 확인할 내용 |
| --- | --- |
| `smartthings` 명령을 찾지 못함 | CLI 설치와 Homebrew PATH 설정 |
| `config.yml`을 못 찾음 | 프로젝트 최상위 폴더에서 명령을 실행했는지 |
| `invalid profile file` | `profiles/` 안에 `.bak` 등 YAML 이외 파일이 있는지. 백업은 다른 폴더로 이동 |
| `install and hub are mutually exclusive` | `--hub`를 지정할 때 `--install`을 함께 사용했는지 |
| 채널·허브 ID가 비어 있음 | 새 터미널에서 변수를 다시 입력하거나 대화형 배포 사용 |
| 드라이버가 전환 목록에 없음 | 같은 허브에 설치했는지, 기기 식별값이 맞는지 |
| 같은 리밋 작업이 다시 실행되지 않음 | Idle로 저장한 뒤 원하는 작업을 다시 선택했는지 |
| 로그 연결 실패 | 허브의 로컬 IP 및 맥에서 해당 IP로 접근 가능한지 |

## 참고 자료

- [공식 CLI 설치·인증](https://developer.smartthings.com/docs/sdks/cli)
- [공식 Driver Channels](https://developer.smartthings.com/docs/devices/hub-connected/driver-channels/)
- [검증 기준 CLI 3.0.1 package 명령](https://github.com/SmartThingsCommunity/smartthings-cli/blob/27581cf266026bfa3dc6fd2ef0fe40db13a875e8/src/commands/edge/drivers/package.ts)
- [CLI 설정 파일 처리](https://github.com/SmartThingsCommunity/smartthings-cli/blob/27581cf266026bfa3dc6fd2ef0fe40db13a875e8/src/lib/cli-config.ts)
