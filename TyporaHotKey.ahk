; Typora
; 快捷增加字体颜色
; SendInput {Text} 解决中文输入法问题
 
#IfWinActive ahk_exe Typora.exe
{
    ; Ctrl+Alt+o 橙色
    ^!o::addFontColor("orange")

    ; Ctrl+Alt+g 绿色
    ^!g::addFontColor("green ")

    ; Ctrl+Alt+z 橄榄绿色
    ^!z::addFontColor("olive green")

    ; Ctrl+Alt+r 红色
    ^!r::addFontColor("red")
 
    ; Ctrl+Alt+b 浅蓝色
    ^!b::addFontColor("cornflowerblue")

    ; Ctrl+Alt+y 黄色
    ^!y::addFontColor("yellow")

    ; Ctrl+Alt+p 紫色
    ^!p::addFontColor("purple")

    ; Ctrl+Alt+l 淡紫色
    ^!l::addFontColor("lavender")
}
 
; 快捷增加字体颜色
addFontColor(color){
    clipboard := "" ; 清空剪切板
    Send {ctrl down}c{ctrl up} ; 复制
    SendInput {TEXT}<font color='%color%'>
    SendInput {ctrl down}v{ctrl up} ; 粘贴
    If(clipboard = ""){
        SendInput {TEXT}</font> ; Typora 在这不会自动补充
    }else{
        SendInput {TEXT}</ ; Typora中自动补全标签
    }
}