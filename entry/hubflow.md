---
Title: "HubFlow使ってみた"
Category:
- Git
- GitHub
Date: 2013-01-12T10:31:21+09:00
URL: http://blog.yuuk.io/entry/hubflow
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/12704914408862859788
---

## HubFlowとは

- [http://datasift.github.com/gitflow/index.html:title:bookmark]

HubFlowはGitHubリポジトリで[https://github.com/nvie/gitflow:title=GitFlow]を便利に使うためのGitコマンド拡張です．  
gitflowをforkして開発されています．[https://github.com/datasift/gitflow:title]  
今の時点では，大幅に便利になるというものではない感じです．  
```git hf```のようにサブコマンドhfを用いたコマンド体系なので，gitflowと併用できます．  
さらに，gitflowを利用している既存のリポジトリに対しても```git hf init```で上書きすれば使えます．  

## 使い方

![HubFlow Poster](http://datasift.github.com/gitflow/GitFlowWorkflowNoFork.png)

なんか新しい図が出てますが，流れはGitFlowとほとんど変わりません．  
リモートブランチとfork元のブランチに対する操作が用意されていないGitFlowに対して，HubFlowでは用意されているという点が異なります．


## 便利になったところ

```
git hf update
```
でmasterとdevelopの両方をupstreamに追従できます．


------

git push origin feature/xxxxを
```
git hf feature push
```
で代替できます．
feature/xxxxを指定しなくてもカレントブランチに対応するリモートブランチにpushしてくれます(pullについても同様)．  
Gitのpush時のデフォルトの挙動をsimpleモードにしたときとおそらく同じ挙動だと思います．（see おまけ）

>`simple` - like `upstream`, but refuses to push if the upstream branch's name is different from the local one. This is the safest option and is well-suited for beginners. It will become the default in Git 2.0. 
https://github.com/git/git/blob/master/Documentation/config.txt

------

プルリクエストがマージされたのちに
```
git hf feature finish
```
でカレントブランチとリモートブランチを削除してくれる．

## 欲しい機能

- git hf release start とかしたときに，[http://datasift.github.com/gitflow/Versioning.html:title=Semantic Versioning]にしたがって，自動でバージョン番号を管理してくれると良いですね．


## おまけ -  git hf feature push時の挙動

ソースコードをみて確認します．

- https://github.com/datasift/gitflow/blob/develop/git-hf-feature

[gist:4515603]

1. feature pushするとcmd_push関数が呼ばれます．
2. parse_remote_name関数でfeature pushの第1引数がREMOTEに，第2引数がNAMEが代入されます．BRANCHには feature/$NAME が代入されます．引数がなければいずれの変数も空になります．
3. feature pushに引数がなければ$REMOTEにoriginがセットされます．
4. name_or_current関数でNAMEが空のときに，use_current_feature_branch_name関数を呼んでBRANCHにカレントブランチ名を，NAMEに'feature'を削ったカレントブランチ名を代入する．
5. git push "$REMOTE" "$BRANCH:refs/heads/$BRANCH" でpushします．

以上より，feature pushの引数を指定しない場合は，カレントブランチ名が補完されることがわかりました．


普段はforkモデルではなく，ブランチモデルを使っているので，あまり恩恵が預かれない感じです．
