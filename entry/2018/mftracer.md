---
Title: TCP接続の追跡によるホスト単位でのネットワーク依存関係分析システム
Category:
- Architecture
- Monitoring
- Tracing
Date: 2018-11-11T22:46:32+09:00
URL: https://blog.yuuk.io/entry/2018/mftracer
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/10257846132668194747
Draft: true
CustomPath: 2018/mftracer
---

この記事は，[Web System Architecture研究会#3](https://websystemarchitecture.hatenablog.jp/entry/2018/10/09/231937)の予稿です．
共著者 id:masayoshi:detail

# あらまし

# 背景

ウェブシステムは，一般的に，分散したホスト上で動作するソフトウェアが互いにネットワーク通信することにより構成される．
相互にネットワーク通信するシステムにおいて，システム管理者があるネットワーク内のノードに変更を加えた結果，ノードと通信している他のノードに変更の影響がでることがある．
ネットワーク接続数が多いまたはノードが提供するサービスの種類が多くなるほど，システム管理者が個々の通信の依存関係を記憶することは難しくなる．
さらに，常時接続しておらず必要なタイミングで一時的に通信するケースでは，あるタイミングの通信状況を記録するだけでは通信の依存関係を把握できない．
システム管理者がネットワーク通信の依存関係を把握できないために，システムを変更するときの影響範囲がわからず，変更のたびに依存関係を調査しなければならないという問題がある．

先行手法では，ネットワーク内の各ノード上で動作するiptablesのようなファイアウォールのロギング機構を利用し，TCP/UDPの通信ログをログ集計サーバに転送し，ネットワークトポロジを可視化する研究[1]がある．
次に，tcpdumpのようなパケットキャプチャにより，パケットを収集し，解析することにより，ネットワーク通信の依存関係を解析できる．
さらに，sFlowやNetFlowのように，ネットワークスイッチからサンプリングした統計情報を取得するツールもある．
また，アプリケーションのログを解析し，依存関係を推定する研究[2]がある．
マイクロサービスの文脈において，分散トレーシングは，各サービスが特定のフォーマットのリクエスト単位でのログを出力し，ログを収集することにより，リクエスト単位でのサービス依存関係の解析と性能測定を可能とする[3]．

しかし，ファイアウォールのロギング機構とパケットキャプチャには，パケット通信レイテンシにオーバーヘッドが追加されるという課題がある．
さらに，サーバ間の依存関係を知るだけであれば，どのリッスンポートに対する接続であるかを知るだけで十分なため，パケット単位や接続単位で接続情報を収集すると，TCPクライアントのエフェメラルポート単位での情報も含まれ，システム管理者が取得する情報が冗長となる．
分散トレーシングには，アプリケーションの変更が必要となる課題がある．

そこで，本研究では，TCP接続に着目し，アプリケーションに変更を加えることなく，アプリケーション性能への影響が小さい手法により，ネットワーク通信の依存関係を追跡可能なシステムを提案する．
本システムは，TCP接続情報を各サーバ上のエージェントが定期的に収集し，収集した結果を接続管理データベースに保存し，システム管理者がデータベースを参照し，TCP通信の依存関係を可視化する．
まず，パケット通信やアプリケーション処理に割り込まずに，netstatのような手段でOSのTCP通信状況のスナップショットを取得する．
次に，取得する情報の冗長性を削減するために，TCPポート単位ではなく，リッスンポートごとにTCP接続を集約したホストフロー単位でTCP通信情報を管理する．
さらに，過去の一時的な接続情報を確認できるように，接続管理データベースには時間範囲で依存関係を問い合わせ可能である．

提案システムを実現することにより，システム管理者は，アプリケーションへの変更の必要なく，アプリケーションに影響を与えずに，ネットワーク構成要素を適切に抽象化した単位でネットワーク依存関係を把握できる．

<!-- - 前提: ウェブシステムは、複数の分散したホスト上で動作するソフトウェアが互いにネットワーク通信することにより構成されることが一般的である。
- 問題意識: システム障害の影響範囲がわからない。システムを変更するときの影響範囲がわからない。
- 課題1: 先行手法では、サービスメッシュやwhitebox分散トレーシングなどアプリケーションに変更を加える必要がある。しかし、すでに多数のシステムが稼働している環境においてアプリケーションに変更を加えることは大きな手間を要する。
- 課題2: パケットレベルで追跡する手法がある。しかし、パケットをリアルタイムで解析し、収集することは負荷が大きい。
- 課題3: Linuxのiptablesのようなファイアウォールのロギング機構で追跡する手法がある。しかし、既存のファイアウォール設定との衝突や、パケット転送のレイテンシが悪化するという課題がある。
- 課題4: 多数の複製ノードをもつ分散システムにおいて、ノード単位の情報を表示すると理解しづらい
- 課題5: クライアントのephmeral portを含む1つ1つのコネクション管理することには意味はなく、ノイズとなる
- 課題6: cronによるスケジューリングによるジョブ実行などにより、特定の時刻にネットワーク通信することもあるため，ある時刻での通信のスナップショットをとるだけでは不十分である。
- 本研究: アプリケーションに変更を加えることなく、負荷の小さい収集方法にて、分散アプリケーションの依存関係を追跡する。
- アイデア(課題1,2)1: OSのTCPコネクション状況を都度中央データベースに保存し、問い合わせにより関係性を解析する。
- アイデア(課題4): 中央データベースの問い合わせ時に複製ノードをロール単位でまとめる。ただし、あらかじめロールでまとめておく必要はある。
- アイデア(課題5): https://memo.yuuk.io/entry/2018/03/25/152138 のように、ホスト同士の関係性を知るには不要なephemeral portを無視し，listen portでまとめる
- アイデア(課題6): 中央の管理データベースに関係情報を保持し、時間範囲で問い合わせできるようにする -->

# 提案システム

## システム概要

提案システムの外観図を以下に示す．

```ascii
+--------+
| host   |--------+
| (agent)|        |
+--------+        | send
                  V
+------+       +------+
| host |------>| CMDB |
+------+  send +------+
                  | 
+----------+      |  get
| analyzer |<-----+
+----------+
     ^
     | get
+----------+
| sysadmin |
+----------+
```

提案システムの動作フローを以下に示す．

1. 各ホスト上のエージェントがホストフロー情報を取得する．
1. エージェントはCMDB(接続管理データベース)のホストフロー情報を送信する．
1. システム管理者はアナライザーを通して，CMDBに格納されたホストフロー情報を取得し，解析された結果を表示する．

## ホストフロー

個々のTCP接続情報は，通常<送信元IPアドレス，送信先IPアドレス，送信元ポート，送信先ポート>の4つの値のタプルにより表現する．
ホストフローは，送信元ポートまたは送信先ポートのいずれかをリッスンポートとして，同じ送信元IPアドレスとを送信先IPアドレスをもち，同じリッスンポートに対してアクティブオープンしている接続を集約したものを指す．
ホストフローの具体例は次のようになる．

```ascii
Local Address:Port   <-->   Peer Address:Port     Connections
10.0.1.9:many        -->    10.0.1.10:3306        22
10.0.1.9:many        -->    10.0.1.11:3306        14
10.0.2.10:22         <--    192.168.10.10:many    1
10.0.1.9:80          <--    10.0.2.13:many        120
10.0.1.9:80          <--    10.0.2.14:many        202
```

## 接続管理データベース

CMDBは，ノードとホストフローを格納する．
ノードは，ユニークなIDをもち，IPアドレスとポートが紐付けられる．
ホストフローは，ユニークなID，アクティブオープンかパッシブオープンかのフラグ，送信元ノード，送信先ノードをもつ．

## アナライザー

アナライザーがCMDBに対して問い合わせるパターンは次の2つである．

- a) ある特定のノードを指定し，指定したノードからアクティブオープンで接続するノード一覧を取得する
- b) ある特定のノードを指定し，指定したノードがパッシブオープンで接続されるノード一覧を取得する

# 実装

## 概要

提案手法を実現するプロトタイプ実装であるmftracerをGitHubに公開している．<https://github.com/yuuki/mftracer>
mftracerの概略図を以下に示す．

```ascii
+-----------+
| mftracerd |----------+
+-----------+          | INSERT or UPDATE
                       V
+-----------+         +------------+
| mftracerd |------>  | PostgreSQL |
+-----------+         +------------+
                       ^       | SELECT
+-----------+          |       |            +----------+
| mftracerd |----------+       | <--------- | Mackerel |
+-----------+                  v            +----------+
                          +--------+  
                          | mftctl |
                          +--------+
```

ロールと実装の対応表を以下に示す．

| ロール名 | 実装名 | 
|:--------|:-------|
| agent   | mftracerd | 
| CMDB    | PostgreSQL |
| analyzer | mftracer |

mftracerでは，予め各ホストを[Mackerel](https://mackerel.io)に登録し，サービス・ロールという単位でグルーピングを設定しておくことにより，mftctlがホスト単位ではなく，サービス・ロール単位でノードを集約し，扱うことができる．

## 使い方

mftracerの使い方の例を以下に示す．

```shell
$ mftctl --level 2 --dest-ipv4 10.0.0.21
10.0.0.21
└<-- 10.0.0.22:many (connections:30)
└<-- 10.0.0.23:many (connections:30)
└<-- 10.0.0.24:many (connections:30)
	└<-- 10.0.0.30:many (connections:1)
	└<-- 10.0.0.31:many (connections:1)
└<-- 10.0.0.25:many (connections:30)
...
```

```shell
$ mftctl --level 2 --dest-service blog --dest-roles redis --dest-roles memcached
blog:redis
└<-- 10.0.0.22:many (connections:30)
└<-- 10.0.0.23:many (connections:30)
└<-- 10.0.0.24:many (connections:30)
	└<-- 10.0.0.30:many (connections:1)
	└<-- 10.0.0.31:many (connections:1)
└<-- 10.0.0.25:many (connections:30)
blog:memcached
└<-- 10.0.0.23:many (connections:30)
└<-- 10.0.0.25:many (connections:30)
...
```

##　ホストフロー

プロトタイプでは，netstatとssコマンドで利用されているLinuxのNetlink APIを利用して，TCP接続情報を取得している．
[https://memo.yuuk.io/entry/2018/06/18/003157:title]

各接続の方式がアクティブオープンかパッシブオープンかを判定する実装は次のようにになっている．

1. 各ホスト上で`/proc/net/tcp`から現在プロセスがリッスンしているポートの一覧を取得する．
1. Netlink APIによりTCP接続情報を取得する.
1. 1.と2.を突き合わせ，接続先ポートがリッスンポートであればアクティブオープン，それ以外の接続はパッシブオープンと判定する．

## CMDBのスキーマ

CBDBのスキーマ定義を以下に示す．

```sql
CREATE TYPE flow_direction AS ENUM ('active', 'passive');

CREATE TABLE IF NOT EXISTS nodes (
    node_id bigserial NOT NULL PRIMARY KEY,
    ipv4    inet NOT NULL,
    port    integer NOT NULL CHECK (port >= 0)
);
CREATE UNIQUE INDEX IF NOT EXISTS nodes_ipv4_port ON nodes USING btree (ipv4, port);

CREATE TABLE IF NOT EXISTS flows (
    flow_id                 bigserial NOT NULL PRIMARY KEY,
    direction               flow_direction NOT NULL,
    source_node_id          bigint NOT NULL REFERENCES nodes (node_id) ON DELETE CASCADE,
    destination_node_id     bigint NOT NULL REFERENCES nodes (node_id) ON DELETE CASCADE,
    connections             integer NOT NULL CHECK (connections > 0),
    created                 timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated                 timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE (source_node_id, destination_node_id, direction)
);
CREATE UNIQUE INDEX IF NOT EXISTS flows_source_dest_direction_idx ON flows USING btree (source_node_id, destination_node_id, direction);
CREATE INDEX IF NOT EXISTS flows_dest_source_idx ON flows USING btree (destination_node_id, source_node_id);
```

nodesテーブルはノード情報を表現し，とflowsテーブルはホストフロー情報を表現する．

## 実装の課題

- ネットワークトポロジの循環に対する考慮
- クラウド事業者が提供するマネージドサービスを利用している場合，IPアドレスから実体をたどることの困難
- パターンa)の実装
- 時間範囲を指定した依存関係の取得

# むすび

システムの複雑化に伴い，システム管理者が個々のネットワーク通信の依存関係を記憶することが難しくなっている．
そこで，アプリケーションを変更せずに，アプリケーションに影響を与えることなく，適切な抽象度で情報を取得可能な依存関係解析システムを提案した．
実装では，Go言語で書かれたエージェントがLinuxのNetlink APIを利用し，RDBMSにホストフロー情報を格納し，Go言語で書かれたCLIから依存関係を可視化できた．

今後の課題として，問題の整理，サーベイ，評価がある．
問題の整理では，ネットワークの依存関係といっても，OSI参照モデルにおけるレイヤごとにシステム管理者が必要とする情報は異なるため，最終的にレイヤ4のTCP通信に着目する理由を明らかにする必要がある．
サーベイについては，ネットワークの依存関係解析に関する先行研究は多岐に渡るため，
評価については，先行手法となるファイアウォールロギングとパケットキャプチャによるレイテンシ増大による影響を定量評価し，提案手法の優位性を示す必要がある．
また，実装では，すべての接続情報を取得できるわけではないため，接続情報の取得率を確認し，実運用において，十分な精度であることを確認する必要がある．
さらに将来の展望として，同じような通信をしているホストをクラスタリング推定し，システム管理者がより抽象化された情報だけをみて依存関係を把握できるようにしたい．
また，コンテナ型仮想化環境での依存関係の解析への発展を考えている．

# 参考文献

- [1]: John K Clawson, "Service Dependency Analysis via TCP/UDP Port Tracing", Master thesis, Brigham Young University, 2015
- [2]: Jian-Guang LOU, Qiang FU, Yi WANG, Jiang LI, "Mining dependency in distributed systems through unstructured logs analysis", ACM SIGOPS Operating Systems Review, 2010, vol 44, no 1, pp. 91
- [3]: @itkq, "サービスのパフォーマンス数値と依存関係を用いたサービス同士の協調スケール構想", 第1回Web System Architecture研究会, https://gist.github.com/itkq/6fcdaa31e6c50df0250f765be5577b59
- [x]: id:masayoshi:detail, "ミドルウェア実行環境の多様化を考慮したインフラアーキテクチャの一検討", 第2回Web System Architecture研究会,https://masayoshi.hatenablog.jp/entry/2018/05/19/001806
