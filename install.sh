dotfiles="$(dirname "$(realpath "$0")")"

for dotfile in .*; do
  # skip "." and ".."
  if [ x"$dotfile" = x"." ]; then continue; fi 
  if [ x"$dotfile" = x".." ]; then continue; fi 

  echo "$dotfile"

  ln -nfs "$dotfiles"/"$dotfile" ~/
done
