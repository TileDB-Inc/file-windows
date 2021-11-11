cmake_minimum_required(VERSION 3.7)

INCLUDE(CheckIncludeFile)

project(file)


# Get library directory for multiarch linux distros
include(GNUInstallDirs)

#
# Stores the IMPORTED_LOCATION* target property of LIB_TARGET in RESULT_VAR.
# On Windows, preferentially tries the IMPORTED_IMPLIB* target property instead.
#
function(get_imported_location RESULT_VAR LIB_TARGET)
  if (WIN32)
    # Try several methods to find the imported location.
    get_target_property(TMP ${LIB_TARGET} IMPORTED_IMPLIB)
    if (TMP MATCHES "NOTFOUND")
      get_target_property(TMP ${LIB_TARGET} IMPORTED_IMPLIB_RELWITHDEBINFO)
    endif()
    if (TMP MATCHES "NOTFOUND")
      get_target_property(TMP ${LIB_TARGET} IMPORTED_IMPLIB_RELEASE)
    endif()
    if (TMP MATCHES "NOTFOUND")
      get_target_property(TMP ${LIB_TARGET} IMPORTED_IMPLIB_DEBUG)
    endif()
  endif()
  # Try several methods to find the imported location.
  if (TMP MATCHES "NOTFOUND" OR NOT WIN32)
    get_target_property(TMP ${LIB_TARGET} IMPORTED_LOCATION)
  endif()
  if (TMP MATCHES "NOTFOUND")
    get_target_property(TMP ${LIB_TARGET} IMPORTED_LOCATION_RELWITHDEBINFO)
  endif()
  if (TMP MATCHES "NOTFOUND")
    get_target_property(TMP ${LIB_TARGET} IMPORTED_LOCATION_RELEASE)
  endif()
  if (TMP MATCHES "NOTFOUND")
    get_target_property(TMP ${LIB_TARGET} IMPORTED_LOCATION_DEBUG)
  endif()
  set(${RESULT_VAR} "${TMP}" PARENT_SCOPE)
endfunction()

#
# Adds imported libraries from the given target to the TileDB installation
# manifest.
#
function(install_target_libs LIB_TARGET)
  get_imported_location(TARGET_LIBRARIES ${LIB_TARGET})
  if (TARGET_LIBRARIES MATCHES "NOTFOUND")
    message(FATAL_ERROR "Could not determine library location for ${LIB_TARGET}")
  endif()
  if (WIN32 AND ${TARGET_LIBRARIES} MATCHES "${CMAKE_SHARED_LIBRARY_SUFFIX}$")
    install(FILES ${TARGET_LIBRARIES} DESTINATION ${CMAKE_INSTALL_BINDIR})
  else()
    install(FILES ${TARGET_LIBRARIES} DESTINATION ${CMAKE_INSTALL_LIBDIR})
  endif()
endfunction()

function(cat IN_FILE OUT_FILE)
  file(READ ${IN_FILE} CONTENTS)
  file(APPEND ${OUT_FILE} "${CONTENTS}")
endfunction()

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/Modules")
find_package(pcre2 REQUIRED)

option(BUILD_SHARED_LIBS "build as shared library" ON)

set(LIBMAGIC_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/file/src")
set(LIBMAGIC_TEST_DIR "${CMAKE_CURRENT_SOURCE_DIR}/file/tests")
set(WIN_HEADERS_DIR "${CMAKE_CURRENT_SOURCE_DIR}/win-headers")
set(PCRE2_LIB_DIR "${CMAKE_CURRENT_SOURCE_DIR}/pcre2/install_dir/lib")

set(FILE_VERSION 5.39)

set(WIN_COMPAT_SOURCES 
  ${LIBMAGIC_SOURCE_DIR}/asctime_r.c
  ${LIBMAGIC_SOURCE_DIR}/asprintf.c
  ${LIBMAGIC_SOURCE_DIR}/ctime_r.c
  ${LIBMAGIC_SOURCE_DIR}/dprintf.c
  ${LIBMAGIC_SOURCE_DIR}/getline.c
  ${LIBMAGIC_SOURCE_DIR}/gmtime_r.c
  ${LIBMAGIC_SOURCE_DIR}/localtime_r.c
  ${LIBMAGIC_SOURCE_DIR}/pread.c
  ${LIBMAGIC_SOURCE_DIR}/strcasestr.c
  ${LIBMAGIC_SOURCE_DIR}/strlcat.c
  ${LIBMAGIC_SOURCE_DIR}/strlcpy.c
  ${LIBMAGIC_SOURCE_DIR}/vasprintf.c
  ${LIBMAGIC_SOURCE_DIR}/fmtcheck.c
  ${WIN_HEADERS_DIR}/magic.def
)

set(LIBMAGIC_SOURCE_FILES
  ${WIN_COMPAT_SOURCES}
  ${LIBMAGIC_SOURCE_DIR}/apprentice.c
  ${LIBMAGIC_SOURCE_DIR}/apptype.c
  ${LIBMAGIC_SOURCE_DIR}/ascmagic.c
  ${LIBMAGIC_SOURCE_DIR}/buffer.c
  ${LIBMAGIC_SOURCE_DIR}/cdf.c
  ${LIBMAGIC_SOURCE_DIR}/cdf_time.c
  ${LIBMAGIC_SOURCE_DIR}/compress.c
  ${LIBMAGIC_SOURCE_DIR}/der.c
  ${LIBMAGIC_SOURCE_DIR}/encoding.c
  ${LIBMAGIC_SOURCE_DIR}/fsmagic.c
  ${LIBMAGIC_SOURCE_DIR}/funcs.c
  ${LIBMAGIC_SOURCE_DIR}/is_json.c
  ${LIBMAGIC_SOURCE_DIR}/is_tar.c
  ${CMAKE_CURRENT_BINARY_DIR}/magic.c
  ${LIBMAGIC_SOURCE_DIR}/print.c
  ${LIBMAGIC_SOURCE_DIR}/readcdf.c
  ${CMAKE_CURRENT_BINARY_DIR}/readelf.c
  ${LIBMAGIC_SOURCE_DIR}/softmagic.c
  ${LIBMAGIC_SOURCE_DIR}/is_csv.c
)

# replace the version in the magic.h.in and write it to magic.h
FILE(READ ${LIBMAGIC_SOURCE_DIR}/magic.h.in MAGIC_H_CONTENT)
STRING(REPLACE "." "" FILE_VERSION_WITHOUT_DOT "${FILE_VERSION}")
STRING(REPLACE "X.YY" ${FILE_VERSION_WITHOUT_DOT} MAGIC_H_CONTENT_NEW "${MAGIC_H_CONTENT}")
FILE(WRITE ${LIBMAGIC_SOURCE_DIR}/magic.h "${MAGIC_H_CONTENT_NEW}")


FILE(READ ${LIBMAGIC_SOURCE_DIR}/readelf.c READELF_C_CONTENT)
STRING(CONCAT READELF_C_CONTENT_NEW "#include <dirent.h>\n" "${READELF_C_CONTENT}")
FILE(WRITE ${CMAKE_CURRENT_BINARY_DIR}/readelf.c "${READELF_C_CONTENT_NEW}")

FILE(READ ${LIBMAGIC_SOURCE_DIR}/magic.c MAGIC_C_CONTENT)
STRING(CONCAT MAGIC_C_CONTENT_NEW "#include <dirent.h>\n" "${MAGIC_C_CONTENT}")
FILE(WRITE ${CMAKE_CURRENT_BINARY_DIR}/magic.c "${MAGIC_C_CONTENT_NEW}")

FILE(READ ${LIBMAGIC_SOURCE_DIR}/file.h FILE_H_CONTENT)
STRING(CONCAT FILE_H_CONTENT_NEW "#ifdef WIN32\n#include <unistd.h>\n#include <dirent.h>\n#undef S_IFLNK\n#undef S_IFSOCK\n#endif\n" "${FILE_H_CONTENT}")
FILE(WRITE ${LIBMAGIC_SOURCE_DIR}/file.h "${FILE_H_CONTENT_NEW}")

add_definitions(-DHAVE_CONFIG_H -DVERSION="${FILE_VERSION}" -DWIN32_LEAN_AND_MEAN -DWIN32 -DPCRE2_STATIC )
#add_library(libmagic SHARED ${LIBMAGIC_SOURCE_FILES})
#include_directories (${WIN_HEADERS_DIR} pcre2/src ${LIBMAGIC_SOURCE_DIR} dirent/include getopt)
#target_link_libraries(libmagic pcre2-posix shlwapi)

if(BUILD_SHARED_LIBS)
  add_library(libmagic SHARED ${LIBMAGIC_SOURCE_FILES})
else()
  add_library(libmagic STATIC ${LIBMAGIC_SOURCE_FILES})
endif()
#include_directories (${WIN_HEADERS_DIR} ${PCRE2_INCLUDE_DIRS} ${LIBMAGIC_SOURCE_DIR} dirent/include getopt)
include_directories (${WIN_HEADERS_DIR} ${LIBMAGIC_SOURCE_DIR} dirent/include getopt)
#target_link_libraries(libmagic PRIVATE ${PCRE2_LIBRARIES} ${PCRE2_POSIX_LIBRARIES} shlwapi)
target_link_libraries(libmagic PRIVATE pcre2-posix pcre2-8 shlwapi)

target_include_directories(libmagic
        PUBLIC
        "$<BUILD_INTERFACE:${LIBMAGIC_SOURCE_DIR}>"
        "$<INSTALL_INTERFACE:include>"
)

# copy /pcre2posix.h to regex.h so it can be used as posix regex libary if regex.h does not exist
if (NOT PCRE2_INCLUDE_DIRS)
  GET_TARGET_PROPERTY(PCRE2_INCLUDE_DIRS pcre2-posix INCLUDE_DIRECTORIES)
endif()
CHECK_INCLUDE_FILE("regex.h" REGEX_HEADER_FOUND)
if(NOT REGEX_HEADER_FOUND)
  foreach(DIR ${PCRE2_INCLUDE_DIRS})
    if(EXISTS ${DIR}/pcre2posix.h)
      configure_file(${DIR}/pcre2posix.h ${DIR}/regex.h COPYONLY)
      set(REGEX_HEADER_FOUND TRUE)
      break()
    endif()
  endforeach()
  if(NOT REGEX_HEADER_FOUND)
    message("copying ${CMAKE_CURRENT_SOURCE_DIR}/pcre2/src/pcre2posix.h to ${CMAKE_CURRENT_SOURCE_DIR}/file/src/regex.h")
    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/pcre2/src/pcre2posix.h ${CMAKE_CURRENT_SOURCE_DIR}/file/src/regex.h COPYONLY)
  endif()
endif()

add_executable(file ${LIBMAGIC_SOURCE_DIR}/file.c)
add_executable(file_test ${LIBMAGIC_TEST_DIR}/test.c)
target_link_libraries(file_test libmagic pcre2-posix shlwapi)
target_link_libraries(file libmagic pcre2-posix shlwapi)

# this tests all because of time-zone or crlf errors
set(DISABLED_TESTS 
  gedcom
  fit-map-data
  regex-eol
  )

enable_testing()
file(GLOB TESTFILES "${LIBMAGIC_TEST_DIR}/*.testfile")
foreach(TEST_FILE ${TESTFILES})
  # extract testname from path and generate command
  string(REGEX MATCH  "(.*)\.testfile" TESTPATH ${TEST_FILE})
  set(TESTPATH ${CMAKE_MATCH_1})
  string(REGEX MATCH  "([a-zA-Z0-9_]|-|\\.)+$" TESTNAME ${TESTPATH})
  if(NOT ${TESTNAME} IN_LIST DISABLED_TESTS)
      add_test(NAME ${TESTNAME} COMMAND ${CMAKE_CURRENT_BINARY_DIR}/file_test ${TEST_FILE} ${TESTPATH}.result)
  endif()
endforeach()


# Following is the compilation of the magic file
set(MAGIC_FRAGMENT_DIR file/magic/Magdir)
file(GLOB MAGIC_FRAGMENTS ${MAGIC_FRAGMENT_DIR}/*)

# Prepare a temporary file to "cat" to:
file(WRITE magic.in "")

# Call the "cat" function for each input file
foreach(MAGIC_FRAGMENT ${MAGIC_FRAGMENTS})
  cat(${MAGIC_FRAGMENT} magic.in)
endforeach()

# Copy the temporary file to the final location
configure_file(magic.in magic COPYONLY)

add_custom_command(OUTPUT magic.mgc
  COMMAND file -C -m magic
  DEPENDS file
  COMMENT "Compiling magic file"
)

add_custom_target(magic_mgc ALL DEPENDS magic.mgc)

# Get library directory for multiarch linux distros
include(GNUInstallDirs)
# Include module with function 'configure_package_config_file'
include(CMakePackageConfigHelpers)

install(TARGETS file file_test DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/magic.mgc DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES ${LIBMAGIC_SOURCE_DIR}/magic.h DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
install(TARGETS libmagic
        EXPORT libmagic-target
        RUNTIME DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
        )
install(EXPORT libmagic-target
        FILE libmagic-targets.cmake
        DESTINATION lib/cmake/libmagic
        )
file(WRITE
        ${CMAKE_BINARY_DIR}/libmagic-config.cmake
        "include(\${CMAKE_CURRENT_LIST_DIR}/libmagic-targets.cmake)\n")
install(FILES
        ${CMAKE_BINARY_DIR}/libmagic-config.cmake
        DESTINATION lib/cmake/libmagic)