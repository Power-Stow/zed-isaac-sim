cmake_minimum_required(VERSION 3.10.2)

project(zed_isaac_sim)

find_package(ament_cmake REQUIRED)

set(ZED_BUILD_SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/build.sh")
set(ZED_BUILD_STAMP "${CMAKE_CURRENT_BINARY_DIR}/zed_isaac_sim_build.stamp")

if(NOT EXISTS "${ZED_BUILD_SCRIPT}")
    message(FATAL_ERROR "Expected build script not found: ${ZED_BUILD_SCRIPT}")
endif()

add_custom_command(OUTPUT "${ZED_BUILD_STAMP}"
                   COMMAND "${ZED_BUILD_SCRIPT}"
                   COMMAND "${CMAKE_COMMAND}" -E touch "${ZED_BUILD_STAMP}"
                   WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
                   COMMENT "Building zed-isaac-sim via build.sh"
                   VERBATIM
)

add_custom_target(build_zed_isaac_sim ALL DEPENDS "${ZED_BUILD_STAMP}")

install(FILES package.xml DESTINATION share/${PROJECT_NAME})

ament_package()
