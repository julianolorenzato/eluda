#include <erl_nif.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>
#include <math.h>

ErlNifResourceType *DEVICE_REF;

static int load(ErlNifEnv *env, void **priv_data, ERL_NIF_TERM load_info)
{
    DEVICE_REF = enif_open_resource_type(
        env,
        NULL,
        "device_ref",
        NULL, // dev_array_destructor,
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

// recebe ponteiro para lista elixir e faz uma lista de ponteiros de float apra apssar pra funcao
// spawn, código que gera kernel
static ERL_NIF_TERM execute_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
    ERL_NIF_TERM e_kernel_name = argv[0];

    unsigned int kernel_name_size;

    enif_get_list_length(env, e_kernel_name, &kernel_name_size);

    char lib_name[1024] = "priv/c_dest/kernels.so";
    char kernel_name[32];

    enif_get_string(env, e_kernel_name, kernel_name, kernel_name_size + 1, ERL_NIF_LATIN1);

    void *m_handle = dlopen(lib_name, RTLD_NOW);
    if (m_handle == NULL)
    {
        char message[200];
        strcpy(message, "Error opening dll!! ");
        enif_raise_exception(env, enif_make_string(env, message, ERL_NIF_LATIN1));
    }

    void (*kernel)(float *dest, float **src, int length) = dlsym(m_handle, kernel_name);

    // ------------- Deal with the binary ----------------------
    unsigned int length;
    if (enif_get_list_length(env, argv[1], &length))
    {
        return enif_make_badarg(env);
    }

    ERL_NIF_TERM list = argv[1];
    ERL_NIF_TERM head, tail;

    float **src = malloc(sizeof(float *) * length);

    u_int64_t min_size = INFINITY;
    for (unsigned int i = 0; i < length; i++)
    {
        if (!enif_get_list_cell(env, list, &head, &tail))
        {
            return enif_make_badarg(env);
        }

        ErlNifBinary matrix_bin;
        if (!enif_inspect_binary(env, head, &matrix_bin))
        {
            return enif_make_badarg(env);
        }

        float *matrix = (float *)matrix_bin.data;

        u_int32_t rows = ((u_int32_t *)matrix)[0];
        u_int32_t cols = ((u_int32_t *)matrix)[1];
        u_int64_t matrix_size = rows * cols;

        // The smallest size between the matrixes will be used to build the resultant matrix
        if (matrix_size < min_size)
        {
            min_size = matrix_size;
        }

        matrix += 2;

        src[i] = matrix;
    }

    // // Kernel execution
    ERL_NIF_TERM matrex_data_bin;

    float *dest = (float *)enif_make_new_binary(env, min_size * sizeof(float), &matrex_data_bin);

    kernel(dest, src, min_size);

    dlclose(m_handle);

    return matrex_data_bin;
}
static int upgrade(ErlNifEnv *env, void **priv_data, void **old_priv_data, ERL_NIF_TERM load_info)
{
    return 1;
}

static ERL_NIF_TERM load_matrex(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
    ErlNifBinary matrix_bin;

    if (!enif_inspect_binary(env, argv[1], &matrix_bin))
    {
        return enif_make_badarg(env);
    }

    float *matrix = (float *)matrix_bin.data;

    u_int32_t rows = ((u_int32_t *)matrix)[0];
    u_int32_t cols = ((u_int32_t *)matrix)[1];
    u_int64_t matrix_size = rows * cols;

    matrix += 2;

    // // Kernel execution
    ERL_NIF_TERM matrex_data_bin;

    float *new_matrix = (float *)enif_make_new_binary(env, matrix_size * sizeof(float), &matrex_data_bin);

    return matrex_data_bin;
}

// static ERL_NIF_TERM device_alloc_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
// {
//     ErlNifBinary matrix_bin;

//     if (!enif_inspect_binary(env, argv[0], &matrix_bin))
//     {
//         return enif_make_badarg(env);
//     }

//     float *matrix = (float *)matrix_bin.data;

//     u_int32_t rows = ((u_int32_t *)matrix)[0];
//     u_int32_t cols = ((u_int32_t *)matrix)[1];
//     u_int64_t matrix_size = sizeof(float) * rows * cols;

//     matrix += 2;

//     float **resource_space = (float **)enif_alloc_resource(DEVICE_REF, matrix_size);

//     *resource_space = matrix;

//     ERL_NIF_TERM term = enif_make_resource(env, resource_space);

//     enif_release_resource(resource_space);

//     ERL_NIF_TERM m_size = enif_make_int64(env, matrix_size);

//     return enif_make_tuple2(env, term, m_size);
// }

void dev_array_destructor(ErlNifEnv *env, void *res)
{
    printf("DESTRCTOR CALLED\n");
}

static ErlNifFunc nif_funcs[] = {
    {"execute_nif", 3, execute_nif}};

ERL_NIF_INIT(Elixir.Eluda, nif_funcs, &load, NULL, &upgrade, NULL);