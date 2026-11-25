# 검증 기록

검증일: 2026-11-25. 드라이버: `ZM16B Personal`, packageKey `zm16b.personal.v1`.

## 2026-11-25 프로필 표시 문구 수정

사용자의 실제 업로드에서 HTTP 422 `ConstraintViolationError`가 보고되었습니다. 오류 대상은 `definition.options.value`이며 서버가 허용하는 길이는 0–36자입니다. 기존 `set_up`, `set_down` 표시 문구는 각각 41자였습니다.

두 문구를 각각 `현재 위치를 상한으로 저장`, `현재 위치를 하한으로 저장`으로 줄였습니다. 수정된 두 문구는 각각 14자이고, 전체 9개 옵션의 표시 문구가 모두 36자 이하임을 확인했습니다. 옵션 키·기본값·Lua 명령 매핑은 동일합니다.

이 수정본은 로컬 YAML 검사와 CLI 3.0.1 패키징을 다시 확인했습니다. 수정본의 실제 SmartThings API 업로드 승인과 허브·모터 동작은 아직 확인하지 않았습니다. 아래 기존 SDK 테스트 결과는 서버 측 프로필 제약 검증을 포함하지 않습니다.

## 완료한 검증

| 검증 | 결과 | 확인 범위 |
| --- | --- | --- |
| 순수 Lua 프로토콜·모델 | **40 assertions 통과** | Tuya 바이트 배열, 타입·길이 검사, 여러 DP 파싱, 잘린 패킷 거부, 퍼센트 범위, 식별값, 설정 변경 조건 |
| 공식 SmartThings SDK 통합 | **12 / 12 tests 통과** | 실제 SDK 드라이버 초기화·디스패치, 모의 소켓의 송수신, lifecycle, capability, preferences, Zigbee 보고 |
| SmartThings CLI 3.0.1 | **build-only 성공** | 소스 디렉터리 처리, YAML 파싱, 배포 ZIP 생성, 테스트 코드 제외 |
| 옵션 표시 문구 길이 | **9개 모두 36자 이하** | 사용자 업로드 오류에서 확인된 서버 제약. 최장 문구 30자, 수정된 상·하단 저장 문구 각각 14자 |
| 설치 안내 검토 | **완료** | MSI, OAuth, 허브/기기 ID, 채널 생성·등록, 업로드·설치, 드라이버 전환, logcat의 현재 옵션 |

공식 SDK는 SmartThingsEdgeDrivers 릴리스 **`apiv21_62`**의 `lua_libs-api_v21_62X.tar.gz`를 사용했습니다. 이번 검증 환경의 Lua 런타임은 **5.4**이며 공식 개발환경 문서가 안내하는 Lua 5.3 및 실제 허브 런타임과 동일한 환경은 아닙니다.

## SDK 통합 테스트 12개

1. 열기·멈춤·닫기가 DP1 enum 0·1·2로 전송됩니다.
2. 목표 위치 0·37·100이 반전 없이 DP9 uint32로 전송됩니다.
3. configure·driverSwitched·refresh·재초기화 시 리밋/방향 DP를 쓰지 않습니다.
4. `delete_both` 또는 회전 반전 값이 저장되어 있어도 시작·이름 변경·재시작 시 실행하지 않습니다.
5. 명시적인 설정 변경만 DP16을 한 번 전송하고 중복 이벤트를 무시합니다.
6. 이전 설정값이 없는 최초 프로필 상태에서는 리밋 명령을 실행하지 않습니다.
7. 프로필 교체 이벤트 자체로는 리밋 명령을 실행하지 않습니다.
8. 회전 방향은 DP11로 전송하며 DP9의 백분율을 임의로 반전하지 않습니다.
9. 여러 DP가 들어 있는 보고에서 실제 위치 DP8과 배터리 DP13을 표시합니다.
10. 잘린 패킷·잘못된 타입·범위 초과 값·목표 위치 echo가 실제 위치를 바꾸지 않습니다.
11. 두 번째 지원 제조사 식별값에서도 SDK 메시지가 전송됩니다.
12. 다른 제조사의 TS0601에는 명령을 보내지 않습니다.

송신 fixture는 드라이버의 인코더 호출 결과를 기대값으로 재사용하지 않고 독립적인 바이트 상수로 비교했습니다. Tuya 트랜잭션 번호는 **little endian**, DP 길이와 uint32 값은 **big endian**입니다.

## 재현 방법

Lua 5.3 이상에서 프로젝트 루트를 작업 디렉터리로 하고:

```bash
lua tests/test_protocol.lua .
```

공식 SDK를 별도로 내려받고 프로젝트의 `src` 디렉터리에서:

```bash
ST_LUA_LIBS=/실제/경로/lua_libs-api_v21 lua test/test_sdk_review.lua
```

SmartThings CLI 패키징만 확인하려면 프로젝트 루트에서:

```powershell
smartthings edge:drivers:package --build-only ..\zm16b-built.zip .
```

SDK와 Lua는 위 개발자 테스트를 재현할 때만 필요합니다. `README.ko.md`의 Windows MSI 설치·드라이버 배포 흐름에는 별도 설치하지 않습니다.

## 아직 확인하지 못한 범위

실제 사용자 계정·허브·모터에 접근하지 않았습니다. 다음 사항은 실물에서 확인해야 합니다.

- 사용자의 정확한 Zigbee Manufacturer/Model과 펌웨어의 DP 매핑 일치.
- 실제 무선 명령 수신과 모터의 열기·정지·닫기 및 회전 방향.
- 상단·하단 리밋의 실제 저장과 이후 주행에서의 정지 위치.
- 리모컨으로 조작한 뒤의 위치 보고, 배터리 보고 시점.
- SmartThings 앱의 실제 설정 화면과 갱신 동작.

`command SENT` 로그는 SDK로 송신했다는 의미입니다. 모터의 물리적 리밋 저장 완료를 입증하는 응답으로 취급하지 않습니다. 최종 설치 후에는 모터가 보이는 곳에서 정지 기능부터 확인하고 상·하단을 설정하세요.

채널 생성, 계정 업로드, 허브 설치 및 드라이버 전환은 사용자 실행 단계로 남겨 두었습니다. 소프트웨어 검증 성공을 실물 동작 보증으로 표현하지 않습니다.

## 기준 자료

- [공식 SmartThings Edge SDK apiv21_62](https://github.com/SmartThingsCommunity/SmartThingsEdgeDrivers/releases/tag/apiv21_62)
- [공식 SDK 개발환경 안내](https://developer.smartthings.com/docs/devices/hub-connected/set-up-dev-env)
- [공식 SmartThings CLI 3.0.1](https://github.com/SmartThingsCommunity/smartthings-cli/releases/tag/%40smartthings/cli%403.0.1)
- [ZM16B 장치 매핑](https://github.com/Koenkk/zigbee-herdsman-converters/blob/master/src/devices/zemismart.ts)
- [Tuya 값 변환기](https://github.com/Koenkk/zigbee-herdsman-converters/blob/master/src/lib/tuya.ts)
- [Tuya ZCL 구조](https://github.com/Koenkk/zigbee-herdsman/blob/master/src/zspec/zcl/definition/cluster.ts)
