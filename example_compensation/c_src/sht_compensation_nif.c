#include "erl_nif.h"
#include "sht_compensation.h"

#include <string.h>

#define DATA_SIZE (sizeof(v) / sizeof(float))

static ERL_NIF_TERM atom_ok;

static ERL_NIF_TERM compensate(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
    double temperature_sht, humidity_sht, telem_display_current, telem_cpu_load;
    float temperature_res, humidity_res;

    if (!enif_get_double(env, argv[0], &temperature_sht) ||
        !enif_get_double(env, argv[1], &humidity_sht) ||
        !enif_get_double(env, argv[2], &telem_display_current) ||
        !enif_get_double(env, argv[3], &telem_cpu_load))
        return enif_make_badarg(env);

    sht_compensate_every_5_seconds(
        (float)temperature_sht,
        (float)humidity_sht,
        (float)telem_display_current,
        (float)telem_cpu_load,
        &temperature_res,
        &humidity_res);

    ERL_NIF_TERM out_temp = enif_make_double(env, temperature_res);
    ERL_NIF_TERM out_hum = enif_make_double(env, humidity_res);

    return enif_make_tuple(env, 2, out_temp, out_hum);
}

static ERL_NIF_TERM get_state(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
    ERL_NIF_TERM term_list[DATA_SIZE];

    for (size_t i = 0; i < DATA_SIZE; i++)
        term_list[i] = enif_make_double(env, v[i]);

    return enif_make_list_from_array(env, term_list, DATA_SIZE);
}

static ERL_NIF_TERM set_state(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
    ERL_NIF_TERM list = argv[0];

    for (size_t i = 0; i < DATA_SIZE; i++) {
        ERL_NIF_TERM head;
        ERL_NIF_TERM tail;
        double value;

        if (!enif_get_list_cell(env, list, &head, &tail) ||
            !enif_get_double(env, head, &value))
            return enif_make_badarg(env);

        v[i] = value;
        list = tail;
    }

    return atom_ok;
}

static ERL_NIF_TERM reset_state(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
    for (size_t i = 0; i < DATA_SIZE; i++)
        v[i] = 0;

    return atom_ok;
}

static int nif_load(ErlNifEnv *env, void **priv_data, ERL_NIF_TERM info)
{
    for (size_t i = 0; i < DATA_SIZE; i++)
        v[i] = 0;

    atom_ok = enif_make_atom(env, "ok");
    return 0;
}

static ErlNifFunc nif_funcs[] = {
    {"do_compensate", 4, compensate, 0},
    {"set_state", 1, set_state, 0},
    {"get_state", 0, get_state, 0},
    {"reset_state", 0, reset_state, 0}
};

ERL_NIF_INIT(Elixir.ExampleCompensation, nif_funcs, nif_load, NULL, NULL, NULL)
