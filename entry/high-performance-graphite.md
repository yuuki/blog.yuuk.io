---
Title: Mackerelを支える時系列データベース技術
Category:
- Graphite
- Mackerel
- Performance
- Kernel
- Monitoring
- Architecture
- Database
Date: 2015-04-30T08:30:00+09:00
URL: http://blog.yuuk.io/entry/high-performance-graphite
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/8454420450093057979
---

サーバモニタリングサービス [Mackerel](https://mackerel.io) で採用している時系列データベース [Graphite](http://graphite.readthedocs.org/en/latest/) を用いたシステムの構築と運用事情を紹介します。Graphiteについては、プロビジョニングやアプリケーションからの使い方、Graphite自体のモニタリングなど様々なトピックがありますが、特に大規模ならではのトピックとして、Graphiteの内部アーキテクチャ、パフォーマンスチューニングおよびクラスタ構成についての知見を書こうと思います。

<!-- more -->
[:contents]

# 背景

Munin、Zabbix、Growthforecastなどに代表されるサーバモニタリングツール、特にグラフによるメトリック可視化機能をもつようなツールを運用する場合、時系列データの扱いが重要になってきます。サーバのメトリックはCPU利用率やメモリ使用量などのOSのメトリックに加えて、JVMやMySQLなどのミドルウェアのメトリックを加えると、
1ホストあたりのメトリック数は100を軽く超えます。仮想化したものも含めてネットワークカードやブロックデバイスが複数ある場合は、デバイスごとにメトリックを収集するので、さらに多くのメトリックを収集することになります。

仮にメトリック取得間隔を1分として、1ホストあたりのメトリック数を100、ホスト数を1,000台とすると、1分あたり最低でも100,000以上のメトリックの書き込みに耐える必要があります。
自社サーバのみをモニタリングするのであればホスト数が1,000以上になるような環境はそれほど多くはないと思いますが、MackerelのようにSaaSとしてシステムを一般提供する場合、10,000台規模でスケーラビリティを考える必要があります。

時系列データを格納するためにバックエンドとして、MySQLのようなRDBMSを使う場合もあれば、RRDtoolのような時系列データに特化したデータベースを用いる場合もあります。
後者については最近では、Goで書かれた[InfluxDB](http://influxdb.com/)やHBaseをバックエンドとした[OpenTSDB](http://opentsdb.net/)なども選択肢に入ります。

RDBMSを用いた例として、[http://highscalability.com/blog/2011/7/18/new-relic-architecture-collecting-20-billion-metrics-a-day.html:title:bookmark] があります。2011年の情報なので今はどうなっているかわかりませんが、NewRelicではMySQLのテーブルをアカウントごとかつ1時間毎に分割しているようです。

RRDtoolについては今のMackerelを開発する以前に数年前から自社開発していた社内Mackerelの時系列DBとして用いていたことがあります。これについては以前YAPCでトークしたことがあるのでそちらの資料を参照してください。RRDtoolで消耗している様子がわかります。[http://yuuki.hatenablog.com/entry/2013/09/21/154911:title]

このように様々な選択肢がある中でGraphiteを選んだのは、知見を溜めていたRRDtoolへの不満をうまく解消していたというのと、RRDtoolと同じようなデータ構造を採用していることから、Better RRDtoolとして使えることを期待したからです。

一方で、前述のInfluxDBやOpenTSDB、Kairosなどの採用も考えましたが、そもそもInfluxDBは当時バージョン0.3でまだまだこれからのプロダクトだったということもあり、さすがにプロダクションで使うものではなかったと思います。今もまだバージョン0.8でプロダククションで使えるかはわかりません。
OpenTSDBとKairosはそれぞれHBaseとCassandraをバックエンドとして用いており、理屈上はスケーラビリティに優れていそうには見えますが、慣れ親しんだマスター・スレーブ型以外の分散DBを運用しきれるのかという問題がありました。

Graphiteは賢いシャーディングや冗長化の仕組みをもつわけではありませんが、個々のコンポーネントの仕組みはシンプルです。
仕組みがシンプルでわかりやすいならば、いざとなればコードを読んで詳細な挙動を把握することもパッチをあてることもやりやすいので。これならなんとか運用しきれるだろうと考えました。
[採用事例](http://graphite.readthedocs.org/en/latest/who-is-using.html)もそれなりに豊富です。特にEvernoteの事例をみたのが最初にGraphiteを知ったきっかけでした。[http://blog.evernote.com/tech/2013/07/29/graphite-at-evernote/:title]

# Graphiteシステム概観

Graphiteは、タイムスタンプ、メトリック名、メトリック値、これらの値の組を連続的に受け取り、グラフ化するというシンプルな機能をネットワークサービスとして提供しています。ネットワークサービスというのが重要で、RRDtoolの場合、それ単体ではネットワーク経由でデータの出し入れが難しくありました。GrowthForecastでは、HTTPインタフェースを提供するために、RRDtoolをバックエンドとしたWebアプリケーションという形式をとっています。

Graphiteではデータの書き込みと読み込みでプロトコルが異なり、TCPベースの独自のテキストプロトコルで時系列データを書き込み、書き込んだ時系列データをHTTPで取得します。
時系列データは、グラフ画像もしくはJSON形式で取得できます。単に取得できるだけでなく、時間範囲指定やアグリゲーションなどの機能を備えています。（詳細は公式ドキュメント [http://graphite.readthedocs.org/en/latest/render_api.html] , [http://graphite.readthedocs.org/en/latest/functions.html] ）
Mackerelのようにグラフの描画はクライアントサイドJavaScriptで行う場合、JSON形式で取得します。

Graphiteは主に以下の3つのコンポーネントで構成されています。

- `whisper`: ラウンドロビンデータベースファイルを作成・更新するためのライブラリ
- `carbon`: 書き込み要求を受け付けるためのデーモン。厳密にはcarbon-cache。
- `graphite-web`: 読み込み要求を受け付けるためのWebアプリケーション

[f:id:y_uuki:20150425224002p:plain]

まず、whisperはラウンドロビンデータベースとしてRRDtoolと似たようなデータ構造で時系列の数値データのみを格納します。（[http://graphite.readthedocs.org/en/latest/whisper.html:title] ）
whisperは、サーバとして動作しクライアントとソケット通信するようなインタフェースはもたず、ただのPythonのライブラリとしてwhisper専用のフォーマットのファイルに保存されたデータを扱います。基本操作としてwhisper形式のデータファイルを作成するcreate、whisper形式のファイルに対して時系列データポイントを更新するupdate、時系列データポイント列を取得するfetchなどがあります。

次に、carbonはネットワークごしの書き込み要求を受けて、whisperライブラリを使ってデータファイルの作成と更新をします。（ [http://graphite.readthedocs.org/en/latest/carbon-daemons.html:title] ）
carbonに対する書き込み要求が多くなりがちなため、パフォーマンスを考慮して、ヘッダのパースなどのオーバヘッドの大きいHTTPではなく独自のテキストベースの単純なプロトコルを使います。具体的には、`<metric path> <metric value> <metric timestamp>`で表現された形式の文字列をTCPで送信すればよいだけです。
例えば、以下のようなコマンドを叩けばデータを書き込めます。（ [http://graphite.readthedocs.org/en/latest/feeding-carbon.html:title] ）

```
PORT=2003
SERVER=graphite.your.org
echo "local.random.diceroll 4 `date +%s`" | nc -q0 ${SERVER} ${PORT}
```

テキスト形式だけでなく、Pythonのpickle形式でシリアライズすることもできます。pickleの方が`carbon`デーモンにテキストパース処理が不要になるため、CPU効率がよくなるはずです。
クライアントからみて非同期書き込みとなっている点に注意が必要です。
MySQLのバイナリログのような仕組みもないため、絶対にデータをロストしてはいけないようなシステムには向いていません。

最後に、graphite-webはDjangoで書かれたWebアプリケーションです。
クライアントからのリクエストに応じて、whisperライブラリを通して該当ファイルのデータを読み出し、グラフをレンダリングします。
Webサーバとしてgunicornやuwsgiが使われることが多いようです。

# データ構造とアーキテクチャ
パフォーマンス特性を明らかにするにはデータ構造とアーキテクチャについて知る必要があります。

## whisperのデータ構造
時系列データを保存する上で重要なのはディスクサイズをどれだけ節約できるかです。素朴に考えると、1分おきにやってくるデータポイントを年単位で保存するとなると相当なディスク使用量になってしまいます。

そこで、古いデータについては一定期間で平均化するなり最大値を残すなりして丸めてしまってディスク使用量を節約するというのがラウンドロビンデータベースの考え方です。
例えば、1分精度のデータは1日分だけでよいが、5分精度のデータは1週間残すというようなイメージです。

precision(精度)とretention(データ保持期間)の組をarchiveと呼びますが、whisperのラウンドロビンデータベースはarchiveを複数定義し、あるprecisionのretentionを過ぎたら次点のprecisionに丸めて([Rollup Aggregation](http://graphite.readthedocs.org/en/latest/whisper.html#rollup-aggregation))、最も荒いprecisionのretentionを過ぎたらそれ以前のデータポイントを完全に削除するというような仕組みです。 (http://graphite.readthedocs.org/en/latest/whisper.html#archives-retention-and-precision) 。
データを取得するときは、指定した時間範囲に応じて適切なarchiveが選択されます。

whisperファイルの構造は以下の図のようになっており、先頭にMetadataとArchiveへのオフセットを格納するHeader領域があり、後続に複数のArchive領域が並びます。

[f:id:y_uuki:20150426214849p:image]
(The Architecture of Open Source Applications - Graphite [http://www.aosabook.org/en/graphite.html])

より詳細な情報はwhisperのコードに書いてあります。時系列データそのものはArchive領域に保存されていることがわかれば十分です。

```
# https://github.com/graphite-project/whisper/blob/0.9.12/whisper.py#L19-25
File = Header,Data
Header = Metadata,ArchiveInfo+
	Metadata = aggregationType,maxRetention,xFilesFactor,archiveCount
	ArchiveInfo = Offset,SecondsPerPoint,Points
Data = Archive+
	Archive = Point+
		Point = timestamp,value
```

データ書き込み時は、Headerを参照して最も高いprecisionをもつArchiveへのオフセットを取得して、該当Archiveの末尾へseekして書き込みます。
ただし、Rollup Aggregationする必要があるため、次点以下のprecisionをもつArchiveを必要があれば丸めて更新します。

## carbon-cacheのアーキテクチャ
先に述べたように、carbon-cacheによりファイルシステム上にメトリックごとのwhisperファイルが作成されます。
メトリック数が膨大になるため、大量のwhisperファイルに対して1分ごとにデータポイントを書き込むことになります。

実装にはPythonのイベント駆動フレームワークのTwistedが使われており、書き込み要求をlistenするスレッドとwhisperを使ってデータを書き込むスレッドがそれぞれ独立して動作します。書き込み要求はlistenスレッドによりバッファリングされて、writerスレッドがバッファからデータポイントを取り出して、ディスクに書き込むという仕組みです。

ディスクのI/O性能低下などにより、同じメトリックだがtimestampの異なるデータポイントがバッファに貯まっても、whisperの`update_many`でまとめて書き込んでくれるます。
(https://github.com/graphite-project/carbon/blob/0.9.12/lib/carbon/writer.py#L128)

ただしこのとき、whisperファイルへの反映は当然遅れるので、graphite-webには読み出し時にcarbon-cacheのメモリ上のデータを取得して、whisperファイルのデータとマージするという機能(`CARBON_LINK`)があります。

## パフォーマンス特性
以上のアーキテクチャから、ディスクI/O、CPU効率などの観点からパフォーマンス特性について考察します。

まず、ディスクI/Oですが、carbon-cacheレベルでみると大量のファイルに小さな書き込みを頻繁に書き込むことになります。
さらに、whisperレベルでみると1つのファイルに対して、Archiveサイズ分離れた位置で複数のwrite I/Oが発生するということが言えます。
carbon-cacheレベルでみてもwhisperレベルでみても、ファイルシステム上の異なるブロックに対して同時に書き込むため、I/Oスケジューラによるwrite mergeが効きづらいように思えます。HDDのような低速なディスクの場合では致命的かもしれません。
Graphiteのアーキテクチャ上避けられない問題なので、SSDないしioDriveのようなフラッシュストレージを使って、高IOPSを捌けるようにするなどの力技が必要だと思います。

一方、CPU利用率という観点でみると、carbon-cacheとcarbon-relayは2スレッドでしか動作しないためマルチコアスケールしません。
carbon-relayの場合は、ロードバランサにぶら下げて横に並べれば垂直にスケールしますが、carbon-cacheはローカルのディスクに書き込むため、同じホスト上に複数のcarbon-cacheプロセスを動かす必要があります。

以上は書き込み時のパフォーマンス特性ですが、サービスの性質上人間がグラフをみるときだけ読み込みが発生するため、それほどスケールを気にする必要はないと思います。carbon-cacheの全方位書き込みのおかげで、大半のデータがOSのページキャッシュに載っているため、read I/Oが少ないということもあります。

# パフォーマンスチューニング
Graphiteのパフォーマンス特性を踏まえて、ミドルウェアレイヤとカーネルレイヤでのチューニング方法を書きます。

## ミドルウェアレイヤ
ミドルウェアレイヤといっても、主にcarbon-cacheのチューニングですが、パラメータの説明は`carbon.conf`のexampleにあります。

https://github.com/graphite-project/carbon/blob/0.9.12/conf/carbon.conf.example

この中でパフォーマンスに影響するのは以下のパラメータです。
パフォーマンス特性でみたように、CPUをなるべく使わないようにするということとディスクは高速なものを使うという方針でパラメータを決定します。

- MAX_CACHE_SIZE
- MAX_UPDATES_PER_SECOND
- MAX_CREATES_PER_MINUTE
- CACHE_WRITE_STRATEGY
- WHISPER_AUTOFLUSH
- WHISPER_FALLOCATE_CREATE

まず、`MAX_CACHE_SIZE`はcarbon-cache上のバッファサイズ(キャッシュサイズ)の上限です。バッファサイズが大きいと、その分ソートなどによるCPUコストが高くなります。
指定した方がよさそうにみえますが、MAX_CACHE_SIZEを指定してしまうとスレッド間でリソース競合を起こして、CPU使用率が跳ね上がるバグ？があるので、よほどメモリが少ない環境でない場合は`inf`を指定します。
バージョン0.9.13(未リリース)だと既に直っているかもしれません。https://github.com/graphite-project/carbon/issues/167

次に、`MAX_UPDATES_PER_SECOND`はwhisperへの書き込みレートを制限します。
書き込みレートを制限することにより、細々とディスクに書き込まずにバッファにデータポイントをためて、まとめて書き込むようになります。
ディスクI/O効率がよくなりますが、高速なディスクを使用しているので、今のところ特に制限不要なので`inf`にしています。
バッファに溜め込みすぎるとcarbon-cacheが落ちたときのデータロストが大きくなるので、なるべく使わないようにして、I/Oで詰まったら試すぐらいがよいと思います。

`MAX_CREATES_PER_MINUTE`はwhisperファイルの新規作成のレートを制限します。パラメータの意図は`MAX_UPDATES_PER_SECOND`と同じでファイル作成時のI/Oを抑えるというものです。whisperは指定されたprecisionとretentionにしたがって、未来のデータ領域も最初に作成するので、I/Oインパクトが大きいです。
ただし、これも高速なディスクを使用しているので、今のところ`inf`にしています。

`CACHE_WRITE_STRATEGY`はwriterスレッドがデータポイント列をディスクにフラッシュするときのオーダーを決定する方針を指定します。
`sorted`、`max`、`naive`の3つを選択できますが、SSDかつCPU利用率を節約したいときは`naive`を選びます。

`WHISPER_AUTOFLUSH`はwrite(2)後にfsync(2)するかどうかを指定します。クライアントからみればどのみち非同期書き込みであるというのと、CPU利用率を節約したいので、iowaitが増えそうなオプションは切ったほうがよいと思います。

`WHISPER_FALLOCATE_CREATE`は[fallocate(2)](http://man7.org/linux/man-pages/man2/fallocate.2.html)を使うことによりwhisperのファイル作成が高速化されます。fallocateが使用可能なファイルシステムあれば使ったほうがよいでしょう。高速な理由は、空のarchive領域を確保するのに、writeシステムコールでゼロフィルするより、事前に連続領域をOSに予約してからゼロフィルしているためのようです。(https://github.com/graphite-project/whisper/blob/0.9.12/whisper.py#L384-397)

各種パラメータについて試行錯誤した結果、全体としてはcarbon-cacheに何もさせないようなチューニングになっています。
ioDriveのような高性能なディスクを使う場合は、I/Oスケジューラもnoopを選んで何もさせないようにすることが多いため、carbon-cacheも同様に下手にI/O性能の管理をさせるよりは、何もさせないほうがよいようです。

## カーネルレイヤ
カーネルレイヤではメモリ管理まわりとファイルシステムまわりでチューニングを試しました。

### メモリ管理
まずメモリ管理まわりでは、スワップしたわけでもないのに、ページインとページアウトが頻繁に発生(スラッシング)し、read I/Oが増えるという問題がありました。
これは、carbon-cacheがファイルシステム上の全方位に定期的に書き込みをかけるため、whisperファイルの更新時のページキャッシュによりメモリを圧迫したためです。
whisperファイルへの更新はwriteだけなくMetadataの参照などでreadも実行されるので、おそらくキャッシュから追い出されたページに対してread I/Oが走っていたものと考えています。

スラッシングを防ぐ手段を3つ考えました。

まず参照することのない無駄なページキャッシュが大量にあるということに着目して、`posix_fadvise`によりwriteしたページのキャッシュを落としておくという方法があります。`posix_fadvise`はwriteしたページに対して、POSIX_FADV_DONTNEEDにより該当ページへは将来アクセスされないことをOSに伝えるという仕組みです。
これはRRDtoolではファイル作成時のみ使われています。更新時はなぜかコメントアウトされていました。https://github.com/oetiker/rrdtool-1.x/blob/72147e099cb655c1db5aca9b3c450aedbc0825ee/src/rrd_update.c#L952
whisperにパッチをあてて試していたのですが、writeしたページだけという判定が難しく、read対象のページのキャッシュも落としてしまったりしたので、うまくいきませんでした。 https://github.com/yuuki1/whisper/commit/42a662dbfeae9849e0824f4ecdd154446f32a176

次に、MySQLでも使われているI/Oダイレクトによりそもそも書き込み時にはページキャッシュしないという方法です。
I/Oダイレクトはopen(2)に`O_DIRECT`フラグを渡せばよいのですが、出力バッファを512バイト単位でアライメントしておく必要があるという制限があります。
昔CでSIMD演算やってたときはalignedアトリビュートでアライメントとったりしていましたが、Pythonだと`posix_memalign`を使えば良さそうに思ったものの、そこで諦めました。

結局、メモリ増やせばよいだけなので、数十GBくらいのメモリを積んで金で解決しました。

【追記】 [https://speakerdeck.com/yuukit/performance-improvement-of-tsdb-in-mackerel:title:bookmark] にて、posix_fadviseを利用するパッチを投げて、スラッシングを解決した話を紹介しています。

### ファイルシステム
ファイルシステムまわりでは、ファイルシステムをext4かxfsのどちらを使うかという話があります。
大量のファイルを探索するという要求と、大量のファイルに同時に書き込むという要求があるので、ディレクトリツリーをB+treeで探索できて、並列I/O性能の優れたxfsが有利だと思いました。
念のため、同じサーバスペック(ioDrive)でnoatime, nobarrierでマウントしてブロックサイズは4KB、ioDriveなのでI/Oスケジューラをnoopにした2つのノードにcarbon-cacheをたてて、同じ量の書き込みをさせたところ、xfsのほうがCPU効率が1.07倍ほどよく、I/O timeも1.2倍ほど大きいという結果になりました。
IOPSはなぜかext4のほうが大きく、あまり考察ができていないという状態です。
思った以上に差がでなかったのはwhisperファイル数がまだ差が出るほどの数ではなかったというのと、carbon-cacheは同一ファイルに対して1スレッドしか書き込まないため、ext4でもそれほど並列性が悪くなかったのではないかと予想しています。

他には、whisperファイルが固定長であるという特徴を利用して、ブロックサイズをwhisperファイルの固定長に合わせるとI/O効率がよくなるかもしれないなど、まだ試していないこともあります。

# クラスタ構成

Graphiteはcarbon-relayという仕組みを使って、冗長化または負荷分散のためにクラスタを構築できるようになっています。
もちろん、ロードバランサやDRBDも組み合わせて、クラスタを組むこともあります。
クラスタといっても、バイナリログを使ったマスター・スレーブ型でもRaftのような分散アルゴリズムを使ったものでもなく、非常に素朴です。

## carbon-relayの仕組み
[http://graphite.readthedocs.org/en/latest/carbon-daemons.html#carbon-relay-py:title]

carbon-relayはcarbon-cacheの前段で書き込み要求を複数のcarbon-cacheインスタンスにシャーディングもしくはレプリケーションします。
carbon-relay自体はcarbon-cacheとは別のインスタンスで動作し、carbon-cacheと同じくTwistedを使って実装されたデーモンです。
carbon-relayのシャーディング方式はconsistent-hashingとrulesの2つがあります。
シャーディングにより別々のノードにデータを分散保存できるため、carbon-cacheのCPU利用率、IOPS、ディスク容量などが分散できます。

まず、consistent-hashing方式はメトリック名をキーとしたconsistent-hashingで複数のcarbon-cacheに書き込み要求をシャーディングします。
一方、rules方式はメトリック名に対して、正規表現マッチングで分散先のノードを選択できます。
これにより、先頭一文字がaならノード1、bならノード2といった分散ルールを書くことができます。

consistent-hashing方式を使えば何もルールを決めなくても均等に分散される一方で、分散先のノードを増やしたときにシャードをrebalanceさせなければなりません。
ここでいうシャードのrebalanceとは、ノードを増やしたことにより同じキー名であっても分散先が変更されたために、同じキー名に紐づく既存のデータを新しい分散先に移動させることです。
consistent-hashingはノードの増減時に分散先のノードがなるべく変わらないようなアルゴリズムですが、それでも同じキー名に対して別のノードに分散することはあります。
この仕組みはキャッシュデータを格納するMemcachedなどに対しては使いやすいです。ノードの増減時になるべくキャッシュミス仮にキャッシュミスしたとしても、オリジンデータを引いて埋め直せばよいだけです。
もしconsistent-hashingを使うなら、carbonはシャードのrebalanceをサポートするような仕組みはないので、自前で仕組みを作る必要があります。

carbon-relayのもうひとつの機能であるレプリケーションはcarbon-cacheインスタンスを冗長化するための仕組みです。
レプリケーションといっても、MySQLのようなバイナリログを用いたものではなく、単純にcarbon-relayが複数のレプリケーション先のcarbon-cacheにそれぞれ書き込み要求を投げるだけです。
結構素朴な仕組みなので、carbon-relayインスタンスが落ちたときに全てのレプリケーション先でデータの一貫性は保証されません。そもそもcarbon-relayのバッファ上のデータをロストする可能性もあります。
素朴な仕組みだからといって、使えないかといえばそうでもなく、carbon-relayインスタンスがそんなに頻繁に落ちることはない、サーバのメトリックデータは絶対に欠けてはいけない性質のものではない、たとえ欠けたとしてもwhisperのRollup Aggregationにより過去のデータは丸められるため時間経過によりデータロストが気にならなくなる、という3点を考慮して使ってもよいと考えています。

## クラスタ設定

クラスタの設定方法については[http://bitprophet.org/blog/2013/03/07/graphite/:title] や [https://grey-boundary.io/the-architecture-of-clustering-graphite/:title] が参考になります。

## Mackerelにおける構成

前述のGraphiteにおけるクラスタ構成を踏まえて、Mackerelにおける構成を紹介します。
Mackerelで構成を組むときに、Web上に公開されている様々な構成に目を通して研究しました。

- [http://www.slideshare.net/AnatolijDobrosynets/graphite-cluster-setup-blueprint:title]
- [http://www.slideshare.net/MatthewBarlocker/highly-available-graphite:title]

### 初期構成
f:id:y_uuki:20150426234339p:image

最初期の構成は本当に単純で1台のホストにcarbon-cacheとgraphite-webを立てておくだけでした。
もちろん、これでは1台落ちたら終わりなので冗長化を考えます。

### carbon-relayにより冗長化
f:id:y_uuki:20150426234340p:image

carbon-cacheの載ったインスタンスをtsdb-masterと呼んでいますが、tsdb-masterを2台用意し、carbon-relayをその前段におきます。
carbon-relayはreplicationモードで動作しており、書き込み要求を2台のtsdb-masterに複製します。

さらに、carbon-relayをSPOFにしないために、ロードバランサ以下にcarbon-relayを複数台並べます。
ロードバランサはkeepalivedで冗長化したLVSを使ってますが、ELBやHAProxyでもよいでしょう。

graphite-webはcarbon-cacheが書き込み先ファイルシステムと同じファイルシステムを参照する必要があるため、同じノードで両方動いています。
graphite-webもLVS越しに参照されます。
先に述べたようにtsdb-master間のデータの一貫性が保証されないことを考えると、tsdb-masterをVIPで参照すべきなような気はします。今のところはcarbon-relayがダウンしたときに、2つのtsdb-masterそれぞれにランダムにグラフを大量に描画させて、データロストを目視で確認してロストしてる方をLVSから外すということでよしとしています。

### バックアップ
f:id:y_uuki:20150426234341p:image

参照はされないものの、2台では不安なのでバックアップ用のtsdb-masterを作っています。carbon-relayにぶら下げるだけなので構築は簡単です。

### マルチcarbon-cache
f:id:y_uuki:20150426234342p:image

秒間書き込みデータポイント数が増えてくるとcarbon-cacheのCPUが1コア使い切るようになりました。
そこで、なるべくマルチコアスケールさせるために、tsdb-masterへの書き込みをcarbon-relayで受けてそこからconsitent-hashingで複数のcarbon-cacheに分散させました。
carbon-relayを挟むのではなくL4ロードバランサでも良かったのですが、consistent-hashingを使うことにより同じメトリックは同じcarbon-cacheインスタンスに分散させることで、update_manyによるまとめ書き込みを期待できます。

### tsdb-relay-lb導入
f:id:y_uuki:20150426234343p:image

さらに秒間書き込みデータポイント数が増えると、tsdb-master上のcarbon-relayのCPU利用率であたるので、carbon-relayを外に出すことを考えました。
外に出したcarbon-relayをスケールさせるために、LVSにぶら下げます。

1つのcarbon-relayでreplicationさせつつ、consistent-hashingするといったことができないので、carbon-relayが2段必要になってしまうのが難点ですね。
多段になればなるほど全体としての可用性やメンテナンス性は落ちるので、1段で完結させる方法を考えてはいます。
例えば、前段のcarbon-relayを無くしてアプリケーションに複製させたり、試したことはないもののcarbon-cacheはAMQPプロトコルをしゃべることもできるので、carbon-relayの代わりにRabbitMQを使うことも考えられます。

かなり複雑ですが、大雑把にみると冗長ペアを2台1組構築しているだけです。

ほとんど落ちることはないのですが、tsdb-masterノードが落ちたあとの復旧は、復旧側にcarbon-cacheの書き込みをさせつつ、rsyncで片肺からファイル同期します。
世の中的にもほとんどrsyncを使っているようです。
一旦どこかのレイヤで書き込み要求を貯めこんでその間にデータ同期するということができないと一貫性のあるデータ同期はかなり難しいです。

もちろんDRBDを使って同期するという方法はあります。試したものの、DRBDは更新のあったブロックを同期する仕組みなので、carbon-cacheのような全方位書き込みをすると、大量のブロックを同期しようとするため、ネットワーク帯域であたるということがありました。

# Graphite開発状況
https://github.com/graphite-project/

Graphiteは2006年から開発が始まったプロダクトです。
最近では大きなリリースはないものの、開発はゆるやかに進んでおり、プルリクエストもそこそこ活発というような状況です。
ただ、中の人のメンテナンスが追いついてないというか、結構放置されたプルリクエストが多いですね。
たまにissueがまとめて大量closeされたりしています。
whisper以外テストコードがない状態なので、いきおいよくマージできる状態じゃないのかもしれません。

現在のstableバージョンは0.9.12でMackerelでもこのバージョンを使っています。

一方で、次世代のCarbonとWhisperの実装として、MegacarbonとCeresというものもあります。
今ひとつ開発状況をつかめていないですが、Yahoo!で大規模に使われている事例もあります。

- [http://techblog.yahoo.co.jp/operation/2014-sensu-and-graphite/:title:bookmark]
- [http://anatolijd.blogspot.com.es/2013/06/graphitemegacarbonceres-multi-node.html:title]

# 参考

- [http://www.aosabook.org/en/graphite.html:title:bookmark]
- [https://github.com/sonots/growthforecast-tuning:title:bookmark]
- [http://www.slideshare.net/techblogyahoo/sensu-casualtalksyahoojapan:title]
- [https://answers.launchpad.net/graphite/+question/178969:title=Tuning Graphite for 3M points/minute with a single backend machine (a story)]
- [https://answers.launchpad.net/graphite/+question/184293:title=What is the recommended backup method?]
- [https://answers.launchpad.net/graphite/+question/228472:title=DESTINATIONS vs CARBONLINK_HOSTS in a cluster]
- [https://answers.launchpad.net/graphite/+question/188509:title=Adding a new carbon-cache server with consistent-hashing]
- [https://answers.launchpad.net/graphite/+question/176084:title=Metric creation has slowed to a crawl]
- [https://answers.launchpad.net/graphite/+question/170794:title=carbon-cache.py at its limit?]

# まとめ

<blockquote class="twitter-tweet" lang="ja"><p>SQLドリルとかやってないでRRDtoolドリルやれよ</p>&mdash; yuuki (@y_uuk1) <a href="https://twitter.com/y_uuk1/status/339953501113286656">2013, 5月 30</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

今回ははてなにアルバイトにきて初めてRRDtoolを触ってからの2年半にわたって蓄積した時系列DB、特にGraphiteに関する知見を紹介しました。
今の構成に落ち着いたのは1年ほど前ですが、改善する余地は多々あるものの正式リリース以降もそれほど大したトラブルもなく安定して動作しています。

とはいえ、現状安定しているシステムでも、サービスの成長にあわせてスケールさせていく必要があります。
特にトラヒックの桁が1つ2つ上のスケーラビリティを達成するためにはシステムのアーキテクチャを大きく変えることもあるでしょう。

はてなでは、計算機、OS、ネットワーク、ミドルウェアの知識を駆使して、日々成長していくサービスのトラヒックに耐えるシステムを構築・運用することに興味のあるエンジニアを募集しています。

[http://hatenacorp.jp/recruit/career/operation-engineer:embed]

[asin:1491916435:detail]
