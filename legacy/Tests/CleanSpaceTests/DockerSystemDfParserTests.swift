import Foundation
import Testing

@testable import CleanSpaceKit

@Suite("Docker system df parsing")
struct DockerSystemDfParserTests {
    @Test("splitColumns splits on 2+ spaces")
    func splitColumns() {
        let cols = DockerSystemDfParser.splitColumns("REPOSITORY   TAG       IMAGE ID")
        #expect(cols == ["REPOSITORY", "TAG", "IMAGE ID"])
    }

    @Test("parseSummary reads four resource rows after header")
    func parseSummary() {
        let text = """
        TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
        Images          5         3         2.5GB     1.2GB (48%)
        Containers      10        2         200MB     50MB (25%)
        Local Volumes   3         1         500MB     100MB (20%)
        Build Cache     20        5         1GB       800MB (80%)
        """
        let rows = DockerSystemDfParser.parseSummary(text)
        #expect(rows.count == 4)
        #expect(rows.first?.resourceType == "Images")
        #expect(rows.first?.total == "5")
        #expect(rows.first?.reclaimable.contains("1.2GB") == true)
        #expect(rows.contains { $0.resourceType == "Local Volumes" })
    }

    @Test("parseVerboseSections extracts image and container blocks")
    func parseVerbose() {
        let text = """
        Images space usage:

        REPOSITORY   TAG       IMAGE ID   CREATED   SIZE
        a/b          latest    abc        1d        10MB

        Containers space usage:

        CONTAINER ID   IMAGE     COMMAND   SIZE
        deadbeef       a/b:latest   /bin/sh   1MB
        """
        let sections = DockerSystemDfParser.parseVerboseSections(text) { key in
            switch key {
            case "images": return "Images"
            case "containers": return "Containers"
            case "volumes": return "Volumes"
            case "build_cache": return "Build cache"
            default: return key
            }
        }
        #expect(sections.count == 2)
        #expect(sections[0].title == "Images")
        #expect(sections[0].columnTitles.contains("REPOSITORY"))
        #expect(sections[0].rows.count == 1)
        #expect(sections[1].title == "Containers")
        #expect(sections[1].rows.count == 1)
    }

    @Test("build cache inline remainder is leading orphan; table header follows")
    func buildCacheInline() {
        let text = """
        Build cache usage: 0B

        CACHE ID   CACHE TYPE   SIZE
        """
        let sections = DockerSystemDfParser.parseVerboseSections(text) { _ in "Build cache" }
        #expect(sections.count >= 1)
        let bc = sections.first { $0.id == "build_cache" }
        #expect(bc != nil)
        #expect(bc?.prefixLines.contains("0B") == true)
        #expect(bc?.columnTitles.contains("CACHE ID") == true)
    }
}
