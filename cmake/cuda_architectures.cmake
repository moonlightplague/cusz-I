function(psz_sanitize_cuda_architectures)
  if(NOT CMAKE_CUDA_ARCHITECTURES)
    return()
  endif()

  set(_psz_cuda_compiler "${CMAKE_CUDA_COMPILER}")
  if(NOT _psz_cuda_compiler AND DEFINED ENV{CUDACXX})
    set(_psz_cuda_compiler "$ENV{CUDACXX}")
  endif()
  if(NOT _psz_cuda_compiler)
    find_program(
      _psz_cuda_compiler
      NAMES nvcc
      HINTS "$ENV{CUDA_HOME}/bin" "$ENV{CUDA_PATH}/bin" "/usr/local/cuda/bin")
  endif()
  if(NOT _psz_cuda_compiler)
    return()
  endif()

  execute_process(
    COMMAND "${_psz_cuda_compiler}" --list-gpu-arch
    RESULT_VARIABLE _psz_cuda_arch_result
    OUTPUT_VARIABLE _psz_cuda_arch_output
    ERROR_QUIET
    OUTPUT_STRIP_TRAILING_WHITESPACE)
  if(NOT _psz_cuda_arch_result EQUAL 0 OR _psz_cuda_arch_output STREQUAL "")
    return()
  endif()

  string(REGEX MATCHALL "compute_[0-9]+[a-z]?" _psz_cuda_supported_compute
                       "${_psz_cuda_arch_output}")
  foreach(_psz_cuda_arch IN LISTS _psz_cuda_supported_compute)
    string(REGEX REPLACE "^compute_" "" _psz_cuda_arch_number
                         "${_psz_cuda_arch}")
    list(APPEND _psz_cuda_supported_architectures "${_psz_cuda_arch_number}")
  endforeach()

  set(_psz_cuda_filtered_architectures)
  set(_psz_cuda_removed_architectures)
  foreach(_psz_cuda_arch IN LISTS CMAKE_CUDA_ARCHITECTURES)
    if(_psz_cuda_arch MATCHES "^[0-9]+[a-z]?(-real|-virtual)?$")
      string(REGEX REPLACE "(-real|-virtual)$" "" _psz_cuda_arch_number
                           "${_psz_cuda_arch}")
      if(_psz_cuda_arch_number IN_LIST _psz_cuda_supported_architectures)
        list(APPEND _psz_cuda_filtered_architectures "${_psz_cuda_arch}")
      else()
        list(APPEND _psz_cuda_removed_architectures "${_psz_cuda_arch}")
      endif()
    else()
      list(APPEND _psz_cuda_filtered_architectures "${_psz_cuda_arch}")
    endif()
  endforeach()

  if(_psz_cuda_removed_architectures)
    if(NOT _psz_cuda_filtered_architectures)
      message(
        FATAL_ERROR
          "CUDA compiler ${_psz_cuda_compiler} does not support any requested "
          "CMAKE_CUDA_ARCHITECTURES entries: ${CMAKE_CUDA_ARCHITECTURES}.")
    endif()

    list(JOIN _psz_cuda_removed_architectures ", " _psz_cuda_removed_message)
    list(JOIN _psz_cuda_filtered_architectures ", " _psz_cuda_filtered_message)
    message(
      WARNING
        "Removing unsupported CMAKE_CUDA_ARCHITECTURES entries for "
        "${_psz_cuda_compiler}: ${_psz_cuda_removed_message}. "
        "Using: ${_psz_cuda_filtered_message}.")

    set(CMAKE_CUDA_ARCHITECTURES
        "${_psz_cuda_filtered_architectures}"
        CACHE STRING "CUDA architectures" FORCE)
    set(CMAKE_CUDA_ARCHITECTURES "${_psz_cuda_filtered_architectures}"
        PARENT_SCOPE)
  endif()
endfunction()
