# Configure with -DUSE_EXECUTORCH=ON to run the policies whose policy_file in config.yaml is a .pte with ExecuTorch.
# The prebuilt library ships in the executorch Python package and needs CMake 3.28 or newer.
option(USE_EXECUTORCH "Build with ExecuTorch, to run .pte policies" OFF)
if(USE_EXECUTORCH)
  find_package(executorch 1.5 REQUIRED CONFIG COMPONENTS runtime kernels_optimized backend_xnnpack)
  add_compile_definitions(USE_EXECUTORCH)
  link_libraries(executorch::kernels_optimized executorch::backend_xnnpack)
endif()
