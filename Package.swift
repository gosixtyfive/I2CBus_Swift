import PackageDescription

let package = Package(

    name: "I2CBus-swift",
    dependencies: [
	.Package(url: "https://www.github.com/sixtyfiveford/Ci2c.swift.git", majorVersion: 1),
    ]
)
