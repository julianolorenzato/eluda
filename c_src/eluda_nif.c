#include <erl_nif.h>

ErlNifResourceType *my_rt;

static int load(ErlNifEnv *env, void **priv_data, ERL_NIF_TERM load_info)
{
    my_rt = enif_open_resource_type(
        env,
        NULL,
        "some_object",
        // dev_array_destructor,
        NULL,
        ERL_NIF_RT_CREATE,
        NULL);

    return 0;
}

static ERL_NIF_TERM loop_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
    if (!enif_is_list(env, argv[0]))
    {
        return enif_make_badarg(env);
    }

    return enif_make_int(env, 23);
}

typedef struct myStruct
{
    int dole;
} MyStruct;

void dev_array_destructor(ErlNifEnv *env, void *res)
{
    printf("DESTRCTOR CALLED\n");
}

/**
 * Alloc memory to a MyStruct resource and returns a reference to it.
 */
static ERL_NIF_TERM obj_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
    MyStruct *obj = (MyStruct *)enif_alloc_resource(my_rt, sizeof(MyStruct));

    ERL_NIF_TERM term = enif_make_resource(env, obj);

    return term;
}

static ERL_NIF_TERM test_list_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
    if (argc != 1 || !enif_is_list(env, argv[0]))
    {
        return enif_make_badarg(env);
    }

    ERL_NIF_TERM list = argv[0];
    ERL_NIF_TERM head, tail;
    int sum = 0;
    int value;

    while (enif_get_list_cell(env, list, &head, &tail))
    {
        if (!enif_get_int(env, head, &value))
        {
            return enif_make_badarg(env);
        }
        sum += value;
        list = tail;
    }

    return enif_make_int(env, sum);
}

static ErlNifFunc nif_funcs[] = {
    {"obj_nif", 0, obj_nif},
    {"loop_nif", 1, loop_nif},
};

ERL_NIF_INIT(Elixir.Eluda, nif_funcs, &load, NULL, NULL, NULL);