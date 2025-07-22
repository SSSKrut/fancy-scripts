# arguments:
# $1..n git file hash

#!/bin/bash
if [ "$#" -eq 0 ]; then
  echo "Usage: $0 <git-file-hash>...[<git-file-hash>]"
  exit 1
fi

founded_files=""
founded_files_hashes=""
founded_files_paths=""
not_found_files=""

for file_hash in "$@"; do
    file_relative_path=$(git rev-list --objects --all | grep $file_hash --color=always) 
    match_count=$(echo "$file_relative_path" | wc -l)
    if [ "$match_count" -eq 1 ]; then
        founded_files+="$file_relative_path \n"
        founded_files_hashes+=$(echo "$file_relative_path" | awk '{print $1}')
        founded_files_paths+=$(echo "$file_relative_path" | awk '{print $2}')

    elif [ "$match_count" -gt 1 ]; then
        echo "Warning: Multiple matches found for hash $file_hash:"
        echo "$file_relative_path"
        echo 

        not_found_files+="$file_hash\n"
    else
        echo "Warning: No match found for hash $file_hash"
        echo "$file_relative_path"
        echo 

        not_found_files+="$file_hash\n"
    fi
done

if [ -n "$not_found_files" ]; then
    echo "Not found files:"
    echo -e "$not_found_files" 

fi

if [ -n "$founded_files" ]; then
    echo "Found files:"
    echo -e "$founded_files"

fi

git filter-repo --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Please install git-filter-repo to proceed."
    exit 1
fi

echo "Proceed to delete files from git history? (y/n)"
read -r answer
if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    echo "Aborting deletion."
    exit 0
fi

for file_path in $founded_files_paths; do
    echo "Deleting file: $file_path"
    git filter-repo --path $file_path --invert-paths
done

echo "You may want to update your origin repository:"
echo -e "\t$ git push origin --force --all\n" \
        "\t$ git push origin --force --tags"