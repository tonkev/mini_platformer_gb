rgbasm -o main.o src/main.asm
rgblink -o mini_platformer.gb main.o
rgbfix -v -p 0 mini_platformer.gb