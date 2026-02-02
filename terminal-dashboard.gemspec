Gem::Specification.new do |s|
  s.name        = "terminal-dashboard"
  s.version     = "1.0.1"
  s.summary     = "Terminal-based media server status dashboard with cat animation"
  s.description = "A minimal, self-contained bash dashboard for monitoring a home media server. " \
                  "Displays service health, disk usage, active Plex streams, download speed, " \
                  "uptime, and quick-access links in a single terminal window."
  s.authors     = ["embmeals"]
  s.homepage    = "https://github.com/embmeals/terminal-dashboard"
  s.license     = "MIT"
  s.files       = ["lib/dashboard.sh", "bin/terminal-dashboard"]
  s.executables = ["terminal-dashboard"]
  s.required_ruby_version = ">= 2.0"
  s.metadata    = {
    "homepage_uri"    => "https://github.com/embmeals/terminal-dashboard",
    "source_code_uri" => "https://github.com/embmeals/terminal-dashboard",
    "bug_tracker_uri" => "https://github.com/embmeals/terminal-dashboard/issues"
  }
end
