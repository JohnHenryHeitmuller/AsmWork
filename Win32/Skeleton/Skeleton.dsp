# Microsoft Developer Studio Project File - Name="Skeleton" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 5.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Application" 0x0101

CFG=Skeleton - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "Skeleton.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "Skeleton.mak" CFG="Skeleton - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "Skeleton - Win32 Release" (based on "Win32 (x86) Application")
!MESSAGE "Skeleton - Win32 Debug" (based on "Win32 (x86) Application")
!MESSAGE 

# Begin Project
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
MTL=midl.exe
RSC=rc.exe

!IF  "$(CFG)" == "Skeleton - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "Release"
# PROP BASE Intermediate_Dir "Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "Release"
# PROP Intermediate_Dir "Release"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /YX /FD /c
# ADD CPP /nologo /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /YX /FD /c
# ADD BASE MTL /nologo /D "NDEBUG" /mktyplib203 /o NUL /win32
# ADD MTL /nologo /D "NDEBUG" /mktyplib203 /o NUL /win32
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:windows /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib comdlg32.lib comctl32.lib /nologo /subsystem:windows /machine:I386

!ELSEIF  "$(CFG)" == "Skeleton - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "Debug"
# PROP Intermediate_Dir "Debug"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /Gm /GX /Zi /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /YX /FD /c
# ADD CPP /nologo /W3 /Gm /GX /Zi /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /YX /FD /c
# ADD BASE MTL /nologo /D "_DEBUG" /mktyplib203 /o NUL /win32
# ADD MTL /nologo /D "_DEBUG" /mktyplib203 /o NUL /win32
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:windows /debug /machine:I386 /pdbtype:sept
# ADD LINK32 kernel32.lib user32.lib gdi32.lib comdlg32.lib comctl32.lib /nologo /subsystem:windows /debug /machine:I386 /pdbtype:sept

!ENDIF 

# Begin Target

# Name "Skeleton - Win32 Release"
# Name "Skeleton - Win32 Debug"
# Begin Group "Source Files"

# PROP Default_Filter "*.asm;*.hpj"
# Begin Source File

SOURCE=.\About.asm

!IF  "$(CFG)" == "Skeleton - Win32 Release"

# Begin Custom Build
InputPath=.\About.asm
InputName=About

".\Release\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	ml /c /coff /Fo.\Release\$(InputName).obj $(InputName).asm

# End Custom Build

!ELSEIF  "$(CFG)" == "Skeleton - Win32 Debug"

# Begin Custom Build
InputPath=.\About.asm
InputName=About

".\debug\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	ml /c /coff /Zi /Fo.\debug\$(InputName).obj $(InputName).asm

# End Custom Build

!ENDIF 

# End Source File
# Begin Source File

SOURCE=.\CmdFile.asm

!IF  "$(CFG)" == "Skeleton - Win32 Release"

# Begin Custom Build
InputPath=.\CmdFile.asm
InputName=CmdFile

".\Release\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	ml /c /coff /Fo.\Release\$(InputName).obj $(InputName).asm

# End Custom Build

!ELSEIF  "$(CFG)" == "Skeleton - Win32 Debug"

# Begin Custom Build
InputPath=.\CmdFile.asm
InputName=CmdFile

".\debug\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	ml /c /coff /Zi /Fo.\debug\$(InputName).obj $(InputName).asm

# End Custom Build

!ENDIF 

# End Source File
# Begin Source File

SOURCE=.\Misc.asm

!IF  "$(CFG)" == "Skeleton - Win32 Release"

# Begin Custom Build
InputPath=.\Misc.asm
InputName=Misc

".\Release\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	ml /c /coff /Fo.\Release\$(InputName).obj $(InputName).asm

# End Custom Build

!ELSEIF  "$(CFG)" == "Skeleton - Win32 Debug"

# Begin Custom Build
InputPath=.\Misc.asm
InputName=Misc

".\debug\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	ml /c /coff /Zi /Fo.\debug\$(InputName).obj $(InputName).asm

# End Custom Build

!ENDIF 

# End Source File
# Begin Source File

SOURCE=.\Msg.asm

!IF  "$(CFG)" == "Skeleton - Win32 Release"

# Begin Custom Build
InputPath=.\Msg.asm
InputName=Msg

".\Release\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	ml /c /coff /Fo.\Release\$(InputName).obj $(InputName).asm

# End Custom Build

!ELSEIF  "$(CFG)" == "Skeleton - Win32 Debug"

# Begin Custom Build
InputPath=.\Msg.asm
InputName=Msg

".\debug\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	ml /c /coff /Zi /Fo.\debug\$(InputName).obj $(InputName).asm

# End Custom Build

!ENDIF 

# End Source File
# Begin Source File

SOURCE=.\StatBar.asm

!IF  "$(CFG)" == "Skeleton - Win32 Release"

# Begin Custom Build
InputPath=.\StatBar.asm
InputName=StatBar

".\Release\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	ml /c /coff /Fo.\Release\$(InputName).obj $(InputName).asm

# End Custom Build

!ELSEIF  "$(CFG)" == "Skeleton - Win32 Debug"

# Begin Custom Build
InputPath=.\StatBar.asm
InputName=StatBar

".\debug\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	ml /c /coff /Zi /Fo.\debug\$(InputName).obj $(InputName).asm

# End Custom Build

!ENDIF 

# End Source File
# Begin Source File

SOURCE=.\ToolBar.asm

!IF  "$(CFG)" == "Skeleton - Win32 Release"

# Begin Custom Build
InputPath=.\ToolBar.asm
InputName=ToolBar

".\Release\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	ml /c /coff /Fo.\Release\$(InputName).obj $(InputName).asm

# End Custom Build

!ELSEIF  "$(CFG)" == "Skeleton - Win32 Debug"

# Begin Custom Build
InputPath=.\ToolBar.asm
InputName=ToolBar

".\debug\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	ml /c /coff /Zi /Fo.\debug\$(InputName).obj $(InputName).asm

# End Custom Build

!ENDIF 

# End Source File
# Begin Source File

SOURCE=.\WinMain.asm

!IF  "$(CFG)" == "Skeleton - Win32 Release"

# Begin Custom Build
InputPath=.\WinMain.asm
InputName=WinMain

".\Release\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	ml /c /coff /Fo.\Release\$(InputName).obj $(InputName).asm

# End Custom Build

!ELSEIF  "$(CFG)" == "Skeleton - Win32 Debug"

# Begin Custom Build
InputPath=.\WinMain.asm
InputName=WinMain

".\debug\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	ml /c /coff /Zi /Fo.\debug\$(InputName).obj $(InputName).asm

# End Custom Build

!ENDIF 

# End Source File
# Begin Source File

SOURCE=.\WndProc.asm

!IF  "$(CFG)" == "Skeleton - Win32 Release"

# Begin Custom Build
InputPath=.\WndProc.asm
InputName=WndProc

".\Release\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	ml /c /coff /Fo.\Release\$(InputName).obj $(InputName).asm

# End Custom Build

!ELSEIF  "$(CFG)" == "Skeleton - Win32 Debug"

# Begin Custom Build
InputPath=.\WndProc.asm
InputName=WndProc

".\debug\$(InputName).obj" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	ml /c /coff /Zi /Fo.\debug\$(InputName).obj $(InputName).asm

# End Custom Build

!ENDIF 

# End Source File
# End Group
# Begin Group "Resource Files"

# PROP Default_Filter ""
# Begin Source File

SOURCE=.\Resource.rc
# End Source File
# End Group
# Begin Group "Include Files"

# PROP Default_Filter ""
# Begin Source File

SOURCE=.\Common.inc
# End Source File
# Begin Source File

SOURCE=.\WindowsA.inc
# End Source File
# End Group
# Begin Group "Help Files"

# PROP Default_Filter ""
# Begin Source File

SOURCE=.\Help\HelpFile.hpj

!IF  "$(CFG)" == "Skeleton - Win32 Release"

# Begin Custom Build
OutDir=.\Release
InputPath=.\Help\HelpFile.hpj

".\help\skeleton.hlp" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	start /wait hcw /C /E /M .\help\helpfile.hpj 
	copy .\help\skeleton.cnt .\$(OutDir)\skeleton.cnt 
	copy .\help\skeleton.hlp .\$(OutDir)\skeleton.hlp 
	
# End Custom Build

!ELSEIF  "$(CFG)" == "Skeleton - Win32 Debug"

# PROP Ignore_Default_Tool 1
# Begin Custom Build
OutDir=.\Debug
InputPath=.\Help\HelpFile.hpj

".\help\skeleton.hlp" : $(SOURCE) "$(INTDIR)" "$(OUTDIR)"
	start /wait hcw /C /E /M .\help\helpfile.hpj 
	copy .\help\skeleton.cnt .\$(OutDir)\skeleton.cnt 
	copy .\help\skeleton.hlp .\$(OutDir)\skeleton.hlp 
	
# End Custom Build

!ENDIF 

# End Source File
# Begin Source File

SOURCE=.\Help\HelpFile.rtf

!IF  "$(CFG)" == "Skeleton - Win32 Release"

!ELSEIF  "$(CFG)" == "Skeleton - Win32 Debug"

# PROP Exclude_From_Build 1

!ENDIF 

# End Source File
# Begin Source File

SOURCE=.\Help\Skeleton.cnt

!IF  "$(CFG)" == "Skeleton - Win32 Release"

!ELSEIF  "$(CFG)" == "Skeleton - Win32 Debug"

# PROP Exclude_From_Build 1

!ENDIF 

# End Source File
# End Group
# End Target
# End Project
