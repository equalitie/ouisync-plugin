cmake_minimum_required(VERSION 3.16.0)

get_filename_component(ROOT_DIR ../ ABSOLUTE)

set (SOURCE_DIR ${ROOT_DIR}/ios/Classes)
set (CALLBACK_MANAGER_DIR ${ROOT_DIR}/ios/Classes/Shared)
set (NATIVE_DIR ${ROOT_DIR}/ios/ouisync/src)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fcoroutines-ts -stdlib=libc++ -std=c++17")

add_subdirectory(
    ${ROOT_DIR}/ios/ouisync ${ROOT_DIR}/ios/ouisync_bin
)

add_library( 
    native_ouisync

    SHARED
    
    ${CALLBACK_MANAGER_DIR}/CallbackManager.h
    ${CALLBACK_MANAGER_DIR}/CallbackManager.cpp

    ${SOURCE_DIR}/localRepository.cpp
)

target_include_directories(native_ouisync PUBLIC ${CALLBACK_MANAGER_DIR} ${NATIVE_DIR})
target_link_libraries(native_ouisync PUBLIC libouisync)