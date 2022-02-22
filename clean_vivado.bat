echo off 
echo.
echo.


echo Start cleaning ...                                   
echo.
echo.
echo.

set would=
set be=
if "%1" == "-t" set would=would 
if "%1" == "-t" set be=be 

rem ****************************
rem Clean Vivado project folder
echo [105mClean Vivado project folder[0m

set /A VFFILECOUNT=0
set /A VFDELFILECOUNT=0
set /A VFFOLDERCOUNT=0

set keep=

for /F "tokens=* delims==" %%f in ('dir "Vivado" /S /B /A:-D' ) do (
    set keep=
    
    if %%~xf == .xpr set keep=true
    
    if not defined keep (
      if not "%1" == "-t" del "%%f"
      set /A VFDELFILECOUNT+=1
      )
    set /A VFFILECOUNT+=1
    )

for /F "tokens=* delims==" %%g in ('dir "Vivado" /S /B /A:D  ^| sort /r' ) do (
    if not "%1" == "-t" rd "%%g" > nul 2>&1
    )
echo.
echo Done
echo.
echo.
 

rem ****************************
rem Clean Vivado IPs folder

echo [105mClean Vivado IPs folder[0m

set /A IPCOUNT=0
set /A IPFILECOUNT=0
set /A IPDELFILECOUNT=0

set res=

for /D /r %%G in (*Vivado_ip*) do (
  echo(
  echo [36mVivado IPs found in folder [1m%%G[0m
  for /F "tokens=* delims==" %%f in ('dir "%%G" /B /A:D' ) do (
    echo [32mProcessing [1m%%f[0m
    for /F "tokens=* delims==" %%t in ('dir "%%G\%%f" /B /A:-D' ) do (
      set res=
      
      if %%~xt == .xci set res=T
      if %%~xt == .coe set res=T
      
      if %%~xt == .xci set /A IPCOUNT+=1
      if defined res (
        echo    I %would%keep file:     %%G\%%f\%%t
        ) else (
        echo    I %would%delete file:   %%G\%%f\%%t
        set /A IPDELFILECOUNT+=1
        if not "%1" == "-t" del "%%G\%%f\%%t"
        )
      set /A IPFILECOUNT+=1
      )
    for /F "tokens=* delims==" %%y in ('dir "%%G\%%f" /B /A:D ^| sort /r' ) do (
      echo    I %would%remove folder: %%G\%%f\%%y
      if not "%1" == "-t" rd "%%G\%%f\%%y" /s /q > nul 2>&1    
      )
    )
  )
echo.
echo Done
echo.
echo. 
  
rem ****************************
rem Clean Vivado BDs folder

echo [105mClean Vivado BDs folder[0m

set /A BDCOUNT=0
set /A BDFILECOUNT=0
set /A BDDELFILECOUNT=0

set res=

for /D /r %%G in (*Vivado_bd*) do (
  echo(
  echo [36mVivado BDs found in folder [1m%%G[0m
  for /F "tokens=* delims==" %%f in ('dir "%%G" /B /A:D' ) do (
    echo [32mProcessing [1m%%f[0m
    for /F "tokens=* delims==" %%t in ('dir "%%G\%%f" ? /B /A:-D' ) do (
      
      set res=
      
      if %%~xt == .bd set res=T
      if %%~xt == .ui set res=T
    
      if %%~xt == .bd set /A BDCOUNT+=1
    
      if defined res (
        echo    I %would%keep file:     %%G\%%f\%%t
        ) else (
        echo    I %would%delete file:   %%G\%%f\%%t
        set /A BDDELFILECOUNT+=1
        if not "%1" == "-t" del "%%G\%%f\%%t"
        )
      SET /A BDFILECOUNT+=1
      )
    
    for /F "tokens=* delims==" %%y in ('dir "%%G\%%f" /B /A:D' ) do (
      echo %%G\%%f
      if %%y == ui (
        echo    I %would%keep folder:   %%G\%%f\%%y
        ) else (
        echo    I %would%remove folder: %%G\%%f\%%y
        if not "%1" == "-t" rd "%%G\%%f\%%y" /s /q 
        )
      )
    )
  )
  
echo.
echo Done
echo.
echo.
  

echo.
echo.  
echo ---------------------------------------------------------------------   
echo.  
echo %VFDELFILECOUNT% Files in Vivado folder %would%%be%deleted
echo.  
echo %IPCOUNT% IPs found   
echo %IPFILECOUNT% IPs files processed 
echo %IPDELFILECOUNT% IPs files %would%%be%deleted 
echo.
echo %BDCOUNT% BDs found   
echo %BDFILECOUNT% BDs files processed 
echo %BDDELFILECOUNT% BDs files %would%%be%deleted 
echo.
echo. 
echo Finished: Vivado work files %would%%be%cleaned  