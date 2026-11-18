load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "GrowthPartnersUI",
    module_name = "GrowthPartnersUI",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//submodules/SSignalKit/SwiftSignalKit",
        "//submodules/AsyncDisplayKit",
        "//submodules/Display",
        "//submodules/TelegramCore",
        "//submodules/TelegramPresentationData",
        "//submodules/AccountContext",
        "//submodules/LocalizedPeerData",
        "//submodules/ItemListUI",
        "//submodules/ItemListPeerItem",
    ],
    visibility = [
        "//visibility:public",
    ],
)
