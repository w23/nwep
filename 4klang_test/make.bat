nasmw.exe -fwin32 -o"audio.obj" 4klang.asm

crinkler.exe main.obj audio.obj kernel32.lib user32.lib winmm.lib /UNSAFEIMPORT /COMPMODE:FAST /NOINITIALIZERS /HASHSIZE:100 /HASHTRIES:0 /ORDERTRIES:0

pause
