@echo off

set ODIN_PATH=

for /f %%i in ('odin root') do set ODIN_PATH=%%i

if exist "%ODIN_PATH%\vendor\raylib\linux\libraylib.a" (
	echo raylib.dll not found in current directory. Copying from %ODIN_PATH%\vendor\raylib\linux\libraylib.a
	copy "%ODIN_PATH%\vendor\raylib\linux\libraylib.a" build\
)

call emsdk activate latest

if not exist build mkdir build
if not exist build/dist mkdir build/dist
pushd build

call odin build ../extras/wasm -o:speed -target=freestanding_wasm32 -out:odin -build-mode:obj -debug -show-system-calls
call emcc -O2 --shell-file ..\template.html -o ../build/dist/index.html ../wasm/main.c odin.wasm.o ../lib/libraylib.a -s USE_GLFW=3 -s GL_ENABLE_GET_PROC_ADDRESS  -s TOTAL_STACK=64MB -s INITIAL_MEMORY=128MB -s ASSERTIONS -s DETERMINISTIC=1 -s ASYNCIFY -Os -DPLATFORM_WEB -sERROR_ON_UNDEFINED_SYMBOLS=0 --use-preload-plugins --preload-file ../assets@/assets

popd
