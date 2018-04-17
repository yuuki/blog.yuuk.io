---
Title: Webサービスをデータセンター移行するときに必要となる技術要素
Category:
- Infrastructure
- Migration
Date: 2018-02-19T09:20:00+09:00
URL: http://blog.yuuk.io/entry/2018/datacenter-migration-for-web-system
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/8599973812302592884
Draft: true
---

クラウドへの移行を含むデータセンター(以下DC)移行事例を基に、WebサービスをDC移行するための基本的な技術要素を紹介します。
最近、社内で大規模なDC移行を実施しつつあり、DC移行とはなにかをメンバーへ共有するための文章でもあります。
ちなみに、この記事は[Hosting Casual Talks #4](https://connpass.com/event/62208/)の発表内容を書き下ろしたものです。

<!-- more -->
[:contents]

# 移行事例

まず、この発表でDC移行がどういうものを指すかを示すために、2つのサービスの移行事例を紹介します。
前者は、オンプレミス(ハウジング)から準オンプレミスともいえる専用サーバへの移行、後者はオンプレミス(ハウジング)からAWSへの移行になります。

## サービスAの事例

サービスAは比較的単純なCMSサイトです。以下の前提のもと、東京のオンプレミスDCから石狩の専用サーバDCへ移行しました。

- 無停止メンテナンス
- 東京DCと石狩DC間のネットワークは専用線
- 東京DCと石狩DC間のネットワークRTTは20ms弱

移行は以下の3ステップで実施しました。

### 移行前

まず、移行前の状態です。一般的なWebアプリケーション構成であり、proxyはリバースプロキシ、appはアプリケーションサーバ、dbはデータベースサーバを指します[[1]](http://blog.yuuk.io/entry/large-scale-infrastructure)。[^1]
使用しているミドルウェアは、nginx、httpd + mod_perl2、MySQLでした。

```
          東京
          |---------------------------------------|
          |                                       |
          |  ---------   ---------   ----------   |
internet--+->| proxy |---|  app  |---|   db   |   |
          |  --------|   ---------   ----------   |
          |                              |        |
          |------------------------------+--------|
                                         |
                                         | レプリケーション
          石狩                           |
          |------------------------------+--------|
          |  ---------   ---------   ----------   |
          |  | proxy |---|  app  |---|   db   |   |
          |  ---------   ---------   ----------   |
          |----------------------------------------
```

石狩DCにサービスセットを用意し、dbを切り替えるために、MySQLのレプリケーションにより石狩DCにスレーブを作成しました。

### 移行ステップ1

```
          東京
          |---------------------------------------|
          |                                       |
          |  ---------   ---------    ----------  |
internet--+->| proxy |---|  app  |--  |   db   |  |
          |  ---------   --------- |  ----------  |
          |                        |              |
          |------------------------+--------------|
                                   |
                                   |
          石狩                     |
          |------------------------+--------------|
          |                        | ----------   |
          |                        |-|   db   |   |
          |                          ----------   |
          |----------------------------------------
```

最初に、dbのマスタ切り替えを実施しました。MySQLのマスタ切り替えについては、同僚のid:dekokun:detailが書いた[[2]](http://dekotech.dekokun.info/entry/2015/12/11/120052) を参照してください。[^2]
ここで、切り戻しできるように、石狩DC db => 東京DC db へ先程とは逆向きのレプリケーションを確立しています。

### 移行ステップ2

```
          東京
          |---------------------------------------|
          |                                       |
          |  ---------                            |
internet--|->| proxy |--                          |
          |  --------| |                          |
          |            |                          |
          |---------------------------------------|
                       |
                       |
          石狩         |
          |---------------------------------------|
          |            | --------   ----------    |
          |            |-|  app | - |   db   |    |
          |              --------   ----------    |
          |---------------------------------------|
```

### 移行ステップ3

```
          東京
          |---------------------------------------|
          |                                       |
          |  ---------                            |
          |  | proxy |--                          |
          |  --------| |                          |
          |            |                          |
          |------------+--------------------------|
                       |
          石狩         |
          |---------------------------------------|
          |  --------- | ---------   ----------   |
internet--+->| proxy | |-|  app  | - |   db   |   |
          |  ---------   ---------   ----------   |
          |---------------------------------------|
```

ユーザのインターネット経由のアクセスを石狩DCのproxyに切り替えるにはDNSレコードの変更が必要です。
レコードの変更自体は簡単ですが、すぐに切り戻しができるように、事前にTTLを短くしました。このとき、TTL値を一時的に60としました。

DNSレコードの変更により、大半のリクエスト先は切り替わるのですが、移行後にも東京DCのproxyに少量のリクエストが到着していました。
移行前のproxyにリクエストしていたのは、おそらく名前解決結果をキャッシュしてしまっているbotアプリケーションやドメイン名ではなく直にIPアドレスを指定した接続だろうと考えています。

## サービスBの事例

サービスBはサービスAより複雑であり、複数のマイクロサービスを含みます。東京のオンプレミスDCからAWS Tokyo Regionへ移行しました。
条件は以下の通りです。

- 無停止メンテナンス
- 東京DCとAWS Tokyoリージョン間のRTTは7ms弱
- 東京DCとAWS Tokyoリージョン間のネットワークはインターネットVPN
- 一部のデータベースの互換性のない移行

移行は2フェーズで実施しました。

### システム概要

サービスBは、メインシステムに加えて、マイクロサービス型のDBと、マイクロサービスa、b、cを含みます。
多くの機能はメインシステムで完結しており、一部の特定の機能をマイクロサービスが処理します。

```
              |---------------------------------------------------|
              |                        |---> マイクロサービス型DB |
              |                        |                          |
internet   ---+----> メインシステム -->|---> マイクロサービスa    |
              |                        |                          |
              |                        |---> マイクロサービスb    |
              |                        |                          |
              |                        |---> マイクロサービスc    |
              |---------------------------------------------------|
```

### フェーズ1: メインシステムとマイクロサービス型DBの移行

メインシステムは大まかにはサービス事例Aと同じような構成です。
ただし、RDB以外にKVSとしてRedisを利用しています。

```
          |---------------------------------------|
          |  ---------   ---------   ----------   |
internet--+->| proxy |---|  app  |---|   db   |   |
          |  ---------   --------- | ----------   |
          |                        |              |
          |                        | ----------   |
          |                        |-|  redis |   |
          |                          ----------   |
          |---------------------------------------|
```

移行手順もほぼ同じです。ただし、サービスAとは異なり、DC間ネットワークが専用線ではなくインターネットVPNであり信頼性に懸念があることと、サービスAと比べてコンポーネント間のネットワークトラフィック量がかなり大きいという特徴があります。
したがって、移行中にDC間ネットワークをまたいだ通信の時間を極力短くするため、ステップ1〜3までを一息に移行しました。
メインシステムとマイクロサービスa~c間のトラフィック量は小さいため、DC間をまたいだ通信時間が長くてもよいと判断し、フェーズを分割しました。

マイクロサービス型DBの移行は、互換性のない移行でした。したがって、既存のレプリケーション実装やバックアップツールを利用できません。
実際は、以下の2ステップで移行しました。

- 新規のデータ書き込みを新旧DB両方に反映させる。具体的には、アプリケーションのデュアルライトにより、新旧DBに同じ内容の書き込みを向ける。
- データ移行スクリプトにより、既存のデータをすべて移行する。専用に開発したバッチ処理ツールにより、旧DBの内容を読み出し、新DBの書き込み形式で書き込む。

### フェーズ2: その他のマイクロサービスの移行

フェーズ1の移行が落ち着いたのち、週単位の期間を置いて、フェーズ2の移行を実施しました。
マイクロサービスa~cは、長期的に保存するデータを持たず、Redisをジョブキューとして利用するシステムです。
したがって、データ移行が不要なため、ジョブの投入先を新環境に向けるのみの作業でした。

# 移行のための技術要素

移行を計画する段階で、一般的に以下の不確定要素があると考えます。
これらの要素に対する技術的解決手段を洗い出すことが、移行戦略を練るための材料になります。

- 既存データの移行
- 新規データの移行
- サービスドメインのDNSレコード変更
- DC間ネットワークの信頼性
- 内部エンドポイントの変更

## 既存データの移行

これまでの運用で蓄積したデータを移行する方法を考えます。

サービスAの事例では、mysqldumpでバックアップを取得し、移行先のホストでリストアできます。
このようにデータベースミドルウェアの機能を利用すればある程度簡単に移行できます。

一方で、サービスBの事例のように異種DB間の移行の場合、バッチ処理プログラムを書いて移行することになります。
データ移行の観点については、 [大規模データ移行の失敗を防ぎたい。計画やプログラム、インフラの注意点と、ありがちなこと[3]](https://qiita.com/yoshi-taka/items/35d3ed126f4d45e9662d) によくまとめられています。
この資料に書かれていない観点として、バッチ処理プログラムの性能とリソース消費のトレードオフがあります。
バッチ処理プログラムの性能は、例えば処理の並列度を上げることで向上し、実行時間が速くなります。
しかし、代わりにより多くのDC間ネットワーク帯域を消費することになります。
他にも、バッチ処理プログラムのTCP接続数が多すぎて、バッチ処理プログラムの実行ホスト、間のフォワードプロキシ、移行先のDBなどでポートを使い潰すといった問題がよくあります。

## 新規データの移行

ここでは、既存データを移行したあとに書き込まれるデータを新規データと呼びます。
新規データ移行が問題になるのは、無停止移行かもしくは既存データの移行時間分より短いメンテナンスウィンドウを設けた移行の場合です。
無停止で移行するためには、新規データを移行しつつ、既存データを移行するという難しい作業が必要です。

サービスAの事例のように、データベースミドルウェアのレプリケーションを利用すれば、既存データを移行しつつ、新規データをレプリケーションを介して新DBに書きこめます。
サービスBの事例のように、異種DB間の移行手段として、アプリケーションによるデュアルライトがあります。
これは単純に新旧2つのDBに同じ内容の書き込みを同期的に実行するだけです。

しかし、デュアルライトには、分散システムの文脈における一貫性の問題があります。
今回は、データベース移行ではなく、データセンター移行が主眼であるため、この問題に関する説明を省きます。
サービスBの場合は、データの一貫性をそれほど求められないデータベースであったため、この問題を回避できました。

## サービスドメインのDNSレコード変更

提供しているサービスドメインがhoge.example.comであるとし、Aレコードが198.18.0.1だとすると、これを新DCのIPアドレスである198.51.100.1に切り替える必要があります。
移行先がAWSであれば、hoge.example.comのCNAMEレコード(もしくはALIASレコード)として、ALB/NLBのFQDNエンドポイントに設定することも多いでしょう。

DNSの名前解決結果は、各地にあるリゾルバによりキャッシュされることが多いため、各リゾルバが保持するキャッシュが破棄されるまで、新DCに接続されないことになります。
キャッシュのクリアタイミングはレコードごとのTTLにより制御されており、サービス提供者がユーザの接続先を変更するには、各地にあるリゾルバの該当レコードのTTLが0になるまで待たなければなりません。

サービス提供者が完全には制御できない作業になるため、前述の移行事例のように切り替え作業の最後に実施します。
問題があった場合の切り戻し時間を小さくするために、切り戻し作業前にTTLを短くしておきます。((最近は、各サービスのAレコードのTTLをみていると平常時から60秒以下のサイトが多いですね))

DNSというと、いわゆる浸透問題 [なぜ「DNSの浸透」は問題視されるのか[6]](http://www.geekpage.jp/blog/?id=2011/10/27/1) が頭をよぎります。
権威サーバを移行しないのであれば、浸透問題のうちアプリケーションのDNSキャッシュ [「DNSの浸透」とアプリケーションのキャッシュ[7]](http://www.geekpage.jp/blog/?id=2011/10/27/3) 2つが問題になることがありえます。
前者について、たとえばサービスがAPIを提供している場合、クライアントプログラムがTTLを無視して名前解決結果をキャッシュしてしまっていることがありえます。JVMでは、デフォルトだと未来永劫キャッシュしてしまうようです。

>
networkaddress.cache.ttl
>
Specified in java.security to indicate the caching policy for successful name lookups from the name service.. The value is specified as integer to indicate the number of seconds to cache the successful lookup.
A value of -1 indicates "cache forever". The default behavior is to cache forever when a security manager is installed, and to cache for an implementation specific period of time, when a security manager is not installed.
>
https://docs.oracle.com/javase/8/docs/technotes/guides/net/properties.html
[http://moznion.hatenadiary.com/entry/2016/03/11/121343:title:bookmark]

この問題について、IPアドレスを変更する前提では、技術的解決する手段はあまりなく、移行期間を設けて、強制的に旧環境を破棄するしかないのが実情です。とはいえ、経験上数日待てばほとんどの接続は新環境に向いてくれました。

## 内部エンドポイントの変更

異なるDCへの移行であれば、異なるサブネットへの移行となるため、基本的にIPアドレスの変更が必要です。
例えば、サービスA、Bともにステップ1におけるDBの移行では、新DCのDBへエンドポイントを変更しています。
無停止で移行する場合、極力短時間かつ少量のエラーでエンドポイントを変更する必要があります。

単純にアプリケーションやミドルウェアの設定に書かれたエンドポイントを変更し、デプロイすればよいということもあります。
しかし、ローリングアップデートを利用している場合などは、同時に反映されない上に、反映開始から終了までに時間がかかることがあります。
もしくは、なんらかの都合で設定に書かれたエンドポイントを書き変えられないということもあります。

接続元の設定を変えずに、移行する手段として以下の2つを考えます。

### IPアドレス参照の場合

iptablesによりDNATするのがよくあるやり方です。
ペパボさんの[大規模サーバリプレイスを支える技術[8]](https://speakerdeck.com/tnmt/background-of-large-scale-server-replace)では、rinetd、redirなどのL4リダイレクタを利用する方法が紹介されています。

### FQDN参照の場合

DNSのレコードを書き換えるのみです。
ただし、同時に全てのノードの参照先が変更されるわけではないため、一貫性を担保するために、旧DCのDBを直前に停止して、確実に新DCのDBのみに書き込みが向く状態にするなどの工夫が必要です。

## DC間ネットワークの信頼性

### RTT

DC間ネットワークのRTTが大きい場合、サービスAの事例のように、サービスのレスポンスタイムが悪化することがあります。
RTTとレスポンスタイムの相関は、接続を永続化しているかしていないかや、1リクエスト処理あたりの接続数などに影響されるため、残念ながらシステムごとに異なります。(データベース接続の永続化については、[Webシステムにおけるデータベース接続アーキテクチャ概論[9]](http://blog.yuuk.io/entry/architecture-of-database-connection)にまとめています。)
したがって、事前にテスト環境でレスポンスタイムへの影響を計測できるとよいでしょう。
レスポンスタイムへの影響が大きい場合、サービスBの事例のように各ステップを一息に実行し、影響時間を小さくするといった工夫が必要になることもあります。

### 可用性

レスポンスタイムへの影響が小さくても、DC間ネットワークの可用性が高くない場合、長期間のDC間ネットワーク転送に影響がでることがあります。
例えば、サービスBの事例のようにインターネットVPNを利用する場合、dbだけ移行して長期間放置するのは避けたいとことです。
逆に専用線が用意できるなら、dbだけ移行する判断もありえます。
専用線は、例えば、さくらインターネットのサービスとして、[ハイブリッド接続](https://www.sakura.ad.jp/services/hybrid/)が用意されています。
オンプレミスからクラウドの専用線については、AWSの場合、[AWS Direct Connect](https://aws.amazon.com/jp/directconnect/)というサービスがあります。
ミクシィさんの事例 [10年オンプレで運用したmixiをAWSに移行した10の理由 [10]](https://speakerdeck.com/mounemoi/10nian-onhureteyun-yong-sitamixiwoawsniyi-xing-sita10falseli-you) にて、Direct Connectの利用が紹介されています。可用性に限らず、信頼性の高い専用線を用いることで、前述の移行事例のように一斉に移行するのではなく、徐々に置き換える作戦をとられています。

### 帯域

ネットワーク帯域(時間あたりの転送データ量)について、この文章のコンテキストの範囲内では、以下のような影響があります。

- DC間帯域が小さいと既存データ移行の時間が長くなる
- データ移行トラフィックが、他のシステムで利用しているDC間帯域を圧迫する

帯域と一口にいっても、経路のうちどこがボトルネックになるかはそのときどきの状況によるでしょう。
経験では、既存データ移行時に、対外線の帯域より先にデータ移行のための送受信するサーバのNICのスループットや、共用のNATゲートウェイのNICのスループット、インターネットVPN接続を担うLinuxサーバのCPU利用がボトルネックになるケースがありました。

# まとめ

2つのWebサービスのDC移行事例を紹介し、その際に必要となった技術要素をまとめました。
技術要素として、既存データ移行、新規データ移行、DNSレコード変更、DC間ネットワークの信頼性、内部エンドポイントの変更、移行失敗時のロールバックについて議論しました。
Webサービスにおけるデータセンター移行は、SREの仕事の中でも総合的な技術を求められる仕事です。
特定の技術に対しての深い理解が必要というより、系全体を俯瞰する視点が必要です。
アプリケーションエンジニアの同僚が、心臓の手術で動脈を付け替えるドクターのようだと評していたことが記憶に残っています。

今回は、技術要素のみを紹介しましたが、技術要素を踏まえた上で移行計画を設計するには、以下のような問いに答える必要があります。

- 何を移行する(しない)のか
- いつ移行するのか
- どのように移行するのか
- 移行作業の影響範囲はなにか
- ロールバックは可能か、可能であればロールバックするための判断基準はなにか

これらについては、またの機会に書きあげたいと思います。

# 参考資料

- [1]: [http://blog.yuuk.io/entry/large-scale-infrastructure:title:bookmark]
- [2]: [http://dekotech.dekokun.info/entry/2015/12/11/120052:title:bookmark]
- [3]: [https://qiita.com/yoshi-taka/items/35d3ed126f4d45e9662d:title:bookmark]
- [4]: [https://speakerdeck.com/mounemoi/10nian-onhureteyun-yong-sitamixiwoawsniyi-xing-sita10falseli-you:title:bookmark]
- [5]: [http://blog.yuuk.io/entry/redis-cpu-load:title:bookmark]
- [6]: [http://www.geekpage.jp/blog/?id=2011/10/27/1:title:bookmark]
- [7]: [http://www.geekpage.jp/blog/?id=2011/10/27/3:title:bookmark]
- [8]: [https://speakerdeck.com/tnmt/background-of-large-scale-server-replace:title:bookmark]
- [9]: [http://blog.yuuk.io/entry/architecture-of-database-connection:title:bookmark]
- [10]: [https://speakerdeck.com/mounemoi/10nian-onhureteyun-yong-sitamixiwoawsniyi-xing-sita10falseli-you:title:bookmark]

[^1]: 実際には、ロードバランサとしてLVSが間に挟まっていたりします。
[^2]: MySQL5.6なので、MySQL 4.0と異なり、mk-slave-moveが利用できます。