#Requires AutoHotkey v2.0

; --- THE SEARCH ENGINE (Same as before) ---
PerformSearch(inputVal) {
    if !InStr(inputVal, "/")
        return ""

    parts := StrSplit(inputVal, "/")
    searchQuery := Trim(parts[1])
    fileName := Trim(parts[2])
    
    userProfile := EnvGet("USERPROFILE")
    filePath := userProfile . "\Downloads\cheatPDF\" . fileName . ".txt"

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
        if InStr(line, "--start") {
            isInsideBlock := true
            currentBlock := ""
            continue
        }
        if InStr(line, "--end") {
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

; --- THE STEALTH INPUT TRIGGER (Ctrl + P) ---
^p:: {
    ; Create a borderless, "AlwaysOnTop" tiny window
    StealthGui := Gui("-Caption +AlwaysOnTop +ToolWindow")
    StealthGui.BackColor := "1A1A1A" ; Dark background
    StealthGui.SetFont("s12 cWhite", "Consolas") ; Sleek font
    
    ; Add the input field
    EditField := StealthGui.Add("Edit", "w300 r1 -E0x200 Background222222") 
    
    ; Hidden button to handle the 'Enter' key
    Btn := StealthGui.Add("Button", "Default w0 h0", "OK")
    Btn.OnEvent("Click", ProcessInput)

    ; Get mouse position to place the input there
    MouseGetPos(&mX, &mY)
    
    ; Show the GUI at the mouse location
    StealthGui.Show("x" . mX . " y" . mY)

    ProcessInput(*) {
        userInput := EditField.Value
        StealthGui.Destroy() ; Immediately vanish
        
        if (userInput != "") {
            result := PerformSearch(userInput)
            if (result != "") {
                A_Clipboard := result
                ; Subtle confirmation at cursor
                ToolTip("Ready")
                SetTimer () => ToolTip(), -800
            }
        }
    }

    ; Allow Escape to cancel and close the input
    StealthGui.OnEvent("Escape", (*) => StealthGui.Destroy())
}