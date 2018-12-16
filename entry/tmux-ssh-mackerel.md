---
Title: tmux + ssh + Mackerel API を組み合わせたとにかくモダンなサーバオペレーション
Category:
- Mackerel
Date: 2014-09-26T09:00:00+09:00
URL: https://blog.yuuk.io/entry/tmux-ssh-mackerel
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/8454420450066357653
---

冗長化させたホストやスケールアウトさせたホストなどの同じサーバ構成をもつホストグループや、あるサービスに所属するホスト全てに同時にsshして同時に操作したいことがある。
複数のホストに同時ログインするツールとして cssh があるけど、毎回複数のホスト名をチマチマ入力したり、すぐに古くなるホスト一覧ファイルを手元に持ちたくない。Immutable Infrastructure 時代にはそぐわない。Immutable Infrastructure 時代にはホスト名なんて毎日変化するし誰も覚えてない。サーバ管理ツール上のグループ名を使ってグループ配下のホストに同時にsshしたい。
あと、cssh は個人的に挙動がなんか微妙なので、代わりに tmux と ssh を組み合わせている。
cssh はマスタとかスレーブとか気持ちはわかるけど、複数ウィンドウ操作は使い慣れたターミナルマルチプレクサを使いたい。

[https://www.youtube.com/watch?v=iZElF6GVkjI:title]

もう1台1台丁寧に ssh したり、毎回複数のホスト名をチマチマ指定して cssh する時代は終わった。
（タイトルに Mackerel と書いてるけど、半分以上は Mackerel に依存しない話です。）

<!-- more -->

## デモ
[http://i.imgur.com/Bvj9pes.gif:image]

## tssh

tmux を使って、複数ホストに同時 ssh ログインして同時にオペレーションできる。

[https://github.com/dennishafemann/tmux-cssh:title] を使ってもよいし、下記のようなスクリプトを使ってもよい。
挙動はほぼ同じで、tmux を使うと30行足らずで実現できるがすごい。

https://github.com/y-uuki/opstools/blob/master/tssh

```sh
#!/bin/bash

hosts=("$@")
session_name="tmux-ssh-$$"

tmux start-server

is_first="true"
for host in ${hosts[@]}; do
    cmd="ssh $SSH_OPTION $USER@$host"
	if [ "${is_first}" == "true" ]; then
		tmux new-session -d -s $session_name "$cmd"

		is_first="false"
    else
        tmux split-window  -t $session_name "$cmd"
        tmux select-layout -t $session_name tiled 1>/dev/null
    fi
done

tmux set-window-option -t $session_name synchronize-panes on
tmux select-pane -t 0
tmux attach-session -t $session_name
```

### Usage

```sh
$ tssh blogapp001.domain blogapp002.domain blogapp003.domain ...
$ tssh blogapp00{1,2,3}.domain # ditto
```

このあと、だいたい top 叩くか ログファイルを tail したりする。

おまけとして、特定のホストのみを操作したいときは tmux の synchronize-panes と ペイン移動を使う。
~/.tmux.conf に下記の設定を書いておいて、<prefix> + g でペインの同期をオフにして、操作したいホストに割り当てられたペインに移動して操作するとよさそう。

```
bind-key g setw synchronize-panes
```

tssh だけでも十分便利だが、Mackerel の RESTful API を使うことで、ホスト名または IP アドレスに依存しないオペレーションができる。、

## Mackerel

[https://mackerel.io:title:bookmark]

サーバ管理ツール Mackerel では、ホストをロールで管理する。
具体的には、サービス名とロール名の組で、Saba-Blog::proxy や Saba-Blog::app、Saba-Blog::db みたいな感じ。

[f:id:y_uuki:20140925080121p:image]

Mackerel はモニタリングだけでなく、RESTful API を使ったサーバ管理の自動化も促進しようとしている。

[http://help-ja.mackerel.io/entry/spec/api/v0:title]

今回は、ロールに所属するホスト一覧が取りたいので下記のような curl と jq を組み合わせたワンライナーを使う。
これくらいの用途なら API クライアントを使うまでもない。

```sh
$ curl -s -H "X-Api-Key:<apikey>" -X GET 'https://mackerel.io/api/v0/hosts.js?service=Saba-Blog&role=app' | jq -a -M -r ".hosts[].name
blogapp001.domain
blogapp002.domain
blogapp003.domain
```

毎回ワンライナーを叩くのもだるいのでスクリプトにする。```~/bin/role``` に以下のようなスクリプトを置いてる。

```sh
#!/bin/bash

if [[ $1 == '' ]]; then
  echo "requried service name"
  exit 1
fi
if [[ $2 == '' ]]; then
  echo "requried role name"
  exit 1
fi

curl -s -H "X-Api-Key:<apikey>" -X GET "https://mackerel.io/api/v0/hosts.json?service=$1&role=$2" | jq -a -M -r ".hosts[].name
```

上記 role コマンドにサービス名とロール名を指定してやれば簡単にホスト一覧を取得できる。

```sh
$ role Saba-Blog app
blogapp001.domain
blogapp002.domain
blogapp003.domain
```

role コマンドの他に service コマンドも置いてる。さっきとほとんど同じ。

```sh
#!/bin/bash

if [[ $1 == '' ]]; then
  echo "requried service name"
  exit 1
fi
curl -s -H "X-Api-Key:<apikey>" -X GET 'https://mackerel.io/api/v0/hosts.js?service=$1' | jq -a -M -r ".hosts[].name
```

```sh
service Saba-Blog
blogproxy001.domain
blogproxy002.domain
blogproxy003.domain
blogapp001.domain
blogapp002.domain
blogapp003.domain
...
```

## tssh + Mackerel

```sh
$ tssh `role Saba-Blog app`
```

これでなんでもできる。
Zabbix や Datadog など他のサーバ管理ツール/サービスを使っても、もちろん同じことはできるだろうけど、Mackerel はホストのグルーピングの指針が定まっているので、グルーピング方針に迷うことが少ないと思う。

社内でこの手の連携は昔からやってて、とにかく便利で毎日使ってる。
