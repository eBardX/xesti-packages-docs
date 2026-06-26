// swift-tools-version: 6.3

// © 2026 John Gary Pusey (see LICENSE.md)

import PackageDescription

let package = Package(name: "xesti-packages-docs",
                      dependencies: [.package(url: "https://github.com/eBardX/XestiArchive.git",
                                              branch: "main"),
                                     .package(url: "https://github.com/eBardX/XestiCommand.git",
                                              branch: "main"),
                                     .package(url: "https://github.com/eBardX/XestiMarkov.git",
                                              branch: "main"),
                                     .package(url: "https://github.com/eBardX/XestiNetwork.git",
                                              branch: "main"),
                                     .package(url: "https://github.com/eBardX/XestiNumbers.git",
                                              branch: "main"),
                                     .package(url: "https://github.com/eBardX/XestiSexp.git",
                                              branch: "main"),
                                     .package(url: "https://github.com/eBardX/XestiText.git",
                                              branch: "main"),
                                     .package(url: "https://github.com/eBardX/XestiTokens.git",
                                              branch: "main"),
                                     .package(url: "https://github.com/eBardX/XestiTools.git",
                                              branch: "main"),
                                     .package(url: "https://github.com/eBardX/XestiXML.git",
                                              branch: "main"),],
                      targets: [])
