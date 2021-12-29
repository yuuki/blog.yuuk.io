---
Title: Redis Clusterとgo-redisの深刻な性能劣化を解決した話
Category:
- Go
- Redis
Date: 2020-12-23T06:34:04+09:00
URL: https://blog.yuuk.io/entry/2020/goredis-performance-degradation
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/26006613668819288
---

[さくらインターネット Advent Calendar 2020](https://qiita.com/advent-calendar/2020/sakura)の23日目です。

現時点では最新版のRedis 6.0の[Redis Cluster](https://redis.io/topics/cluster-spec)に対して、Go言語の代表的なRedisクライアントライブラリである[go-redis](https://github.com/go-redis/redis)からアクセスしたときに、性能が深刻なレベルで劣化しました。
この記事では、ミドルウェアを利用したGo言語アプリケーションの性能劣化に関する問題調査の事例として、この性能劣化を修正するまでの話をまとめました。

go-redisへのPull Requestは<https://github.com/go-redis/redis/pull/1355>です。

---

## はじめに

半年ほど前の論文の締め切りに追われていたある日、評価実験のために[Redisを使った時系列データベースのプロトタイプ](http://github.com/yuuki/xtsdb)を開発していました。
[ベンチマークツール](https://github.com/yuuki/influxdb-comparisons)でプロトタイプの性能を測定したところ、単一インスタンスのRedisに対して想定した結果を得られました。

そこで、意気揚々と、スケールアウト性能を評価するために、複数のRedisインスタンスにデータを水平分割可能なRedis Clusterを利用して、スループットを計測しました。
ところが、信じがたいことに、単一インスタンスに対するスループットよりも、クラスタ化することでかえって、1/10倍ほどスループットが低下する結果となりました。

最初は、単一インスタンスとRedisクラスタとの処理の差分に着目しました。
実験では、GoアプリケーションとRedisプロセスのCPUリソースを全く使い切れていなかったため、ネットワークI/Oに関わるボトルネックにあたりをつけました。

Redisクラスタは、水平分割のために、コマンドが対象とするキーとノードを対応させる必要があります。
キーとノードの対応を直接管理するわけではなく、ノードの増減に対応しやすいように、ハッシュスロットという固定数のスロットが利用されます((水平分割（パーティショニング）におけるノードのパーティション割り当て戦略について詳しくは、「Martin Kleppmann著,斉藤太郎 監訳,玉川竜司 訳, データ指向アプリケーションデザイン――信頼性、拡張性、保守性の高い分散システム設計の原理, 6.4.1.2 パーティション数の固定, オライリー・ジャパン, 2019」を参照してください。))。
ノードが自身に割り当てられたハッシュスロットに対応しないキーを含むコマンドを受信したときに、クライアントへリダイレクトするように指示します。
なるべくリダイレクトさせないほうが望ましいため、go-redisはキーがどのハッシュスロットに属するかを計算した上で、適切なノードに最初からコマンドを送信します。

<!-- Redisクラスタでは、単一のトランザクション内で複数のコマンドを実行する[パイプライニング](https://redis.io/topics/pipelining)や[Luaスクリプティング](https://redis.io/commands/eval)を利用するときに、トランザクション内でアクセスするキーは全て同一のノード内に存在しなければならない制約があります。
とはいえ、通常であればキーとノード（実際には、キーとノードの対応を直接管理するわけではなく、ノードの増減に対応しやすいように、ハッシュスロットという固定数のスロットを利用する）の対応は、キーに対するハッシュ値で決定されてしまうので、プログラマが直接に制御できるわけではありません。
そこで、あるキーパターンを同一のハッシュスロットに強制的に割り当てるためのハッシュタグと呼ばれる機能があります。 -->

[https://twitter.com/yuuk1t/status/1267877063374991360:embed]

クライアントによるノード選択がうまく動かずに、コマンド発行のたびにリダイレクトしているのではないかとあたりをつけました。
しかしながら、go-redis内でprintデバッグしても、リダイレクトを観測できませんでした。

このように、その時点で持ってる知識から直感であたりをつけて問題調査をしても、試行錯誤の回数が増えて、結局遠回りなりました。
そこで、推測せずに、計測することにしました。
計測のために、Go言語標準のトレーシングツールである[Execution tracer](https://golang.org/doc/diagnostics.html#execution-tracer)を利用しました。
[pprof](https://golang.org/pkg/net/http/pprof/)で取得した結果を`go tool trace`に食わせると、goroutineの実行状況、特にメソッドの呼び出し関係とメソッド単位の実行時間を可視化できます。

## go tool traceの分析結果

`go tool trace`はView Trace、Goroutine Analysis、Network blocking profile、Synchronization blocking profile、Syscall blocking profile、Scheduler latency profileなどのトレースのビューがあります。
次の画像は、実際のプロトタイプの動作が可視化されたビューの種類ごとの結果です。
ビューによっては、みやすさのために、ビューの一部を拡大して表示しています。

View Traceは、Goroutine数、ヒープメモリ量、スレッド数、プロセスごとのGC回数やどのコードが実行されているかなどの時間変化を表示します。

[f:id:y_uuki:20201223142544p:image]

Goroutine Analysisは、プロファイル期間に実行されたgoroutineの数を、goroutineが起動された関数ごと、かつ、全体の実行時間の割合の降順に表示します。

[f:id:y_uuki:20201223142507p:image]
(Goroutine Analysis)

[f:id:y_uuki:20201223143647p:image]

Network blocking profoleは、ネットワークI/O待ち時間をメソッドの呼び出し関係とともに表示します。

[f:id:y_uuki:20201223142503p:image]
(Network blocking profole)

Synchornization blocking profileは、排他ロックなどの同期プリミティブにより待ちに入った時間をメソッドの呼び出し関係とともに表示します。

[f:id:y_uuki:20201223040626p:image]
(Synchornization blocking profile)

Syscall blocking profileは、OSカーネルに対するシステムコールのブロック時間をメソッドの呼び出し関係とともに表示します。

[f:id:y_uuki:20201223164031p:image]
(Syscall blocking profile)

Scheduler latency profileは、Goの処理系のスケジューラのスケジューリング遅延時間を表示します。

[f:id:y_uuki:20201223142458p:image]
(Scheduler latency profile)

<!-- `go tool trace`をあまり使ったことがなかったので、最初は見方がわからず、次のツイートのように、ネットワークI/O待ちがボトルネックであることしかわかっていませんでした。

[https://twitter.com/yuuk1t/status/1268391512615739393:embed] -->

各ビューをみると、go-redis内のミューテックスロックと画像では見えづらいですがRedisのパイプライン処理内のネットワークI/O待ちがボトルネックとなっていることがわかります。
profile系のビューでは、上の画像では範囲外になっていますが、自分が書いているアプリケーションのコードのメソッドも表示されるので、ライブラリの内部的な処理と紐付けることができます。

## ミューテックスロックの調査

このロックは何のためにどこで利用されているのでしょうか。
sync.Mutexの呼び出し元は、ClusterClient.mapCmdsByNode -> ClusterClient.cmdSlot -> ClusterClient.cmdInfo -> cmdsInfoCache.Get -> internal.Once.Do の順となっています。
mapCmdsByNodeは、パイプライニングのキーに関する制約にあたらないように、適切なノードにコマンドを振り分けるために、ノードとコマンドの対応を生成します。
その一連の処理の中で、コマンド引数の中のキーの位置を知る必要があります。
go-redisでは`COMMAND`コマンドを利用することにより、動的にコマンドとキーの位置の対応関係を取得できます。
コマンドとキーの位置の対応関係は、Redisのコード内で静的に決定されるため、Redisサーバにアクセスするたびに、取得する必要はありません。
そこで、`COMMAND`コマンドの結果をキャッシュするのが、cmdsInfoCacheです。
おそらくは、複数のgoroutineから`COMMAND`コマンドがRedisサーバに殺到しないように、ミューテックスロックを獲得したのちに、`COMMAND`コマンドを送信しています。

このミューテックスロックの箇所がボトルネックということは、`COMMAND`コマンドをキャッシュできずに、毎回`COMMAND`コマンドを送信しているのではないか？と疑いました。
実際に、printデバッグすると、パイプラインを実行するたびに、たしかに`COMMAND`コマンドを送信していました。
なぜこのようなことが起きているのかを探っていくと、`COMMAND`コマンドの結果を取得するメソッドがエラーとして`redis: got 7 elements in COMMAND reply, wanted 6`を返していました<https://github.com/go-redis/redis/blob/v7.2.0/cluster.go/#L1534-L1540>。
このエラーが上位の呼び出し元に伝搬する過程で、エラーが無視され、`COMMAND`コマンドの結果をnilとして返却していました。<https://github.com/go-redis/redis/blob/v7.2.0/cluster.go/#L1546-L1549>
この調査により、キャッシュできずに、毎回`COMMAND`コマンドを送信していたことが確定しました。

## エラーの分析と修正

前述のエラーの生成元は、`COMMAND`コマンドの結果のパース処理でした。ここでエラーになるということはnが期待する6ではなかったことを指します。

```golang
func commandInfoParser(rd *proto.Reader, n int64) (interface{}, error) {
	if n != 6 {
		return nil, fmt.Errorf("redis: got %d elements in COMMAND reply, wanted 6", n)
	}
# https://github.com/go-redis/redis/blob/v7.2.0/command.go/#L1936-L1939
```

このnの値は、`COMMAND`コマンドが出力する、各コマンドごとのメタ情報の要素数を指しています。
そして、Redis 6.0からはこの要素数が6から7に増えていました。<https://github.com/redis/redis/commit/c5e717c637cbb1c80e1259560ebf995fb7920628>
このRedis本体の変更により、先程のエラーが生成されるようになっていました。

[https://twitter.com/yuuk1t/status/1268561458574446598:embed]

実際に、コマンドを叩いて確認してみます。
Redis 5.0.8は、次のように要素数6となりました。

```shell-session
127.0.0.1:6379> COMMAND INFO xadd
1) 1) "xadd"
   2) (integer) -5
   3) 1) write
      2) denyoom
      3) random
      4) fast
   4) (integer) 1
   5) (integer) 1
   6) (integer) 1
```

一方で、Redis 6.0.1では、次のように要素数が7となりました。

```shell-session
127.0.0.1:6379> COMMAND INFO xadd
1) 1) "xadd"
   2) (integer) -5
   3) 1) write
      2) denyoom
      3) random
      4) fast
   4) (integer) 1
   5) (integer) 1
   6) (integer) 1
   7) 1) @write
      2) @stream
      3) @fast
```

以上により、エラーの修正内容は、要素数7のケースの対応を追加するだけだとわかりました。
修正の結果、プロトタイプにおいて、想定するスループットを得ることができました。

最終的に、この修正内容をgo-redisへPull Requestとして提案して、提案が取り込まれました。

[https://twitter.com/yuuk1t/status/1268759306943389697:embed]

## 参考

- [https://about.sourcegraph.com/go/an-introduction-to-go-tool-trace-rhys-hiltner/:title]
- [https://kiririmode.hatenablog.jp/entry/20190506/1557097529:title]
- [https://yuroyoro.hatenablog.com/entry/2017/12/11/192341:title]
- [https://blog.yuuk.io/entry/redis-cpu-load:title]

## まとめ

Redis 6.0のクラスタにおいて、go-redisで接続したときの深刻な性能劣化に対して、pprofを利用して、ボトルネックを発見し、ソースコードを調査した上で、修正しました。
今回の問題は、Redis 6.0以降のクラスタに対して、go-redisから接続すると必ず発生するものでしたので、小さな修正のわりには、潜在的な影響範囲はそれなりに大きかったように思います。
それを修正できたので、自分としては満足感を得ました。

僕は、自分が開発したわけではない既存のOSSの、バグや改善点を発見することがどうも苦手なため、既存のOSSにパッチを投げることに対して苦手意識をもっています。
実際、Pull Requestを投げる頻度は、高々年に1,2回程度です。
OSSの問題を発見して修正パッチを息を吸うように投げられる人は、おそらくソフトウェアの問題を発見する目が鍛えられているのでしょう。

研究を進める上では、実験結果をよくするために、どうしても所定の性能がほしかったり、研究成果の一部を世の中で使ってもらうためには、既存のOSSを改善することが必要になります。
このような目的意識から駆動される、ある種の強制力をうまく利用して、苦手ながらもOSSコミュニティへ少しずつ貢献していきたいですね。

振り返ってみると、サーバ側のAPIの仕様変更にクライアントライブラリが追従できていなかった故に発生した問題ということになります。
仕様変更を異なる組織や個人が管理するクライアントライブラリまでに反映させるのは、コミュニケーションのレベルで、一般的に難しい問題です。
性能の問題と捉えると、CI/CDのプロセスに性能測定をして、異常があれば通知することも一つの手です。
しかし、どの程度遅くなれば、異常とみなすのか、性能値を評価するには、CI/CD環境で一貫したハードウェアリソースを利用しつづけなければならない、様々なアクセスパターンが考えられる中で、どの程度テストケースを網羅すべきかなど考えることはたくさんあります。

このように、ちょっとした工夫では解決しづらい問題を、研究開発で解決する問題と捉えると、おもしろいかもしれません。
