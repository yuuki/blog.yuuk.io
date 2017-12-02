---
Title: ISUCON予選突破を支えたオペレーション技術
Category:
- ISUCON
- Performance
Date: 2016-08-23T09:11:42+09:00
URL: http://blog.yuuk.io/entry/web-operations-isucon
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/10328749687180423370
---

ISUCONに参加する会社の同僚を応援するために、ISUCONの予選突破する上で必要なオペレーション技術を紹介します。
自分がISUCONに初出場したときに知りたかったことを意識して書いてみました。
一応、過去2回予選突破した経験があるので、それなりには参考になると思います。
といっても、中身は至って標準的な内容です。
特に、チームにオペレーションエンジニアがいない場合、役に立つと思います。

今年のISUCON6は開催間近で、まだ予選登録受付中です。
[http://isucon.net/archives/48165644.html:embed]

※ 文中の設定ファイルなどはバージョンやその他の環境が異なると動かなかったりするので必ず検証してから使用してください。

# ISUCONでやること (Goal)

ISUCONでやることは、与えられたウェブアプリケーションをとにかく高速化することだけです。
高速化と一口に言っても、複数のゴールがあります。ウェブアプリケーションの場合は以下のようなものでしょう。

- レスポンスタイムが小さい
- スループット (req/s) が大きい
- CPUやメモリなどリソース消費量が小さい

ISUCONでは、基本的にはレスポンスタイムを小さくすることを目指します。
これは実際のウェブアプリケーションにおいても、ユーザ体験に最も直結するレスポンスタイムを改善することが重要なので理にかなっています。

とはいっても、リトルの法則により、安定した系において、レスポンスタイムが小さくなれば、スループットは向上するため、レスポンスタイムとスループットは相関します。

リソース消費量の改善は、レスポンスタイムに寄与するというよりは、サーバ管理にまつわる人的または金銭的なコストを下げることに寄与します。
例えばメモリが余っているのに、メモリ使用量を削減しても、レスポンスタイムには影響しません。ただし、そういった無駄を省くことで、アプリケーションの処理効率がよくなり、結果としてレスポンスタイムが良くなることはあります。

ISUCONは、具体的には、以下のような要素で構成されていると考えます。

- サーバを含む環境構築
- OS・ミドルウェアの選択とチューニング
- アプリケーションロジックとデータ構造の改善

ここでは、前者2つをオペレーションの領域、後者をプログラミングの領域とします。
必ずしも、オペレーション要員が必要ということはなく、あくまで領域なので、分担することも多いと思います。
自分の場合、過去2回とも、チームの構成上、オペレーションまわりはほぼ全部1人でやっていました。

# ISUCONの考え方 (Principles)

自分が考えるISUCONの原則は、「オペレーション（System Engineering）で点を守り、 プログラミング（Software Engineering）で点をとる」です。

OS・ミドルウェアのチューニングが劇的な加点要素になることはあまりありません。
そのレイヤのチューニングはリソース消費量を小さくすることに寄与することが多いためです。

ただし、チューニングしていないために、劇的に性能が劣化することはあります。
例えば、InnoDBのバッファプールサイズを小さくしていると、データがメモリに乗り切らず、大量のディスクI/Oが発生し、スコアが大きく下がるはずです。

もちろん、アプリケーションロジックが薄いとそれだけOSやミドルウェアが仕事をする割合が大きくなるため、 OSやミドルウェアのチューニングによりスコアが伸びることはあります。

[http://kazeburo.hatenablog.com/entry/2014/10/14/170129:embed]

そうはいっても、基本的にスコアを伸ばす手段は、アプリケーションロジックとデータ構造の改善です。
これは実際のウェブアプリケーション開発の現場でも同じことが言えます。
雑な体感によると、パフォーマンスの支配率は、アプリケーションが8割、OS・ミドルウェアが2割程度（要出典）だと思っています。

# ISUCONにおけるオペレーション

## 環境構築

予選の場合は、クラウド環境セットアップが必要です。ISUCON3、ISUCON4ではAWS、ISUCON5ではGCE、ISUCON6はAzureです。
アカウント作成やインスタンス作成がメインです。
当日のレギュレーションにも一応手順は記載されるはずですが、事前に触っておくと本番で混乱せずに済むと思います。

## サーバログイン環境

例年であれば、`/home/isucon` 以下に必要なアプリケーション一式が入っています。

isuconユーザがもしなければ (`useradd -d /home/isucon -m isucon`) などで作成します。
さらに、`/home/isucon/.ssh` 以下に公開鍵認証するための公開鍵を設置します。
`/home/isucon/.ssh/authorized_keys`ファイルを作成し、`.ssh`ディレクトリのパーミッションは700、`authorized_keys`ファイルのパーミッションは600であることを確認します。（この辺のパーミッションがおかしいとログインできない）
メンバー分のユーザを作成するのは面倒なので、共通ユーザ1つだけで問題ないと思います。

## デプロイ自動化

Capistranoのような大げさなものは使わなくて良いので、以下のような雑スクリプトでデプロイを自動化しましょう。

<script src="https://gist.github.com/yuuki/5e3f1ed205f29cb159c1069ac433dda5.js"></script>

やっていることはSlackへ開始デプロイ通知、git pull、MySQL、Redis、memcached、app、nginxの再起動、Slackへデプロイ完了通知ぐらいです。
MySQLやnginxもいれているのは、設定ファイルを更新したはいいが、再起動をし忘れるということがよくあるので、まとめて再起動してしまいます。
接続先のプロセスがしぬと、うまく再接続されない場合もなくはないので、再起動するのは原則バックエンドからが一応よいです。

## リソース利用率把握とログの確認

ここでいうリソースとはCPU、メモリ、ディスクI/O、ネットワーク帯域などのハードウェアリソースを指します。
要はtopの見方を知っておきましょうということです。以前ブログに書いたので、参照してください。

[http://blog.yuuk.io/entry/linux-server-operations:embed]

冒頭でISUCONではレスポンスタイムを小さくするのがよいと述べました。とはいえ、リソース消費量を把握しておくことはボトルネック特定のヒントになるので重要です。
例えば、予選問題の初期状態ではMySQLのCPU負荷が支配的であることが多いかつディスクI/Oが高ければ、まずMySQLのバッファプールを増やしたり、クエリ改善が必要そうという程度のことはすぐわかります。
ISUCON4で話題になったCache-Controlの件も、ネットワーク帯域が限界であることにもっと早く気づいていれば、何かしら手は打てたかもと思います。（当時は思い込みでそこでボトルネックになってるとは思っていなかった。）

## 監視

去年のISUCONでは、自分たちのチームではMackerelの外形監視を使ってみました。
競技中に、アプリケーションのsyntax errorか何かで500でてるのに、ベンチマーカーを走らせてしまい、時間を無駄にしてしまうことがあります。
インターネット経由でポート80番が疎通できてさえいれば、アプリケーションが落ちていると、Mackerelの外形監視がすぐに通知してくれます。

[https://mackerel.io/ja/docs/entry/external-monitoring:embed]

## MySQLデータサイズ確認

MySQLのデータサイズとして、テーブルごとのサイズや行数などを把握しておくと、クエリ改善の参考にできる。
行数が小さければ、多少クエリが悪くてもスコアへの影響は小さいため、後回しにできる。

```
mysql> use database;
mysql> SELECT table_name, engine, table_rows, avg_row_length, floor((data_length+index_length)/1024/1024) as allMB, floor((data_length)/1024/1024) as dMB, floor((index_length)/1024/1024) as iMB FROM information_schema.tables WHERE table_schema=database() ORDER BY (data_length+index_length) DESC;
```

## アクセスログの解析

proxyでアクセスログを解析することにより、URLごとのリクエスト数やレスポンスタイムを集計できます。

解析には、tkuchikiさんの[alp](https://github.com/tkuchiki/alp)が便利です。
自分の場合は、適当な自作スクリプトを使っていました。[https://gist.github.com/yuuki/129983ab4b02e3a646ad]

```
isucon@isucon01:~$ sudo parse_axslog isucon5.access_log.tsv taken_sec
req:GET / HTTP/1.1 taken_sum:474.08 req_count:714 avg_taken:0.66
req:GET /footprints HTTP/1.1 taken_sum:58.378 req_count:198 avg_taken:0.29
req:GET /friends HTTP/1.1 taken_sum:27.047 req_count:238 avg_taken:0.11
req:POST /diary/entry HTTP/1.1 taken_sum:6.51 req_count:195 avg_taken:0.03
…
```

nginxでLTSVによるアクセスログをだすには、以下のような設定を去年は使いました。

```
log_format tsv_isucon5  "time:$time_local"
 "\thost:$remote_addr"
 "\tvhost:$host"
 "\tforwardedfor:$http_x_forwarded_for"
 "\treq:$request"
 "\tstatus:$status"
 "\tsize:$body_bytes_sent"
 "\treferer:$http_referer"
 "\tua:$http_user_agent"
 "\ttaken_sec:$request_time"
 "\tcache:$upstream_http_x_cache"
 "\truntime:$upstream_http_x_runtime"
 "\tupstream:$upstream_addr"
 "\tupstream_status:$upstream_status"
 "\trequest_length:$request_length"
 "\tbytes_sent:$bytes_sent"
 ;
access_log /var/log/nginx/isucon5.access_log.tsv tsv_isucon5;
```

## MySQLスロークエリログの解析

MySQLのスロークエリログは、実行時間が閾値以上のクエリのログを吐いてくれるというものです。
最初は、`long_query_time = 0` にして、全クエリのログをとります。もちろん、ログ採取のためのオーバヘッドはありますが、最終的にオフにすればよいです。

```
slow_query_log                = 1
slow_query_log_file           = /var/lib/mysql/mysqld-slow.log
long_query_time               = 0
log-queries-not-using-indexes = 1
```

pt-query-digestで集計するのが便利です。 https://gist.github.com/yuuki/aef3b7c91f23d1f02aaa266ebe858383

## 計測環境の整備

ログの解析については、前回のベンチマークによるログを対象に含めたくないため、ベンチマーク前に過去のログを退避させるようにします。

[https://gist.github.com/yuuki/b1977ace1c2f9d80ac71df382bde0f74:embed]

設定ファイルを変更したまま、プロセスの再起動を忘れることがあるので、ベンチマーク前に各プロセスを念の為に再起動させます。

## チューニング

MySQL、nginx、redis、memcachedについては、特殊なお題でないかぎり、kazeburoさんのエントリの通りでよいと思います。
比較的スコアに効きやすいのは、静的ファイルのproxy配信、UNIXドメインソケット化あたりかなと思っています。

[http://kazeburo.hatenablog.com/entry/2014/10/14/170129:embed]

ただし、sysctl.confの設定内容反映については、Systemd バージョン 207と21xで注意が必要です。
具体的には、`/etc/sysctl.conf` が読まれず、`/etc/sysctl.d/*.conf` または `/usr/lib/sysctl.d/*.conf` が読まれるようです。
[https://wiki.archlinux.org/index.php/sysctl:title]

## アプリケーションの把握

オペレーションばかりやってると意外と、何のアプリケーションか知らずに作業しているということがあります。
特に序盤は定例作業が多いので、一息つくまでにそれなりに時間をとられます。
その間に、アプリケーション担当が把握していて、把握していることが前提になるので、会話についていけないこともあります。

そこで、以下のようなことを最初に全員でやって認識を合わせるといった工夫をしたほうがよいです。

- ウェブサービスとしてブラウザからひと通りの導線を踏んでみる
- テーブルスキーマをみる
- MySQLのコンソールに入ってデータの中身をみてみる
- コードを読む

## 競技終了前のチェック

競技終了前になにか見落としがないかチェックします。

- ディスクサイズに余裕があるか。運営サイドでベンチマークを回す時にログ出力でディスクがうまることがないとも限らない。ログを吐きまくってると意外とディスクに余裕がなくなっていたりするため、最後に確認する。
- ページの表示は正常か。CSSがなぜかあたってないとかないか。
- ログの出力を切る。アクセスログやスロークエリログ。
- (厳密には競技終了30分〜60分の間ぐらい) OSごと再起動してもベンチマークが通るかどうか

# 参考文献

kazeburoさんの資料が非常に参考になります。何度も読みました。

- [http://kazeburo.hatenablog.com/entry/2014/10/14/170129:title:bookmark]
- [http://www.slideshare.net/kazeburo/isucon-summerclass2014action2final:title:bookmark]
- [http://www.slideshare.net/kazeburo/isucon-yapcasia-tokyo-2015:title:bookmark]

昨年の予選のコードと設定ファイルは公開しています。https://github.com/yuuki/isucon5-qualifier
昨年の様子です。[http://blog.yuuk.io/entry/isucon5-qualifier:title:bookmark]

# 発表資料

この記事は、[京都.なんか#2](https://atnd.org/events/79718) で発表した内容を元にしています。
準備・運営ありがとうございました！ > id:hakobe932:detail / id:hitode909:detail

どの発表もおもしろかったけど、個人的にはkizkohさんのRust&netmapの話がよくて、netmapは昔論文読んだりしたものの、全然使っていなかったので、実験的とはいえ実際にコード書いて動かしているのがとてもよいなと思いました。
というかこんなところで、netmapとかdpdkの話がでてくるのかとびっくりしました。

<script async class="speakerdeck-embed" data-id="2c1dcbd00e024ee4b310f3362c40aba3" data-ratio="1.33333333333333" src="//speakerdeck.com/assets/embed.js"></script>

# あとがき

今年もはてなから何チームか出場するとのことだったので、知見共有のために、これまでのISUCON出場経験をまとめてみました。

ISUCON当日に調べながらやっていては間に合わないので、今のうちに練習しておくことをおすすめします。
さらに、全体を把握するために、過去の問題を一人で解いてみることもおすすめします。

おもしろいのは、多少ISUCON特有のノウハウは混じっているものも、実際の現場でやっているようなことがほとんどだということです。
昨今では、ウェブアプリケーションが複雑化した結果、高速化の余地があったとしても、大きすぎる問題を相手にすることが多いため、ISUCONは手頃な環境で経験を積むにはもってこいの題材です。

[http://isucon.net/archives/48241450.html:embed]

さらに本戦出場して惨敗すると、人権をロストしたり、ヒカリエの塔からハロウィンでめちゃくちゃになった街に突き落とされるような体験が待っています。

[https://twitter.com/y_uuk1/status/660433623703646208:embed]
