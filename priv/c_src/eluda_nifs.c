#include <erl_nif.h>
// #include <stdlib.h>
#include <string.h>

#include "kernel.h"

ErlNifResourceType *device_ref;

static int load(ErlNifEnv *env, void **priv_data, ERL_NIF_TERM load_info)
{
    device_ref = enif_open_resource_type(
        env,
        NULL,
        "device_ref",
        // dev_array_destructor,
        NULL,
        ERL_NIF_RT_CREATE,
        NULL);

    return 0;
}

// float *gpu_alloc(float* data, u_int32_t data_length)
// {
//     // need to be replaced by CUDA stuff, just simulating
//     float* mem_block = (float *)malloc(sizeof(float) * data_length);

//     memcpy(mem_block, );

//     return mem_block;
// }

static ERL_NIF_TERM device_alloc_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
    ErlNifBinary matrix_bin;

    if (!enif_inspect_binary(env, argv[0], &matrix_bin))
    {
        return enif_make_badarg(env);
    }

    float *matrix = (float *)matrix_bin.data;

    u_int32_t rows = ((u_int32_t *)matrix)[0];
    u_int32_t cols = ((u_int32_t *)matrix)[1];
    u_int64_t matrix_size = sizeof(float) * rows * cols;

    matrix += 2;

    float **resource_space = (float **)enif_alloc_resource(device_ref, matrix_size);

    *resource_space = matrix;

    ERL_NIF_TERM term = enif_make_resource(env, resource_space);

    enif_release_resource(resource_space);

    return term;
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
// static ERL_NIF_TERM obj_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
// {
//     MyStruct *obj = (MyStruct *)enif_alloc_resource(my_rt, sizeof(MyStruct));

//     ERL_NIF_TERM term = enif_make_resource(env, obj);

//     return term;
// }

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
    {"device_alloc_nif", 1, device_alloc_nif},
};

ERL_NIF_INIT(Elixir.Eluda, nif_funcs, &load, NULL, NULL, NULL);