#include <erl_nif.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>

ErlNifResourceType *KERNEL_TYPE;
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

    KERNEL_TYPE = enif_open_resource_type(
        env,
        NULL,
        "kernel",
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

static ERL_NIF_TERM load_kernel_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
    ERL_NIF_TERM e_kernel_name = argv[0];

    unsigned int kernel_name_size;

    enif_get_list_length(env, e_kernel_name, &kernel_name_size);

    char lib_name[1024] = "priv/c_dest/kernels.so";
    char kernel_name[32];

    enif_get_string(env, e_kernel_name, kernel_name, kernel_name_size + 1, ERL_NIF_LATIN1);

    // printf("lib_name %s\n", lib_name);
    // printf("kernel_name %s\n", kernel_name);

    void *m_handle = dlopen(lib_name, RTLD_NOW);
    if (m_handle == NULL)
    {
        char message[200];
        strcpy(message, "Error opening dll!! ");
        enif_raise_exception(env, enif_make_string(env, message, ERL_NIF_LATIN1));
    }

    float *(*fn)(float *data, int data_length) = dlsym(m_handle, kernel_name);

    printf("%p\n", fn);

    // -----------------------------------

    void (**kernel_res)() = (void (**)())enif_alloc_resource(KERNEL_TYPE, sizeof(void *));

    // // Let's create conn and let the resource point to it

    *kernel_res = fn;

    // // We can now make the Erlang term that holds the resource...
    // ERL_NIF_TERM term = enif_make_resource(env, kernel_res);
    // // ...and release the resource so that it will be freed when Erlang garbage collects
    // enif_release_resource(kernel_res);

    // return term;

    return enif_make_int(env, 3);
}

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

    float **resource_space = (float **)enif_alloc_resource(DEVICE_REF, matrix_size);

    *resource_space = matrix;

    ERL_NIF_TERM term = enif_make_resource(env, resource_space);

    enif_release_resource(resource_space);

    ERL_NIF_TERM m_size = enif_make_int64(env, matrix_size);

    return enif_make_tuple2(env, term, m_size);
}

void dev_array_destructor(ErlNifEnv *env, void *res)
{
    printf("DESTRCTOR CALLED\n");
}

// typedef struct myStruct
// {
//     int dole;
// } MyStruct;

/**
 * Alloc memory to a MyStruct resource and returns a reference to it.
 */
// static ERL_NIF_TERM obj_nif(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
// {
//     MyStruct *obj = (MyStruct *)enif_alloc_resource(my_rt, sizeof(MyStruct));

//     ERL_NIF_TERM term = enif_make_resource(env, obj);

//     return term;
// }

static ErlNifFunc nif_funcs[] = {
    {"device_alloc_nif", 1, device_alloc_nif},
    {"load_kernel_nif", 1, load_kernel_nif}};

ERL_NIF_INIT(Elixir.Eluda, nif_funcs, &load, NULL, NULL, NULL);