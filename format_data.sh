#!bin/bash

for f in *.hea
do
sed '1s/20[0-9][0-9]//g' $f > formatted_data/$f
done
