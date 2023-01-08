for file in ./*
do
    sed 's/程序设计/Tech/g' $file
    sed 's/变成语言/Tech/g' $file
done