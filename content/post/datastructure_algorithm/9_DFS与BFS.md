---
title: "DFS与BFS"
date: 2021-01-08
draft: false
toc: true
categories: ["数据结构与算法"]
tags: ["数据结构与算法"]
---

## 回溯
DFS很多情况下会和回溯结合起来, 先通过全排列问题来构建回溯问题的框架. 我的理解中, 回溯实际上就是一种剪枝的技巧. 算法的本质依然是遍历.

1. 选择开始遍历的节点, 可能有多个
2. 构建回溯方法, 回溯的限制条件通常有`visited`, 数组的范围, 类似n皇后那种的其他限制条件
3. 回溯中递归的终止条件中通常包含答案. dfs遍历到的路径如果和目标路径长度相同, 就可以添加该路径. 注意要重新new新的对象, 防止浅拷贝带来的问题.

### 46. 全排列
```
class Solution {
    List<List<Integer>> res = new LinkedList<>(); //结果
    public List<List<Integer>> permute(int[] nums) {
        LinkedList<Integer> track  = new LinkedList<>(); //dfs的路径
        backtrack(track, nums);
        return res;
    }

    private void backtrack(LinkedList<Integer> track, int[] nums) {
        if (track.size() == nums.length) { //路径符合要求
            res.add(new LinkedList(track)); //将路径加入答案
            return;
        }
        for (int i = 0; i < nums.length; i++) {
            if (track.contains(nums[i])) continue; //路径不符合要求, 跳过
            track.add(nums[i]); //添加当前走到的结点
            backtrack(track, nums); //继续走
            track.removeLast(); //删除当前走到的结点
        }
    }
}
```

### 47. 全排列II
这道题有重复值, 在46题的基础上需要增加判断. 在46题中我们忽视了`visited`数组(因为没有重复的), 这道题和其他大多数题都是需要加上的. 数组排序后, 对于前面出现过的重复的值, 这个值是已经遍历过了, 所以要剪枝.
```
class Solution {
    List<List<Integer>> res = new LinkedList<>();
    public List<List<Integer>> permuteUnique(int[] nums) {
        LinkedList<Integer> track = new LinkedList<>();
        Arrays.sort(nums);
        boolean[] visited = new boolean[nums.length];
        backtrack(track, visited, nums);
        return res;
    }

    private void backtrack(LinkedList<Integer> track, boolean[] visited, int[] nums) {
        if (track.size() == nums.length) {
            res.add(new LinkedList(track));
            return;
        }

        for (int i = 0; i < nums.length; i++) {
            //前面遍历过的重复值就不需要再遍历了
            if ((i > 0 && nums[i] == nums[i - 1] && !visited[i - 1]) || visited[i]) continue;
            visited[i] = true;
            track.add(nums[i]);
            backtrack(track, visited, nums);
            visited[i] = false;
            track.removeLast();
        }
    }
}
```

### 51. N皇后/52. N皇后II
这道题用数组做应该更快, 为了方便理解, 我用了StringBuilder. 不符合要求的判断条件增加了, 因为是从上往下填数字, 所以要检查左上, 右上和每一列是否有Q出现. 
```
class Solution {
    List<List<String>> res = new LinkedList<>();
    public List<List<String>> solveNQueens(int n) {
        LinkedList<String> track = new LinkedList<>();
        StringBuilder s = new StringBuilder("");
        for (int i = 0; i < n; i++) s.append(".");
        for (int i = 0; i < n; i++) track.add(s.toString());
        bracktrack(track, 0);
        return res;
    }

    private void bracktrack(LinkedList<String>track, int row) {
        if (row == track.size()) {
            res.add(new LinkedList(track));
            return;
        }
        for (int col = 0; col < track.size(); col++) {
            if (!isValid(track, row, col)) continue;

            StringBuilder s = new StringBuilder(track.get(row));
            String origin = track.get(row);
            s.replace(col, col + 1, "Q");
            track.set(row, s.toString());

            bracktrack(track, row + 1);
            track.set(row, origin); //恢复
        }
    }

    private boolean isValid(LinkedList<String> track, int row, int col) {
        for (int i = 0; i < track.size(); i++) {
            if (track.get(i).charAt(col) == 'Q') return false; //列上不重合
        }
        for (int i = row - 1, j = col - 1; i >= 0 && j >= 0; i--, j--) {
            if (track.get(i).charAt(j) == 'Q') return false; //左上不重合
        }
        for (int i = row - 1, j = col + 1; i >= 0 && j < track.size(); i--, j++) {
            if (track.get(i).charAt(j) == 'Q') return false; //右上不重合
        }
        return true;
    }
}
```

### 37. 解数独
**这道题只需要一个解, 那么可以用`boolean`作为返回值来节省时间**. 只要符合要求, 直接返回这个正确答案, 不需要后续的修改.

```
class Solution {
    public void solveSudoku(char[][] board) {
        backtrack(board, 0, 0);
    }

    private boolean backtrack(char[][] board, int row, int col) {
        if (col == 9) {
            return backtrack(board, row + 1, 0); //这一行遍历完了, 进入下一行继续遍历
        }
        if (row == 9) return true; //全部遍历完成
        for (int i = row; i < 9; i++) {
            for (int j = col; j < 9; j++) {
                if (board[i][j] != '.') {
                    return backtrack(board, i, j + 1);
                }
                for (char c = '1'; c <= '9'; c++) {
                    if (!isValid(board, i, j, c)) continue;
                    board[i][j] = c;
                    if (backtrack(board, i, j + 1)) return true;
                    board[i][j] = '.';
                }
                return false;
            }
        }
        return false;
    }

    private boolean isValid(char[][] board, int row, int col, char c) {
        //row colume
        for (int i = 0; i < 9; i++) {
            if (board[row][i] == c) return false;
            if (board[i][col] == c) return false;
        }
        int r = row / 3;
        int co = col / 3;
        for (int i = r * 3; i < r * 3 + 3; i++) {
            for (int j = co * 3; j < co * 3 + 3; j++) {
                if (board[i][j] == c) return false;
            }
        }
        return true;
    }
}
```

### 22. 括号生成
不合法等价于每个从0开始的子串的左括号数量大于右括号的数量.
```
class Solution {
    LinkedList<String> res = new LinkedList<>();
    public List<String> generateParenthesis(int n) {
        StringBuilder s = new StringBuilder("");
        backtrack(n, n, n, s);
        return res;
    }

    private void backtrack(int n, int left, int right, StringBuilder s) {
        if (left == 0 && right == 0) {
            res.add(s.toString());
            return;
        } else if (left < 0 || right < 0 || left > right) return;
        s.append("(");
        backtrack(n, left - 1, right, s);
        s.deleteCharAt(s.length() - 1);

        s.append(")");
        backtrack(n, left, right - 1, s);
        s.deleteCharAt(s.length() - 1);
    }
}
```


### 17. 电话号码的字母组合
```
class Solution {
    List<String> res = new LinkedList<>();
    HashMap<Character, String> map = new HashMap<>();
    public List<String> letterCombinations(String digits) {
        if (digits.equals("")) return res;
        map.put('2', "abc");
        map.put('3', "def");
        map.put('4', "ghi");
        map.put('5', "jkl");
        map.put('6', "mno");
        map.put('7', "pqrs");
        map.put('8', "tuv");
        map.put('9', "wxyz");
        StringBuilder track = new StringBuilder();
        backtrack(digits, track, 0);
        return res;
    }

    private void backtrack(String digits, StringBuilder track, int index) {
        if (index == digits.length()) {
            res.add(track.toString());
            return;
        }
        String currentString = map.get(digits.charAt(index));
        for (int i = 0; i < currentString.length(); i++) {
            track.append(currentString.charAt(i));
            backtrack(digits, track, index + 1);
            track.deleteCharAt(track.length() - 1);
        }
    }
}
```

### 79. 单词搜索
一定要在回溯方法的外面循环找结点, 否则逻辑不正确. 
```
class Solution {
    public boolean exist(char[][] board, String word) {
        boolean[][] visited = new boolean[board.length][board[0].length];
        for (int i = 0; i < board.length; i++) {
            for (int j = 0; j < board[0].length; j++) {
                if (backtrack(board, word, visited, i, j, 0)) return true;
            }
        }
        return false;
    }

    private boolean backtrack(char[][] board, String word, boolean[][] visited, int row, int col, int index) {
        if (word.charAt(index) != board[row][col]) return false;
        if (index == word.length() - 1) return true; //当前字母相等而且是最后一个字母
        int[][] directions = {{0, 1}, {0, -1}, {1, 0}, {-1, 0}};

        visited[row][col] = true;
        for (int[] d: directions) {
            int r = row + d[0];
            int c = col + d[1];
            
            if (r >= 0 && c >= 0 && r < board.length && c < board[0].length && !visited[r][c]) {
                if (backtrack(board, word, visited, r, c, index + 1)) return true;
            }
        }
        visited[row][col] = false;

        return false;
    }
}
```

### 78. 子集
从前往后遍历, 因为是子集, 所以对比全排列, `backtrack`中的`i`每次递归都会更新, 不会对同一个位置计算两次.
```
class Solution {
    List<List<Integer>> res = new LinkedList<>();

    public List<List<Integer>> subsets(int[] nums) {
        LinkedList<Integer> track = new LinkedList<>();
        backtrack(nums, track, 0);
        return res;
    }

    private void backtrack(int[] nums, LinkedList<Integer> track, int index) {
        res.add(new LinkedList(track));
        for (int i = index; i < nums.length; i++) {
            track.add(nums[i]);
            backtrack(nums, track, i + 1);
            track.removeLast();
        }
    }
}
```

## BFS
BFS可以找到**最优路径**, 而DFS只能找到路径. 但是BFS空间复杂度远大于DFS.

1. 构建队列` Queue<TreeNode> queue = new LinkedList<>();`, 并添加第一个结点
2. while循环, `while (!queue.isEmpty())`
3. 将当前队列的大小`size`记录下来, 这个大小就是本轮便利的次数. 在`visited`这个set中的值跳过.
4. 添加下一层节点

### 111. 二叉树的最小深度
```
//DFS前序遍历, 每次向下则深度加1
class Solution {
    public int minDepth(TreeNode root) {
        if (root == null) return 0;
        if (root.left == null && root.right == null) return 1;
        else if (root.left == null && root.right != null) return minDepth(root.right) + 1;
        else if (root.left != null && root.right == null) return minDepth(root.left) + 1;
        return Math.min(minDepth(root.left), minDepth(root.right)) + 1;
    }
}
```

BFS的框架基本都是固定的, 如下.
```
//BFS
class Solution {
    public int minDepth(TreeNode root) {
        if (root == null) return 0;
        Queue<TreeNode> queue = new LinkedList<>();
        queue.offer(root); //第一个结点
        int depth = 1;
        while (!queue.isEmpty()) {
            int size = queue.size(); //当前包含元素数量
            for (int i = 0; i < size; i++) {
                TreeNode cur = queue.poll(); //当前节点
                if (cur.left == null && cur.right == null) return depth;
                if (cur.left != null) queue.offer(cur.left); //添加下一层节点
                if (cur.right != null) queue.offer(cur.right); //添加下一层节点
            }
            depth++;
        }
        return depth;
    }
}
```

### 752. 打开转盘锁
BFS要防止往回走造成死循环, 所以要`visited`的HashSet. 这道题增加了不能到达的节点, 所以还需要额外的HashSet来存储这些不能去的节点. 如果只用`visited`一个哈希集合, 那么开头要检查`"0000"`是否在deadends内.
```
class Solution {
    public int openLock(String[] deadends, String target) {
        Set<String> visited = new HashSet();
        Set<String> deadends_set = new HashSet();
        Queue<String> q = new LinkedList<>();
        int res = 0;
        for (String s : deadends)
            deadends_set.add(s);
        q.add("0000"); //第一个结点
        visited.add("0000");

        while (!q.isEmpty()) {
            int size = q.size(); //当前包含元素数量
            for (int i = 0; i < size; i++) {
                String cur = q.poll(); //当前节点
                if (cur.equals(target)) return res;
                if (deadends_set.contains(cur)) continue;
                for (int j = 0; j < 4; j++) { //添加下一层8个节点
                    String up = add(cur, j);
                    String down = minus(cur ,j);
                    
                    if (!visited.contains(up)) {
                        visited.add(up);
                        q.offer(up);
                    }
                    if (!visited.contains(down)) {
                        visited.add(down);
                        q.offer(down);
                    }
                }
            }
            res++;
        }
        return -1;
    }

    private String add(String password, int index) {
        char[] parray = password.toCharArray();
        if (parray[index] == '9') parray[index] = '0';
        else parray[index]++;
        return new String(parray);
    }

    private String minus(String password, int index) {
        char[] parray = password.toCharArray();
        if (parray[index] == '0') parray[index] = '9';
        else parray[index]--;
        return new String(parray);
    }    
}
```

### 773. 滑动谜题
上一道题和这道题我们都可以把每一种状态想象成树的结点. 二维数组不好想象, 所以我们先把二维数组转换为`String`, 并且用一个数组来记录二维数组中每个元素的相邻元素在这个新的`String` board中的位置. 遍历的时候只要交换0和与其相邻的数字即可. 通过`visited`**确保不走走过的路(包括回头路)**.
```
class Solution {
    public int slidingPuzzle(int[][] board) {
        StringBuilder sbboard = new StringBuilder();
        for (int i = 0; i < 2; i++) {
            for (int j = 0; j < 3; j++) {
                sbboard.append(board[i][j]);
            }
        }
        String newboard = sbboard.toString();

        int[][] exchangeArray = new int[][]{
            {1, 3},
            {0, 2, 4},
            {1, 5},
            {0, 4},
            {1, 3, 5},
            {2, 4}
        };

        Queue<String> q = new LinkedList<>();
        Set<String> visited = new HashSet<>();
        q.offer(newboard);
        visited.add(newboard);
        int res = 0;
        String target = "123450";
        
        while (!q.isEmpty()) {
            int size = q.size();
            for (int i = 0; i < size; i++) {
                String cur = q.poll();
                if (cur.equals(target)) return res;

                int index = 0;
                while (cur.charAt(index) != '0') index++;
                for (int j : exchangeArray[index]) {
                    String tboard = swap(cur, j, index);
                    if (!visited.contains(tboard)) {
                        q.offer(tboard);
                        visited.add(tboard);
                    }
                }
            }
            res++;
        }
        return -1;
    }

    private String swap(String board, int i, int j) {
        char[] array = board.toCharArray();
        char temp = array[j];
        array[j] = array[i];
        array[i] = temp;
        return new String(array);
    }
}
```

## 参考
1. [labuladong算法-数组](https://mp.weixin.qq.com/s/1221AWsL7G89RtaHyHjRPNJENA)
2. [大雪菜LeetCode刷题活动第二期Week1——BFS与DFS专题讲解](https://www.bilibili.com/video/BV1yW411U72F)
3. [leetcode](https://leetcode-cn.com)
4. [acwing](https://www.acwing.com/problem/) 