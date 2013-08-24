#! /bin/sh
find ../../loom/graphics -name "*.[ch]" -o -name "*.cpp" > ./files.txt

files=$(cat files.txt)

for item in $files ; do

  dn=$(dirname $item)
  mkdir -p out/$dn
  ./uncrustify -f $item -c default.cfg > out/$item

done

