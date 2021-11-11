MESSAGE("PCRE2_INSTALL_DIR: " $ENV{PCRE2_INSTALL_DIR})
find_library(PCRE2_LIBRARIES NAMES pcre2 pcre2-8 pcre2d pcre2-8d PATHS "$ENV{PCRE2_INSTALL_DIR}/lib")
find_library(PCRE2_POSIX_LIBRARIES NAMES pcre2-posix pcre2-posix-8 pcre2-posixd pcre2-posix-8d PATHS "$ENV{PCRE2_INSTALL_DIR}/lib")
find_path(PCRE2_INCLUDE_DIRS pcre2.h PATHS "$ENV{PCRE2_INSTALL_DIR}/include")
if(PCRE2_LIBRARIES AND PCRE2_INCLUDE_DIRS)
  message(STATUS "PCRE2 libs: ${PCRE2_LIBRARIES}")
  message(STATUS "PCRE2 posix libs: ${PCRE2_POSIX_LIBRARIES}")
  message(STATUS "PCRE2 include directory: ${PCRE2_INCLUDE_DIRS}")
  set(PCRE2_FOUND TRUE CACHE BOOL "Found PCRE2 libraries" FORCE)

  add_library(pcre2-8 UNKNOWN IMPORTED)
  set_target_properties(pcre2-8 PROPERTIES
          IMPORTED_LOCATION "${PCRE2_LIBRARIES}"
          INTERFACE_INCLUDE_DIRECTORIES "${PCRE2_INCLUDE_DIRS}"
  )

  add_library(pcre2-posix UNKNOWN IMPORTED)
  set_target_properties(pcre2-posix PROPERTIES
          IMPORTED_LOCATION "${PCRE2_POSIX_LIBRARIES}"
          INTERFACE_INCLUDE_DIRECTORIES "${PCRE2_INCLUDE_DIRS}"
  )
else()
  message(STATUS "PCRE2 library not found, building from source")
  add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/pcre2)
#  print_target_properties(pcre2-8)
#  install_target_libs(pcre2-8)
#  install_target_libs(pcre2-posix)
  list(APPEND targets pcre2-8 pcre2-posix)
  set(PCRE2_FOUND TRUE CACHE BOOL "Found PCRE2 libraries" FORCE)
endif()
