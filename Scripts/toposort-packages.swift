#!/usr/bin/env swift

// © 2026 John Gary Pusey (see LICENSE.md)

//
// Reads the umbrella Package.swift and each checkout's Package.swift to
// discover inter-Xesti dependencies, then prints the packages in topological
// build order (each package after all Xesti packages it depends on).
//
// Usage: swift toposort-packages.swift <umbrella-Package.swift> <checkouts-dir>
//

import Foundation

guard CommandLine.arguments.count == 3 else {
    fputs("Usage: toposort-packages.swift <umbrella-Package.swift> <checkouts-dir>\n", stderr)
    exit(1)
}

let umbrellaSwift = CommandLine.arguments[1]
let checkoutsDir  = CommandLine.arguments[2]

func contents(of path: String) -> String {
    (try? String(contentsOfFile: path,
                 encoding: .utf8)) ?? ""
}

func xestiPackages(in text: String) -> [String] {
    text.matches(of: #/github\.com/eBardX/(Xesti[^"]+)\.git/#)
        .map { String($0.output.1) }
}

let packages = xestiPackages(in: contents(of: umbrellaSwift))

// Collect inter-Xesti deps for each package from its checkout's Package.swift.
var deps: [String: Set<String>] = .init(uniqueKeysWithValues: packages.map { ($0, []) })

for pkg in packages {
    let path = "\(checkoutsDir)/\(pkg)/Package.swift"

    for dep in xestiPackages(in: contents(of: path)) where dep != pkg && deps[dep] != nil {
        deps[pkg]!.insert(dep)
    }
}

// Kahn's topological sort.
var inDegree:  [String: Int] = .init(uniqueKeysWithValues: packages.map { ($0, deps[$0]!.count) })
var prereqOf:  [String: [String]] = [:]

for (pkg, pkgDeps) in deps {
    for dep in pkgDeps { prereqOf[dep, default: []].append(pkg) }
}

var queue  = packages.filter { inDegree[$0] == 0 }.sorted()
var result = [String]()

while !queue.isEmpty {
    let pkg = queue.removeFirst()

    result.append(pkg)

    for dependent in (prereqOf[pkg] ?? []).sorted() {
        inDegree[dependent]! -= 1

        if inDegree[dependent] == 0 {
            queue.append(dependent)
        }
    }
}

print(result.joined(separator: "\n"))
