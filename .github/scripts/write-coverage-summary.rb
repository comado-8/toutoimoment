#!/usr/bin/env ruby

require "json"

result_bundle, output_path = ARGV
abort "usage: write-coverage-summary.rb RESULT_BUNDLE OUTPUT_PATH" unless result_bundle && output_path

heading = <<~MARKDOWN
  # TouToiMoment unit-test coverage

  Phase 1 is report-only. Coverage values do not fail the workflow.

MARKDOWN

unless File.exist?(result_bundle)
  File.write(output_path, heading + "Coverage unavailable because no result bundle was produced.\n")
  exit 0
end

json_path = File.join(File.dirname(output_path), "coverage-report.json")
success = system("xcrun", "xccov", "view", "--report", "--json", result_bundle, out: json_path)
unless success
  File.write(output_path, heading + "Coverage unavailable because `xccov` could not read the result bundle.\n")
  exit 0
end

report = JSON.parse(File.read(json_path))
targets = report.fetch("targets", [])
app_target = targets.find { |target| target["name"] == "TouToiMoment.app" }

logic_patterns = [
  %r{/TouToiMoment/Core/},
  %r{/TouToiMoment/Features/.+/(Models|ViewModels|Services)/},
  %r{/TouToiMoment/Repositories/},
  %r{/TouToiMoment/Services/},
]
excluded_patterns = [
  %r{/Views/},
  %r{/Components/},
  %r{/Theme/},
  %r{/TouToiMomentTests/},
  %r{/TouToiMomentUITests/},
  /Generated/,
]

logic_files = targets.flat_map { |target| target.fetch("files", []) }.select do |file|
  path = file["path"].to_s
  logic_patterns.any? { |pattern| pattern.match?(path) } &&
    excluded_patterns.none? { |pattern| pattern.match?(path) }
end
logic_covered = logic_files.sum { |file| file.fetch("coveredLines", 0).to_i }
logic_executable = logic_files.sum { |file| file.fetch("executableLines", 0).to_i }

percentage = lambda do |covered, executable|
  executable.zero? ? "n/a" : format("%.2f%%", covered.to_f * 100 / executable)
end

app_covered = app_target&.fetch("coveredLines", 0).to_i
app_executable = app_target&.fetch("executableLines", 0).to_i

table = <<~MARKDOWN
  | Scope | Covered / executable lines | Coverage |
  | --- | ---: | ---: |
  | App target | #{app_covered} / #{app_executable} | #{percentage.call(app_covered, app_executable)} |
  | Logic scope | #{logic_covered} / #{logic_executable} | #{percentage.call(logic_covered, logic_executable)} |

  Logic scope includes Core, Models, ViewModels, Services, and Repositories. Views, Components, Theme, tests, and generated code are excluded.
MARKDOWN

File.write(output_path, heading + table)
