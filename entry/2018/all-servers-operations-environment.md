---
Title: AnsibleとDockerによる1000台同時SSHオペレーション環境
Category:
- Operation
- Ansible
- Docker
Date: 2018-01-29T09:40:43+09:00
URL: http://blog.yuuk.io/entry/2018/all-servers-operations-environment
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/8599973812341703119
---

1000台同時SSHオペレーション環境を構築するにあたって、手元のローカル環境の性能限界の問題を解決するために、オペレーションサーバをSSHクライアントとすることによりSSH実行を高速化した。実行環境としてDocker、レジストリとしてAmazon ECR(EC2 Container Registry)を用いて、ローカル環境とオペレーションサーバ環境を統一することにより、オペレーションサーバの構成管理の手間を削減した。

[:contents]

# はじめに

3年前に [http://blog.yuuk.io/entry/ansible-mackerel-1000:title:bookmark] という記事を書いた。
この記事では、ホストインベントリとしてのMackerelと、並列SSH実行にすぐれたAnsibleを組み合わせ、オペレーション対象のホスト情報をプログラマブルに管理する手法を紹介した。また、工夫点として、並列SSH実行する上でのパフォーマンスチューニングやレガシーOSでの対応について紹介した。

しかし、並列度をあげるとforkするプロセスの個数が増えてローカル環境のリソースをくいつぶすという問題があった。加えて、並列度が小さいと実行終了まで待たされるという問題があった。
さらに、ローカル環境のOSやハードウェア性能が人によって異なるため、ローカル環境を統一して整備する手間があった。特に毎日利用する用途ではないため、利用頻度に対する整備コストが大きかった。

そこで、ローカルから対象ホスト群に接続するのではなく、オペレーションサーバをクライアントとして対象ホスト群に接続する仕組みに変更した。
これにより、スケールアップが容易になり、普段利用しているサーバ構成管理ツールを用いて、複数ユーザが同じ環境を利用できるようになった。
オペレーションサーバを対象ホスト群と同じデータセンター内に配置すれば、SSHクライアントと対象ホスト群とのレイテンシが小さくなるため、実行速度が向上する可能性があるというメリットもある。

しかし、playbookの開発にはオペレーションサーバではなくローカル環境を用いるため、ローカル環境とオペレーションサーバ環境の差異を小さくできるほうがよい。
そこで、Dockerを用いて、ローカルとオペレーションサーバ共通の環境を構築する。

# アーキテクチャと実装

## アーキテクチャ

アーキテクチャを図1に示す。
[f:id:y_uuki:20180128215001p:image:title="図１: アーキテクチャ"]
図１: アーキテクチャ

単一サーバから命令を各サーバへ送信するPull型のイベント送信モデルになる。
ローカル -> オペレーションサーバ -> 対象ホストの流れに沿ってSSHログインする。
オペレーションサーバ上では、並列SSHツール(Ansible)が起動し、記述したplaybookにしたがい、オペレーションを実行する。
対象ホスト一覧は、ホストインベントリ(Mackerel)のAPIから取得し、フィルタ([Ansibleのfilter](http://docs.ansible.com/ansible/latest/playbooks_filters.html))により、除外パターンを記述できる。
Ansibleそのものとplaybook、スクリプトなどが入ったDockerイメージをコンテナリポジトリ(ECR)にPUSHし、オペレーションサーバ上でPULLしておく。

## ヘルパースクリプト

運用観点では、オペレーションサーバのホスト名、Dockerイメージ名、コンテナ名などを覚えてオペレーションはしたくない。
そこで、ヘルパースクリプト [yuuki/ansible-operation-helper](https://github.com/yuuki/ansible-operation-helper) を参考のため公開している。これは社内事情を吸収するための層になるため、汎用的ではなく、そのまま動くわけではない。

- `Makefile`: でDockerイメージのビルド、ECRへのプッシュ、オペレーションサーバへのデプロイ、オペレーションサーバが動作するかどうかチェックするテストのタスクを定義している。
- `bin/on_local_container`: ローカルのDockerコンテナ上で引数指定したコマンドを実行する。
- `bin/on_remote`: オペレーションサーバにSSHしつつ、引数指定したコマンド実行する。
- `bin/on_remote_container`: オペレーションサーバ上のDockerコンテナにて、引数指定したコマンドを実行する。
- `libexec/mackerel.rb`: Mackerel用のAnsible Dynamic Inventory。

## 工夫

### オペレーションサーバ越しのroot権限実行

一斉にOSのパッケージを更新したいなど、コマンドをroot権限で実行したいことはケースはたくさんある。
Ansibleでは、[Become](http://docs.ansible.com/ansible/latest/become.html)により、対象ホストにてコマンドをsudo/suを用いて、インタラクティブパスワード入力でroot権限実行できる。
しかし、たいていはsudoerの秘密鍵がローカルにあるため、オペレーションサーバ経由で対象ホストにsudoerとしてログインするにはひと工夫必要になる。
((LinuxユーザとSSH鍵の管理ポリシーにより、とりえる手段がかわってくるため注意))

オペレーションサーバ上には当然sudoerの秘密鍵を配置するわけにはいかないため、今回はagent forwardingを用いた。
agent forwardingにより、オペレーションサーバ上のssh-agentプロセスがUNIXドメインソケットを提供し、オペレーションサーバ上のSSHクライアントがそのソケットから認証情報を読み出し、対象ホストへのSSH接続を認証する。

>
Agent forwarding should be enabled with caution. Users with the ability to bypass file permissions on the remote host (for the agent's Unix-domain socket) can access the local agent through the forwarded connection. An attacker cannot obtain key material from the agent, however they can perform operations on the keys that enable them to authenticate using the identities loaded into the agent.
>
https://linux.die.net/man/1/ssh

agent forwardingは、セキュリティポリシー上、問題ないか確認した上で利用したほうがよいと考えている。
上記のssh(1)のmanにも書かれているように、攻撃者がagentにロードされた認証情報を使って、オペレーションすることができてしまう。((鍵の中身そのものを取得はできないとのこと))
例えば、インターネットに公開された踏み台サーバ上でagent forwardingを用いることは好ましくない。

ヘルパーツールでは、agent forwardingをむやみに利用しないように、`on_remote`ラッパー実行時のみ、
forwardingを有効するために、-Aオプションを用いている。[参考](https://github.com/yuuki/ansible-operation-helper/blob/0780b39e36ed0ea5818026ff8ab84e05bbf28936/bin/on_remote#L15)

### rawモジュールとscriptモジュールのみの利用

本格的なサーバ構成管理をするわけではないため、シェルスクリプトを実行できれば十分だ。
Ansibleには[rawモジュール](http://docs.ansible.com/ansible/latest/raw_module.html)や[scriptモジュール](http://docs.ansible.com/ansible/latest/script_module.html)があり、シェルスクリプトを実行できる。
rawモジュールとscriptモジュールのメリットは、対象ホスト上のPython環境に左右されずにオペレーションできることだ。
例えば、Ansible 2.4からPython 2.4/2.5のサポートが切られた((https://github.com/ansible/ansible/issues/33101#issuecomment-345802554))ため、CentOS 5ではepelからpython 2.6をインストールして使うなどの手間が増える。[Ansible 2.4 upgrade and python 2.6 on CentOS 5
](https://stackoverflow.com/questions/46480621/ansible-2-4-upgrade-and-python-2-6-on-centos-5)

### Ansibleの実行ログのGit保存

どのサーバに対してオペレーションしたかを記録するため、ログをとっておくことは重要だ。
CTO motemenさんの [furoshiki2](https://github.com/motemen/furoshiki2)を用いて、Ansibleのコマンド実行ログをGit保存している。
[http://motemen.hatenablog.com/entry/2017/12/furoshiki:title:bookmark]
前述の `on_remote_container` 内でansible-playbookの実行に対して、`furo2`コマンドでラップするだけで使える。

# まとめと今後の課題

AnsibleとDockerを用いて、オペレーションサーバ経由で、大量のサーバに同時SSHオペレーションする環境の構築例を紹介した。
アーキテクチャと、アーキテクチャを実現するOSS、ヘルパーツールに加えて、3つの工夫として、agent forwardingによる権限エスカレーション、raw/scriptモジュールの利用、furoshiki2によるログのGit保存がある。

並列SSHすることが目的であれば、Ansibleはややオーバーテクノロジーといえるかもしれない。
具体的には、YAMLにより宣言的に記述されたplaybookや、各種Ansibleモジュールは今回の用途では不要であり、これらの存在は余計な学習コストを生む。
そこで、シンプルな並列SSHコマンド実行ツールとして、最近発見した[orgalorg](https://github.com/reconquest/orgalorg)に着目している。
サーバとの接続に対してプロセスをforkするAnsibleと異なり、orgalorgはgoroutineを用いるため、より高速な動作を期待できる。
しかし、現時点では、パスワードありsudo実行、ssh agent forwardingに対応していない((これぐらいならコントリビュートできそう))ことと、Ansibleの[Patterns](http://docs.ansible.com/ansible/latest/intro_patterns.html)機能が、ホスト管理上非常に便利なため、今のところはAnsibleを利用している。
