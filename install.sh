dotfiles="$(dirname "$(realpath "$0")")"

for dotfile in .*; do
  # skip "." and ".."
  if [ x"$dotfile" = x"." ]; then continue; fi 
  if [ x"$dotfile" = x".." ]; then continue; fi 

  # skip ".git"
  if [ x"$dotfile" = x".git" ]; then continue; fi

  ln -vfs "$dotfiles"/"$dotfile" ~/
done
