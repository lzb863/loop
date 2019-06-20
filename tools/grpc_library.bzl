#
# The MIT License
#
# Copyright (c) 2019 - Present Aaron Ma http://www.aaronhma.com/,
# Copyright (c) 2017 - 2019 Firebolt, Inc. http://www.firebolt.ai/,
# Copyright (c) 2017 - 2019 Firebolt Space Agency,
# Copyright (c) 2019 Project Titan Loop https://github.com/titan-loop/loop/.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
load("@com_github_grpc_grpc//:bazel/generate_cc.bzl", "generate_cc")

def cc_grpc_library(name,
                    srcs = [],
                    deps = [],
                    deps_cc = [],
                    proto_only = False,
                    well_known_protos = False,
                    generate_mocks = False,
                    use_external = False,
                    **kwargs):
  """Generates C++ grpc classes from a .proto file.
  Assumes the generated classes will be used in cc_api_version = 2.
  Arguments:
      name: name of rule.
      srcs: a single proto_library, which wraps the .proto files with services.
      deps: a list of C++ proto_library (or cc_proto_library) which provides
        the compiled code of any message that the services depend on.
      deps_cc: a list of cc_library which provides
        the compiled code of any message that the services depend on
      well_known_protos: Should this library additionally depend on well known
        protos
      use_external: When True the grpc deps are prefixed with //external. This
        allows grpc to be used as a dependency in other bazel projects.
      generate_mocks: When True, Google Mock code for client stub is generated.
      **kwargs: rest of arguments, e.g., compatible_with and visibility.
  """
  if len(srcs) > 1:
    fail("Only one srcs value supported", "srcs")

  proto_target = "_" + name + "_only"
  codegen_target = "_" + name + "_codegen"
  codegen_grpc_target = "_" + name + "_grpc_codegen"
  proto_deps = deps

  native.proto_library(
      name = proto_target,
      srcs = srcs,
      deps = proto_deps,
      **kwargs
  )

  generate_cc(
      name = codegen_target,
      srcs = [proto_target],
      well_known_protos = well_known_protos,
      **kwargs
  )

  if not proto_only:
    plugin = "@com_github_grpc_grpc//:grpc_cpp_plugin"
    generate_cc(
        name = codegen_grpc_target,
        srcs = [proto_target],
        plugin = plugin,
        well_known_protos = well_known_protos,
        generate_mocks = generate_mocks,
        **kwargs
    )
    grpc_deps  = ["@com_github_grpc_grpc//:grpc++_codegen_proto",
                  "//external:protobuf"]
    native.cc_library(
        name = name,
        srcs = [":" + codegen_grpc_target, ":" + codegen_target],
        hdrs = [":" + codegen_grpc_target, ":" + codegen_target],
        deps = deps_cc + grpc_deps,
        **kwargs
    )
  else:
    native.cc_library(
        name = name,
        srcs = [":" + codegen_target],
        hdrs = [":" + codegen_target],
        deps = deps + ["//external:protobuf"],
        **kwargs
    )
