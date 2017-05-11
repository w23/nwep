nasmw.exe -fwin32 -o"4klang.obj" 4klang.asm

crinkler.exe nwep.obj 4klang.obj kernel32.lib user32.lib winmm.lib /ENTRY:entrypoint /UNSAFEIMPORT /COMPMODE:FAST /NOINITIALIZERS /HASHSIZE:100 /HASHTRIES:0 /ORDERTRIES:0

pause
