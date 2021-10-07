for file in ./*
do
    sed -i '' 's/author: "小拳头"/author: "小拳头"/g' $file
done