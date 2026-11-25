# ZM16B Personal

Zemismart ZM16B Zigbee 블라인드 모터를 위한 개인용 SmartThings Edge 드라이버입니다.
열기·닫기·정지, 열림 비율, 배터리, 회전 방향 및 상·하단 리밋 설정을 지원합니다.

- 드라이버 이름: **ZM16B Personal**
- 패키지 식별자: **`zm16b.personal.v1`**
- 명령 예시: **macOS 기본 터미널(zsh), SmartThings CLI 3.0.1** 기준
- 처음 설치할 때: [macOS 설치 및 운영 안내](README.ko.md)
- 검증 범위와 제한: [VALIDATION.md](VALIDATION.md)

## 지원 기기

SmartThings 호환 허브에 Zigbee로 직접 연결한 아래 기기를 대상으로 합니다.

| Model | Manufacturer |
| --- | --- |
| `TS0601` | `_TZE284_3mzb0sdz` |
| `TS0601` | `_TZE2841000000_3mzb0sdz` |

[SmartThings 고급 페이지](https://my.smartthings.com/advanced/devices)에서 기기의 Manufacturer Code와 Model을 확인할 수 있습니다. 이 드라이버는 위 식별값에 맞는 장치에만 명령을 보냅니다.

## 기존 채널로 빠르게 업데이트

이 README와 `config.yml`이 있는 프로젝트 최상위 폴더에서 실행합니다.

```zsh
smartthings edge:drivers:package . --install
```

채널과 허브를 묻는 경우 사용 중인 채널(예: **Taeu Channel**)과 허브를 선택합니다. CLI에 기본 채널·허브를 저장해 두었다면 그 값을 사용할 수 있으므로 출력에 표시되는 배포 대상도 확인하세요. 소스를 패키징하여 업로드하고, 해당 채널에 새 버전을 배정한 뒤 허브에 설치합니다.

ID를 직접 지정하려면 다음 순서로 실행합니다.

```zsh
smartthings edge:channels
read "channelId?사용할 channelId 붙여넣기: "
smartthings devices --type HUB
read "hubId?설치할 허브 deviceId 붙여넣기: "
smartthings edge:drivers:package . --channel "$channelId" --hub "$hubId"
smartthings edge:drivers:installed --hub "$hubId"
```

이미 모터가 사용하는 동일 드라이버를 업데이트할 때는 기존 채널과 기기 연결을 그대로 사용합니다. 최초 설치에 필요한 채널 생성·허브 등록·드라이버 전환은 [상세 설치 안내](README.ko.md)에 있습니다.

**`config.yml`의 `packageKey: "zm16b.personal.v1"`은 계속 유지하세요.** Git 태그를 `v0.2.0` 등으로 올려도 패키지 식별자는 바꾸지 않습니다. GitHub에 push한 소스는 위 CLI 배포 명령으로 SmartThings에 반영합니다.

## 리밋 설정

상한은 원단을 위로 말아 올려 창이 드러나는 위치, 하한은 원단을 아래로 내려 창을 가리는 위치입니다. 리밋 저장 명령은 **현재 멈춘 위치**를 끝점으로 지정합니다.

1. SmartThings 앱의 모터 상세 → **⋮ → 설정 → Limit Action**에서 **Idle / 실행 안 함**을 선택해 저장합니다.
2. 열기와 정지로 원하는 상단 위치에 맞춥니다.
3. **현재 위치를 상한으로 저장**을 선택해 저장한 뒤 **Idle / 실행 안 함**으로 바꾸어 저장합니다.
4. 닫기와 정지로 원하는 하단 위치에 맞춥니다.
5. **현재 위치를 하한으로 저장**을 선택해 저장한 뒤 **Idle / 실행 안 함**으로 바꾸어 저장합니다.
6. 열기와 닫기를 실행해 지정한 위치에서 멈추는지 확인합니다.

| Limit Action 선택지 | 동작 |
| --- | --- |
| Idle / 실행 안 함 | 명령을 보내지 않음 |
| 현재 위치를 상한으로 저장 | 상단 리밋 저장 |
| 현재 위치를 하한으로 저장 | 하단 리밋 저장 |
| Delete upper limit / 상한 삭제 | 상단 리밋 삭제 |
| Delete lower limit / 하한 삭제 | 하단 리밋 삭제 |
| Delete both limits / 상하한 모두 삭제 | 상·하단 리밋 삭제 |

같은 작업을 다시 실행하려면 **Idle 저장 → 원하는 작업 저장** 순서로 진행합니다. 설정에 마지막 선택이 표시되어 있어도 재시작이나 드라이버 업데이트 시 저장 명령을 반복하지 않습니다.

열기·닫기 방향이 반대라면 리밋을 맞추기 전에 **Motor Direction**에서 방향을 조정하세요. **Keep current / 현재 방향 유지**를 저장한 뒤 **Set normal / 정방향 설정** 또는 **Set reversed / 역방향 설정**을 저장합니다. 회전 방향과 리밋은 각각 따로 설정합니다.

위치는 **100%가 열림, 0%가 닫힘**입니다. 설정의 마지막 선택 및 로그의 `command SENT`는 요청 기록이므로, 실제 리밋 저장 여부는 모터 움직임으로 확인해야 합니다.

## 소스 구성

| 경로 | 내용 |
| --- | --- |
| `config.yml` | 드라이버 이름, 패키지 식별자, Zigbee 권한 |
| `fingerprints.yml` | 지원 기기 식별값 |
| `profiles/zm16b-personal.yml` | SmartThings 앱 기능과 설정 항목 |
| `src/init.lua` | 드라이버와 핸들러 등록 |
| `src/handlers.lua` | 제어 명령, 설정 변경, 수신 처리 |
| `src/model.lua` | ZM16B 명령값과 모델 규칙 |
| `src/protocol.lua` | Tuya 메시지 인코딩·파싱 |
| `tests/test_protocol.lua` | 프로토콜·모델 검사 |
| `src/test/test_sdk_review.lua` | 공식 SDK 통합 검사 |
| `licenses/` | 참고·재사용한 소스의 라이선스 고지 |

## 개발 시 유지할 규칙

- 업데이트에는 같은 삼성 계정, 같은 `packageKey`, 기존 채널을 사용합니다.
- 프로필의 `definition.options` 표시 문구는 **36자 이하**로 작성합니다.
- 설정의 기본값은 실제 옵션 키와 일치시킵니다. 현재 기본값은 `idle`, `keep`입니다.
- `profiles/`에는 `.yml` 또는 `.yaml` 파일만 둡니다. 백업 파일은 프로젝트 최상위 등 다른 위치에 둡니다.
- 리밋 저장·삭제는 명시적인 설정 변경으로만 실행되도록 유지합니다.

로컬 패키지만 만들려면 프로젝트 최상위 폴더에서 실행합니다.

```zsh
smartthings edge:drivers:package --build-only ../zm16b-package.zip .
```

이 명령은 소스 구조와 YAML을 확인해 배포 ZIP을 생성합니다. 서버의 모든 프로필 제약이나 실제 모터 동작을 검증하지는 않습니다.

Lua 개발 환경에서 기존 프로토콜 검사를 실행하려면:

```zsh
lua tests/test_protocol.lua .
```

공식 SDK 검사 방법과 실행 환경은 [검증 기록](VALIDATION.md)을 참고하세요.

## 프로토콜 참고

| DP | 타입 | 기능 |
| --- | --- | --- |
| 1 | enum | 0=열기, 1=정지, 2=닫기 |
| 8 | uint32 | 실제 위치 보고, 0–100 |
| 9 | uint32 | 목표 위치 설정, 0–100 |
| 11 | enum | 0=정방향, 1=역방향 |
| 13 | uint32 | 배터리 보고, 0–100 |
| 16 | enum | 0=상한 저장, 1=하한 저장, 2=상한 삭제, 3=하한 삭제, 4=모두 삭제 |

Tuya 클러스터는 `0xEF00`, 쓰기 명령은 `0x00`, 조회 명령은 `0x03`입니다. 트랜잭션 번호는 16비트 little endian, DP 길이와 uint32 값은 big endian입니다. DP8과 DP13의 실제 보고를 상태에 반영합니다.

## 검증 및 라이선스

프로토콜·모델 검사 40개 항목과 공식 SmartThings SDK 모의 통합 테스트 12개를 통과했습니다. 구현·검증 환경에서 실물 허브와 모터에 연결해 시험하지는 않았습니다. 상세 범위는 [VALIDATION.md](VALIDATION.md)에 기록되어 있습니다.

이 프로젝트는 개인용 드라이버이며 Zemismart 또는 SmartThings의 공식 제품 드라이버가 아닙니다. 라이선스와 출처는 [LICENSE](LICENSE), [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)를 참고하세요.

## 참고 자료

- [SmartThings CLI](https://developer.smartthings.com/docs/sdks/cli)
- [SmartThings Driver Channels](https://developer.smartthings.com/docs/devices/hub-connected/driver-channels/)
- [SmartThings Device Preferences](https://developer.smartthings.com/docs/devices/preferences)
- [Zigbee2MQTT ZM16B](https://www.zigbee2mqtt.io/devices/ZM16B.html)
- [ZM16B 장치 정의](https://github.com/Koenkk/zigbee-herdsman-converters/blob/master/src/devices/zemismart.ts)
- [Tuya 변환기](https://github.com/Koenkk/zigbee-herdsman-converters/blob/master/src/lib/tuya.ts)
