output = Process.run(
  "git",
  ["--no-optional-locks", "status", "--porcelain=v2", "--branch", "--show-stash", "--ignore-submodules", "-uno"],
  error: Process::Redirect::Close,
  output: Process::Redirect::Pipe
)

is_git = false
branch_name = ""
is_dirty = false
is_staged = false
has_stash = false
upstream : Int32? = nil

output.output.to_s.each_line do |line|
  is_git = true
  line = line.strip

  if line.starts_with?('#')
    if line.starts_with?("# branch.head")
      branch_name = line[14..]
    elsif line.starts_with?("# stash")
      has_stash = true
    elsif line.starts_with?("# branch.ab")
      remote_differences = line[12..].gsub(/[+-]/, "")
      if remote_differences == "0 0"
        upstream = 0
      elsif remote_differences.starts_with?("0 ")
        upstream = -1
      elsif remote_differences.ends_with?(" 0")
        upstream = 1
      else
        upstream = 2
      end
    end
  elsif line[2] != "."
    is_staged = true
    is_dirty = true if line[3] != '.'
  else
    is_dirty = true
  end

  break if is_staged && is_dirty
end

# Figure out whether we are running inside Fish since it uses a different
# syntax to set and unset environment variables.
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
