require "process"
require "env"

output = Process.run(
  "git",
  args: [
    "--no-optional-locks",
    "status",
    "--porcelain=v2",
    "--branch",
    "--show-stash",
    "--ignore-submodules",
    "-uno"
  ],
  shell: false,
  output: Process::Redirect::Pipe,
  error: Process::Redirect::Null
).output.gets_to_end

is_git = false
branch_name = ""
is_dirty = false
is_staged = false
has_stash = false
upstream = nil # Nilable(Int32)

output.each_line do |line|
  is_git = true
  line = line.strip

  if line.starts_with?("#")
    if line.starts_with?("# branch.head")
      branch_name = line[14..-1]
    elsif line.starts_with?("# stash")
      has_stash = true
    elsif line.starts_with?("# branch.ab")
      remote_differences = line[12..-1].gsub('+', "").gsub('-', "")
      case remote_differences
      when "0 0"
        upstream = 0
      when /^0 / # Diverging behind upstream
        upstream = -1
      when / 0$/ # Diverging ahead of upstream
        upstream = 1
      else # Diverging both ahead and behind
        upstream = 2
      end
    end
  elsif line[2] != '.'
    is_staged = true
    is_dirty ||= line[3] != '.'
  else
    is_dirty = true
  end

  # Early exit if both dirty and staged are found
  break if is_staged && is_dirty
end

is_fish = ENV["SHELL"]?.includes?("fish")

if is_fish
  puts "set -e GSF_REPOSITORY"
  puts "set -e GSF_BRANCH"
  puts "set -e GSF_DIRTY"
  puts "set -e GSF_STAGED"
  puts "set -e GSF_UPSTREAM"
  puts "set -e GSF_STASH"
else
  puts "unset GSF_REPOSITORY"
  puts "unset GSF_BRANCH"
  puts "unset GSF_DIRTY"
  puts "unset GSF_STAGED"
  puts "unset GSF_UPSTREAM"
  puts "unset GSF_STASH"
end

if is_git
  if is_fish
    puts "set -gx GSF_REPOSITORY 1"
    puts "set -gx GSF_BRANCH '#{branch_name}'"
  else
    puts "export GSF_REPOSITORY=1"
    puts "export GSF_BRANCH='#{branch_name}'"
  end

  if is_dirty
    puts is_fish ? "set -gx GSF_DIRTY 1" : "export GSF_DIRTY=1"
  end

  if is_staged
    puts is_fish ? "set -gx GSF_STAGED 1" : "export GSF_STAGED=1"
  end

  if upstream
    puts is_fish ? "set -gx GSF_UPSTREAM #{upstream}" : "export GSF_UPSTREAM=#{upstream}"
  end

  if has_stash
    puts is_fish ? "set -gx GSF_STASH 1" : "export GSF_STASH=1"
  end
end
