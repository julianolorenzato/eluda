#include <erl_nif.h>

static ERL_NIF_TERM loop_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
    if (!enif_is_list(env, argv[0]))
    {
        return enif_make_badarg(env);
    }

    return enif_make_int(env, 23);
}

static ErlNifFunc nif_funcs[] = {
    {"loop_nif", 1, loop_nif},
};

ERL_NIF_INIT(Elixir.Eluda, nif_funcs, NULL, NULL, NULL, NULL);