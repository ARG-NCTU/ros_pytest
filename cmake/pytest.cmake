_generate_function_if_testing_is_disabled("add_pytests")

#
# Add Python py.test.
#
# Pytest collects tests from the directory ``dir`` automatically.
#
# .. note:: The test can be executed by calling ``py.test``
#   directly or using:
#   `` make run_tests_${PROJECT_NAME}_pytests_${dir}``
#   (where slashes in the ``dir`` are replaced with periods)
#
# :param path: a relative or absolute directory to search for
#   pytests in or a relative or absolute file containing tests
# :type path: string
# :param DEPENDENCIES: the targets which must be built before executing
#   the test
# :type DEPENDENCIES: list of strings
# :param OPTIONS: additional arguments to pass to pytest
# :type OPTIONS: list of strings
# :param WORKING_DIRECTORY: the working directory when executing the
#   tests (this option can only be used when the ``path`` argument is a
#   file  but not when it is a directory)
# :type WORKING_DIRECTORY: string
#
# @public
#
function(add_pytests path)
  _warn_if_skip_testing("add_pytests")

  if(NOT PYTESTS)
    message(STATUS "skipping pytests(${path}) in project '${PROJECT_NAME}'")
    return()
  endif()

  cmake_parse_arguments(_pytest "" "OPTIONS" "WORKING_DIRECTORY" "DEPENDENCIES" ${ARGN})

  # check that the directory exists
  set(_path_name _path_name-NOTFOUND)
  if(IS_ABSOLUTE ${path})
    set(_path_name ${path})
  else()
    find_file(_path_name ${path}
      PATHS ${CMAKE_CURRENT_SOURCE_DIR}
      NO_DEFAULT_PATH NO_CMAKE_FIND_ROOT_PATH)
    if(NOT _path_name)
      message(FATAL_ERROR "Can't find pytests path '${path}'")
    endif()
  endif()

  # check if coverage reports are being requested
  if("$ENV{CATKIN_TEST_COVERAGE}" STREQUAL "1")
    set(_covarg " --cov=${PROJECT_NAME} --cov-append")
  endif()

  # strip PROJECT_SOURCE_DIR and PROJECT_BINARY_DIR prefix from output_file_name
  set(output_file_name ${path})
  _strip_path_prefix(output_file_name "${output_file_name}" "${PROJECT_SOURCE_DIR}")
  _strip_path_prefix(output_file_name "${output_file_name}" "${PROJECT_BINARY_DIR}")
  if("${output_file_name}" STREQUAL "")
    set(output_file_name ".")
  endif()
  string(REPLACE "/" "." output_file_name ${output_file_name})
  string(REPLACE ":" "." output_file_name ${output_file_name})

  set(output_path ${CATKIN_TEST_RESULTS_DIR}/${PROJECT_NAME})
  # make --junit-xml argument an absolute path
  get_filename_component(output_path "${output_path}" ABSOLUTE)
  set(cmd "${CMAKE_COMMAND} -E make_directory ${output_path}")
  set(coverage_dir "${output_path}${output_file_name}_coverageDIR")

  if(IS_DIRECTORY ${_path_name})
    set(tests "--where=${_path_name}")
  else()
    set(tests "${_path_name}")
  endif()

  add_custom_target(
    create_coverage_dir_${output_file_name} "${CMAKE_COMMAND}" "-E" "make_directory" ${coverage_dir} COMMENT "Creating directory coverage"
  )

  set(cmd ${cmd} "${PYTESTS} ${tests} ${_pytest_OPTIONS} --junit-xml=${output_path}/pytests-${output_file_name}.xml${_covarg}")

  # Copy coverage files to ${PROJECT_BINARY_DIR} for later collection by https://github.com/mikeferguson/code_coverage
  set(cmd ${cmd} "cp ${coverage_dir}/.coverage ${PROJECT_BINARY_DIR}/.coverage.${output_file_name}")

  catkin_run_tests_target("pytests" ${output_file_name} "pytests-${output_file_name}.xml" COMMAND ${cmd} DEPENDENCIES ${_pytest_DEPENDENCIES} create_coverage_dir_${output_file_name} WORKING_DIRECTORY ${coverage_dir})

endfunction()

find_program(PYTESTS NAMES
  "py.test${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR}"
  "py.test-${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR}"
  "py.test${PYTHON_VERSION_MAJOR}"
  "py.test-${PYTHON_VERSION_MAJOR}"
  "py.test"
  "pytest${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR}"
  "pytest-${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR}"
  "pytest${PYTHON_VERSION_MAJOR}"
  "pytest-${PYTHON_VERSION_MAJOR}"
  "pytest")
if(PYTESTS)
  message(STATUS "Using Python pytest: ${PYTESTS}")
else()
  if("${PYTHON_VERSION_MAJOR}" STREQUAL "3")
    message(STATUS "pytests not found, Python tests can not be run (try installing package 'python3-pytest')")
  else()
    message(STATUS "pytests not found, Python tests can not be run (try installing package 'python-pytest')")
  endif()
endif()
