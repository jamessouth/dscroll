#include <time.h>

#define CAML_NAME_SPACE
#include <caml/mlvalues.h>

CAMLprim value caml_long_clock_nanosleep(value ms_v)
{
    long ms = Long_val(ms_v);

    struct timespec ts = {
        .tv_sec = ms / 1000,
        .tv_nsec = (ms % 1000) * 1000000L
    };

    clock_nanosleep(CLOCK_MONOTONIC, 0, &ts, NULL);

    return Val_unit;
}