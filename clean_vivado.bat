echo off                                     
echo.
echo.

for /F "tokens=* delims==" %%f in ('dir "Vivado" /S /B /A:-D' ) do (
    if not %%~xf == .xpr del "%%f"
    )

for /F "tokens=* delims==" %%g in ('dir "Vivado" /B /A:D' ) do (
    rmdir "Vivado\%%g" /S /Q
    )



for /F "tokens=* delims==" %%f in ('dir "src\Vivado_bd" /B /A:D' ) do (
    echo %%f
    for /F "tokens=* delims==" %%t in ('dir "src\Vivado_bd\%%f" /B /A:-D' ) do (
      if %%~xt == .bd echo preservo:  src\Vivado_bd\%%f\%%t
      if not %%~xt == .bd echo cancello: "src\Vivado_bd\%%f\%%t"
      if not %%~xt == .bd del "src\Vivado_bd\%%f\%%t"
      )
    for /F "tokens=* delims==" %%y in ('dir "src\Vivado_bd\%%f" /B /A:D' ) do (
      echo Cancello "src\Vivado_bd\%%y"
      rd "src\Vivado_bd\%%f\%%y" /s /q
      )
    echo.
    )
    
    
for /F "tokens=* delims==" %%f in ('dir "src\Vivado_ip" /B /A:D' ) do (
    echo %%f
    for /F "tokens=* delims==" %%t in ('dir "src\Vivado_ip\%%f" /B /A:-D' ) do (
      if %%~xt == .xci echo preservo:  src\Vivado_ip\%%f\%%t
      if not %%~xt == .xci echo cancello: "src\Vivado_ip\%%f\%%t"
      if not %%~xt == .xci del "src\Vivado_ip\%%f\%%t"
      )
    for /F "tokens=* delims==" %%y in ('dir "src\Vivado_ip\%%f" /B /A:D' ) do (
      echo Cancello "src\Vivado_ip\%%y"
      rd "src\Vivado_ip\%%f\%%y" /s /q
      )
    echo.
    )    


echo. 
echo. 
 
                
echo Finished: Vivado work files cleaned           
