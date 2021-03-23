hugo # 生成public文件夹
cd public
git init
git remote add origin git@github.com:huanruiz/huanruiz.github.io.git
git add .
git commit -m 'init'
git push -f --set-upstream origin master
cd ..
rm -rf public
