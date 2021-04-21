cmake_minimum_required(VERSION 3.16.0)

add_library( 
    native_ouisync
    SHARED
    ../ios/Classes/localRepository.cpp
)