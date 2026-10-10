# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(fllama_library VERSION 0.0.1 LANGUAGES CXX)

# Include build info generation
include("${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp/cmake/build-info.cmake")


set(BUILD_SHARED_LIBS OFF)

# Otherwise ex. Android build on macOS fails with `error: unknown target CPU 'cyclone'`
set(LLAMA_NATIVE OFF CACHE BOOL "llama: disable -march=native flag" FORCE)

# Disable HTTP/CURL support on all platforms (we handle model downloads in Dart, not C++)
set(LLAMA_HTTPLIB OFF CACHE BOOL "Disable httplib for downloading" FORCE)
set(LLAMA_CURL OFF CACHE BOOL "Disable CURL (deprecated)" FORCE)
set(LLAMA_BUILD_SERVER OFF CACHE BOOL "Disable server (requires httplib)" FORCE)
set(LLAMA_BUILD_TESTS OFF CACHE BOOL "Disable tests" FORCE)
set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "Disable examples" FORCE)

if(ANDROID)
    # Debug: Print build information for Android
    message(STATUS "Android build detected")
    message(STATUS "CMAKE_ANDROID_ARCH_ABI: ${CMAKE_ANDROID_ARCH_ABI}")
    message(STATUS "CMAKE_SYSTEM_PROCESSOR: ${CMAKE_SYSTEM_PROCESSOR}")
    
    # Android-specific settings for llama.cpp (apply to all Android builds)
    set(GGML_LLAMAFILE OFF CACHE BOOL "Disable llamafile for Android" FORCE)
    set(GGML_OPENMP OFF CACHE BOOL "Disable OpenMP for Android" FORCE)
    set(BUILD_SHARED_LIBS OFF CACHE BOOL "Use static libs for Android" FORCE)
    
    # Only apply ARM-specific optimizations for ARM64 builds
    if(CMAKE_ANDROID_ARCH_ABI STREQUAL "arm64-v8a" OR CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64|arm64")
        message(STATUS "ARM64 Android build - enabling dot product optimizations with KleiDiAI support")
        # ARMv8.2-A with dot product only (i8mm not supported on this device)
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -march=armv8.2-a+dotprod -O3")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=armv8.2-a+dotprod -O3")
        
        # Enable KleiDiAI ONLY for ARM64 builds (it's ARM64-specific)
        # Disabled: it requires CMake 4.0+ and src/CMakeLists.txt (via flutter template)
        # strongly suggests not going over 3.22, i.e. what is required for Flutter.
        # Because KleidiAI showed a small lift on performance (well within variation, 3-5%) 
        # for Android CPU on Pixel Fold, it is better to disable it for now. It is also
        # worth leaving here as ersatz documentation of how to get it working.
        # set(GGML_CPU_KLEIDIAI ON CACHE BOOL "Enable KleiDiAI optimizations" FORCE)
    else()
        message(STATUS "Non-ARM64 Android build (${CMAKE_ANDROID_ARCH_ABI}) - skipping ARM optimizations")
        # Explicitly disable KleiDiAI for non-ARM64 architectures
        # set(GGML_CPU_KLEIDIAI OFF CACHE BOOL "Disable KleiDiAI for non-ARM64" FORCE)
    endif()

    # ── GPU backends: Vulkan + OpenCL (arm64 only, opt-in at runtime) ──────
    # Both backends are compiled in, but neither is registered with ggml at
    # startup (FLLAMA_LAZY_GPU_REG, see ggml-backend-reg.cpp and fllama.cpp):
    # a request has to ask for one via fllama_inference_request.gpu_backend,
    # so CPU-only users never load a vendor GPU driver.
    #
    # Restricted to arm64-v8a: every real phone the app targets is arm64, and
    # the Vulkan shader build is the slowest part of the native build, so the
    # emulator / 32-bit ABIs stay CPU-only.
    option(FLLAMA_ANDROID_GPU "fllama: build Vulkan and OpenCL backends on Android arm64" ON)
    if(FLLAMA_ANDROID_GPU AND (CMAKE_ANDROID_ARCH_ABI STREQUAL "arm64-v8a" OR ANDROID_ABI STREQUAL "arm64-v8a"))
        message(STATUS "fllama: Android GPU backends enabled (Vulkan, OpenCL)")
        add_compile_definitions(FLLAMA_LAZY_GPU_REG)

        # NDK root, whichever NDK the toolchain file came from.
        if(ANDROID_NDK)
            set(FLLAMA_NDK "${ANDROID_NDK}")
        elseif(CMAKE_ANDROID_NDK)
            set(FLLAMA_NDK "${CMAKE_ANDROID_NDK}")
        else()
            message(FATAL_ERROR "fllama: cannot locate the Android NDK (neither ANDROID_NDK nor CMAKE_ANDROID_NDK is set)")
        endif()

        # glslc ships with the NDK under shader-tools/<host-tag>/ (darwin-x86_64,
        # linux-x86_64, windows-x86_64). It compiles the Vulkan shaders at
        # build time; without it there is no Vulkan backend, so fail loudly.
        if(NOT Vulkan_GLSLC_EXECUTABLE)
            file(GLOB FLLAMA_GLSLC_CANDIDATES
                "${FLLAMA_NDK}/shader-tools/*/glslc"
                "${FLLAMA_NDK}/shader-tools/*/glslc.exe")
            list(LENGTH FLLAMA_GLSLC_CANDIDATES FLLAMA_GLSLC_COUNT)
            if(FLLAMA_GLSLC_COUNT EQUAL 0)
                message(FATAL_ERROR
                    "fllama: glslc not found under ${FLLAMA_NDK}/shader-tools/*/.\n"
                    "The Vulkan backend needs it to compile shaders. Install a complete "
                    "NDK (r23+) or pass -DVulkan_GLSLC_EXECUTABLE=/path/to/glslc. To build "
                    "without GPU backends instead, pass -DFLLAMA_ANDROID_GPU=OFF.")
            endif()
            list(GET FLLAMA_GLSLC_CANDIDATES 0 FLLAMA_GLSLC)
            set(Vulkan_GLSLC_EXECUTABLE "${FLLAMA_GLSLC}" CACHE FILEPATH "glslc for Vulkan shaders" FORCE)
        endif()
        message(STATUS "fllama: glslc = ${Vulkan_GLSLC_EXECUTABLE}")

        # The NDK sysroot has vulkan_core.h but not the C++ vulkan.hpp that
        # ggml-vulkan needs (and its C headers are older than ggml-vulkan
        # expects), so headers come from the vendored Khronos Vulkan-Headers.
        # They are only headers: the loader is the platform's libvulkan.so.
        set(Vulkan_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/third_party/Vulkan-Headers/include" CACHE PATH "Vulkan headers" FORCE)

        # libvulkan.so link stub from the NDK sysroot. It exists from API 24 on
        # (the app's minSdk); fall back to 24 if the configured level has none.
        if(NOT Vulkan_LIBRARY)
            file(GLOB FLLAMA_NDK_SYSROOTS "${FLLAMA_NDK}/toolchains/llvm/prebuilt/*/sysroot")
            list(GET FLLAMA_NDK_SYSROOTS 0 FLLAMA_NDK_SYSROOT)
            set(FLLAMA_NDK_LIBDIR "${FLLAMA_NDK_SYSROOT}/usr/lib/aarch64-linux-android")
            set(FLLAMA_VK_API "${ANDROID_PLATFORM_LEVEL}")
            if(NOT FLLAMA_VK_API OR NOT EXISTS "${FLLAMA_NDK_LIBDIR}/${FLLAMA_VK_API}/libvulkan.so")
                set(FLLAMA_VK_API 24)
            endif()
            if(NOT EXISTS "${FLLAMA_NDK_LIBDIR}/${FLLAMA_VK_API}/libvulkan.so")
                message(FATAL_ERROR "fllama: libvulkan.so not found in ${FLLAMA_NDK_LIBDIR}/${FLLAMA_VK_API}/")
            endif()
            set(Vulkan_LIBRARY "${FLLAMA_NDK_LIBDIR}/${FLLAMA_VK_API}/libvulkan.so" CACHE FILEPATH "Vulkan loader stub" FORCE)
        endif()
        message(STATUS "fllama: Vulkan_LIBRARY = ${Vulkan_LIBRARY}")

        set(GGML_VULKAN ON CACHE BOOL "ggml: use Vulkan" FORCE)

        # OpenCL: Adreno-tuned kernels embedded in the binary. libOpenCL.so is a
        # vendor library that many phones lack, so it is never linked directly;
        # ggml-opencl links opencl_shim.c, which dlopens it on first use (see
        # llama.cpp/ggml/src/ggml-opencl/CMakeLists.txt).
        set(GGML_OPENCL ON CACHE BOOL "ggml: use OpenCL" FORCE)
        set(GGML_OPENCL_EMBED_KERNELS ON CACHE BOOL "ggml: embed kernels" FORCE)
        set(GGML_OPENCL_USE_ADRENO_KERNELS ON CACHE BOOL "ggml: use optimized kernels for Adreno" FORCE)
        set(FLLAMA_OPENCL_SHIM ON)
        set(FLLAMA_OPENCL_SHIM_SOURCE "${CMAKE_CURRENT_SOURCE_DIR}/opencl_shim.c")
        set(FLLAMA_OPENCL_HEADERS_DIR "${CMAKE_CURRENT_SOURCE_DIR}/third_party/OpenCL-Headers")
    endif()
endif()

if(WIN32 AND NOT ANDROID)
  set(GGML_VULKAN ON CACHE BOOL "ggml: use Vulkan" FORCE)
  message(STATUS "Windows detected, enabling GGML_VULKAN")
endif()

if(APPLE)
  # Metal GPU acceleration — previously set by podspec/shell scripts.
  # Now handled here so the CMake build is self-contained.
  set(GGML_METAL ON CACHE BOOL "Enable Metal" FORCE)
  set(GGML_METAL_EMBED_LIBRARY ON CACHE BOOL "Embed Metal shader library" FORCE)
endif()

# Provide a fallback version so mtmd's set_target_properties(VERSION ...)
# doesn't fail when there is no git history (e.g. copied source tree).
if(NOT DEFINED LLAMA_INSTALL_VERSION OR LLAMA_INSTALL_VERSION STREQUAL "")
  set(LLAMA_INSTALL_VERSION "0.0.0")
endif()

add_subdirectory("llama.cpp")
add_subdirectory("llama.cpp/common")
add_subdirectory("llama.cpp/tools/mtmd")

# Build the server-context library directly from source files.
# We cannot use add_subdirectory(tools/server) because it also defines the
# llama-server executable which requires cpp-httplib (which we don't ship).
find_package(Threads REQUIRED)
set(SERVER_SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp/tools/server")
add_library(server-context STATIC
  ${SERVER_SRC_DIR}/server-task.cpp
  ${SERVER_SRC_DIR}/server-queue.cpp
  ${SERVER_SRC_DIR}/server-common.cpp
  ${SERVER_SRC_DIR}/server-context.cpp
)
target_include_directories(server-context PUBLIC  ${SERVER_SRC_DIR})
target_include_directories(server-context PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp/tools/mtmd
  ${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp
)
if (BUILD_SHARED_LIBS)
  set_target_properties(server-context PROPERTIES POSITION_INDEPENDENT_CODE ON)
endif()
target_link_libraries(server-context PUBLIC common mtmd ${CMAKE_THREAD_LIBS_INIT})

add_library(fllama SHARED
  "fllama_chat_template.cpp"
  "fllama_download_stub.cpp"
  "fllama_embed.cpp"
  "fllama_eos.cpp"
  "fllama_inference_queue.cpp"
  "fllama_mtmd.cpp"
  "fllama_tokenize.cpp"
  "fllama.cpp"
)

set_target_properties(fllama PROPERTIES
  PUBLIC_HEADER "fllama.h;fllama_embed.h;fllama_eos.h;fllama_tokenize.h"
  OUTPUT_NAME "fllama"
)

target_compile_definitions(fllama PUBLIC DART_SHARED_LIB)

if (ANDROID)
  # Support Android 15 16k page size.
  target_link_options(fllama PRIVATE "-Wl,-z,max-page-size=16384")
endif()
target_include_directories(fllama PUBLIC .)
target_link_libraries(fllama PUBLIC llama common mtmd server-context)

# Apple: link system frameworks for Metal, Accelerate, etc.
# These are needed because we statically link ggml-metal into this shared lib.
if(APPLE)
  find_library(FOUNDATION_LIBRARY Foundation REQUIRED)
  find_library(METAL_LIBRARY Metal REQUIRED)
  find_library(METALKIT_LIBRARY MetalKit REQUIRED)
  find_library(ACCELERATE_LIBRARY Accelerate REQUIRED)
  target_link_libraries(fllama PUBLIC
    ${FOUNDATION_LIBRARY}
    ${METAL_LIBRARY}
    ${METALKIT_LIBRARY}
    ${ACCELERATE_LIBRARY}
  )
endif()

if(ANDROID)
    find_library(LOG_LIB log) # Find the log library
    target_link_libraries(fllama PUBLIC
      ${LOG_LIB} # Add this to link against the log library for Android
    )
endif()
