
# Generate list of source files for QtCreator IDE
ls ../*.c >  pong.files
ls ../*.h >> pong.files

ls ../sound_fx/*.h >> pong.files
ls ../sound_fx/*.c >> pong.files