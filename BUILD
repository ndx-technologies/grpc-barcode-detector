licenses(["notice"])

http_archive(
    name = "com_github_grpc_grpc",
    strip_prefix = "grpc-v1.67.1",
    urls = ["https://github.com/grpc/grpc/archive/refs/tags/v1.67.1.tar.gz",],
)

load("@com_github_grpc_grpc//bazel:grpc_deps.bzl", "grpc_deps")
grpc_deps()

load("@com_github_grpc_grpc//bazel:grpc_extra_deps.bzl", "grpc_extra_deps")
grpc_extra_deps()

http_archive(
    name = "opencv",
    build_file_content = all_content,
    strip_prefix = "opencv-3.4.11",
    urls = ["https://github.com/opencv/opencv/archive/3.4.11.tar.gz"],
)

new_local_repository(
    name = "linux_opencv",
    build_file = "@//third_party:opencv_linux.BUILD",
    path = "/usr",
)

http_archive(
    name = "zxing-cpp",
    build_file_content = all_content,
    strip_prefix = "zxing-cpp-v2.2.1",
    urls = ["https://github.com/zxing-cpp/zxing-cpp/archive/refs/tags/v2.2.1.tar.gz"],
)

package(default_visibility = ["//visibility:public"])

load("@rules_proto//proto:defs.bzl", "proto_library")
load("@com_github_grpc_grpc//bazel:cc_grpc_library.bzl", "cc_grpc_library")

proto_library(
    name = "messages_proto",
    srcs = ["protos/messages.proto"],
)

cc_proto_library(
    name = "messages_cc_proto",
    deps = [":messages_proto"],
)

cc_grpc_library(
    name = "messages_cc_grpc",
    srcs = [":messages_proto"],
    grpc_only = True,
    deps = [":messages_cc_proto"],
)

cc_library(
    name = "tracer_common",
    srcs = ["tracer_common.h"],
    defines = ["BAZEL_BUILD"],
    tags = ["ostream"],
    deps = [
        "//exporters/ostream:ostream_span_exporter",
    ],
)

cc_binary(
    name = "server_grpc",
    srcs = [
        "server.cc",
    ],
    defines = ["BAZEL_BUILD"],
    tags = ["ostream"],
    deps = [
        "messages_cc_grpc",
        ":tracer_common",
        "//api",
        "//sdk/src/trace",
        "//:grpc++",
        "@zxing-cpp//:zxing",
        "@com_github_grpc_grpc//:grpc++",
    ],
)
