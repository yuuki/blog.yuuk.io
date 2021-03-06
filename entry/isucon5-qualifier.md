---
Title: "ISUCON 5予選で5位通過した話"
Category:
- 日記
Date: 2015-09-28T08:30:00+09:00
URL: http://blog.yuuk.io/entry/isucon5-qualifier
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/6653458415122838043
---

ISUCON 5の予選で2日目3位、全体で5位のスコアで通過した。

[http://isucon.net/archives/45532743.html:embed]

メンバーは id:ntakanashi さん, id:astj さんと自分の3人で、「はむちゃん」というかわいいチーム名で参加した。
言語は当然Perl。
役割分担は id:astj さんの記事にも書いてあるけど、だいたい以下のようなものだった。

<blockquote cite="http://astj.hatenablog.com/entry/2015/09/27/234106" data-uuid="6653458415122825413"><p>id:y_uuki : ミドルウェアより下をお任せ / ログ解析して改善ポイントの洗い出し id:ntakanashi : オンメモリにしたりモジュールを入れ替えたり諸々チューニング id:astj : クソクエリやN+1をちまちま潰していく</p><cite><a href="http://astj.hatenablog.com/entry/2015/09/27/234106">ISUCON 5の予選に参加して全体5位で通過しました - 平常運転</a></cite></blockquote>

昨年のISUCON 4に参加したときに、少なくともISUCON予選においてはアプリケーションロジックの改善/改変がスコアに対して支配的だと感じていた。
そこで、インフラ担当の最初の仕事はいかにしてアプリケーションエンジニアにロジックの改善に集中できる環境を作るかということだと考えた。
さらに、インフラエンジニアは普段からシステム全体を俯瞰することを求められるので、インスタンスサイズなど与えられた条件とシステム全体をみてシステムの性質を捉えることが重要だと思う。
今回の指定インスタンスはCPU4コア、メモリ4GB弱と去年よりメモリ搭載量がかなり少なかったので、これはいつものようなオンメモリ勝負は厳しいのではないかとあたりをつけていた。実際、普通に考えるとデータサイズがOSのメモリに乗らない量（一部のテーブルは150万行ぐらい）だったので、初期段階で明らかにMySQLのCPU利用率とディスクI/Oがボトルネックだった。
したがって、今回の出題意図はメモリに乗らないデータをいかに捌くかということにあると判断した。

インフラ担当である自分が具体的にやったことは、インスタンスの構築、デプロイの仕組みの整備、OS/Nginx/MySQL/memcached/アプリサーバのチューニング、topやiostatによるハードウェアリソース利用状況の把握、アクセスログとスロークエリログの解析などだった。
今回はベンチマークをインスタンスのローカルで実行する術がなかったので一回一回のベンチマークを無駄にしないために、どうせ仕込むであろうsysctlやmy.cnf、nginx.confのチューニング、UNIX domain socket化、PlackサーバをGazelleに変更、静的ファイルのnginx配信などは初期の段階で一気にやった。
さすがにやったことのないチューニングをするのは不安なので、過去問で訓練を重ねた。
ちなみにどうせスコアに影響しない（より高req/sな環境では影響するかもしれない）ワーカー数やスレッド数の調整に時間をかけるのも無駄なので、コア数分のワーカーしか立てないと決めていた。
今年はAWSではなくGCPだったので、去年の問題をGCEで構築し一通り癖を把握しておいた。Web UIからの公開鍵の設定やスナップショットの取り方など。
さらにディストリがCentOSからUbuntuに変更されるようだったので、ISUCONに必要なUbuntuのオペレーションも練習しておいた。（といっても普段からDebianをいじってるのであまり差はない）systemdだったのは面くらったけど、やることは大して変わらなかった。

あらかじめチェックリストやオペレーションメモを用意しておいて、それに従ってすばやく足場を組むことを意識していた。
13時すぎまでにはだいたい整えたので、のんびりコードでも眺めるかと思っていたけれど、後述する大きめのトラブルの解決やちょっとインデックス張ったりスコアが変化したときのボトルネックの変化を解析するということをずっとやっていた。
プロファイラとしてDevel::NYTProfの準備を一応していたけど、ディスクI/Oがネックだったので今回はいれなかった。ボトルネックがアプリケーションのCPU利用に移行した段階でいれてたと思う。

しかし、事前にいろいろ準備していたとはいってもやはりトラブルはいろいろある。

## トラブル1: MySQL has gone away

PerlのDBIではMySQLとの接続が切断された状態でSQLを投げると、MySQL has gone away というエラーメッセージがでる。
あるタイミングからこのメッセージが頻発するようになって、最初は接続できてるのにベンチ中に接続に失敗することがあった。
スコアが立ち上がる前だったのでとにかく最悪。
<del>これは結局原因がよくわからなくて</del>(原因らしきものは後述)、要は再接続するようにすればよいということで、DBIを `Scope::Container::DBI` [http://blog.nomadscafe.jp/2011/03/scopecontainerdbi.html:title] に差し替えて、dbhオブジェクトのキャッシュをやめて、`Scope::Container::DBI->connect`を毎回呼ぶようにした。

以前にこういうことを書いてた。

<blockquote cite="http://yuuki.hatenablog.com/entry/architecture-of-database-connection" data-uuid="6653458415122836976"><p>少なくとも、PerlのDBIの場合、DBI-&gt;connectの返り値であるデータベースハンドラオブジェクトをキャッシュしても、うまくいかない。 キャッシュしている間に、データベースとの接続が切れると、再接続せずにエラーを吐く。 データベース接続まわりのオブジェクトをキャッシュするときは、キャッシュして意図どおりに動作するのかをよく調査したほうがよい。</p><cite><a href="http://yuuki.hatenablog.com/entry/architecture-of-database-connection">Webシステムにおけるデータベース接続アーキテクチャ概論 - ゆううきブログ</a></cite></blockquote>

## トラブル2: ALTER TABLEが30分たっても終わらない

entriesテーブルに対するインデックスの作成が2000秒以上かかっていてめちゃくちゃだった。どうみてもディスクI/Oを使いきっていたのでどうしようもなかった。
過去に人数分のインスタンスをたてたりしていたチームがあったようで、それにならってメインのインスタンスのスナップショットからディスクをSSDに変更したインスタンスをたててそちらでALTERを回して、メインのインスタンスに`/var/lib/mysql`ごとncでとばすということをやった（SSDのインスタンスはもちろんベンチにはかけていない）。今ではSSDが当たり前になってるけど、改めてSSDの速さを実感した。これも最初はスナップショットではなくてVMインスタンスの複製機能みたいなのを使った。これは便利とか言ってたら、数時間前の状態のインスタンスの複製が作られることに気づいて、あわててスナップショットによる複製に切り替えた。

その他、手作り感のある最小限の`/etc/my.cnf`は読まれずに、debパッケージ付属の `/etc/mysql/my.cnf` が実は読まれているという罠があった。
これを適当に`/etc/mysql/my.cnf`を`/etc/my.cnf`に差し替えるとbase dir か data dirあたりがたぶん間違っていてmysqldが起動しなくなる。事前に過去問であれこれ壊したのでハマることはなかった。

立ち上がりはそれほどスコアが伸びなかったことや、途中でトラブルがあって、トラブル解析中に複数の改善をいれていたりしたので、はっきりこの変更がスコアに効いたみたいなのがわからずに進んでいった（failしつつもログの解析はやってた）。
とはいえ、基本はアクセスログ解析とpt-query-digestを丁寧にまわして実行時間の割合が大きい順にクエリを改善していくことを意識していた。
その他は変更の手間が少ないものをやるぐらいで、ボトルネック無視で見当違いのところをチューニングし始めるということはたぶんなかったと思う。
打つ手がなくなってくる終盤はともかく中盤まで1つずつボトルネックをつぶせていった感があった。

最終的には、Nginx - Perl - MySQLの普通の構成でセッションだけmemcachedにいれた。usersのようなメモリ内にキャッシュできるところはアプリケーション起動時にMySQLから引いて親のアプリケーションプロセスのメモリにキャッシュした。あとは普通に各テーブルにインデックスを張り、N+1クエリをなくしていくという感じ。
親プロセスにキャッシュするのは、最初 `/initialize` でやってたけど、`/initialize` でキャッシュするとpreforkされた子プロセスのうちの1つだけしかにしかキャッシュされなくて確率的にエラーになるので親プロセスでロードすることにした。

書いてる途中に思い当たったけど、親プロセスでMySQLに接続しつつDBIのattributeで`AutoInactiveDestroy`が指定されているので子プロセスでdbhオブジェクトが勝手に破棄されて、dbhオブジェクトを使いまわしてる場合うまく動かないかも？と思った。 [http://gihyo.jp/dev/serial/01/perl-hackers-hub/003002:title]
いずれにしても親プロセスのソケットディスクリプタをforkで引き継いでるところが問題になっていそう。
あとでみてみる。

リポジトリはこちら。https://github.com/yuuki1/isucon5-qualifier

ちなみにMackerelの外形監視でトップページを監視させた。アプリケーションが停止してるときに誤ってベンチしないようにとかいろいろ使いみちがありそう。

[http://blog-ja.mackerel.io/entry/2015/07/03/105145:embed:cite]

# 参考

ISUCON予選の準備をするときに特に下記のエントリを参考にさせていただくことが多かった。

- [http://kazeburo.hatenablog.com/entry/2014/10/14/170129:title:bookmark]
- [http://www.slideshare.net/kazeburo/isucon-yapcasia-tokyo-2015:title:bookmark]
- [http://sfujiwara.hatenablog.com/entry/20140929/1411972115:title:bookmark]

# あとがき

去年は本戦出場枠に結構ギリギリで滑りこんだので、去年より参加チームの多い今年はかなり厳しいのではと思っていたけど、終わってみれば意外と上位通過でチームメンバーの優秀さをみせつけられた一日だった。
ISUCON、結構メンバーのバランスが重要だと思っていて、全員ある程度サーバをいじれて、ある程度コードを書ける+@みたいなイメージ。
例えば、方針決めたりボトルネック見極めたりはインフラ担当まかせたみたいな感じになりがちのような空気があるけど、ツールさえ置いておけば2人とも勝手にみてくれる。コードだけみて局所最適に走ることが少ない。
同じ会社にいるとその優秀さがだんだん当たり前にみえてくるけど、ISUCONのようなイベントで対外的に評価されることになって、その優秀さは普通じゃなかったんだなということが改めてわかる。

基本はアプリケーションロジックの改善に2人とも集中してもらえたと思うので、スコアにはたいして貢献してないけどとりあえず役目は果たした感がある。
まあまあトラブル多かったわりに意外となんとかなったのは事前準備してやるべきことをわりと早めに終わらせて時間的余裕を稼げたからかなと思う。

インフラエンジニアにとっては複数サーバ使える本戦が本当の力を試されると思う。複数サーバ使うISUCON楽しみすぎる。

ISUCON運営の皆様、すばらしいイベントをありがとうございました。
やりがいのある問題で楽しかった。今回の問題を5台構成で解いたりしてみるとたのしそう。
