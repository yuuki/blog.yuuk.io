---
Title: Ansible + Mackerel APIによる1000台規模のサーバオペレーション
Category:
- Mackerel
- Ansible
Date: 2015-02-26T08:00:00+09:00
URL: https://blog.yuuk.io/entry/ansible-mackerel-1000
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/8454420450085450836
---

Ansible と Mackerel API を組み合わせて、1000台規模のサーバ群に対して同時にパッケージの更新やその他のサーバオペレーションのための方法を紹介します。
タイトルに Mackerel とありますが、それほど Mackerel に依存しない話です。
([https://blog.yuuk.io/entry/2018/all-servers-operations-environment:title:bookmark]に続編を書いています。)

# 背景

社内では、サーバ構成管理ツールとして Chef を使用しています。
Chef Server は運用が大変なので使用しておらず、knife-solo と Mackerel APIを組み合わせてホストと Chef role とのマッピングに Mackerel のロール情報を用いています。
また、Mackerel の Ruby クライアントを利用して recipe 内で API を叩いて、Mackerel から動的にホスト情報を参照するといったこともやっています。

<!-- more -->

今も構成管理は全て Chef でやっているのですが、Chef Server を用いていないため、cookbook の変更を基本的には1台1台適用することになります。(頻繁に変更するミドルウェアのクラスタ設定などは Capistrano を用いて該当設定ファイルのみ配っています。)
これでは、例えば mackerel-agent のようなパッケージを全てのホストに一斉に更新をかけるといったことができません。

そこで、エージェントレスな、並列実行に優れたサーバ構成管理ツール Ansible に注目しました。
並列実行だけでなく、後述するようにDynamic Inventoryを使ってサーバ管理ツールとの連携もしやすいことも重要です。

# 1000台規模で Ansible を使う

1000台規模で Ansible を使うために、いくつかのパフォーマンスチューニングを行います。
パフォーマンスチューニングについては、Ansibleの公式ブログが詳しいです。

[http://www.ansible.com/blog/ansible-performance-tuning:title:bookmark]

まず、forks で並列度を上げます。デフォルトは 5 ぐらいなので、100 とかにしてみます。
`local_action` とか使ってると詰まるので、手元のファイルを送信するのではなく、どこかのファイルサーバに置いて、各ホストから落としてくるほうがよさそうです。

次に、SSH接続を高速化します。
OpenSSH の `ControlPersist` を使うと、SSH のコネクションを維持するようになり、再接続のオーバヘッドを軽減できます。
さらに、[pipelining](http://docs.ansible.com/intro_configuration.html#pipelining) を有効にすると、かなりのパフォーマンスが改善されます。sudo を使う場合、`/etc/sudoers`で requiretty を無効にする必要があります。
以前は、[Accelerated Mode](http://docs.ansible.com/playbooks_acceleration.html)を使えばよかったようですが、今では SSH pipelining を使うほうがよいようです。
ただし、RHEL 5,6環境では OpenSSH のバージョンが古くて、paramiko という pure PythonでのSSH実装にフォールバックします。paramiko は `ControlPersist` 機能がないため、毎回接続が発生するので、これを回避するために、Accelerated Mode を使うとよいようです。

リポジトリルートに下記のような設定を書いた `.ansible.cfg` を設置して、他のチームメンバーも同じ設定を使えるようにしておきます。

```
[defaults]
transport=ssh
pipelining=True
forks=100

[ssh_connection]
ssh_args=-o ControlMaster=auto -o ControlPersist=30m
scp_if_ssh=True 
control_path=%(directory)s/%%h-%%r
```

# Mackerel APIと組み合わせる

通常、Ansible では静的な inventory ファイルに実行対象のホストを記述する必要があります。
特に1000台以上もサーバを持っているとファイルで管理はしていられません。
普段、Mackerel などのサーバ管理ツールを使っている場合、API経由でホスト情報がとれるので、なるべくホスト情報を別のファイルを管理したくありません。
そこで、Ansible の [Dynamic Inventory](http://docs.ansible.com/intro_dynamic_inventory.html) を使います。
Dynamic Inventory は EC2 や Zabbix のホスト情報を inventory として使用することができる機能です。
実体は、EC2ならEC2のAPIを用いて、定められたフォーマットのJSONを出力するスクリプトです。 [https://raw.githubusercontent.com/ansible/ansible/devel/plugins/inventory/ec2.py:title]
Dynamic Inventory スクリプトの書き方は [http://docs.ansible.com/developing_inventory.html:title] に書かれています。

## Mackerel API Dynamic Inventory
[http://docs.ansible.com/developing_inventory.html#tuning-the-external-inventory-script] によると、JSON出力に`_meta` キーを含めるフォーマットのほうが実行が高速らしいです。
つまり、下記のように、ロール名やサービス名のようなグループ名をキーとして、グループ内のホスト識別子(ホスト名に限らない)をバリューとしたJSONを出力するスクリプトを書けばよいです。
各ホストの情報は、`_meta` => `hostvars` のキーの中にいれておく。`hostvars` は playbook の中で参照することができる。例えば、Mackerel の status に応じた task を書くことができます。

```
{
  "Example-Blog_app": ["blogapp001.host.h", "blogapp002.host.h"],
  "Example-Blog_proxy": ["blogproxy001.host.h", "blogdproxy002.host.h"],
  ...
  "Example-Blog": ["blogapp001.host.h", "blogapp002.host.h", "blogproxy001.host.h", "blogdproxy002.host.h"]
  ...
  "_meta" => { 
    "hostvars" => {
      "blogapp001.host.h" => {
        "status": "working",
        "roleFullnames": ["Example-Blog::app"]
        ...
      },
      "blogapp002.host.h" => {
        ...
      },
      ...
    }
  }
}
```

簡単な Mackerel 用の Dynamic Inventory スクリプトを書いてみました。 
Ansible は Python で書かれているので、本当は Python で書くのが筋がよさそうですが、Python クライアントがないので、とりあえず Ruby で書きました。
言語による大した違いはないと思います。

[https://gist.github.com/y-uuki/5aa1d703f163d22a5f46:embed]

実行方法は簡単で、`-i` オプションに実行権限をつけてスクリプトを渡します。 
パターンを `all` にすると、inventory 内の全ホストが対象になります。

```
$ ansible -i ./bin/mackerelio_inventry all --list-hosts
```

## playbook

### playbooks リポジトリのディレクトリ構成

Ansible の公式ドキュメントに構成のベストプラクティスが書かれています。 [http://docs.ansible.com/playbooks_best_practices.html:title]
今回は、そんなに複雑な構成管理をするわけではないので、シンプルなディレクトリ構成にしています。

- 普通のフルプロビジョニング用途とは思想が異なり、単発のオペレーション用途なので、playbook ファイルはオペレーション単位で作る。 `mackerel-agent.yml`、`mkr.yml`、`jq.yml`など。
- `script/` 以下に Dynamic Inventory スクリプト、`bin/`以下に直接実行するファイルを置く。`bin/mackerelio_inventry` は `script/mackerelio.rb` を bundle exec でラップしたもの
- `roles` 以下に使用する Ansible Role を置く。これは普通。[https://galaxy.ansible.com/list#/roles/2961:title]

```
.
├── Gemfile
├── Gemfile.lock
├── bin
│   ├── ansible-install-simplejson
│   ├── ansible-pssh
│   └── mackerelio_inventry
├── mackerel-agent.yml
├── mkr.yml
├── jq.yml
├── requirements.yml
├── roles
│   └── mackerel.mackerel-agent
├── script
   └── mackerelio.rb
└── vars
     └── mackerel-agent-plugin
```

### jq のインストール

例として、実際に `jq` を配布してみます。`jq.yml` に下記のような設定を書きます。jq は apt リポジトリはありますが、yum リポジトリはない？ようなので、実行ファイルをそのまま `get_url` モジュールでダウンロードするだけです。サーバのディストリ情報などは使わないため、`gather_facts` は不要なので切っておきます。

```
---
-
  hosts: all
  sudo: yes
  gather_facts: no
  tasks:
  - name: install jq
    get_url: url=http://stedolan.github.io/jq/download/linux64/jq dest=/usr/local/bin/jq mode=0755
```

下記コマンドで実行します。
     
```
$ ansible-playbook --ask-sudo-pass -i ./bin/mackerelio_inventry ./jq.yml
```

だいたい20分くらいで数千台のサーバに配り終えました。それなりに時間はかかりますね。
失敗したホストに対してのみリトライしたければ上記コマンドに `--limit @/Users/y_uuki/jq.retry` をつけて実行してやります。

jq は `all` を指定して全てのホストに配りましたが、Mackerel のサービスやロール単位で task を実行することができます。
[http://docs.ansible.com/intro_patterns.html:title] に、対象ホストを絞り込むためのパターン指定方法があります。ワイルドカードやOR条件、AND条件、NOT条件などでそれなりに柔軟に指定できます。

# 補足

## Capistrano などの並列sshツールとの違い

Capistrano でも複数ホストに同時にコマンド実行することは可能です。
ただし、実際に 1000 台に対して実行すると、手元のsshで詰まったり、実行に失敗したホストの情報がよくわからなかったりするので、複数回実行します。
途中で詰まったりして1回の実行に1時間以上かかるので、結構大掛かりになります。
Capistrano v2 を使用していますが、Capistrano v3 からSSHのバックエンドが `sshkit` になっているので、もう少しはマシかもしれません。

Ansible では、仮に失敗したホストがあっても、失敗したホストのリストをファイルに残してくれます。次回は失敗したホストのみ適用したり、失敗したホストのみ cssh などを使って、手動でオペレーションすることも可能です。
一方実行時間は Capistrano ほどではないですが、それなりに時間はかかります。この辺りは後述する Ansible v2 の free strategy を使うか、`gather_facts no` を指定して各ホストから情報収集ステップをスキップして、代わりに Mackerel の Inventory から取得した情報だけでホスト情報を賄うなどの高速化の可能性があります。

わざわざ Ansible や Capistrano のようなレシピ的なものに記述するタイプではなく、単純にコマンド実行するツールで十分かもしれません。 [http://d.hatena.ne.jp/eco31/20101219/1292732347:title:bookmark] に Parallel ssh や Cluster ssh など複数のリモートホストに同じコマンドを一斉実行するためのツールがまとめられています。
しかし、誰がいつどのようなオペレーションをやったのか記録が残らないかつ、適用前にPull Requestにしてレビューすることができないため、レシピとして記述するタイプのツールのほうが Infrastructure As Code の観点からみても優れていると思います。
（ワンタイムな操作の場合は日付を付けた playbook を用意するとよいかもしれません）

さらに、前述の `get_url` モジュールのように Ansible は標準モジュールが充実しており、ある程度冪等性を期待できるオペレーションがやりやすいのでそのあたりも加点ポイントです。

## ansible-pssh

本当に単純にコマンドを実行したい場合、`ansible-pssh` というスクリプトを用意して、shellモジュールを使って実行させる。

```
#!/bin/bash

set -ex

ANSIBLE_INVENTORY_SCRIPT=./bin/mackerelio_inventry

PATTERN=$1 # Example-Bookmark
if [ -z $PATTERN ]; then
    echo 2>&1 "role required: ansible-pssh ROLE COMMAND"
    exit 1
fi

COMMAND="${@:2:($#-1)}"
if [ -z $COMMAND ]; then
    echo 2>&1 "role command: ansible -pssh ROLE COMMAND"
    exit 1
fi

exec ansible --ask-sudo-pass -i $ANSIBLE_INVENTORY_SCRIPT $PATTERN -m shell -a "$COMMAND"
```

```
$ ./bin/ansible-pssh all 'curl -sSfL https://raw.githubusercontent.com/mackerelio/mkr/master/script/install_linux_amd64 | sudo bash'
```

## python-simplejson

CentOS 5 環境だとプリインストールされている Python のバージョンが古くて、ansible のモジュールに必要な `python-simplejson` がインストールされていない。
そこで、あらかじめ下記のようなスクリプトを実行しておく。raw モジュールだと `python-simplejson` を使わないので、実行できる。

```
#!/bin/bash

set -ex

ANSIBLE_INVENTORY_SCRIPT=./bin/mackerelio_inventry

PATTERN=$1 # Example-Bookmark
if [ -z $PATTERN ]; then
    echo 2>&1 "role required: ansible-install-simplejson PATTERN COMMAND"
    exit 1
fi

exec ansible --ask-sudo-pass -s -i $ANSIBLE_INVENTORY_SCRIPT $PATTERN -m raw -a "[ -e /usr/bin/yum ] && yum install -y python-simplejson || true" # https://github.com/ansible/ansible/issues/1529
```


## Ansible v2
[http://www.slideshare.net/jimi-c/whats-new-in-v2-ansiblefest-london-2015:title:bookmark]

先日の AnsibleFest London 2015 で Ansible v2 の発表がありました。
内部実装の設計変更やエラーメッセージの改善などの変更がありますが、Execution Strategy 機能に注目しています。
Execution Strategy は task の実行方式を変更できる機能で、従来の liner 方式に加えて、他のホストの task 実行をまたずになるべく速く task を実行できる free 方式が実装されるようです。
これにより、高速実行できることを期待できます。

# 関連

以前にMackerel APIの利用例を書いていました。
[http://yuuki.hatenablog.com/entry/tmux-ssh-mackerel:embed]

1年以上前に Chef と Ansible について書いていました。
[http://yuuki.hatenablog.com/entry/2013/08/13/220330:embed]

tagomoris さんのスライドは非常に参考になりました。かなり近い思想で運用されているようにみえます。 
[http://www.slideshare.net/tagomoris/ansibleja:embed]


# まとめ

若者なので大量に ssh しまくっています。

Ansible と Mackerel API を組み合わせたサーバオペレーションを紹介しました。
また、1000台規模で使えるツールであることを確認しました。

Mackerel の思想の一つとして、APIによるホスト情報の一元管理が挙げられます。Ansible の静的Inventoryファイルではなく、Dynamic Inventory により、Ansible 側でホスト情報を管理しなくてすむようになります。
さらに、Mackerel に登録したサービス、ロールやステータスなどのホスト情報を扱えるようになるのが便利なところです。

本当は1台のホストから多数のホストに接続する push 型ではなく、Gossipプロトコルなどのアドホックなネットワーク通信を用いた Serf、Consul のような pull 型のほうが圧倒的にオペレーション速度は速いはずですが、そもそも pull を実行するソフトウェアを各ホストにインストール/アップデートしなければならないため、このような仕組みは必要だと思っています。

# Twitter

[https://twitter.com/wyukawa/status/570789782122418176:embed]

[https://twitter.com/tagomoris/status/570803660025827329:embed]

