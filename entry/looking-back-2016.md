---
Title: "2016年のエンジニアリング振り返り"
Category:
- 日記
Date: 2016-12-31T21:59:12+09:00
URL: http://blog.yuuk.io/entry/looking-back-2016
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/10328749687202592934
---

はてなに入社して3年経った。

[https://twitter.com/y_uuk1/status/804194304923037696:embed]

3年というのは節目と言われる。働き方や考え方の軸が多少変わってきたように思う。
技術観点では、仕事が少しつまらなくなっていた時期があった。
技術的におもしろいことより、つまらないことのほうが優先度が高くなってしまうというよくあるやつだと思う。
もしくは、おもしろいところまで到達できずに、仕事としては十分な成果になってしまうということもあった。

去年の振り返りに、来年はコードを書くと書いていて、多少はできたものの実感としてはあまりできていない。これからのオペレーションエンジニア/SREは、ソフトウェアエンジニアリングによる問題解決ができないと時代に取り残されてしまうという危機感がある。

技術的挑戦を続けていくためには、自分だけでなく、周囲の環境も変えていかないといけないと思い、マネジメントし始めたり、リーダーシップをとったり、直接的な採用活動をするような局面が増えてきた。
それはそれで自分でやると言ってやっていることだし、悪くはないのだけど、これ自分でやっていればアウトプットもできるのになと思いながら、任せないといけないことも多かった。
慣れないことをやっていると、大したことやってなくても疲れるもので、アウトプット活動が止まってしまった時期もあった。

一時的にそういった期間があることは仕方ない、いつも最高の環境があるわけじゃないので、意識的に環境に作用できるようになれれば、それは自分の強みになると言い聞かせてきた。
最終的には、社内外の期待をかけてくださる方々にいくつかのきっかけをいただいて、来年は技術的に挑戦できる年になるという気持ちで年を越せそうだ。
[https://speakerdeck.com/yuukit/the-study-of-time-series-database-for-server-monitoring:title:bookmark] に書いた設計を自分の代表的プロダクトにすべく、プライベートリポジトリでちまちまとコードに落とし込んでいたりする。
このあたりは、今年大変仲良くしていただいたid:matsumoto_r:detailさんと、あとはMackerelチームのプロデューサーである id:sugiyama88:detail さんのおかげだ。

振り返ってみると、今年は次の挑戦のための土台づくりに専念した年かもしれない。

## 成長

内在的な技術的成長は多少はあったものの、アウトプットにつながっていないものは成長とみなさないことにしているので、今年は技術的成長があまりなかったといえる。

あえていえば、実際の運用で導入した[Keepalivedのシンタックスチェッカー](http://blog.yuuk.io/entry/gokc)や今書いているソフトウェアの要素であるGraphiteの式のパーザーなど、これまで書けなかったタイプのコードを書けるようになった。トークナイザーとYACCを書いてるだけはあるけど。

あとは、はてなのこれまでのスタックにはないようなアーキテクチャを構築する機会がいくつかあり、アーキテクチャで解決するという手持ちの札が増えてきたように感じる。

技術以外の成長では、多少マネジメントをしたり、プロジェクト管理みたいなことを覚え始めた。SRE本の第18章"Software Engineering in SRE"にも書かれているが、インフラの領域でも、ソフトウェアエンジニアリングを本格的にやるなら、サービス開発のプロジェクト知見も必要なので、役に立つと思う。周囲の方々の助けもいただいて、多少の手応えもつかめた。

そして、今年一番の収穫は、ストーリーをつくるという意識かもしれない。
ストーリーというとプレゼンのようなものを連想する。もちろんプレゼンも含むのだけど、もっとこう自分の技術の取り組みのストーリーみたいなものを考えるようになった。
普通のエンジニアである僕がなぜか来年に登壇することになった[IPSJ-ONE](http://ipsj-one.org/)の演題を考えたり、[研究会での登壇](http://blog.yuuk.io/entry/iots2016)があったり、あとまだ公開されていない何かのためにまつもとりーさんの論文や口頭発表、ブログを読み返したことが影響している。
博士課程では、複数回のジャーナルを通して、最後にそれらをまとめるということをやるようなので、その手法にも影響を受けている [http://hb.matsumoto-r.jp/entry/2016/09/07/150017:title], [http://www.nakahara-lab.net/blog/2012/11/post_1907.html:title]。
自分のストーリーがあれば、[次に何を勉強するか](http://hakobe932.hatenablog.com/entry/how_to_get_what_to_learn)も決まってくる。
僕のように瞬発力とか手の速さで勝てない凡人は、ひたすら考えて、自分のやってきたこと、これからやることを繋いでいくしかない。

## アウトプットまとめ

いつものようにブログやOSS活動を振り返る。

### ブログ

いつものブログに加えて、今年から技術メモとしてGitHubにちまちまとメモを残していたりする。
[https://github.com/yuuki/yuuki:embed]


|順位| エントリ |
|:---:|:----------------------------------------------------------------------------------------------------------------------------------:|
|1位| [http://blog.yuuk.io/entry/linux-server-operations:title:bookmark] |
|2位| [http://blog.yuuk.io/entry/infra-for-newlang:title:bookmark] |
|3位| [http://blog.yuuk.io/entry/google-linux-distribution-live-upgrade:title:bookmark] |
|4位| [http://blog.yuuk.io/entry/diy-container:title:bookmark] |
|5位| [http://developer.hatenastaff.com/entry/golang-for-ops:title:bookmark] |
|6位| [http://blog.yuuk.io/entry/the-best-entries-of-2015:title:bookmark] |
|7位| [http://blog.yuuk.io/entry/web-operations-isucon:title:bookmark] |
|8位| [http://developer.hatenastaff.com/entry/2016-newbie-training-of-web-operation:title:bookmark] |
|9位| [http://blog.yuuk.io/entry/iots2016:title:bookmark] |
|10位| [http://developer.hatenastaff.com/entry/2016/12/28/151403:title:bookmark] |
|11位| [http://blog.yuuk.io/entry/my-memories-about-web-operation:title:bookmark] |
|12位 | [http://developer.hatenastaff.com/entry/2016/04/28/125529:title:bookmark] |
|13位| [https://github.com/yuuki/yuuki/blob/master/misc/nginx-status-444.md:title=nginxのステータスコード444 · yuuki/yuuki:bookmark] |
|14位| [https://github.com/yuuki/yuuki/blob/master/misc/nginx-status-499.md:title=nginxのステータスコード499 · yuuki/yuuki:bookmark] |
|15位| [http://blog.yuuk.io/entry/gokc:title:bookmark] |
|16位| [https://github.com/yuuki/yuuki/blob/master/misc/proxy-config-test.md:title=リバースプロキシのコンフィグテスト:bookmark] |

合計 8000 users+くらい。

### 発表

- [ウェブオペレーションエンジニアになるまでの思い出](https://speakerdeck.com/yuukit/memories-until-i-become-a-web-operations-engineer), [Hatena Engineer Seminar #7](https://hatena.connpass.com/event/45217/), 2016-12-06
- [サーバモニタリング向け時系列データベースの探究](https://speakerdeck.com/yuukit/the-study-of-time-series-database-for-server-monitoring), [第９回インターネットと運用技術シンポジウム(IOTS2016)](http://www.iot.ipsj.or.jp/iots/2016), 2016-12-01
- [Mackerelにおける時系列データベースの性能改善](https://speakerdeck.com/yuukit/performance-improvement-of-tsdb-in-mackerel), [ペパボ・はてな技術大会〜インフラ技術基盤〜 at 福岡](http://pepabo.connpass.com/event/33522/), 2016-07-09
- [はてなにおけるLinuxネットワークスタックパフォーマンス改善](https://speakerdeck.com/yuukit/linux-network-performance-improvement-at-hatena), [はてな・ペパボ技術大会〜インフラ技術基盤〜 at 京都](http://hatena.connpass.com/event/33521/), 2016-07-02
- [ウェブサービスのCentOS5撤退](https://speakerdeck.com/yuukit/centos5-retiring-for-web-servicies), [Hosting Casual Talks #3](http://connpass.com/event/29857/), 2016-06-25
- [Droot Internals](https://speakerdeck.com/yuukit/droot-internals), [第9回コンテナ型仮想化の情報交換会＠福岡](http://ct-study.connpass.com/event/23455/), 2016-04-23
- ウェブアプリケーション開発に新言語を採用したときにインフラで考えたこと, [第3回関西ITインフラ系勉強会](http://kansai-itinfra.connpass.com/event/26165/), 2016-02-27
- [Writing Tools in Go For Ops Engineers](https://speakerdeck.com/yuukit/writing-tools-in-go-for-ops-engineers), [Go 1.6 Release Party](http://gocon.connpass.com/event/26572/), 2016-02-17

合計8件。

### OSS

[f:id:y_uuki:20161231215324p:plain]

Graphiteへのパフォーマンス改善PR。

[https://github.com/graphite-project/carbon/pull/535:embed]
[https://github.com/graphite-project/whisper/pull/162:embed]

[https://github.com/yuuki/gokc:embed]

[https://github.com/yuuki/capze:embed]

go-sql-driver/mysqlのMySQL 4.0対応をして、MySQLプロトコルの知見を深めたりした。
https://github.com/yuuki/go-sql-driver-mysql

他には、ISUCON6予選の出題側としてGo実装とインフラまわりの手伝いをやったりした。

[まつもとりーさんの振り返り](http://hb.matsumoto-r.jp/entry/2016/12/26/121135) にも書いていただいているように、今年はペパボさんのエンジニアの方々と交流させていただくことが多く、大変刺激になりました。
はてなの技術力が非常に高いと称していただいていますが、僕としてはどちらかというと我々はまだまだだなあと思っていて、ペパボさんの取り組みは、前へ進む勢いを感じさせられるというか、一本筋が通ってみえるというかそんな気がしています。
我々はまだ場当たり的に問題を解決していってて、このままではいけないと思い、はてなシステムについて考えてたりしている。

[http://hatenacorp.jp/recruit/operation_engineer:embed]

## あとがき

他のエンジニアの方々の振り返りを眺めていて、たぶん自分より若い人の台頭がすごいなあと感心している。

- [http://haya14busa.com/2016-is-go-year/:title:bookmark]
- [http://k0kubun.hatenablog.com/entry/2016-summary:title:bookmark]
- [http://keens.github.io/blog/2016/12/31/2016nenchuumokushiteikitakattagijutsunofurikaeritokojintekifurikaeri/:title:bookmark]

悔しいので、負けないようにがんばろう。

今年もお世話になりました。来年もよろしくお願いします。

