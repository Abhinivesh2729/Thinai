// opencl_shim.c — lazy OpenCL loader for Android (fllama).
//
// Why this exists
// ---------------
// ggml-opencl normally links straight against libOpenCL.so. On Android that
// is a vendor library: Adreno and Mali phones ship one under /vendor, many
// other devices ship none, and no app is allowed to bundle its own. A hard
// NEEDED entry on libOpenCL.so would make libfllama.so fail to load, and so
// take CPU inference down with it, on every phone without the vendor library.
//
// Instead ggml-opencl links against this file. Each CL entry point that
// ggml-opencl uses is defined here as a thin forward to the real symbol,
// resolved with dlopen/dlsym the first time any of them is called. When no
// libOpenCL.so can be opened, clGetPlatformIDs reports
// CL_PLATFORM_NOT_FOUND_KHR with zero platforms, which ggml-opencl already
// handles by registering no devices; every other entry point fails with
// CL_INVALID_OPERATION.
//
// Only the functions ggml-opencl.cpp actually calls are shimmed. If a llama.cpp
// update starts calling a new one, the link fails with an undefined clXxx
// symbol: add a forward for it below.
//
// Symbols are compiled with hidden visibility (see src/CMakeLists.txt) so
// libfllama.so does not export clXxx, and the vendor library can never
// accidentally bind to these forwards instead of its own implementations.

#define CL_TARGET_OPENCL_VERSION 300
// ggml-opencl calls clCreateCommandQueue (deprecated in 1.2, still exported by
// every driver); forwarding it should not warn.
#define CL_USE_DEPRECATED_OPENCL_1_2_APIS

#include <CL/cl.h>
#include <CL/cl_ext.h> // CL_PLATFORM_NOT_FOUND_KHR

#include <dlfcn.h>
#include <pthread.h>
#include <stddef.h>

#ifdef __ANDROID__
#include <android/log.h>
#define SHIM_LOG(...) __android_log_print(ANDROID_LOG_INFO, "fllama", __VA_ARGS__)
#else
#include <stdio.h>
#define SHIM_LOG(...) (fprintf(stderr, __VA_ARGS__), fputc('\n', stderr))
#endif

// Tried in order. The bare soname is the one that works for apps: since
// Android 7 an app's linker namespace only sees vendor libraries listed in
// public.libraries.txt, and since Android 12 the app must also declare
// <uses-native-library android:name="libOpenCL.so"> in its manifest. The
// absolute paths are a fallback for older or permissive builds.
static const char *const k_opencl_paths[] = {
    "libOpenCL.so",
    "/vendor/lib64/libOpenCL.so",
    "/system/vendor/lib64/libOpenCL.so",
};

// X-macro list of every forwarded function.
#define FLLAMA_CL_FUNCTIONS(X)       \
  X(clBuildProgram)                  \
  X(clCreateBuffer)                  \
  X(clCreateCommandQueue)            \
  X(clCreateContext)                 \
  X(clCreateImage)                   \
  X(clCreateKernel)                  \
  X(clCreateProgramWithSource)       \
  X(clCreateSubBuffer)               \
  X(clEnqueueBarrierWithWaitList)    \
  X(clEnqueueCopyBuffer)             \
  X(clEnqueueFillBuffer)             \
  X(clEnqueueMarkerWithWaitList)     \
  X(clEnqueueNDRangeKernel)          \
  X(clEnqueueReadBuffer)             \
  X(clEnqueueWriteBuffer)            \
  X(clFinish)                        \
  X(clFlush)                         \
  X(clGetDeviceIDs)                  \
  X(clGetDeviceInfo)                 \
  X(clGetEventProfilingInfo)         \
  X(clGetKernelInfo)                 \
  X(clGetKernelSubGroupInfo)         \
  X(clGetKernelWorkGroupInfo)        \
  X(clGetPlatformIDs)                \
  X(clGetPlatformInfo)               \
  X(clGetProgramBuildInfo)           \
  X(clReleaseContext)                \
  X(clReleaseEvent)                  \
  X(clReleaseMemObject)              \
  X(clReleaseProgram)                \
  X(clSetKernelArg)                  \
  X(clWaitForEvents)

// Function-pointer table, typed from the header prototypes.
static struct {
#define X(name) __typeof__(name) *name;
  FLLAMA_CL_FUNCTIONS(X)
#undef X
} g_cl;

static pthread_once_t g_cl_once = PTHREAD_ONCE_INIT;
static int g_cl_available = 0;

static void fllama_cl_load(void) {
  for (size_t i = 0; i < sizeof(k_opencl_paths) / sizeof(k_opencl_paths[0]); i++) {
    void *handle = dlopen(k_opencl_paths[i], RTLD_NOW | RTLD_LOCAL);
    if (handle == NULL) {
      continue;
    }
    // Without the platform query nothing else is reachable, so a library
    // missing it is treated as no library at all. Any other missing symbol
    // (e.g. clGetKernelSubGroupInfo on an OpenCL 1.2 driver) stays NULL and
    // that one function reports CL_INVALID_OPERATION.
    if (dlsym(handle, "clGetPlatformIDs") == NULL) {
      dlclose(handle);
      continue;
    }
#define X(name) g_cl.name = (__typeof__(name) *)dlsym(handle, #name);
    FLLAMA_CL_FUNCTIONS(X)
#undef X
    g_cl_available = 1;
    SHIM_LOG("opencl shim: loaded %s", k_opencl_paths[i]);
    return; // handle intentionally kept open for the life of the process
  }
  SHIM_LOG("opencl shim: no libOpenCL.so available, OpenCL backend disabled");
}

static inline int fllama_cl_ready(void) {
  pthread_once(&g_cl_once, fllama_cl_load);
  return g_cl_available;
}

// Resolves the pointer or bails out with [fail] (an expression).
#define CL_FORWARD_OR(name, fail)            \
  if (!fllama_cl_ready() || !g_cl.name) {    \
    return fail;                             \
  }

// For constructors that report errors through errcode_ret and return NULL.
#define CL_FORWARD_OR_NULL(name, errcode_ret)                     \
  if (!fllama_cl_ready() || !g_cl.name) {                          \
    if (errcode_ret) *errcode_ret = CL_INVALID_OPERATION;          \
    return NULL;                                                   \
  }

// ── Platform / device discovery ─────────────────────────────────────────────

CL_API_ENTRY cl_int CL_API_CALL
clGetPlatformIDs(cl_uint num_entries, cl_platform_id *platforms,
                 cl_uint *num_platforms) {
  if (!fllama_cl_ready() || !g_cl.clGetPlatformIDs) {
    if (num_platforms) *num_platforms = 0;
    return CL_PLATFORM_NOT_FOUND_KHR;
  }
  return g_cl.clGetPlatformIDs(num_entries, platforms, num_platforms);
}

CL_API_ENTRY cl_int CL_API_CALL
clGetPlatformInfo(cl_platform_id platform, cl_platform_info param_name,
                  size_t param_value_size, void *param_value,
                  size_t *param_value_size_ret) {
  CL_FORWARD_OR(clGetPlatformInfo, CL_INVALID_OPERATION);
  return g_cl.clGetPlatformInfo(platform, param_name, param_value_size,
                                param_value, param_value_size_ret);
}

CL_API_ENTRY cl_int CL_API_CALL
clGetDeviceIDs(cl_platform_id platform, cl_device_type device_type,
               cl_uint num_entries, cl_device_id *devices,
               cl_uint *num_devices) {
  CL_FORWARD_OR(clGetDeviceIDs, CL_INVALID_OPERATION);
  return g_cl.clGetDeviceIDs(platform, device_type, num_entries, devices,
                             num_devices);
}

CL_API_ENTRY cl_int CL_API_CALL
clGetDeviceInfo(cl_device_id device, cl_device_info param_name,
                size_t param_value_size, void *param_value,
                size_t *param_value_size_ret) {
  CL_FORWARD_OR(clGetDeviceInfo, CL_INVALID_OPERATION);
  return g_cl.clGetDeviceInfo(device, param_name, param_value_size,
                              param_value, param_value_size_ret);
}

// ── Context / queue ─────────────────────────────────────────────────────────

CL_API_ENTRY cl_context CL_API_CALL
clCreateContext(const cl_context_properties *properties, cl_uint num_devices,
                const cl_device_id *devices,
                void (CL_CALLBACK *pfn_notify)(const char *errinfo,
                                               const void *private_info,
                                               size_t cb, void *user_data),
                void *user_data, cl_int *errcode_ret) {
  CL_FORWARD_OR_NULL(clCreateContext, errcode_ret);
  return g_cl.clCreateContext(properties, num_devices, devices, pfn_notify,
                              user_data, errcode_ret);
}

CL_API_ENTRY cl_int CL_API_CALL clReleaseContext(cl_context context) {
  CL_FORWARD_OR(clReleaseContext, CL_INVALID_OPERATION);
  return g_cl.clReleaseContext(context);
}

CL_API_ENTRY cl_command_queue CL_API_CALL
clCreateCommandQueue(cl_context context, cl_device_id device,
                     cl_command_queue_properties properties,
                     cl_int *errcode_ret) {
  CL_FORWARD_OR_NULL(clCreateCommandQueue, errcode_ret);
  return g_cl.clCreateCommandQueue(context, device, properties, errcode_ret);
}

CL_API_ENTRY cl_int CL_API_CALL clFinish(cl_command_queue command_queue) {
  CL_FORWARD_OR(clFinish, CL_INVALID_OPERATION);
  return g_cl.clFinish(command_queue);
}

CL_API_ENTRY cl_int CL_API_CALL clFlush(cl_command_queue command_queue) {
  CL_FORWARD_OR(clFlush, CL_INVALID_OPERATION);
  return g_cl.clFlush(command_queue);
}

// ── Memory objects ──────────────────────────────────────────────────────────

CL_API_ENTRY cl_mem CL_API_CALL
clCreateBuffer(cl_context context, cl_mem_flags flags, size_t size,
               void *host_ptr, cl_int *errcode_ret) {
  CL_FORWARD_OR_NULL(clCreateBuffer, errcode_ret);
  return g_cl.clCreateBuffer(context, flags, size, host_ptr, errcode_ret);
}

CL_API_ENTRY cl_mem CL_API_CALL
clCreateSubBuffer(cl_mem buffer, cl_mem_flags flags,
                  cl_buffer_create_type buffer_create_type,
                  const void *buffer_create_info, cl_int *errcode_ret) {
  CL_FORWARD_OR_NULL(clCreateSubBuffer, errcode_ret);
  return g_cl.clCreateSubBuffer(buffer, flags, buffer_create_type,
                                buffer_create_info, errcode_ret);
}

CL_API_ENTRY cl_mem CL_API_CALL
clCreateImage(cl_context context, cl_mem_flags flags,
              const cl_image_format *image_format,
              const cl_image_desc *image_desc, void *host_ptr,
              cl_int *errcode_ret) {
  CL_FORWARD_OR_NULL(clCreateImage, errcode_ret);
  return g_cl.clCreateImage(context, flags, image_format, image_desc, host_ptr,
                            errcode_ret);
}

CL_API_ENTRY cl_int CL_API_CALL clReleaseMemObject(cl_mem memobj) {
  CL_FORWARD_OR(clReleaseMemObject, CL_INVALID_OPERATION);
  return g_cl.clReleaseMemObject(memobj);
}

// ── Programs / kernels ──────────────────────────────────────────────────────

CL_API_ENTRY cl_program CL_API_CALL
clCreateProgramWithSource(cl_context context, cl_uint count,
                          const char **strings, const size_t *lengths,
                          cl_int *errcode_ret) {
  CL_FORWARD_OR_NULL(clCreateProgramWithSource, errcode_ret);
  return g_cl.clCreateProgramWithSource(context, count, strings, lengths,
                                        errcode_ret);
}

CL_API_ENTRY cl_int CL_API_CALL
clBuildProgram(cl_program program, cl_uint num_devices,
               const cl_device_id *device_list, const char *options,
               void (CL_CALLBACK *pfn_notify)(cl_program program,
                                              void *user_data),
               void *user_data) {
  CL_FORWARD_OR(clBuildProgram, CL_INVALID_OPERATION);
  return g_cl.clBuildProgram(program, num_devices, device_list, options,
                             pfn_notify, user_data);
}

CL_API_ENTRY cl_int CL_API_CALL
clGetProgramBuildInfo(cl_program program, cl_device_id device,
                      cl_program_build_info param_name,
                      size_t param_value_size, void *param_value,
                      size_t *param_value_size_ret) {
  CL_FORWARD_OR(clGetProgramBuildInfo, CL_INVALID_OPERATION);
  return g_cl.clGetProgramBuildInfo(program, device, param_name,
                                    param_value_size, param_value,
                                    param_value_size_ret);
}

CL_API_ENTRY cl_int CL_API_CALL clReleaseProgram(cl_program program) {
  CL_FORWARD_OR(clReleaseProgram, CL_INVALID_OPERATION);
  return g_cl.clReleaseProgram(program);
}

CL_API_ENTRY cl_kernel CL_API_CALL
clCreateKernel(cl_program program, const char *kernel_name,
               cl_int *errcode_ret) {
  CL_FORWARD_OR_NULL(clCreateKernel, errcode_ret);
  return g_cl.clCreateKernel(program, kernel_name, errcode_ret);
}

CL_API_ENTRY cl_int CL_API_CALL
clSetKernelArg(cl_kernel kernel, cl_uint arg_index, size_t arg_size,
               const void *arg_value) {
  CL_FORWARD_OR(clSetKernelArg, CL_INVALID_OPERATION);
  return g_cl.clSetKernelArg(kernel, arg_index, arg_size, arg_value);
}

CL_API_ENTRY cl_int CL_API_CALL
clGetKernelInfo(cl_kernel kernel, cl_kernel_info param_name,
                size_t param_value_size, void *param_value,
                size_t *param_value_size_ret) {
  CL_FORWARD_OR(clGetKernelInfo, CL_INVALID_OPERATION);
  return g_cl.clGetKernelInfo(kernel, param_name, param_value_size,
                              param_value, param_value_size_ret);
}

CL_API_ENTRY cl_int CL_API_CALL
clGetKernelWorkGroupInfo(cl_kernel kernel, cl_device_id device,
                         cl_kernel_work_group_info param_name,
                         size_t param_value_size, void *param_value,
                         size_t *param_value_size_ret) {
  CL_FORWARD_OR(clGetKernelWorkGroupInfo, CL_INVALID_OPERATION);
  return g_cl.clGetKernelWorkGroupInfo(kernel, device, param_name,
                                       param_value_size, param_value,
                                       param_value_size_ret);
}

CL_API_ENTRY cl_int CL_API_CALL
clGetKernelSubGroupInfo(cl_kernel kernel, cl_device_id device,
                        cl_kernel_sub_group_info param_name,
                        size_t input_value_size, const void *input_value,
                        size_t param_value_size, void *param_value,
                        size_t *param_value_size_ret) {
  CL_FORWARD_OR(clGetKernelSubGroupInfo, CL_INVALID_OPERATION);
  return g_cl.clGetKernelSubGroupInfo(kernel, device, param_name,
                                      input_value_size, input_value,
                                      param_value_size, param_value,
                                      param_value_size_ret);
}

// ── Enqueue ─────────────────────────────────────────────────────────────────

CL_API_ENTRY cl_int CL_API_CALL
clEnqueueNDRangeKernel(cl_command_queue command_queue, cl_kernel kernel,
                       cl_uint work_dim, const size_t *global_work_offset,
                       const size_t *global_work_size,
                       const size_t *local_work_size,
                       cl_uint num_events_in_wait_list,
                       const cl_event *event_wait_list, cl_event *event) {
  CL_FORWARD_OR(clEnqueueNDRangeKernel, CL_INVALID_OPERATION);
  return g_cl.clEnqueueNDRangeKernel(command_queue, kernel, work_dim,
                                     global_work_offset, global_work_size,
                                     local_work_size, num_events_in_wait_list,
                                     event_wait_list, event);
}

CL_API_ENTRY cl_int CL_API_CALL
clEnqueueReadBuffer(cl_command_queue command_queue, cl_mem buffer,
                    cl_bool blocking_read, size_t offset, size_t size,
                    void *ptr, cl_uint num_events_in_wait_list,
                    const cl_event *event_wait_list, cl_event *event) {
  CL_FORWARD_OR(clEnqueueReadBuffer, CL_INVALID_OPERATION);
  return g_cl.clEnqueueReadBuffer(command_queue, buffer, blocking_read, offset,
                                  size, ptr, num_events_in_wait_list,
                                  event_wait_list, event);
}

CL_API_ENTRY cl_int CL_API_CALL
clEnqueueWriteBuffer(cl_command_queue command_queue, cl_mem buffer,
                     cl_bool blocking_write, size_t offset, size_t size,
                     const void *ptr, cl_uint num_events_in_wait_list,
                     const cl_event *event_wait_list, cl_event *event) {
  CL_FORWARD_OR(clEnqueueWriteBuffer, CL_INVALID_OPERATION);
  return g_cl.clEnqueueWriteBuffer(command_queue, buffer, blocking_write,
                                   offset, size, ptr, num_events_in_wait_list,
                                   event_wait_list, event);
}

CL_API_ENTRY cl_int CL_API_CALL
clEnqueueCopyBuffer(cl_command_queue command_queue, cl_mem src_buffer,
                    cl_mem dst_buffer, size_t src_offset, size_t dst_offset,
                    size_t size, cl_uint num_events_in_wait_list,
                    const cl_event *event_wait_list, cl_event *event) {
  CL_FORWARD_OR(clEnqueueCopyBuffer, CL_INVALID_OPERATION);
  return g_cl.clEnqueueCopyBuffer(command_queue, src_buffer, dst_buffer,
                                  src_offset, dst_offset, size,
                                  num_events_in_wait_list, event_wait_list,
                                  event);
}

CL_API_ENTRY cl_int CL_API_CALL
clEnqueueFillBuffer(cl_command_queue command_queue, cl_mem buffer,
                    const void *pattern, size_t pattern_size, size_t offset,
                    size_t size, cl_uint num_events_in_wait_list,
                    const cl_event *event_wait_list, cl_event *event) {
  CL_FORWARD_OR(clEnqueueFillBuffer, CL_INVALID_OPERATION);
  return g_cl.clEnqueueFillBuffer(command_queue, buffer, pattern, pattern_size,
                                  offset, size, num_events_in_wait_list,
                                  event_wait_list, event);
}

CL_API_ENTRY cl_int CL_API_CALL
clEnqueueBarrierWithWaitList(cl_command_queue command_queue,
                             cl_uint num_events_in_wait_list,
                             const cl_event *event_wait_list,
                             cl_event *event) {
  CL_FORWARD_OR(clEnqueueBarrierWithWaitList, CL_INVALID_OPERATION);
  return g_cl.clEnqueueBarrierWithWaitList(
      command_queue, num_events_in_wait_list, event_wait_list, event);
}

CL_API_ENTRY cl_int CL_API_CALL
clEnqueueMarkerWithWaitList(cl_command_queue command_queue,
                            cl_uint num_events_in_wait_list,
                            const cl_event *event_wait_list, cl_event *event) {
  CL_FORWARD_OR(clEnqueueMarkerWithWaitList, CL_INVALID_OPERATION);
  return g_cl.clEnqueueMarkerWithWaitList(
      command_queue, num_events_in_wait_list, event_wait_list, event);
}

// ── Events ──────────────────────────────────────────────────────────────────

CL_API_ENTRY cl_int CL_API_CALL
clWaitForEvents(cl_uint num_events, const cl_event *event_list) {
  CL_FORWARD_OR(clWaitForEvents, CL_INVALID_OPERATION);
  return g_cl.clWaitForEvents(num_events, event_list);
}

CL_API_ENTRY cl_int CL_API_CALL
clGetEventProfilingInfo(cl_event event, cl_profiling_info param_name,
                        size_t param_value_size, void *param_value,
                        size_t *param_value_size_ret) {
  CL_FORWARD_OR(clGetEventProfilingInfo, CL_INVALID_OPERATION);
  return g_cl.clGetEventProfilingInfo(event, param_name, param_value_size,
                                      param_value, param_value_size_ret);
}

CL_API_ENTRY cl_int CL_API_CALL clReleaseEvent(cl_event event) {
  CL_FORWARD_OR(clReleaseEvent, CL_INVALID_OPERATION);
  return g_cl.clReleaseEvent(event);
}
