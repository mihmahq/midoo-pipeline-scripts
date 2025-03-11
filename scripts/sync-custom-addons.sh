#!/bin/bash


sync_custom_modules() {
    local repos_dir="/opt/midoo/repos"
    local repo_url="https://github.com/mihmahq/midoo-apps.git"
    local branch="17.0"
    local csv_file="repositories.csv"
    local custom_apps_dir="/opt/midoo/custom-apps"
    local log_file="/var/log/midoo/sync_custom_modules.log"

    if [ ! -d "/opt/midoo/midoo-apps" ]; then
        echo "Cloning midoo-apps repository..." | tee -a "$log_file"
        sudo -H -u midoo git clone --depth 1 --branch "$branch" "$repo_url" /opt/midoo/midoo-apps || {
            echo "Failed to clone midoo-apps repository. Aborting." | tee -a "$log_file"
            return 1
        }
    else
        echo "midoo-apps repository already exists. Updating..." | tee -a "$log_file"
        cd /opt/midoo/midoo-apps && sudo -H -u midoo git fetch && sudo -H -u midoo git merge origin/"$branch" >> "$log_file" 2>&1 || {
            echo "Warning: Failed to update midoo-apps repository. Continuing with existing files." | tee -a "$log_file"
        }
    fi

    local csv_path="/opt/midoo/midoo-apps/$csv_file"
    if [ ! -f "$csv_path" ]; then
        echo "Error: $csv_file not found in the midoo-apps repository." | tee -a "$log_file"
        return 1
    fi

    echo "Processing repositories from $csv_file..." | tee -a "$log_file"

    mkdir -p "$repos_dir"

    tail -n +2 "$csv_path" | while IFS=',' read -r repo branch_name; do
        [ -z "$repo" ] || [ -z "$branch_name" ] && {
            echo "Skipping malformed entry: '$repo,$branch_name'" | tee -a "$log_file"
            continue
        }

        repo_name=$(basename "$repo" .git)
        repo_path="$repos_dir/$repo_name"

        echo "Processing repository: $repo (branch: $branch_name)" | tee -a "$log_file"

        if ! git ls-remote --exit-code --heads "$repo" "$branch_name" > /dev/null 2>&1; then
            echo "Invalid repository or branch: $repo ($branch_name). Skipping..." | tee -a "$log_file"
            continue
        fi

        if [ ! -d "$repo_path" ]; then
            echo "Cloning repository $repo_name..." | tee -a "$log_file"
            if ! sudo -H -u midoo git clone --depth 1 --branch "$branch_name" "$repo" "$repo_path" >> "$log_file" 2>&1; then
                echo "Failed to clone repository $repo_name. Skipping..." | tee -a "$log_file"
                continue
            fi
        else
            echo "Repository $repo_name already exists. Updating..." | tee -a "$log_file"
            if ! (cd "$repo_path" && sudo -H -u midoo git fetch && sudo -H -u midoo git pull >> "$log_file" 2>&1); then
                echo "Failed to update repository $repo_name. Skipping..." | tee -a "$log_file"
                continue
            fi
        fi

        if [ -d "$repo_path" ]; then
            echo "Syncing modules from $repo_name..." | tee -a "$log_file"

            rsync -av "$repo_path/" "$custom_apps_dir/" >> "$log_file" 2>&1

            find "$repo_path" -mindepth 1 -maxdepth 1 -type d | while read -r module_dir; do
                module_name=$(basename "$module_dir")
                target_dir="$custom_apps_dir/$module_name"

                if [ ! -d "$target_dir" ]; then
                    echo "Copying new module $module_name..." | tee -a "$log_file"
                    cp -r "$module_dir" "$custom_apps_dir/" >> "$log_file" 2>&1
                fi
            done
        else
            echo "Warning: Repository $repo_name does not exist or failed to clone/update. Skipping..." | tee -a "$log_file"
        fi
    done
}
