cmake_minimum_required(VERSION 3.8)

project(RouteGuide C CXX)

include(../cmake/common.cmake)

# Find absl package
find_package(absl CONFIG REQUIRED)

# Proto file
get_filename_component(rg_proto "../../protos/route_guide.proto" ABSOLUTE)
get_filename_component(rg_proto_path "${rg_proto}" PATH)

# Generated sources
set(rg_proto_srcs "${CMAKE_CURRENT_BINARY_DIR}/route_guide.pb.cc")
set(rg_proto_hdrs "${CMAKE_CURRENT_BINARY_DIR}/route_guide.pb.h")
set(rg_grpc_srcs "${CMAKE_CURRENT_BINARY_DIR}/route_guide.grpc.pb.cc")
set(rg_grpc_hdrs "${CMAKE_CURRENT_BINARY_DIR}/route_guide.grpc.pb.h")
add_custom_command(
      OUTPUT "${rg_proto_srcs}" "${rg_proto_hdrs}" "${rg_grpc_srcs}" "${rg_grpc_hdrs}"
      COMMAND ${_PROTOBUF_PROTOC}
      ARGS --grpc_out "${CMAKE_CURRENT_BINARY_DIR}"
        --cpp_out "${CMAKE_CURRENT_BINARY_DIR}"
        -I "${rg_proto_path}"
        --plugin=protoc-gen-grpc="${_GRPC_CPP_PLUGIN_EXECUTABLE}"
        "${rg_proto}"
      DEPENDS "${rg_proto}")

# Include generated *.pb.h files
include_directories("${CMAKE_CURRENT_BINARY_DIR}")

# rg_grpc_proto
add_library(rg_grpc_proto
  ${rg_grpc_srcs}
  ${rg_grpc_hdrs}
  ${rg_proto_srcs}
  ${rg_proto_hdrs})
target_link_libraries(rg_grpc_proto
  absl::absl_log
  ${_REFLECTION}
  ${_GRPC_GRPCPP}
  ${_PROTOBUF_LIBPROTOBUF})

# route_guide_helper
add_library(route_guide_helper
  "helper.h"
  "helper.cc")
target_link_libraries(route_guide_helper
  rg_grpc_proto
  ${_REFLECTION}
  ${_GRPC_GRPCPP}
  ${_PROTOBUF_LIBPROTOBUF})

# Targets route_guide_(client|server)
foreach(_target
  route_guide_client route_guide_server)
  add_executable(${_target}
    "${_target}.cc")
  target_link_libraries(${_target}
    rg_grpc_proto
    route_guide_helper
    absl::flags_parse
    absl::absl_log
    absl::log_initialize
    absl::log_globals
    ${_REFLECTION}
    ${_GRPC_GRPCPP}
    ${_PROTOBUF_LIBPROTOBUF})
endforeach()

# zxing-cpp
zxing_add_package_stb()

include (GNUInstallDirs)

add_executable (ZXingReader ZXingReader.cpp)

target_link_libraries (ZXingReader ZXing::ZXing stb::stb)

install(TARGETS ZXingReader DESTINATION ${CMAKE_INSTALL_BINDIR})

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(OpenCV QUIET)
if (OpenCV_FOUND)
    add_executable (ZXingOpenCV ZXingOpenCV.cpp)
    target_include_directories (ZXingOpenCV PRIVATE ${OpenCV_INCLUDE_DIRS})
    target_link_libraries (ZXingOpenCV ZXing::ZXing ${OpenCV_LIBS})
else ()
    message("INFO: OpenCV not found, skipping ZXingOpenCV")
endif()

# open telemetry
get_filename_component(proto_file "./protos/messages.proto" ABSOLUTE)
get_filename_component(proto_file_path "${proto_file}" PATH)

message(STATUS "PATH:${proto_file_path}:${proto_file}")

# Generated sources
set(example_proto_srcs "${CMAKE_CURRENT_BINARY_DIR}/messages.pb.cc")
set(example_proto_hdrs "${CMAKE_CURRENT_BINARY_DIR}/messages.pb.h")
set(example_grpc_srcs "${CMAKE_CURRENT_BINARY_DIR}/messages.grpc.pb.cc")
set(example_grpc_hdrs "${CMAKE_CURRENT_BINARY_DIR}/messages.grpc.pb.h")

add_custom_command(
  OUTPUT "${example_proto_srcs}" "${example_proto_hdrs}" "${example_grpc_srcs}"
         "${example_grpc_hdrs}"
  COMMAND
    ${PROTOBUF_PROTOC_EXECUTABLE} ARGS "--grpc_out=${CMAKE_CURRENT_BINARY_DIR}"
    "--cpp_out=${CMAKE_CURRENT_BINARY_DIR}" "--proto_path=${proto_file_path}"
    "--plugin=protoc-gen-grpc=${gRPC_CPP_PLUGIN_EXECUTABLE}" "${proto_file}")

add_library(example_grpc_proto ${example_grpc_srcs} ${example_grpc_hdrs}
                               ${example_proto_srcs} ${example_proto_hdrs})

patch_protobuf_targets(example_grpc_proto)

include_directories(
  ${CMAKE_SOURCE_DIR}/exporters/ostream/include ${CMAKE_SOURCE_DIR}/ext/include
  ${CMAKE_SOURCE_DIR}/api/include/ ${CMAKE_SOURCE_DIR/})

include_directories(${CMAKE_CURRENT_BINARY_DIR})

if(TARGET protobuf::libprotobuf)
  target_link_libraries(example_grpc_proto PUBLIC gRPC::grpc++
                                                  protobuf::libprotobuf)
else()
  target_include_directories(example_grpc_proto PUBLIC ${Protobuf_INCLUDE_DIRS})
  target_link_libraries(example_grpc_proto PUBLIC gRPC::grpc++
                                                  ${Protobuf_LIBRARIES})
endif()
if(WITH_ABSEIL)
  target_link_libraries(example_grpc_proto PUBLIC absl::bad_variant_access)
endif()

foreach(_target client server)
  add_executable(${_target} "${_target}.cc")
  target_link_libraries(${_target} example_grpc_proto opentelemetry_trace
                        opentelemetry_exporter_ostream_span)
  patch_protobuf_targets(${_target})
endforeach()
