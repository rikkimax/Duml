@echo off
setlocal 

goto MAIN
::-----------------------------------------------
:: "%~f2" get abs path of %~2. 
::"%~fs2" get abs path with short names of %~2.
:setAbsPath
  setlocal
  set __absPath=%~f2
  endlocal && set %1=%__absPath%
  goto :eof
::-----------------------------------------------

:MAIN
call :setAbsPath ABS_PATH graphviz/bin/dot.exe
set GRAPHVIZ_DOT=%ABS_PATH%
set /p IFIles=File(S) do you want to use? 
java -jar plantuml.jar -o "output" %IFILES%
java -jar plantuml.jar -o "output" -tutxt %IFILES%
java -jar plantuml.jar -o "output" -tsvg %IFILES%
endlocal
pause