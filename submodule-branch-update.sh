# First delete everything

git submodule foreach -q --recursive "branchPath=$(git config -f $toplevel/.gitmodules submodule.$name.path); sudo rm -rf $branchPath"

# Remove modules commands

git submodule foreach --recursive \

branchPath=$(git config -f $toplevel/.gitmodules submodule.$name.path)

git submodule deinit <path_to_submodule>
git rm <path_to_submodule>
git commit
rm -rf .git/modules/<path_to_submodule>
rm -rf <path_to_submodule>

git submodule update --init --recursive --jobs 16
