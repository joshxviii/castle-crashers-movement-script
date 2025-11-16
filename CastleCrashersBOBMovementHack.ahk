#Requires AutoHotkey v2.0
#SingleInstance Force

#InputLevel 1
InstallKeybdHook(true, true) ; low-level hook is needed for castle crashers

MyGui := Gui("-MinimizeBox -MaximizeBox", "Back Off Barbarian - The Final Countdown")
MyGui.SetFont("s10")
; === Radio Buttons ===
MyGui.AddGroupBox("w280 h70 Section", "Orientation")
MyGui.AddRadio("xs+10 ys+20 Group Checked", "Horizontal").Name  := "RadioHoriz"
MyGui.AddRadio("xp+120 yp", "Vertical").Name                    := "RadioVert"
; === Checkbox ===
MyGui.AddCheckbox("xs+10 y+20", "Flipped").Name         := "ChkFlipped"
MyGui.AddGroupBox("xs w280 h70 Section", "Pattern")
MyGui.AddRadio("xs+10 ys+20 Group Checked", "1").Name   := "Pattern1"
MyGui.AddRadio("xp+50 yp", "2").Name                    := "Pattern2"
MyGui.AddRadio("xp+50 yp", "3").Name                    := "Pattern3"
; === Start Position ===
MyGui.AddText("xs","Start Position")
MyGui.AddEdit("Number VposX w70 Limit1 1", "X Position").Name    := "PosX"
MyGui.AddUpDown()
MyGui.AddEdit("yp Number VposY w70 Limit1 1", "Y Position").Name := "PosY"
MyGui.AddUpDown()
MyGui.AddText("yp w190 vCurrPos","(0 , 0)")

MyGui.AddButton("xs ", "&Reset").OnEvent("Click", (*) => SetPos(0,0))
; === Color definitions ===
patterns := [
    [
        [0,0,3,3],
        [2,1,1,2],
        [3,3,0,0],
        [1,2,2,1]
    ],
    [
        [0,0,2,2],
        [3,1,1,3],
        [2,2,0,0],
        [1,3,3,1]
    ],
    [
        [0,0,1,1],
        [2,3,3,2],
        [1,1,0,0],
        [3,2,2,3]
    ]
]   
colors := Map(0, "Blue", 1, "Yellow", 2, "Red", 3, "Green")
arrows := Map(0, "🠈", 1, "🠉", 2, "🠊", 3, "🠋")
colorHex := Map(
    "Blue",   "0000FF",
    "Yellow", "FFFF00",
    "Red",    "FF0000",
    "Green",  "00FF00"
)
grid  := []
state := [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]

; === 4×4 colored squares ===
MyGui.SetFont("s40")
yPos := 225
Loop 4 {
    row := A_Index
    xPos := 90
    Loop 4 {
        col := A_Index
        idx := (row-1)*4 + col        
        txt := MyGui.AddText("w40 h40 x" xPos " y" yPos " Center 0x200 BackgroundTrans", "■")
        grid.Push(txt)
        txt.OnEvent("Click", Handler(col, row))
        xPos += 40
    }
    yPos += 40
}
MyGui.SetFont("s10")
MyGui.Show("w300 h400 Center")

x := 0
y := 0

currentLayout := []
pattern := 1
orientation := 0
flipped := false
MyGui["Pattern1"].OnEvent("Click", (*) => (UpdateGrid(1)))
MyGui["Pattern2"].OnEvent("Click", (*) => (UpdateGrid(2)))
MyGui["Pattern3"].OnEvent("Click", (*) => (UpdateGrid(3)))
MyGui["RadioVert"].OnEvent("Click", (*) => (UpdateGrid()))
MyGui["RadioHoriz"].OnEvent("Click", (*) => (UpdateGrid()))
MyGui["ChkFlipped"].OnEvent("Click", (*) => (UpdateGrid()))
MyGui.OnEvent("Escape", (*) => MyGui.Hide())

UpdateGrid()

Handler(c, r) {
    return (*) => SetPos(c-1, r-1)
}

; ===================================================================
UpdateGrid(pat:=pattern) {
    global pattern, flipped, orientation, currentLayout
    pattern := pat
    orientation := MyGui["RadioVert"].Value
    flipped := MyGui["ChkFlipped"].Value

    currentLayout := patterns[pattern]
    if (orientation) {
        currentLayout := RotateMatrix(currentLayout)
    }
    if (flipped) {
        currentLayout := FlipMatrix(currentLayout)
    }

    idx := 1
    Loop 4 {
        row := A_Index
        Loop 4 {
            col := A_Index
            state[idx] := currentLayout[row][col]

            color := colors[state[idx]]
            grid[idx].Opt("c" colorHex[color])
            grid[idx].Opt("Background" "d8d8d8")
            grid[idx].Text := arrows[state[idx]]

            idx++
        }
    }
}

RotateMatrix(matrix:=[]) {
    n := matrix.Length
    rotated_matrix := [[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]
    Loop n {
        i := A_Index
        Loop n {
            j := A_Index
            rotated_matrix[j][(n - i) + 1] := matrix[i][j]
        }
    }
    return rotated_matrix
}

FlipMatrix(matrix:=[]) {
    n := matrix.Length
    flipped_matrix := [[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]
    Loop n {
        i := A_Index
        Loop n {
            j := A_Index
            flipped_matrix[i][j] := matrix[i][(n - j) + 1]
        }
    }
    return flipped_matrix
}

SetPos(newX:=MyGui["PosX"].Value, newY:=MyGui["PosY"].Value) {
    global x, y
    MyGui["PosX"].Value:=newX
    MyGui["PosY"].Value:=newY
    x:=newX
    y:=newY
    MyGui["CurrPos"].Value := "(" x " , " y ")"
    OutputDebug("SET POSITION (" x " " y ")")
}

; ==================================================================
dirName   := ["Left", "Up", "Right", "Down"]
currTile := 0
Move(dx, dy) {
    global x, y, currentLayout, currTile

    x += dx
    y += dy

    tx := Abs(Mod(x, 4) + (Mod(x, 4)<0?4:0))
    ty := Abs(Mod(y, 4) + (Mod(y, 4)<0?4:0))

    currTile := grid[(ty*4) + tx+1]

    requiredDir := currentLayout[ty + 1][tx + 1]
    outputKey := dirName[requiredDir + 1]
    
    OutputDebug outputKey
    MyGui["CurrPos"].Value := "(" x " , " y ")"
 
    Send "{Blind}{" outputKey " downR}"
    Sleep 60
    Send "{Blind}{" outputKey " up}"
}

Left::  Move(-1, 0)
Up::    Move(0, -1)
Right:: Move(1, 0)
Down::  Move(0, 1)