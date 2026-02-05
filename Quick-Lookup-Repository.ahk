#Requires AutoHotkey v2.0


; SETTINGS

Global REPOSITORY_FOLDER := EnvGet("USERPROFILE") . "\Downloads\Quick-Lookup-Repository"
Global START_TAG := "--start"
Global END_TAG   := "--end"

+l:: {
    IB := InputBox("Content Search: keywords /FILENAME", "Quick-Lookup Repository", "w400 h120")
    if (IB.Result = "Cancel" || IB.Value = "")
        return

    result := PerformContentSearch(IB.Value)
    
    if (result != "") {
        ResultGui := Gui("+AlwaysOnTop", "Repository Result")
        ResultGui.SetFont("s11", "Segoe UI")
        ResultGui.Add("Edit", "ReadOnly vScroll r15 w550", result)
        ResultGui.Add("Button", "Default w100", "Close").OnEvent("Click", (*) => ResultGui.Destroy())
        ResultGui.Show()
    } else {
        MsgBox("No matching content found.")
    }
}


; MODE 2: SMART FILE LAUNCHER (Ctrl + P)

^p:: {
    IB := InputBox("Launch File: /Folder/File.ext", "Smart File Launcher", "w450 h120")
    if (IB.Result = "Cancel" || IB.Value = "")
        return

    ; Convert / to \ and handle User Profile path
    cleanInput := StrReplace(IB.Value, "/", "\")
    if (SubStr(cleanInput, 1, 1) = "\")
        fullPath := EnvGet("USERPROFILE") . cleanInput
    else
        fullPath := cleanInput

    SplitPath(fullPath, &targetFile, &targetDir)

    ; 1. Fix Directory if misspelled
    if !DirExist(targetDir)
        targetDir := FindBestMatch(RegExReplace(targetDir, "\\[^\\]+$"), RegExReplace(targetDir, ".*\\"), "D")

    ; 2. Fix Filename if misspelled
    bestFile := FindBestMatch(targetDir, targetFile, "F")

    if (bestFile != "") {
        try {
            Run(bestFile)
            ToolTip("Launching: " . bestFile)
            SetTimer () => ToolTip(), -2000
        } catch {
            MsgBox("Found " . bestFile . " but system could not open it.")
        }
    }
}


PerformContentSearch(inputVal) {
    if !InStr(inputVal, "/")
        return ""
    parts := StrSplit(inputVal, "/")
    searchQuery := Trim(parts[1]), fileName := Trim(parts[2])
    filePath := REPOSITORY_FOLDER . "\" . fileName . ".txt"
    if !FileExist(filePath)
        return ""

    fileContent := FileRead(filePath)
    searchWords := StrSplit(searchQuery, " ")
    bestMatch := "", highestScore := 0, currentBlock := "", isInsideBlock := false

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

FindBestMatch(dir, targetName, mode) {
    if !DirExist(dir)
        return ""
    bestScore := 0, bestPath := ""
    Loop Files, dir . "\*", mode {
        score := 0
        searchTarget := StrLower(targetName), foundName := StrLower(A_LoopFileName)
        Loop Parse, searchTarget {
            if InStr(foundName, A_LoopField)
                score++
        }
        if (score > bestScore) {
            bestScore := score
            bestPath := A_LoopFileFullPath
        }
    }
    return bestPath
}
