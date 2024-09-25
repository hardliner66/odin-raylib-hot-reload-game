#include <emscripten/emscripten.h>

extern void init();
extern void update();

int main() {
    init();

    emscripten_set_main_loop(update, 0, 1);
    return 0;
}