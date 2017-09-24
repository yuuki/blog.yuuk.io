---
Title: "2014年、技術しかしてない"
Category:
- 日記
Date: 2014-12-31T17:00:00+09:00
URL: http://blog.yuuk.io/entry/looking-back-2014
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/8454420450078394338
---

2014年、振り返ってみてもとにかく技術しかしてない。

Webオペレーションエンジニアになった。

1人でサービスを構築・運用するようになった。

とうとう25歳になった。もう定年だ。

9月に引っ越した。自炊あきらめた。

ISUCON4の本戦で惨敗した。Cache-Controlとか知らんし。

ブログで承認ゲットした。

Dockerしてた。Dockerは最高。

<!-- more -->

数編の論文を読んた。

京都在住にしてはとにかくたくさん技術プレゼンした。東京で消耗してた。

新卒入社成功してから1年がたってた。

[https://twitter.com/y_uuk1/status/539311302775042050:embed]

去年の目標みたいなのを振り返ってみる。 [http://yuuki.hatenablog.com/entry/2013/12/31/204602:title]

- プロとしてのエンジニアリングをやっていく
  - なにがプロだ。
- ブログエントリばかり読んでないで、体系的にまとめられた書籍
  - 失敗。来年の目標にしよう。
- OSS活動
  - このへんにある https://github.com/mackerelio 。これも来年の目標。
- DockerとかMesosとか使って何かしたり
  - Dockerで何かしてた。

2014年は職業としてのエンジニアになった年であり、エンジニアとしてのアウトプットを積極的にした年でもあった。
よい会社に入ったこともあって、充実していた。人間が1年を振り返れば、5月は5月病でやる気がなかったとか、10月は中退してずっとオンラインゲームしてたとかあると思う。今年はあまりやる気のない期間というものがなかった。1日もないといえば嘘だけど。
ずっと技術のことだけ考えておけばよかった。いつかそうも言ってられない時が来ると思って怯えてる。

来年どうするか。3つだけ考えていることがある。
まず、1年サービス運用してきて、課題がある程度みえてきたので、自作ツールで補えるところは補っていきたい。コードをあまり書けてなかったが、1年は運用技術の習得に集中しようという意識があった。集中できたかはどうか微妙だったかもしれない。
次に、計算機システムそのものについて、より深く理解したい。Dtrace の作者の方が書いてる [http://www.amazon.co.jp/dp/0133390098:title=Systems Performance: Enterprise and the Cloud] という本がよさそうに思って、電子版を買って読んでる。
最後に、去年からのブームである Immutable Infrastructure 技術の導入について、Docker を支える技術と分散システムが柱になっていくと思っていて、[http://www.amazon.co.jp/dp/4894715562:title=分散システムー原理とパラダイム] とかを読んで勉強したい。
Kubernetes や Consul とかツールを触ってるだけではきっと本質はわからない。

あとは、各社でサーバ運用してる同世代の若者と交流したい。この職種、若者が少ない。
年明けには、Docker meetup #4 での発表が控えてる。夏には最後のYAPCもある。どこかで連載するという話もある。
きっと、あと数年はこの延長線上を歩いてそう。その先になにがあるのかはわからない。

## ブログの振り返り

去年は34本のエントリを書いた。合計ブクマ数は 1,590 users だった。年間PVは 65,070 views だった。

今年は28本をエントリを書いた。合計ブクマ数は 5,055 usersだった。年間PVは 172,878 views だった。
今年は、平均 180 users のエントリを書いたことになる。確かに今年の後半では、何か書けば絶対ホットエントリという感じで、ホットエントリ入りして感動する心を徐々に失っていって、残るのは部屋のベッドで丸まって、虚ろな目でリロードしまくる自分の姿だった。あの感動をもう一度取り戻したい。

[https://twitter.com/y_uuk1/status/547713570578759682:embed]

今年のブクマ数ランキングを出してみた。100 users 以上のエントリだけ。

上位5位のうち、4つが論文を読んだ話になってる。全体的に Docker に関するエントリが多い。Docker はちょうど自分が好きな領域をまるごとカバーする技術だから好きなんだと思う。

あとは、Go がよい。余計なことを考えなくてよいようになっていて、やりたいことに集中できる。CやC++を書いてる気持ちで書くと最高だ。クロスコンパイルかつ依存なしワンバイナリで配布できるから、デプロイがしやすい。

|順位| エントリ |
|:---:|:----------------------------------------------------------------------------------------------------------------------------------:|
|1 位|[http://yuuki.hatenablog.com/entry/system-papers:title=インフラエンジニア向けシステム系論文:bookmark]|
|2 位|[http://yuuki.hatenablog.com/entry/tokyo-is-too-old:title=東京はもう古い、これからは京都:bookmark]|
|3 位|[http://yuuki.hatenablog.com/entry/docker-performance:title=Dockerは速いのか？Dockerのパフォーマンスについて重要なことは何か？:bookmark]|
|4 位|[http://yuuki.hatenablog.com/entry/facebook-memcached-paper:title=Facebookの数千台規模のmemcached運用について:bookmark]|
|5 位|[http://yuuki.hatenablog.com/entry/dsync-paper:title=Linuxのブロックデバイスレベルで実現するrsyncより高速な差分バックアップについて:bookmark]|
|6 位|[http://yuuki.hatenablog.com/entry/tmux-ssh-mackerel:title=tmux + ssh + Mackerel API を組み合わせたとにかくモダンなサーバオペレーション:bookmark]|
|7 位|[http://yuuki.hatenablog.com/entry/next-is-docker:title=Perlはもう古い、これからはDocker:bookmark]|
|8 位|[http://yuuki.hatenablog.com/entry/go-and-mysql-jobqueue:title=GoとMySQLを用いたジョブキューシステムを作るときに考えたこと:bookmark]|
|9 位|[http://yuuki.hatenablog.com/entry/go-links:title=Go言語の便利情報:bookmark]|
|10 位|[http://yuuki.hatenablog.com/entry/dockerized-isucon:title=ISUCONでNginxとMySQLをDocker化したときのパフォーマンス:bookmark]|
|11 位|[http://yuuki.hatenablog.com/entry/go-cli-unix:title=Go言語によるCLIツール開発とUNIX哲学について:bookmark]|
|12 位|[http://yuuki.hatenablog.com/entry/ii-conference01:title=Docker 使ってたらサーバがゴミ捨て場みたいになってた話 #immutableinfra:bookmark]|
|13 位|[http://yuuki.hatenablog.com/entry/docker-package-ci:title=Docker を用いた rpm / deb パッケージ作成の継続的インテグレーション:bookmark]|

## 発表振り返り

今年は合計8回発表した。

### [https://atnd.org/events/47786:title=Immutable Infrastructure Conference #1]
やたらとウケた。もう人生であんなにウケることはきっとないと思う。最初からネタに振ってたけど、いま見ると意外と有用なことを言っていた。rebuild.fm で言及されて勝ち組と言われた。

<script async class="speakerdeck-embed" data-slide="3" data-id="0a5ae5e096770131f0373e762bb67ced" data-ratio="1.33333333333333" src="//speakerdeck.com/assets/embed.js"></script>

### [http://atnd.org/events/48999:title=JVM Operation Casual Talks]
知見ないのになぜか話すことになってた。かんべんしてくれ。

<script async class="speakerdeck-embed" data-id="056ecaa0a0d0013156b3322d8ebd0734" data-ratio="1.33333333333333" src="//speakerdeck.com/assets/embed.js"></script>

### [https://atnd.org/events/46446:title=第3回 コンテナ型仮想化の情報交換会＠大阪]
発表が立て込んでて、ちょっと雑になってしまって申し訳なかったかもしれない。
Docker の CHANGELOG を見ましょうという話をした気がする。

### [http://www.zusaar.com/event/7437003:title=可視化ツール現状確認会]
Mackerelの話をした。会場は、VOYAGE GROUP の AJITO で社内にあんなバーがあるのはどう考えてもおかしい。これが東京か〜と思って見てた。

<script async class="speakerdeck-embed" data-id="82b30a90ce3501316bf71e853270e897" data-ratio="1.33333333333333" src="//speakerdeck.com/assets/embed.js"></script>

### [http://www.zusaar.com/event/11447004:title=Monitoring Casual Talks #6]
全員発表型のクローズド？勉強会。質問とか議論が活発で情報交換という意味ではこういうスタイルの勉強会がよいなと思った。
[http://yuuki.hatenablog.com/entry/monitoringcasual6:title:bookmark]

<script async class="speakerdeck-embed" data-id="a0b2b400d4ae01312e0e2a4d531fd829" data-ratio="1.33333333333333" src="//speakerdeck.com/assets/embed.js"></script>

### [http://www.zusaar.com/event/8427003:title=Hosting Casual Talks #1]
会場スポンサードLTとかいって勝手にしゃべった。内容はこれ。[http://yuuki.hatenablog.com/entry/tmux-ssh-mackerel:title:bookmark]。
この時はいろいろな方と話せたけど、特に @matsumotory さんとお会いできたのが良かった。目上に対する敬意がないと言われる自分でも尊敬できる人がいるのはいいことだと思う。

### [http://ct-study.connpass.com/event/9068/:title=第5回 コンテナ型仮想化の情報交換会＠大阪]
ISUCON アプリを Docker 化した話をした。ブログ書いたら、某社とか某社で話題になってたらしい。[http://yuuki.hatenablog.com/entry/dockerized-isucon:title]

### [http://hatena.connpass.com/event/10133/:title=Hatena Engineer Seminar #3 @ Tokyo]
オンプレミスとクラウド、そして Docker という話をした。
発表した後の懇親会とかそのあと2次回で、いろいろ話ができた。いつもは、誰々がどこに転職したとか疲れてるとかそういう東京ローカル事情みたいな話題が多くて、だいたいついていけない。


今年は、YAPC::Asia のような大規模カンファレンスでの発表はなかった。東京へ行く度に結構疲れてしまった反省をこめて、来年はピンポイントで興味のあるカンファレンスや勉強会で発表したい。

今年もお世話になりました。来年もよろしくおねがいします。
