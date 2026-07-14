cmake_minimum_required(VERSION 3.18)
project(llama_jni)

include(FetchContent)

# Automatically download llama.cpp at build time
FetchContent_Declare(
  llama
  GIT_REPOSITORY https://github.com/ggml-org/llama.cpp.git
  GIT_TAG f643120bad8ab3a753daa64aaac8288ee5800e06
)

# Disable llama.cpp features we don't need for mobile to speed up compilation
set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_SERVER OFF CACHE BOOL "" FORCE)
set(BUILD_SHARED_LIBS ON CACHE BOOL "" FORCE)

FetchContent_MakeAvailable(llama)

# Create JNI bridge library
add_library(llama_jni SHARED llama_jni.cpp)

# Include directories (FetchContent stores the source in llama_SOURCE_DIR)
target_include_directories(llama_jni PRIVATE
    ${llama_SOURCE_DIR}/include
    ${llama_SOURCE_DIR}/src
    ${llama_SOURCE_DIR}/ggml/include
)

# Link with llama library and android logging libraries
target_link_libraries(llama_jni
    llama
    log
    android
)
