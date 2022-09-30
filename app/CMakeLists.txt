cmake_minimum_required(VERSION 2.8)

project(teknoir-app)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

include(CheckCXXCompilerFlag)

function(enable_cxx_compiler_flag_if_supported flag)
    string(FIND "${CMAKE_CXX_FLAGS}" "${flag}" flag_already_set)
  if(flag_already_set EQUAL -1)
   check_cxx_compiler_flag("${flag}" flag_supported)
   if(flag_supported)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${flag}" PARENT_SCOPE)
   endif()
   unset(flag_supported CACHE)
  endif()
endfunction()

enable_cxx_compiler_flag_if_supported("-Wall")
enable_cxx_compiler_flag_if_supported("-Wextra")
enable_cxx_compiler_flag_if_supported("-pedantic")
enable_cxx_compiler_flag_if_supported("-fpermissive")

include_directories(include)
add_subdirectory(src)

enable_cxx_compiler_flag_if_supported("-O2")
enable_cxx_compiler_flag_if_supported("D_NDEBUG")

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
find_package(Threads REQUIRED)
find_package(OpenSSL REQUIRED)
find_package(PahoMqttC REQUIRED)
find_package(PahoMqttCpp REQUIRED)
