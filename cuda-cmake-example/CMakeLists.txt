cmake_minimum_required(VERSION 3.6)

project(CUDACMAKETEST)

find_package(CUDA)

if (CUDA_FOUND)
  message("CUDA found, using device squaring!")
  add_subdirectory(src.gpu)
else()
  message("CUDA not found, doing something alternatively")
  # add_subdirectory(src.cpu)
endif()

set(CMAKE_CXX_FLAG "-g -Wall")
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)