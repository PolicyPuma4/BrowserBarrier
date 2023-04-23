#Requires AutoHotkey v2.0

#NoTrayIcon

;@Ahk2Exe-SetMainIcon emoji_u1f500.ico

;@Ahk2Exe-Obey U_bits, = %A_PtrSize% * 8
;@Ahk2Exe-Obey U_type, = "%A_IsUnicode%" ? "Unicode" : "ANSI"
;@Ahk2Exe-ExeName %A_ScriptName~\.[^\.]+$%_%U_type%_%U_bits%

if (not A_IsCompiled) {
    TraySetIcon("emoji_u1f500.ico")
}

url := A_Args.Length ? A_Args[1] : ""
if (not url) {
    ExitApp()
}

scheme := ""
for character in StrSplit(url) {
    if character == ":" {
        break
    }

    scheme := scheme character
}

; myGui := Gui("+ToolWindow +AlwaysOnTop", "")
myGui := Gui("+AlwaysOnTop", "")

associations := []
for hive in ["HKEY_CURRENT_USER", "HKEY_LOCAL_MACHINE"] {
    Loop Reg hive "\SOFTWARE\Clients\StartMenuInternet", "K" {
        applicationName := RegRead(A_LoopRegKey "\" A_LoopRegName "\Capabilities", "ApplicationName", "")
        if (not applicationName) {
            continue
        }

        applicationIcon := Trim(RegRead(A_LoopRegKey "\" A_LoopRegName "\Capabilities", "ApplicationIcon", ""), "`"")
        if (not applicationIcon) {
            continue
        }

        iconPath := RTrim(SubStr(applicationIcon, 1, (InStr(applicationIcon, ",") or StrLen(applicationIcon))), ",")
        iconNumber := LTrim(SubStr(applicationIcon, InStr(applicationIcon, ",")), ",") or 0

        Loop Reg A_LoopRegKey "\" A_LoopRegName "\Capabilities\URLAssociations", "V" {
            if (not A_LoopRegName = scheme) {
                continue
            }

            association := RegRead(A_LoopRegKey, A_LoopRegName, "")
            if (not association) {
                continue
            }

            command := RegRead(hive "\SOFTWARE\Classes\" association "\shell\open\command",, "")
            if (not command) {
                continue
            }

            myPicture := myGui.Add("Picture", "ym Icon" iconNumber, iconPath)
            myPicture.DefineProp("command", {
                Value: command
            })
            myPicture.OnEvent("Click", myPictureClick)
        }
    }
}

myPictureClick(control, *) {
    Run(StrReplace(StrReplace(control.command, "`"%1`"", "%1"), "%1", url))
    ExitApp()
}

myGui.Show()
