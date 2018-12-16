---
Title: インフラエンジニア向けシステム系論文
Category:
- 論文
Date: 2014-12-23T23:30:00+09:00
URL: https://blog.yuuk.io/entry/system-papers
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/8454420450077708710
---

この記事は[はてなエンジニアアドベントカレンダー2014](http://developer.hatenastaff.com/entry/2014/12/01/164046)の23日目と[システム系論文紹介 Advent Calendar 2014](http://www.adventar.org/calendars/440)の23日目を兼ねています。

今回は、インフラエンジニア向けにシステム系論文を読むということについて書きます。
ここでいうインフラエンジニアは、Webサービスを作る会社のサーバ・ネットワーク基盤を構築・運用するエンジニアを指しており、はてなではWebオペレーションエンジニアと呼んでいます。
人が足りなくて普通に困っているので採用にご興味のある方はぜひこちらまで。 [http://hatenacorp.jp/recruit/career/operation-engineer:title]

はてなでは、id:tarao:detail さんを中心に有志で論文輪読会を定期的に開催しており、システム系論文にかぎらず、言語処理系、機械学習についての論文などが読まれています。
だいたい１人でインフラまわりの論文を読んでいて、インフラエンジニア向けの論文知見が溜まってきたので、紹介したいと思います。

<!-- more -->

# システム系論文とは

「システム系論文」という呼称は PFI さんで開催されている [https://atnd.org/events/54159:title=システム系論文輪読会] から拝借しました。
「システム系論文」という呼称は正式なものではなくて、なにがシステム系なのかを一言で表現するのは難しいですが、コンピュータシステムそのものについて論じていればシステム系なのかなと勝手に思っています。
具体的には、計算機アーキテクチャ、オペレーティングシステム、分散システム、ストレージなどトピックは多岐に渡ります。
このあたりの特に実践的な分野はあまり論文中に数式がでてこないので、普段からある程度の規模のシステムを運用されてる方なら比較的論文を読むための素養みたいなものが身についているような気がします。(分散システムのアルゴリズムなんかはタネンバウム本とかを読んで基礎知識を固めておかないと読むのは難しいという勝手なイメージ。http://home.att.ne.jp/sigma/satoh/diary/diary100331.html#20100102 )

# 論文を読むメリット

書籍として出版されていないが、内容が深いかつ新しい技術知見を得たいときに、論文を読むのがよいと思っています。

とりあえず、適当な国際会議の論文タイトルと抄録を見てみましょう。例えば、ストレージまわりに興味があれば、FASTのセッション一覧（ https://www.usenix.org/conference/fast13/technical-sessions ）から興味がありそうな論文を見つけられれば、それでもう読む価値があるといえると思います。
僕の場合は、[https://www.usenix.org/conference/fast13/technical-sessions/presentation/lu:title] や [https://www.usenix.org/conference/fast13/technical-sessions/presentation/ma:title] などが気になりました。

論文、当然英語で書かれていて、とにかくとっかかりにくい印象がありますが、短く内容がまとまっていて短期間で読みきれるのがよいと思っています。
分厚い英語の技術書を買って、読みきれなくて失敗するということは結構あると思いますが、情報系の国際会議の論文なら2カラム構成だけど、数ページから10数ページぐらいでなんとか読めます。
あとは、少なくとも情報系の場合、無料で公開されている論文も多いので、金銭的なデメリットがないというのもあります。

>http://d.hatena.ne.jp/mamoruk/20100604/p1
情報系は他の分野と異なり少々特殊で、英語論文といっても国際会議に投稿された論文と、ジャーナルとか論文誌とかいう雑誌に投稿された論文とあり、基本的には後者のほうがランクのクオリティも高く、分量も多いのだが、国際会議の論文もジャーナルの論文と同じくらい重視される点が違う(ほとんどの分野では国際会議の論文は全く評価されない。逆に海外に遊びに行っていると思われてマイナス評価になることさえあるそうで)。かといって、じゃあジャーナルを読んだ方がいいのかというと、国際会議の論文のほうがページ数も決まっていて短いし、基本的なアイデアは国際会議の論文に書かれているので、自分は最初のうちは国際会議の論文を大量に次から次に読み、俯瞰的にテーマを見渡す力をつけたほうがいいんじゃないか、と思う。

# 過去に読んだ論文

自分のブログに書いているもの限定ですが、過去に自分が読んだ論文を紹介します。
トピックに一貫性がないですが、研究と違って仕事だと幅広いトピックを扱うので、そのときどきに興味があるやつを読んでたりします。

- [http://yuuki.hatenablog.com/entry/2013/04/17/171230:title:bookmark]
  - SSLShader: Cheap SSL acceleration with commodity processors, NSDI'11
- [http://yuuki.hatenablog.com/entry/2013/05/15/153824:title:bookmark]
  - Building a single-box 100 Gbps software router" LANMAN'10 
- [http://yuuki.hatenablog.com/entry/2013/08/03/162715:title:bookmark]
  - netmap: a novel framework for fast packet I/O, USENIX Security'12
- [http://yuuki.hatenablog.com/entry/dsync-paper:title:bookmark]
  - dsync: Efficient Block-wise Synchronization of Multi-Gigabyte Binary Data, LISA'13
- [http://yuuki.hatenablog.com/entry/facebook-memcached-paper:title:bookmark]
  - Scaling Memcache at Facebook, NSDI'13
- [http://yuuki.hatenablog.com/entry/docker-performance:title:bookmark]
  - An Updated Performance Comparison of Virtual Machines and Linux Containers

# 論文の探し方

論文を読もうとしても、そもそもどうやって探すのかという問題があります。
僕の場合、ランクが高いと言われているジャーナル/国際会議のうち、年度が新しいものから順に眺めていって、興味がありそうなやつをリストアップしてメモしておいて、読む気になったら読むことにしています。あとはブログをあさってると、まれに何かの論文に行き着くことがあったりするので、そういうのもストックしておきます。

興味のあるキーワードや著者がはっきりしている場合は、[Microsoft Academic Search](http://academic.research.microsoft.com/) や [Google Scholar](http://scholar.google.co.jp/) で検索するとよいと思います。

- [http://d.hatena.ne.jp/kumagi/20110918:title:bookmark]
- [http://diary.overlasting.net/2011-09-18-1.html:title:bookmark]

ジャーナル/国際会議と言っても、どこがよいかとか最初はわからなくて調べたので、ランクが高いと言われているシステム系の国際会議を列挙します。
各国際会議の Best Paper Award を受賞した論文などはさすがにどれも興味深そうです。
多分、このブログを普段読んでいただいている方には LISA あたりが一番ピンとくる論文が多いのではないかと思います。


- SOSP: http://sosp.org/
  - The ACM Symposium on Operating Systems Principles
  - OS系
- OSDI: https://www.usenix.org/conference/osdi14
  - USENIX Symposium on Operating Systems Design and Implementation
  - OS系
- SIGMOD: http://www.sigmod.org/
  - SPECIAL INTEREST GROUP ON MANAGEMENT OF DATA
  - データベース系
- VLDB: http://www.vldb.org/2014/
  - Very Large Data Bases
  - データベース系 
- SIGCOMM: http://www.sigcomm.org/
  - The ACM Special Interest Group on Data Communication
  - ネットワーク系
- NSDI: https://www.usenix.org/conference/nsdi14
  - USENIX Symposium on Networked Systems Design and Implementation
  - ネットワーク系
- HPCA: http://hpca20.ece.ufl.edu/
  - IEEE Symposium on High Performance Computer Architecture
  - ハイパフォーマンスコンピューティング系 並列計算とか
- LISA: https://www.usenix.org/conference/lisa14
  - USENIX Large Installation System Administration
  - DevOps系
- ICAC: https://www.usenix.org/conference/icac14
  - USENIX International Conference on Autonomic Computing
  - 自律システム系
- FAST: https://www.usenix.org/conference/fast14
  - USENIX Conference on File and Storage Technologie
  - ストレージ系
- EuroSYS: http://eurosys2014.vu.nl/
  - OS、ストレージ、ネットワークと幅広い

情報系国際会議の Best paper賞を受賞した論文まとめページもあるので、ここから探してもよいと思います。

[http://jeffhuang.com/best_paper_awards.html:title:bookmark]

あとは、Google, Facebook, Twitterなどの各社が論文を投稿してるので、これもみてみるとよさそうです。

- [http://research.google.com/pubs/papers.html:title:bookmark]
- [http://research.microsoft.com/en-us/about/our-research/default.aspx:title:bookmark]
- [https://engineering.twitter.com/research:title:bookmark]
- [https://research.facebook.com/publications:title:bookmark]
- [http://labs.yahoo.com/publication/:title:bookmark]

そのほかについては、[http://d.hatena.ne.jp/ny23/20110713/p1:title:bookmark] が参考になります。

# 論文の読み方

USENIX系のカンファレンスだと、プレゼン時のスライドが公開されていたりするので、それをみてイメージをつかむとよさそうです。

論文の文章構成はだいたい決まっていて、Abstraction、Introduction、Proposed Methods, Experiments, Discussion, Conclusion の順になっています。
ありきたりですが、最初に、Abstraction 、Introduction、Conclusion を読んで概要を掴んでから、Proposed Methods, Experiments, Discussion を読むようにしています。

漫然と読んでも内容が頭に入らないので、各段落の要約みたいなものを英語と日本語ごちゃまぜでいいからエディタに書いています。単語の訳とか考えてたら日が暮れるので、英語のままシュッとコピペします。論文はだいたいPDFで手に入るので、コピペが簡単ですね。
油断すると、1文1文を作業的に訳しかねないので、段落あたりの内容をコンパクトにまとめることを意識しています。段落あたりでもかなり粒度が細かいですが、日本語ではないという点と技術的な内容という点で、あたまに入りづらいので、これくらいの粒度が妥当かなと思っています。

発表前提でスライドを作る場合も、いきなり原文を読みながらスライドを作らずに、まずメモを書きながら一通り読んでしまってから、軽く構成を考えて重要ポイントだけスライドにしたりします。

最後に重要な点として、先にこの論文を読んで何を理解したいのかを言語化しておくと、常に問いを意識できるので、読まなくてもよい部分を無視して読み進めることができます。逆に言語化できないような論文を読むと、なんとなく読んだ気分に陥りがちな気がしています。
以前に、`An Updated Performance Comparison of Virtual Machines and Linux Containers` という論文を読んだ時は、`Docker は速いのか？Dockerのパフォーマンスにとって重要なことはなにか？` という問いを意識して読みました (これはそのままブログのタイトルにしました）。

id:shiba_yu36:detail さんがこれに近い内容の記事を書いていますのでご参考までに。 [http://blog.shibayu36.org/entry/2014/12/07/201220:title:bookmark]

# 論文読みの続け方

僕の場合、承認欲求が満たされないと続かないので、読んだ論文についてブログに書いて、はてなブックマークで承認を得られるような形でアウトプットすることを一応目標にしています。
ブログに書くときのポイントとして、論文の内容そのものをまとめる必要はなくて、なるべく自分の立場や経験や興味を踏まえて、ある程度噛み砕いた内容にして自分の考察を書くとより読まれやすいように感じています。
どうでもいい小手先のテクニックとして、論文タイトルをそのまま記事のタイトルにするのではなく、キャッチーな単語を抜いてきて、普通のブログのタイトルっぽくするのがよいと思います。論文のタイトルそのままで当然英語なのでなかなかリンクを踏まれない気がします。

あとは、社内で輪読会とかやってないと絶対読んでないので、輪読会に参加/開催などするとよいと思います。

# 読んでおきたいシステム系論文

とりあえず、最近気になってるおもしろ論文を列挙します。
絶対読みきれないので、助けてください。

- [`Multi-Core, Main-Memory Joins: Sort vs. Hash Revisited`](http://www.vldb.org/pvldb/vol7/p85-balkesen.pdf)
  - VLDB'14
- [`Arrakis: The Operating System is the Control Plane`](https://www.usenix.org/conference/osdi14/technical-sessions/presentation/peter)
  - OSDI'14
  - Awarded Best Paper
  - デバイスアクセスまわりを最適化した新しいOSのデザインの話
- [`f4: Facebook's Warm BLOB Storage System`](https://www.usenix.org/conference/osdi14/technical-sessions/presentation/muralidhar)
  - OSDI'14
- [`mTCP: a Highly Scalable User-level TCP Stack for Multicore Systems`](https://www.usenix.org/conference/nsdi14/technical-sessions/presentation/jeong)
  - NSDI'14
  - Community Award
- [`In Search of an Understandable Consensus Algorithm`](https://www.usenix.org/conference/atc14/technical-sessions/presentation/ongaro)
  - LISA'14
  - Awarded Best Paper
  - Raft アルゴリズムについて (Consul で使われている http://www.consul.io/docs/internals/consensus.html )
- [`Adaptive, Model-driven Autoscaling for Cloud Applications`](https://www.usenix.org/conference/icac14/technical-sessions/presentation/gandhi)
  - ICAC'14
- [`Wear Unleveling: Improving NAND Flash Lifetime by Balancing Page Endurance`](https://www.usenix.org/conference/fast14/technical-sessions/presentation/jimenez)
  - FAST'14
- [`The Scalable Commutativity Rule: Designing Scalable Software for Multicore Processors`](https://www.usenix.org/conference/atc14/technical-sessions/presentation/scalable-commutativity-rule-designing-scalable)
  - SOSP'13
  - Best Paper
- [`Embassies: Radically Refactoring the Web`](https://www.usenix.org/conference/nsdi13/technical-sessions/presentation/howell)
  - NSDI'13
  - Awarded Best Paper
  - MSの人がだしてる。タイトルからしてやばい。
- [`AUTOPLACER: Scalable Self-Tuning Data Placement in Distributed Key-value Stores`](https://www.usenix.org/conference/icac13/technical-sessions/presentation/paiva)
  - ICAC'13
  - Best Paper Award Finalist 
  - KVSの自動シャーディング
- [`I/O Stack Optimization for Smartphones`](https://www.usenix.org/conference/atc13/technical-sessions/presentation/jeong)
  - USENIX ATC'13
  - Awarded Best Paper
- [`Live Upgrading Thousands of Servers from an Ancient Red Hat Distribution to 10 Year Newer Debian Based One`](https://www.usenix.org/conference/lisa13/technical-sessions/presentation/merlin)
  - LISA'13
  - Google の人がだしてる。すさまじい。
- [`A Study of Linux File System Evolution`](https://www.usenix.org/conference/fast13/technical-sessions/presentation/lu)
  - FAST'13
  - Awarded Best Paper
- [`Understanding the Robustness of SSDs under Power Fault`](https://www.usenix.org/conference/fast13/technical-sessions/presentation/zheng)
  - FAST'13
  - SSD を読み書きしながら電源断する話
- [`Spanner: Google’s Globally-Distributed Database`](https://www.usenix.org/conference/osdi12/technical-sessions/presentation/corbett)
  - OSDI'12
  - Awarded Jay Lepreau Best Paper
- [`How Hard Can It Be? Designing and Implementing a Deployable Multipath TCP`](https://www.usenix.org/conference/nsdi12/technical-sessions/presentation/raiciu)
  - NSDI'12
  - [MultiPath TCP](http://multipath-tcp.org/pmwiki.php) の話
- [`NSDMiner: Automated discovery of Network Service Dependencies`](http://ieeexplore.ieee.org/xpl/articleDetails.jsp?tp=&arnumber=6195642)
  - INFOCOM'12
  - サービス間の依存関係の自動ディスカバリ。はてなみたいに多数のサービス抱えてるとこういうのが重要。Python の実装がある。http://sourceforge.net/projects/nsdminer/
- [`Proportional Rate Reduction for TCP`](http://research.google.com/pubs/pub37486.html)
  - SIGCOMM'11
  - Google の人がだしてる。TCPでのパケットロス時の素早いスループット回復について。
- [`DFS: A File System for Virtualized Flash Storage`](https://www.usenix.org/conference/fast-10/dfs-file-system-virtualized-flash-storage)
  - FAST'10
  - FusionIO の ioDrive みたいな NAND フラッシュデバイス用に最適化したファイルシステム
- [`High performance network virtualization with SR-IOV`](http://ieeexplore.ieee.org/xpl/articleDetails.jsp?tp=&arnumber=5416637&url=http%3A%2F%2Fieeexplore.ieee.org%2Fxpls%2Fabs_all.jsp%3Farnumber%3D5416637)
  - HPCA'10

- `Linux Performance Analysis: New Tools and Old Secrets`
  - LISA'14
  - https://www.usenix.org/conference/lisa14/conference-program/presentation/gregg
  - Netflixの人。論文ではなくトークだけど、気になる


# まとめ

インフラエンジニア向けに、読むと知見が得られるような論文の探し方やおすすめの論文などを紹介しました。
論文、最新技術の知見の宝庫なので、一度漁ってみてはいかがでしょうか。
また、識者の皆様に、よりよいシステム系論文についての知見などありましたら教えていただけると嬉しく思います。

最終日の担当は id:stanaka さんです。よろしくお願いします！
