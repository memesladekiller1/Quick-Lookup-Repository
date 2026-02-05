#Requires AutoHotkey v2.0

; USER CUSTOMIZATION SETTINGS

; 1. PATH SETTINGS
Global REPOSITORY_FOLDER := EnvGet("USERPROFILE") . "\Downloads\DataBase"

; 2. SEARCH MARKERS
Global START_TAG := "--start"
Global END_TAG   := "--end"

; 3. VISUAL SETTINGS (Stealth Bar)
Global STEALTH_BG_COLOR := "202020"    ; Dark Gray hex code
Global STEALTH_TEXT_COLOR := "cWhite"  ; White text
Global STEALTH_FONT_SIZE := "s12"      ; Font size
Global STEALTH_FONT_FACE := "Segoe UI SemiLight"

; 4. TIMING
Global TOOLTIP_DURATION := -1000       ; How long "Data Retrieved" stays (ms)


; MODE 1: VISUAL REPOSITORY (Shift + L) - Shows a scrollable window
+l:: {
    IB := InputBox("Query: keywords /FILENAME", "Quick-Lookup Repository", "w400 h120")
    if (IB.Result = "Cancel" || IB.Value = "")
        return

    result := PerformSearch(IB.Value)
    
    if (result != "") {
        ResultGui := Gui("+AlwaysOnTop", "Repository Result")
        ResultGui.SetFont("s11", "Segoe UI")
        ResultGui.Add("Edit", "ReadOnly vScroll r15 w550", result)
        ResultGui.Add("Button", "Default w100", "Close").OnEvent("Click", (*) => ResultGui.Destroy())
        ResultGui.Show()
    }
}

; MODE 2: STEALTH RETRIEVAL (Ctrl + P) - Copies directly to clipboard
^p:: {
    ; Create borderless, sleek retrieval bar at mouse position
    StealthGui := Gui("-Caption +AlwaysOnTop +ToolWindow")
    StealthGui.BackColor := STEALTH_BG_COLOR 
    StealthGui.SetFont(STEALTH_FONT_SIZE . " " . STEALTH_TEXT_COLOR, STEALTH_FONT_FACE)
    
    EditField := StealthGui.Add("Edit", "w350 r1 -E0x200 Background333333") 
    Btn := StealthGui.Add("Button", "Default w0 h0", "OK")
    Btn.OnEvent("Click", ProcessInput)

    MouseGetPos(&mX, &mY)
    StealthGui.Show("x" . mX . " y" . mY)

    ProcessInput(*) {
        userInput := EditField.Value
        StealthGui.Destroy()
        
        if (userInput != "") {
            result := PerformSearch(userInput)
            if (result != "") {
                A_Clipboard := result
                ToolTip("Data Retrieved")
                SetTimer () => ToolTip(), TOOLTIP_DURATION
            }
        }
    }
    StealthGui.OnEvent("Escape", (*) => StealthGui.Destroy())
}

; --- CORE SEARCH ENGINE ---
PerformSearch(inputVal) {
    if !InStr(inputVal, "/")
        return ""

    parts := StrSplit(inputVal, "/")
    searchQuery := Trim(parts[1])
    fileName := Trim(parts[2])
    
    filePath := REPOSITORY_FOLDER . "\" . fileName . ".txt"

    if !FileExist(filePath)
        return ""

    fileContent := FileRead(filePath)
    searchWords := StrSplit(searchQuery, " ")
    
    bestMatch := ""
    highestScore := 0
    currentBlock := ""
    isInsideBlock := false

    Loop parse, fileContent, "`n", "`r" {
        line := A_LoopField
        if InStr(line, START_TAG) {
            isInsideBlock := true
            currentBlock := ""
            continue
        }
        if InStr(line, END_TAG) {
            isInsideBlock := false
            currentScore := 0
            for word in searchWords {
                if (word != "" && InStr(currentBlock, word))
                    currentScore++
            }
            if (currentScore > highestScore) {
                highestScore := currentScore
                bestMatch := currentBlock
            }
            continue
        }
        if (isInsideBlock)
            currentBlock .= line . "`n"
    }
    return Trim(bestMatch)
}
