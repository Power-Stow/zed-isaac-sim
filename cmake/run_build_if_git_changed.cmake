if(NOT DEFINED ZED_SOURCE_DIR)
    message(FATAL_ERROR "ZED_SOURCE_DIR is required")
endif()

if(NOT DEFINED ZED_BUILD_SCRIPT)
    message(FATAL_ERROR "ZED_BUILD_SCRIPT is required")
endif()

if(NOT DEFINED ZED_STATE_FILE)
    message(FATAL_ERROR "ZED_STATE_FILE is required")
endif()

if(NOT DEFINED ZED_CONFIG_SOURCE_DIR)
    message(FATAL_ERROR "ZED_CONFIG_SOURCE_DIR is required")
endif()

if(NOT DEFINED ZED_CONFIG_DEST_DIR)
    message(FATAL_ERROR "ZED_CONFIG_DEST_DIR is required")
endif()

if(NOT EXISTS "${ZED_BUILD_SCRIPT}")
    message(FATAL_ERROR "Build script not found: ${ZED_BUILD_SCRIPT}")
endif()

if(NOT IS_DIRECTORY "${ZED_CONFIG_SOURCE_DIR}")
    message(FATAL_ERROR "Config source directory not found: ${ZED_CONFIG_SOURCE_DIR}")
endif()

find_program(GIT_EXECUTABLE git)
if(NOT GIT_EXECUTABLE)
    message(FATAL_ERROR "git executable not found")
endif()

execute_process(
    COMMAND "${GIT_EXECUTABLE}" -C "${ZED_SOURCE_DIR}" rev-parse HEAD
    RESULT_VARIABLE HEAD_RESULT
    OUTPUT_VARIABLE HEAD_HASH
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_QUIET
)
if(NOT HEAD_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to resolve git HEAD in ${ZED_SOURCE_DIR}")
endif()

execute_process(
    COMMAND "${GIT_EXECUTABLE}" -C "${ZED_SOURCE_DIR}" diff --binary HEAD
    RESULT_VARIABLE DIFF_RESULT
    OUTPUT_VARIABLE TRACKED_DIFF_OUTPUT
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_QUIET
)
if(NOT DIFF_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to query tracked diff in ${ZED_SOURCE_DIR}")
endif()
string(SHA256 TRACKED_DIFF_HASH "${TRACKED_DIFF_OUTPUT}")

execute_process(
    COMMAND "${GIT_EXECUTABLE}" -C "${ZED_SOURCE_DIR}" ls-files --others --exclude-standard
    RESULT_VARIABLE UNTRACKED_LIST_RESULT
    OUTPUT_VARIABLE UNTRACKED_FILES_OUTPUT
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_QUIET
)
if(NOT UNTRACKED_LIST_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to query untracked files in ${ZED_SOURCE_DIR}")
endif()

set(UNTRACKED_FINGERPRINT "")
if(NOT UNTRACKED_FILES_OUTPUT STREQUAL "")
    string(REPLACE "\n" ";" UNTRACKED_FILES_LIST "${UNTRACKED_FILES_OUTPUT}")
    foreach(UNTRACKED_FILE IN LISTS UNTRACKED_FILES_LIST)
        execute_process(
            COMMAND "${GIT_EXECUTABLE}" -C "${ZED_SOURCE_DIR}" hash-object "${UNTRACKED_FILE}"
            RESULT_VARIABLE UNTRACKED_HASH_RESULT
            OUTPUT_VARIABLE UNTRACKED_FILE_HASH
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_QUIET
        )
        if(NOT UNTRACKED_HASH_RESULT EQUAL 0)
            message(FATAL_ERROR "Failed to hash untracked file: ${UNTRACKED_FILE}")
        endif()
        string(APPEND UNTRACKED_FINGERPRINT "${UNTRACKED_FILE}=${UNTRACKED_FILE_HASH}\n")
    endforeach()
endif()
string(SHA256 UNTRACKED_HASH "${UNTRACKED_FINGERPRINT}")

set(CURRENT_STATE "${HEAD_HASH}|${TRACKED_DIFF_HASH}|${UNTRACKED_HASH}")
set(PREVIOUS_STATE "")
if(EXISTS "${ZED_STATE_FILE}")
    file(READ "${ZED_STATE_FILE}" PREVIOUS_STATE)
    string(STRIP "${PREVIOUS_STATE}" PREVIOUS_STATE)
endif()

if(CURRENT_STATE STREQUAL PREVIOUS_STATE)
    message(STATUS "zed-isaac-sim unchanged (${CURRENT_STATE}); skipping build.sh")
else()
    message(STATUS "zed-isaac-sim changed (${PREVIOUS_STATE} -> ${CURRENT_STATE}); running build.sh")

    execute_process(
        COMMAND "${ZED_BUILD_SCRIPT}"
        WORKING_DIRECTORY "${ZED_SOURCE_DIR}"
        RESULT_VARIABLE BUILD_RESULT
    )
    if(NOT BUILD_RESULT EQUAL 0)
        message(FATAL_ERROR "zed-isaac-sim build.sh failed with exit code ${BUILD_RESULT}")
    endif()

    file(WRITE "${ZED_STATE_FILE}" "${CURRENT_STATE}\n")
endif()

file(MAKE_DIRECTORY "${ZED_CONFIG_DEST_DIR}")
file(GLOB ZED_CONFIG_FILES "${ZED_CONFIG_SOURCE_DIR}/*.conf")
if(ZED_CONFIG_FILES)
    file(COPY ${ZED_CONFIG_FILES} DESTINATION "${ZED_CONFIG_DEST_DIR}")
    message(STATUS "Synced ZED config files to ${ZED_CONFIG_DEST_DIR}")
else()
    message(WARNING "No .conf files found in ${ZED_CONFIG_SOURCE_DIR}")
endif()
