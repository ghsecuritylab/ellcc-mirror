include(LLVMParseArguments)

# Compile a source into an object file with COMPILER_RT_TEST_COMPILER using
# a provided compile flags and dependenices.
# clang_compile(<object> <source>
#               CFLAGS <list of compile flags>
#               DEPS <list of dependencies>)
macro(clang_compile object_file source)
  parse_arguments(SOURCE "CFLAGS;DEPS" "" ${ARGN})
  get_filename_component(source_rpath ${source} REALPATH)
  if(NOT COMPILER_RT_STANDALONE_BUILD)
    list(APPEND SOURCE_DEPS clang)
  endif()
  add_custom_command(
    OUTPUT ${object_file}
    # MSVS CL doesn't allow a space between -Fo and the object file name.
    COMMAND ${COMPILER_RT_TEST_COMPILER} ${compile_flags} -c
            ${COMPILER_RT_TEST_COMPILER_OBJ}"${object_file}"
            ${source_rpath}
    MAIN_DEPENDENCY ${source}
    DEPENDS ${SOURCE_DEPS})
endmacro()
