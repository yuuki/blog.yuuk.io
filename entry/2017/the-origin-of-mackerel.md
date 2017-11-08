---
Title: Mackerelの源流 ~ はてなのサーバ「管理」ツールの過去の話
Category:
- Monitoring
- Mackerel
Date: 2017-11-9T18:00:00+09:00
Draft: true
CustomPath: 2017/the-origin-of-mackerel
---

この記事は、SaaSのサーバ監視サービス[Mackerel](https://mackerel.io)を源流を遡り、そこから現在の姿に至った経緯をはてな社内のエンジニアに共有するためのものです。
なお、ここに書かれていることは、Mackerel開発チームの公式見解ではありません。

# 概要

Mackerelの源流は、サーバ「監視」というよりはむしろサーバ「管理」にありました。

# 社内Mackerelの誕生

社内Mackerelは、はてな前CTOのstanakaさんを中心に2007年ごろに開発が始まりました。
社内Mackerelのコードベースは、mackerel.ioのそれとは全く別のものであり、社内Mackerelにしかない機能もあれば、Mackerelにしかない機能もあります。
しかし、共通する思想はあり、その思想は現代のインフラストラクチャ管理にも通ずるものであると考えています。

はてなでは、2007年前後にXen Hypervisorによるサーバ仮想化技術が導入[[1]](http://blog.stanaka.org/entry/20090205/1233794135)され、物体としてのサーバに加えて、データとしてのサーバを管理し始め、人手による管理コストが増大しました。
具体的には、サーバの増減に合わせて、人がIPアドレス管理表を更新したり、ホスト名やIPアドレスが記載された各種設定ファイルを更新して回るとといった手間が増えたことを指します。

これらについて、全体のサーバ数が少ないかつ、個数の増減頻度が小さければ、人手による管理にもコストはかかりません。
一方で、クラウド環境のように、データとしてサーバを扱うのであれば、プログラマブルに管理するためのデータベースが必要です。
そこで、社内Mackerelが誕生しました。

このように、社内Mackerelはサーバ監視というより、プログラマブルなインフラストラクチャ管理を目指したツールでした。
実際、社内Mackerelのことをサーバ「監視」ツールではなく、サーバ「管理」ツールと呼んでいました。

# 社内Mackerelの特徴

## 構成レジストリ

社内Mackerelの主な管理単位は、「ホスト」であり、ホスト名やIPアドレスはもちろんOSの種別やCPU数、メモリ量などのソフトウェア、ハードウェア情報も含みます。
加えて、ホストは以下の属性情報を持ちます。

- 「サービス」「ロール」
- ホストステータス ('working', 'standby', 'maintenance', 'poweroff', 'destroyed')
- 拠点、ラック、電源、ネットワークなど

これらはビューとして人が参照するだけでなく、REST APIにより各種ツールと連携し、インフラストラクチャ要素の情報を一元化しています。
具体的には、以下のように各種ツールのパラメータを、MackerelのAPI経由で動的取得し、ホスト名やIPアドレスの多重管理を防いでいます。

- 1: 死活監視ツールの設定ファイルの自動生成[[2]](https://www.slideshare.net/shoichimasuhara/3-ss-17097401)
- 2: 内部DNSのゾーンファイルの自動生成
- 3: デプロイツールからのデプロイ対象ホストの動的取得
- 4: 構成管理ツール(Chef)の適用cookbookを対象ホスト名から動的解決

1について、サーバ監視のうち、死活監視についてはNagiosを利用します。同一ロールであれば、同じ監視設定を流用できることと、ホストステータスがworking以外に変更すれば監視を外すといった動的なプラットフォームに適した運用が可能になります。[^1]
2について、ホスト単位のレコード以外に、ロール名ベースのDNSラウンドロビン用FQDNとVIP用FQDNがあり、サービスディスカバリに利用します。
3について、Capistranoでホスト名を静的に設定したところをAPIによりロール名だけ設定しておけば、対象にデプロイできます。ホストステータスをmaintenanceにしておけば、デプロイ対象から外れます。
4について、ホスト名を与えれば、ホストに紐付いたロールから適用するcookbookを自動解決できるようになります。

このようなツールは、CMDB[[3]](https://ja.wikipedia.org/wiki/%E6%A7%8B%E6%88%90%E7%AE%A1%E7%90%86%E3%83%87%E3%83%BC%E3%82%BF%E3%83%99%E3%83%BC%E3%82%B9)に似ていますが、資産管理機能は含みません。
どちらかといえば、書籍「Infrastructure As Code」[[4]](https://www.oreilly.co.jp/books/9784873117966/) 3.4節 構成レジストリに近いものです。
構成レジストリは、インフラストラクチャ要素についての情報集積庫であり、書籍では、構成レジストリと例として、Zookeeper/Consul/etcdや、Chef Server/PuppetDB/Ansible Towerなどが挙げられています。

## メトリックの時系列グラフ

社内Mackerelには、前述の構成レジストリ機能に加えて、メトリックのクローリングと、メトリックを時系列グラフ表示する機能があります。
メトリッククローリングはPrometheusなどと同様にPull型のアーキテクチャであり、クローラーがOSの基本メトリックはSNMP、MySQLなどのミドルウェアについてはミドルウェアのプロトコルでメトリックを取得し、RRDtoolに保存します。

社内Mackerelの時系列グラフ機能の実装については、過去の発表資料[[5]](https://speakerdeck.com/yuukit/hatenafalsesabaguan-li-turufalsehua)で詳しく説明しています。

今から振り返ると、メトリックの収集、保存、可視化については、Repiarableにするために、専用のツールに任せ、ビューだけ統合したほうが良かったと考えています。
社内Mackerelの開発開始が2007年より、もう少し後であれば、Collectd[[6]](http://collectd.org/)で収集し、Graphite[[7]](https://graphiteapp.org/)に保存するといった選択肢もありました。

# Mackerelへ

2013年にMackerelの開発が始まり、2014年に正式リリースされました。
SaaSとして提供するにあたって、グラフツールではないため、メトリックに着目するより、「ホスト」に着目するといった主要な思想は、社内Mackerelから引き継がれました。他にも以下の要素が引き継がれました。

- サービス・ロールの概念
- ホストステータスと監視のon/offとの連動
- 統合されたホスト管理とメトリックグラフビュー

特にサービス・ロールはMackerelの中心概念であり、社内Mackerelとほとんど同じものです。
私見ですが、サービス・ロールは、人間が決定しなければいけないラベル付け構造だと考えています。
インフラストラクチャに紐づくラベル情報は多種多様ですが、大きく分類すると、自動で付与できるものと、それ以外の人が判断して付与するものがあります。
自動で付与できるものは、OS、ハードウェア、ネットワーク、インストールされたミドルウェア、クラスタ内の役割などの情報です。
一方で、どのサービスのホストなのか、どのロールなのかといったことは、人間が最初に決めて付与しなければなりません。自動で決定できるとしても、人間が与えたルールにしたがって決定していることが多いと思います。[^2]

以上のように引き継がれた機能がある一方で、ラックや仮想ホストの管理など、クラウド時代にそぐわない機能は削ぎ落とされました。
逆に、死活監視やメトリック監視、外形監視機能は統合されました。

メトリックの収集と時系列グラフについては、SaaSとして提供するために、NAT超えを意識し、Pull型ではなく、Push型のアーキテクチャになっています。
ホストにインストールされたmackerel-agentのリクエストを[[8]](http://blog.yuuk.io/entry/high-performance-graphite)[[9]](http://blog.yuuk.io/entry/the-rebuild-of-tsdb-on-cloud)に書いた時系列データベースに格納します。

このように、Mackerelは監視機能をひと通り備えているため、サーバ「監視」サービスと銘打っていますが、その源流は、サーバ「管理」サービスです。
実際、サーバ「管理」ツールとしてのMackerelをうまく活用していただいている例[[10]](https://github.com/myfinder/mackerel-meetup-3/blob/master/slide.md)があります。
このブログでも、AnsibleのDynamic Inventoryとの連携[[11]](http://blog.yuuk.io/entry/ansible-mackerel-1000)やServerspecとの連携[[12]](http://blog.yuuk.io/entry/mackerel-serverspec)など、サーバ「管理」ツールとしてのMackerelをいくつか紹介しています。

# その他のサーバ「管理」ツール

社内Mackerelと同じサーバ管理ツールは、他にもあり、ここでは、Collins、Yabitzなどを紹介します。

## Collins

Collins[[12]](http://tumblr.github.io/collins/)はTumblrで開発されているインフラストラクチャ管理ツールです。

Collinsの特徴は、Assetsベースのデータモデルです。Assetsはなんでもよく、事前設定されているものはServer Node、Rack、Switch、Router、Data Centerなどです。
さらに、このAssetsオブジェクトに対して、キーバリュー形式のTagsを付与できます。Tagsはハードウェア情報などユーザが管理できないものはManaged，外部自動化プロセスから動的に設定されるものはAutomated、ユーザによって設定されるものはUnmanagedというように3種類のタイプを持ちます。

このように、Collinsは抽象的なデータ表現により各種インフラストラクチャ要素を管理しており、具体的なデータ表現をもつ社内Mackerelとは対照的です。

## Yabitz

Yabitz[[13]](https://github.com/livedoor/yabitz)は、旧ライブドアで開発されたホスト管理アプリケーションです。READMEでは、「ユーザ(多くの場合は企業)が保有するホスト、IPアドレス、データセンタラック、サーバハードウェア、OSなどの情報を管理するためのWebアプリケーション」と説明されています。
機能一覧を見るかぎり、社内Mackerelによく似ています。

いずれのソフトウェアも、死活監視機能やメトリック可視化機能は備えておらず、構成レジストリとしての役割に専念しているという印象です。
他にも、Zabbixのホストインベントリなどがサーバ管理機能にあたると思いますが、Zabbixはあまりに機能が多いので、よく知らずに言及することを控えました。

# これからのサーバ「管理ツール」

<!-- コンテナやマネージドサービスの台灯。 -->
<!--  -->
<!-- 「ホスト」の概念を拡張し、プロセス、Function、DynamoDB Table、S3 Bucket、 -->
<!--  -->
<!-- サービス・ロールは、ホストやリソース -->

# 参考文献

- [1]: [http://blog.stanaka.org/entry/20090205/1233794135:title:bookmark]
- [2]: [https://www.slideshare.net/shoichimasuhara/3-ss-17097401:title:bookmark]
- [3]: [https://ja.wikipedia.org/wiki/%E6%A7%8B%E6%88%90%E7%AE%A1%E7%90%86%E3%83%87%E3%83%BC%E3%82%BF%E3%83%99%E3%83%BC%E3%82%B9:title]
- [4]: Kief Morris著 宮下剛輔監訳 長尾高弘訳,「Infrastructure as Code ――クラウドにおけるサーバ管理の原則とプラクティス」,オライリー・ジャパン,2017/03 https://www.oreilly.co.jp/books/9784873117966/
- [5]: [http://blog.yuuk.io/entry/high-performance-graphite:title:bookmark]
- [6]: [http://collectd.org/:title:bookmark]
- [7]: [https://graphiteapp.org/:title:bookmark]
- [8]: [http://blog.yuuk.io/entry/the-rebuild-of-tsdb-on-cloud:title:bookmark]
- [9]: [https://speakerdeck.com/yuukit/hatenafalsesabaguan-li-turufalsehua:title:bookmark]
- [10]: [https://github.com/myfinder/mackerel-meetup-3/blob/master/slide.md:title:bookmark]
- [11]: [http://blog.yuuk.io/entry/ansible-mackerel-1000:title:bookmark]
- [12]: [http://blog.yuuk.io/entry/mackerel-serverspec:title:bookmark]
- [13]: [http://tumblr.github.io/collins/:title:bookmark]
- [14]: [https://speakerdeck.com/motemen/mackerel-in-hatena-platform-team:title:bookmark]

-------

# あとがき

先日、[http://developer.hatenastaff.com/entry/2017/10/12/184721:title] にて、Mackerelチームとの研究会をやるという話を書きました。
モニタリング研究会では、モニタリングの過去・現在・未来をテーマに、まず過去を知ることから始めており、その一環としてMackerelの源流をまとめました。
MackerelチームもWebオペレーションチームも、最近ジョインしたメンバーに改めてコンテキストを知る場にもなったと思います。

Mackerelのサーバ監視以外の「管理」の側面は、まだ十分に伝えられていないと思っています。
実際、Mackerel本について、mattnさんに書いていただいた書評([https://mattn.kaoriya.net/software/mackerel/20170829100304.htm:title])に

>
これは本書で知ったのですが、どうやら はてな社は Mackerel をホスト管理としても使っている様で、数千いるサーバのロールをうまくラベリングして運用されているとの事でした。

と書いていただいています。

[^1]: mackerel2という社内Mackerelの改良版では、タグという概念で、複数のロールをさらに集約し、同じ設定で監視できるようになっています。これは、ロールはMySQL
[^2]: 例えば、サービスごとにネットワークレンジが決まっているなど。


<!-- Mackerelの昔話 -->
<!-- 現代のインフラストラクチャ管理 -->
<!-- Mackerelの源流 -->

<!-- Dynamic Infrastructure Platforms -->
<!-- Infrastructure Definition Tools -->
