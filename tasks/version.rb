# frozen_string_literal: true

require 'time'

release_version = ENV['RELEASE_VERSION']
release_date = Time.now.strftime '%Y-%m-%d'
release_user = ENV['RELEASE_USER']

version_file = Dir['lib/**/version.rb'].first
version_contents = (File.readlines version_file, mode: 'r:UTF-8').map do |l|
  (l.include? 'VERSION') ? (l.sub %r/'[^']+'/, %('#{release_version}')) : l
end

readme_file = 'README.adoc'
readme_contents = File.readlines readme_file, mode: 'r:UTF-8'
if readme_contents[2].start_with? 'v'
  readme_contents[2] = %(v#{release_version}, #{release_date}\n)
else
  readme_contents.insert 2, %(v#{release_version}, #{release_date}\n)
end

changelog_file = 'CHANGELOG.adoc'
changelog_contents = File.readlines changelog_file, mode: 'r:UTF-8'
if (last_release_idx = changelog_contents.index {|l| (l.start_with? '== ') && (%r/^== \d/.match? l) })
  previous_release_version = (changelog_contents[last_release_idx].match %r/\d\S+/)[0]
else
  changelog_contents << %(#{changelog_contents.pop.chomp}\n)
  changelog_contents << ?\n
  last_release_idx = changelog_contents.length
end
changelog_contents.insert last_release_idx, <<~END
=== Details

{url-repo}/releases/tag/v#{release_version}[git tag]#{previous_release_version ? %( | {url-repo}/compare/v#{previous_release_version}\\...v#{release_version}[full diff]\n) : ''}
END
if (unreleased_idx = changelog_contents.index {|l| (l.start_with? '== Unreleased') && l.rstrip == '== Unreleased' })
  changelog_contents[unreleased_idx] = %(== #{release_version} (#{release_date}) - @#{release_user}\n)
else
  changelog_contents.insert last_release_idx, <<~END
  == #{release_version} (#{release_date}) - @#{release_user}

  _No changes since previous release._

  END
end

File.write version_file, version_contents.join, mode: 'w:UTF-8'
File.write readme_file, readme_contents.join, mode: 'w:UTF-8'
File.write changelog_file, changelog_contents.join, mode: 'w:UTF-8'
