cmake_minimum_required(VERSION 3.10.2)

project(zed_isaac_sim)

find_package(ament_cmake REQUIRED)

set(ZED_BUILD_SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/build.sh")
set(ZED_BUILD_HELPER_SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/cmake/run_build_if_git_changed.cmake")
set(ZED_BUILD_STATE_FILE "${CMAKE_CURRENT_BINARY_DIR}/zed_isaac_sim_build_state.txt")
set(ZED_CONFIG_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/exts/sl.sensor.camera/data/config")
set(ZED_CONFIG_DEST_DIR "/usr/local/zed/settings")

if(NOT EXISTS "${ZED_BUILD_SCRIPT}")
    message(FATAL_ERROR "Expected build script not found: ${ZED_BUILD_SCRIPT}")
endif()

if(NOT EXISTS "${ZED_BUILD_HELPER_SCRIPT}")
    message(FATAL_ERROR "Expected helper script not found: ${ZED_BUILD_HELPER_SCRIPT}")
endif()

add_custom_target(build_zed_isaac_sim ALL
                  COMMAND "${CMAKE_COMMAND}"
                          -DZED_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
                          -DZED_BUILD_SCRIPT=${ZED_BUILD_SCRIPT}
                          -DZED_STATE_FILE=${ZED_BUILD_STATE_FILE}
                          -DZED_CONFIG_SOURCE_DIR=${ZED_CONFIG_SOURCE_DIR}
                          -DZED_CONFIG_DEST_DIR=${ZED_CONFIG_DEST_DIR}
                          -P "${ZED_BUILD_HELPER_SCRIPT}"
                  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
                  COMMENT "Conditionally building zed-isaac-sim via build.sh when git state changes"
                  VERBATIM
)

install(FILES package.xml DESTINATION share/${PROJECT_NAME})

ament_package()
