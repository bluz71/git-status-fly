use std::process::{Command, Stdio};

fn main() {
    let output = Command::new("git")
        .arg("--no-optional-locks")
        .arg("status")
        .arg("--porcelain=v2")
        .arg("--branch")
        .arg("--show-stash")
        .arg("--ignore-submodules")
        .arg("-uno")
        .stderr(Stdio::null())
        .output()
        .expect("Failed to execute command");

    let mut is_git = false;
    let mut branch_name = String::new();
    let mut is_dirty = false;
    let mut is_staged = false;
    let mut has_stash = false;
    let mut upstream = String::new();

    let output_str = String::from_utf8_lossy(&output.stdout);

    for line in output_str.lines() {
        is_git = true;

        let line = line.trim();
        if line.starts_with('#') {
            if line.starts_with("# branch.head") {
                branch_name = line[14..].to_string();
            } else if line.starts_with("# stash") {
                has_stash = true;
            } else if line.starts_with("# branch.ab") {
                let remote_differences = line[12..].replace(['+', '-'], "");
                if remote_differences == "0 0" {
                    upstream = "0".to_string();
                } else if remote_differences.starts_with("0 ") {
                    upstream = "-1".to_string();
                } else if remote_differences.ends_with(" 0") {
                    upstream = "1".to_string();
                } else {
                    upstream = "2".to_string();
                }
            }
        } else if &line[2..3] != "." {
            is_staged = true;
        } else {
            is_dirty = true;
        }
        if is_staged && is_dirty {
            // No need to check anymore entries since both dirty and staged are in
            // effect.
            break;
        }
    }

    println!("unset GSF_REPOSITORY");
    println!("unset GSF_BRANCH");
    println!("unset GSF_STASH");
    println!("unset GSF_UPSTREAM");
    println!("unset GSF_DIRTY");
    println!("unset GSF_STAGED");
    if is_git {
        println!("export GSF_REPOSITORY=1");
        println!("export GSF_BRANCH='{}'", branch_name);
        if has_stash {
            println!("export GSF_STASH=1");
        }
        if !upstream.is_empty() {
            println!("export GSF_UPSTREAM='{}'", upstream);
        }
        if is_dirty {
            println!("export GSF_DIRTY=1");
        }
        if is_staged {
            println!("export GSF_STAGED=1");
        }
    }
}
