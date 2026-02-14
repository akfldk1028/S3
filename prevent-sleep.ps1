# AC 전원 시 절전 해제
powercfg /change standby-timeout-ac 0
powercfg /change monitor-timeout-ac 30
Write-Host "AC: 절전 OFF, 모니터 30분후 꺼짐"

# 덮개 닫아도 아무 동작 안 함 (AC 전원)
# LIDACTION: 0=아무것도 안 함, 1=절전, 2=최대절전, 3=종료
powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 0
powercfg /setactive SCHEME_CURRENT
Write-Host "덮개 닫아도 절전 안 됨 (AC 전원)"

# 배터리도 설정 (선택)
powercfg /change standby-timeout-dc 0
powercfg /setdcvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 0
powercfg /setactive SCHEME_CURRENT
Write-Host "배터리에서도 절전 해제 + 덮개 닫아도 유지"

Write-Host "`n현재 설정 확인:"
powercfg /query SCHEME_CURRENT SUB_BUTTONS LIDACTION
