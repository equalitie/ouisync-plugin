cmake_minimum_required(VERSION 3.16.0)

get_filename_component(ROOT_DIR ../ ABSOLUTE)

set (SOURCE_DIR ${ROOT_DIR}/ios/Classes)
set (CALLBACK_MANAGER_DIR ${ROOT_DIR}/ios/Classes/Shared)

add_library( 
    native_ouisync

    SHARED
    
    ${CALLBACK_MANAGER_DIR}/CallbackManager.h
    ${CALLBACK_MANAGER_DIR}/CallbackManager.cpp

    ${SOURCE_DIR}/localRepository.cpp
)

target_include_directories(native_ouisync PUBLIC ${CALLBACK_MANAGER_DIR})

find_library( # Sets the name of the path variable.
          android-lib

          # Specifies the name of the NDK library that
          # you want CMake to locate.
          android )

target_link_libraries(native_ouisync log)
target_link_libraries(native_ouisync ${android-lib})