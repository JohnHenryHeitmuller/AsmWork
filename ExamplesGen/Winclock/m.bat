ml /c /W2 /DMODEL=small /Zi /FoAPPENTRY.obj APPENTRY.ASM
ml /c /W2 /DMODEL=small /Zi /FoWINCLOCK.obj WINCLOCK.ASM
rc /r /fo winclock.res winclock.rc
link appentry.obj+winclock.obj,winclock.exe,,libw.lib,winclock.def
