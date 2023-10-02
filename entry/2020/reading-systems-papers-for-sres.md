---
Title: SRE向けシステム系論文
Category:
- Research
- SRE
Draft: true
CustomPath: 2020/reading-systems-papers-for-sres
---

この記事は、システム系論文とはなにか、論文に期待することはなにか、論文をどうやって探すのか、論文をどうやって読むのか、を研究者目線ではなく、ソフトウェアエンジニア、特にSRE（Site Reliability Engineer）目線で紹介する。

[:contents]

---

## はじめに

「論文ってどうやって探しているんですか？」

ここ1,2年で、ソフトウェアエンジニアの方から何度か聞かれた質問だ。
そのときは、6年前に書いた[「インフラエンジニア向けシステム系論文」](https://blog.yuuk.io/entry/system-papers)を紹介してきた。
当時、筆者はまだエンジニアだったが、2年前にさくらインターネットに転職して以来、研究者として論文を読み書きする時間が圧倒的に増えた。
今、この記事を読み返すと、古くなっていて、書き直したくなってきたので、2020年版を書くことにした。

[https://blog.yuuk.io/entry/system-papers:embed]

この数年間の変化を振り返ると、6年前は、まだクラウドやウェブのインフラ領域のエンジニアが論文を読む光景をそれほど見かけなかった。
当時のはてな社内では、情報科学系の博士が3名ほどいらした((今思えばエンジニア3,40人に対して博士が3人もいるのはすごいことだ。現在所属しているさくらインターネット研究所でも博士は3人しかいない))ので、論文輪読会が開催されていて、僕は、たまたまそれに参加していたので、少し論文を読んでいた。
今では、当たり前とはいわないまでも、論文を読まれている姿を頻繁にみかけようになった。

実際に、次に列挙するように、ソフトウェアエンジニアの方々が様々なシステム系論文を読んでいる、または、参考文献に挙げている。

- [https://deeeet.com/posts/2020/#paper:title]
- [https://speakerdeck.com/rrreeeyyy/iot40-rrreeeyyy?slide=11:title]
- [https://nhiroki.jp/tag/paper/:title]
- [https://tombo2.hatenablog.com/archive/category/Research%20Paper:title]
- [https://keens.github.io/categories/%E8%AB%96%E6%96%87%E3%83%A1%E3%83%A2/:title]
- [https://ccvanishing.hateblo.jp/search?q=%E8%AB%96%E6%96%87:title]
- [https://deeeet.com/writing/2015/09/17/qa-omega/:title:bookmark]
- [https://techlife.cookpad.com/entry/timeseries-database-001:title:bookmark]
- [https://blog.inductor.me/entry/2020/08/27/105821:title:bookmark]
- [https://www.wantedly.com/companies/wantedly/post_articles/223522:title:bookmark]
- [https://qiita.com/tzkoba/items/5316c6eac66510233115:title:bookmark]
- [https://qiita.com/nk2/items/d9e9a220190549107282:title:bookmark]
- [https://www.nullpo.io/2019/12/17/container-design-pattern/:title:bookmark]
- [https://kakakakakku.hatenablog.com/entry/2018/09/24/003723:title:bookmark]
- [https://techlife.cookpad.com/entry/timeseries-database-001:title:bookmark]
- [https://www.m3tech.blog/entry/container-based-system-design-pattern:title:bookmark]
- [https://kiririmode.hatenablog.jp/entry/20180630/1530329159:title:bookmark]
- [https://kakakakakku.hatenablog.com/entry/2014/03/06/104814:title:bookmark]

<!-- （網羅的に探索すればもっと記事を発見できるはず。なぜか同一の論文を読んだ記事が5件もある。） -->

著者は、手前味噌だが、[WebSystemArchitecture（WSA）研究会](https://websystemarchitecture.hatenablog.jp/archive)という学会に属していない野良の研究会を主催している。
ここでは、発表者の内訳は半分以上がエンジニアであり、発表のサーベイのために、当たり前に論文を読んでいる方が多い。

エンジニアに広く利用されているプロダクトの貢献が論文として出版されているケースもある。
ここでは、昨年発表された論文を例を挙げよう。
AWS LambdaやAWS Fargateの基盤として利用されているFirecrackerは、[ネットワーク寄りのシステムソフトウェア系トップカンファレンスNSDI'20で発表された](https://www.usenix.org/conference/nsdi20/presentation/agache)。
NewSQLのOSS実装の代表格の一つであるCockroachDBは、[データベース系トップカンファレンス SIGMOD'20で発表されていた]((https://www.cockroachlabs.com/blog/cockroachdb-sigmod-2020/))。
Facebookで開発されたMySQLのRocksDBベースのストレージエンジンMyRocksは、[データベース系トップカンファレンス VLDB'20で発表された](https://tombo2.hatenablog.com/entry/2020/09/06/155018)。
第一著者の松信嘉範さんは、MySQLの高可用性クラスタを構築するMHA for MySQLの開発者としても知られている。

このように、実践性が要求されやすく、学術研究とは縁遠いようにみえるシステム系の分野であっても、学術研究とエンジニアの距離は、近づいているように感じられる。
この距離をより近づけるために、システム系分野の論文の読み方を以降では紹介していく。

## システム系論文とはなにか？

6年前のエントリでは次のように書いている。

> 「システム系論文」という呼称は正式なものではなくて、なにがシステム系なのかを一言で表現するのは難しいですが、コンピュータシステムそのものについて論じていればシステム系なのかなと勝手に思っています。 具体的には、計算機アーキテクチャ、オペレーティングシステム、分散システム、ストレージなどトピックは多岐に渡ります。

付け加えるなら、「システム系」といっても、範囲は広いため、自分の専門分野を中心に隣接分野が展開されるようなメンタルモデルをもつのではないかと思う。

著者の分野がクラウドで、かつ、ソフトウェア層のシステムを扱うため、この記事が対象とする「システム系」は、強いて言えば、「ソフトウェアにより構成されるクラウドを構成するシステム系」となる。
この「システム系」は、USENIX LISAで扱われるテーマ・トピックが近しい。

[f:id:y_uuki:20201224150353p:image]

（<https://www.usenix.org/conference/lisa19/call-for-participation> より引用）

ある程度独立した要素技術をあえて統合して扱っていることには理由がある。
最終的に、システムとして成立させるためには、ネットワーク、データベースなど、複数の要素技術を統合して扱う必要がある。
本記事のタイトルで、「SRE向け」と銘打っているのはそのためである。

<!-- インフラエンジニアという呼称は、あまり見かけなくなった。
クラウドの上で、比較的下位層のシステムを構築・運用するエンジニアを、今ではSRE（Site Reliability Engineer）と呼んだり、プラットフォームエンジニアと呼ぶようになってきた。
最近、著者は、このあたりの区分を知らない人には、ソフトウェアエンジニアとまとめて紹介している。
著者の専門分野はSREであるため、自然とシステム系論文の中でも、SRE、つまり運用技術を意識した論文を読むことが多いため、このような記事タイトルになっている。 -->

## 論文に期待することはなにか？

研究者は、少なくとも学術を志向する場合は、新しい知を既存の知に積み上げていくため、既存の知を知るために論文を読む必要がある。

その一方で、エンジニアが論文を読むことで、何を得られるのだろうか？

実装が公開されていないか、プロトタイプに留まることも多く、読んですぐに実践できることは少ない。
単に知識やテクニックを学ぶだけなら、初歩的なところから解説してくれる書籍のほうが望ましいのではないか。

論文がどんなものであるかを知って、論文に対する期待値を揃える必要がある。

- トップカンファレンス・トップジャーナルの論文であれば、世界の最先端技術と思考が集まっているので、好奇心を満たす
- ソフトウェアの検証結果を知る

論文は、少し外れた分野の人も読むことを想定するので、抽象度の高いところから徐々に具体性をもたせていき、実装の詳細は簡単に記述することもある。
有名プロダクトの論文など、その有用性はすでに広く知られているから、新規性や有用性よりも、実装の細部を知りたい、というケースには論文は不向きなこともある。

論文から得られる学術的知識の価値は、即時の実践ではなく、思考の切り口を提供してくれることにあると考えている。
「事例」よりも抽象度の高い。

## 論文をどうやって探すのか？

### 論文の種類

論文を探す上で、論文の種類をまず覚えておくとよい。
[https://next49.hatenadiary.jp/entry/20101110/p1:title]の記事によると、論文の種類を次のように分類できる。

> 研究の完成度から、原著論文＞会議録掲載論文＞Letter, Communication＞Short paper, Technical report＞Postion Paper という関係

一般に完成度の低い順から投稿し、徐々に完成度を上げていき、最終的には原著論文として採録されると研究が完成となる。
とはいっても、いきなり原著論文を投稿してもよく、何から書き始めるかにルールはない。

原著論文は、学術雑誌に掲載されるため、学術雑誌の種類に応じて、ジャーナル論文、論文誌論文と呼ぶこともある。

情報系では、会議録掲載論文のうち、査読つきの国際会議の掲載論文が他分野と比べて重視されており、原著論文をあえて書かないこともある。
いわゆるトップカンファレンスと呼ばれる会議の会議録に掲載される論文は、会議録掲載論文になる。

オープンアクセスの論文アーカイブであるarXivもある。
ジャーナルや国際会議で、査読を受ける前に、成果を速報するために、投稿することがある。
特に機械学習分野ではよく利用されている。

同じ研究内容でも、複数の異なる種類の媒体に掲載されることがあるので、論文を探すときは、基本的に完成度の高い形式の論文を選ぶとよい。
単純に発行年が新しいものを選ぶだけでよいはず。
原著論文は、掲載媒体名に"Journal"や"Transaction"を含むことが多く、国際会議名は"Conference"を含むことが多いので、目安にするとよい。

あとは、大学・大学院で学位を取得するための学位論文がある。
学位に応じて、卒業論文、修士論文、博士論文があり、学究の達成を評価するための論文なので、前述の種類の論文よりも、前提知識が丁寧に記述されていることがある。
<!-- 博士論文を列挙する -->

### サーベイ論文

媒体以外の分類として、手法やシステムを提案する論文以外に、サーベイ論文がある。
サーベイ論文はレビュー論文とも呼ばれ、以前に他者によって公表された研究結果をまとめ、分析や考察をする論文である。

専門以外の分野の論文を読むときには、まず、サーベイ論文を読んで全体像を掴むと良い。
例えば、著者の場合は、エッジコンピューティングという当時未知だった分野を知るために、まずサーベイ論文を読んだ。[https://memo.yuuk.io/entry/2019/learning-edge-computing01:tilte]
サービス論文は、論文タイトルに"Survey"を含むことが多いため、検索で発見しやすい。

サーベイ論文ではないが、多数の研究論文をもとに、特定の分野の技術を体系的に概説する書籍もある。
例えば、書籍「データ指向アプリケーションデザイン」はデータベース分野の非常に優れた導き手となる。

### Morning Paper

<https://blog.acolyer.org/>

Morning Paperを眺めているだけで、十分に思う。

### トップカンファレンスとトップジャーナル

| 分野          |  カンファレンス名（略称）                                  | CORE rank |  備考  |
|:-------------|:-------------------------------------------------------|:-----------:|:------|
| システム系全般  | [USENIX ATC](https://www.usenix.org/conference/atc20) |  A        | USENIXが取り扱う |
|               | [EuroSys](https://www.eurosys2020.org/)               |           | [2020ではGoogleからBorgのトレース情報のデータセット](https://ai.googleblog.com/2020/04/yet-more-google-compute-cluster-trace.html)
| クラウド     | IEEE CLOUD                                             | B        | [https://blog.yuuk.io/entry/2020/ieeecloud2020:title] |
|               | ACM SoCC                                                |          |           |


クラウド系

- ACM SoCC
- IEEE CLOUD (A)

ウェブサービス系

- WEBConf （旧略名 WWW）
- IEEE ICWS

ネットワーク系

- SIGCOMM
- USENIX NSDI

データベース

- ACM SIGMOD
- VLDB
- USENIX FAST

OSとプログラミング言語処理

- ASPLOS

その他、セキュリティや


### 国内の研究会

- 情報処理学会 インターネットと運用技術研究会（IOT研究会）
- 情報処理学会 オペレーティングシステムとシステムソフトウェア（OS研究会）
- 情報処理学会 データベースシステム研究会
- 日本データベース学会

### 論文の検索

論文を検索するツールとして、筆者は[Google Scholar](http://scholar.google.com/)を利用している。
機能はそれほど多くはないが、とにかく高速に動作するので、昔から愛用している。

とはいえ、いきなり上手に検索するのは難しい。
"database"や"network"だと、あまりに検索結果が多すぎて、そこから興味のあるものを抽出するのは大変だ。

例えば、ここ数年だと、マイクロサービスの論文が非常に多数出版されているので、
"Microservices 〇〇"

あるいはよく使っているツール名で検索するのも一つの手だ。

普段ならGoogleで検索する語句を、Google Scholarに入力してみると、意外な論文を発見できることもある。

### 探した論文の管理

論文はたくさんあるので、発見した論文をあとで思い出して、たどり着くことは難しい。
昔発見した論文にたどり着けるように、発見した論文を管理しておきたい。
筆者は、文献管理サービスの[Paperpile](http://paperpile.com/)を使って、論文のPDFと書誌情報を管理している。

[https://ocoshite.me/how-to-use-paperpile:title]

## 論文をどうやって読むのか？

[https://nhiroki.jp/2020/03/02/how-to-read-more-papers:title]

## 論文は書けるものなのか？

[https://twitter.com/ki1tos/status/1337325057966702593:embed]

論文を読むにも技術が必要だ。
論文の読み方を学ぶには、やはり自分で書くのが一番である。

とはいえ、ハードルは高い。
ソフトウェアエンジニアとしての仕事をこなしながら、休日に執筆することになる。
文章を書くこと自体に慣れていても、
上手にレビューしてもらう人も必要となる。

エンジニア時代に、論文の執筆に関する記事を書いていた。
[https://blog.yuuk.io/entry/2018/writing-the-tsdb-paper:title]

もし論文を書くことに興味があって、レビュワーに心当たりがなければ、お手伝いさせていただきたいと考えている。
論文に書くネタを醸成するために、ひとまず、前述したWSA研で発表いただくことをおすすめする。

## 参考

- [https://mmi.hatenablog.com/entry/2020/12/01/034833:title]
- [https://gist.github.com/ozaki-r/9b28005eb877ae35f5507976f190983e]
- http://muratbuffalo.blogspot.com/2021/02/read-papers-not-too-much-mostly.html
- http://muratbuffalo.blogspot.com/search/label/paper-review
- https://micchie.net/files/RG-HowToPaper.pdf

## まとめ
