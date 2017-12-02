---
Title: ウェブシステムの運用自律化に向けた構想 - 第3回ウェブサイエンス研究会
Category:
- Monitoring
- Concept
- Experimentable
Date: 2017-12-02T23:55:00+09:00
URL: http://blog.yuuk.io/entry/2017/the-concept-of-autonomous-web-system
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/8599973812323144142
CustomPath: 2017/the-concept-of-autonomous-web-system
---

[はてなエンジニア Advent Calendar 2017](https://qiita.com/advent-calendar/2017/hatena)の2日目です。
昨日は、id:syou6162:detail さんによる[http://www.yasuhisay.info/entry/saba_disambiguator:title:bookmark]でした。

この記事は、[人工知能学会 合同研究会2017 第3回ウェブサイエンス研究会](http://sigwebsci.tumblr.com/post/166061452488/%E7%AC%AC3%E5%9B%9E%E3%82%A6%E3%82%A7%E3%83%96%E3%82%B5%E3%82%A4%E3%82%A8%E3%83%B3%E3%82%B9%E7%A0%94%E7%A9%B6%E4%BC%9A%E3%81%94%E6%A1%88%E5%86%85)の招待講演の内容を加筆修正したものです。
講演のテーマは、「自然現象としてのウェブ」ということでそれに合わせて、「自然のごとく複雑化したウェブシステムの運用自律化に向けて」というタイトルで講演しました。
一応、他の情報科学の分野の研究者や技術者に向けて書いているつもりですが、その意図がうまく反映されているかはわかりません。

[:contents]

# 概要

ウェブシステムの運用とは、信頼性を制約条件として、費用を最小にする最適化問題であると考えています。
費用を最小にするには、システム管理者の手を離れ、システムが自律的に動作し続けることが理想です。
クラウドやコンテナ技術の台頭により、ウェブシステム運用技術の自動化が進んでおり、自律化について考える時期になってきたと感じています。
自律化のために、観測と実験による「Experimentable Infrastructure」という構想を練っています。
Experimentable Infrastructureでは、監視を超えた観測器の発達、実験による制御理論の安全な導入を目指しています。

# 1. ウェブシステムの信頼性を守る仕事

ここでのウェブシステムとは、ウェブサービスを構成する要素と要素のつながりを指しており、技術要素とは「ブラウザ」「インターネットバックボーン」「ウェブサーバ」「データベース」「データセンター内ネットワーク」などのことを指します。
特に、データセンター内のサーバ・ネットワークおよびその上で動作するウェブアプリケーションを指すことがほとんどです。
総体としてのウェブというよりは、単一組織内の技術階層としてのシステムに焦点をあてています。

ウェブシステムの最も基本的な機能として、「信頼性」があります。
信頼性を守る役割は「Site Reliability Engineer(SRE)」が担います。
SREはウェブ技術者界隈で市民権を得ている概念であり、Googleのエンジニアたちによって書かれた書籍「Site Reliability Engineering」[Bet17]に詳細が記されています。

信頼性にはいくらかの定義のしようがあります。
[Bet17]では[Oco12]の定義である「システムが求められる機能を、定められた条件の下で、定められた期間にわたり、障害を起こすことなく実行する確率」を採用しています。
信頼性というとつい100%を目指したくなりますが、信頼性と費用はトレードオフなため、信頼性を最大化するということはあえてしません。

さらに、信頼性をたんに担保することが仕事なのではなく、費用を最小化することが求められます。
この記事では、`費用=コンピューティングリソース費用 + 人件費用 + 機会費用` ((発表時には機会費用を含めていませんでしたが、機会費用を大幅に増加させて前者2つを削減できるため、この記事では含めました))としています。
SREは費用をエンジニアリングにより削減できます。例えば、前者は、ソフトウェアの実行効率化などにより達成され、後者はソフトウェア自動化などにより達成されます。
以上より、SREの仕事のメンタルモデルは、「目標設定された信頼性((厳密にはService Level Objective(SLO)))を制約条件として、費用を最小にする最適化問題」((信頼性と費用はトレードオフであり、信頼性を定期的に見直す必要があります。高すぎる信頼性のために想定より費用が最小化できないとなれば、例えば四半期ごとに信頼性目標を下げるといった運用が必要です)) (([Bet17]では、「サービスのSLOを下回ることなく、変更の速度の最大化を追求する」という表現になっています。今回は、自分自身のメンタルモデルに近い、費用の最小化という表現を選択しました。))を解くことであると言い換えられると考えます。
特にSREでは、定型作業(トイルと呼ばれる)を自動化し、スケールさせづらい人間ではなくコンピュータをスケールさせることが重要な仕事となります。

一般の人々からみれば、ウェブシステムは、十分自律動作していると言えます。
内部的に障害が発生したとしても、人々は何もせずとも、障害から回復し普段通りサービスを利用できます。
ただし、その裏では、信頼性を担保するために、数多くの人間の手作業や判断が要求されているのが現実です。
人間がなにもしなければ、およそ1週間程度((これはサービスによって大きく異なります。
これまで運用してきたサービスの肌感覚では、1週間程度。運が良くて1ヶ月程度。))で信頼性は損なわれることもあります。

我々のゴールは、最終的にコンピュータのみでシステムを運用可能な状態にすることです。
IOTS2016の開催趣旨が、このゴールを端的に言い表しています。

>
インターネット上では多種多様なサービスが提供されている。このサービスを提供し続け、ユーザに届けることを運用と呼ぶ。サービスが複雑・多様化すれば運用コストは肥大する。このコストを運用担当者の人的犠牲により「なんとか」してしまうことが「運用でカバーする」と揶揄される。日本では大規模構造物を建造する際に、破壊されないことを祈願して人身御供 (人柱) を捧げる伝統があるが、現在のインターネットの一部はこのような運用担当者の人柱の上に成立する前時代的で野蛮な構造物と言うことができる。
>
運用担当者を人柱となることから救う方法の一つが運用自動化である。運用の制御構造における閾値を明らかにすることにより、人は機械にその仕事を委託することができる。機械学習や深層学習により、この閾値を明らかにすることをも機械に委託することが可能となることも期待される。不快な卑しい仕事をやる必要がなくなるのは、人間にとってひじょうな福祉かもしれないが、あるいはそうでないかもしれない。しかし機械に仕事を委託することにより空いた時間を人間が他のことに使うことができるのは事実である。
>
本シンポジウムは、インターネットやネットワークのサービスの運用の定量的な評価を通じて、積極的に制御構造を計算機に委託することで人間の生産性を向上させ社会全体の収穫加速に結びつけることを目的とする。
>
IOTS2016 開催の趣旨より引用 http://www.iot.ipsj.or.jp/iots/2016/announcement

# 2. ウェブシステム運用の現状

## 国内のウェブシステムの運用技術の変遷

2010年以前は自作サーバ時代[[rx709]](http://d.hatena.ne.jp/rx7/20091125/p1)でした。
秋葉原でパーツを購買し、組み立てたサーバをラックに手作業で配置していました。
自作だと壊れやすいこともあり、冗長化機構やスケールアウト機構など信頼性を高める基礎機能が浸透しました。[[ito08]](https://gihyo.jp/magazine/wdpress/plus/978-4-7741-3566-3)
のちにベンダー製サーバやクラウドへ移行が進みます。
このころから、XenやKVMなどのハイパーバイザ型のサーバ仮想化技術の台頭により、徐々にサーバをモノからデータとして扱う流れができはじめます。

## クラウド時代

2011年にAWS東京リージョンが開設され[[awshis]](https://aws.amazon.com/jp/aws_history/details/)、有名ウェブ企業が移行しはじめます[[coo15]](https://aws.amazon.com/jp/solutions/case-studies/cookpad/)。
クラウドの利用により、必要なときにすぐにハードウェアリソースが手に入り、従来の日または月単位のリードタイムが一気に分単位になりました。
さらに、単にハードウェアリソースが手に入るだけでなく、クラウドのAPIを用いて、サーバやデータベースをプログラムから作成することが可能になりました。
これを利用し、負荷に応じて自動でサーバを増やすなどの動的なインフラストラクチャを構築できるようになってきました。

## コンテナ型仮想化技術

2013年のDocker[[doc13]](https://blog.docker.com/2013/03/opening-docker/)の登場により、ソフトウェアの動作環境を丸ごとパッケージ化し、さまざまな環境に配布できるようになりました。
コンテナ型仮想化技術そのものは古くから存在しますが、Dockerはコンテナの新しい使い方を提示しました。
コンテナ環境は、ハイパーバイザ環境と比べてより高速に起動する((実質OSのプロセスの起動))ため、より動的なインフラストラクチャの構築が可能になりました。

この頃より、Immutable Infrastructure[[imm13]](http://chadfowler.com/2013/06/23/immutable-deployments.html)[[miz13]](http://mizzy.org/blog/2013/10/29/1/)[[mir13]](http://blog.mirakui.com/entry/2013/11/26/231658)[[sta13]](http://blog.stanaka.org/entry/2013/12/01/092642)またはDisposable Infrastructureの概念が登場し、サーバを使い捨てるという発想がでてきました。

## サーバレスアーキテクチャ

2015年ごろから、サーバレスアーキテクチャ[[mar16]](https://martinfowler.com/articles/serverless.html) [[nek16]](http://d.nekoruri.jp/entry/20161222/serverless2016)という概念が登場しました。
これは本当にサーバがないわけではなく、サーバの存在を意識しなくてよいような状態へもっていくためのアーキテクチャと技術選択を指します。

サーバレスアーキテクチャでは、具体的なサーバやコンテナの存在を意識することなく、抽象化された複数のサービスを組み合わせて、ビジネスロジックを実装するようになります。
ここでのサービスは、フルマネージドサービスと呼ばれることが多く、データベースサービス(Amazon DynamoDB、Google BigQueryなど)、CDNサービス(Akamai、Amazon Cloudfrontなど)、Functionサービス(AWS Lambda、Google Function)などを指します。
理想的なフルマネージドサービスは、裏側にあるサーバの個数や性能ではなく、APIの呼び出し回数や実行時間、データ転送量といったよりアプリケーションに近い単位でスケーリングし、課金されます。
ウェブサービス事業者がこれらの抽象層を実装するというよりは、クラウドベンダーがサービスとして提供しているものを利用することがほとんどです。

## Site Reliability Engineering(SRE)の登場

2015年から日本のウェブ業界にSREの概念が浸透し始めました[[mer15]](http://tech.mercari.com/entry/2015/11/18/153421)。
SREにより、ウェブシステムの「信頼性」を担保するエンジニアリングという、何をする技術やエンジニアなのかがはっきり定義されました。
それまでは、システム管理者、インフラエンジニアや下回りといったざっくりした用語で何をする技術で何をする人なのかが曖昧な状態であることに気付かされました。
トレードオフである信頼性を損なわずに変更の速度の最大化する((前述の信頼性を維持し費用を最小化するという話))上で、ソフトウェアエンジニアリングを特に重視しているのも特徴的です。

SRE自体は技術そのものではなく、SREによりウェブシステムの運用分野に、体系的な組織開発・組織運用の概念が持ち込まれたことが、大きな変化だと考えています。

## 変遷まとめ

昔はハードウェアを調達し、手作業でラッキングしていました。
現在では、サーバの仮想化技術の発達とアプリケーション動作環境パッケージングの概念、さらにサーバレスアーキテクチャの考え方とサービスの浸透により、よりダイナミックで抽象的なインフラストラクチャが構築可能になりました。
このように、インフラストラクチャがソフトウェアとして扱いやすくなり、ソフトウェアエンジニアリングを重視した組織文化の浸透と合わさり、この10年でソフトウェアによる運用自動化が大幅に進んできたと言えます。

しかし、これでめでたしめでたしかというとそういうわけではありません。

# 3. ウェブシステム運用の課題

## 本当は怖いウェブシステム運用

このテーマについては、今年のIPSJ-ONEにて「高度に発達したシステムの異常は神の怒りと見分けがつかない」[[yuu17]](http://blog.yuuk.io/entry/ipsjone2017)で話しました。

ウェブシステムでは、異常が発生しても原因がわからないことがあります。
原因がわからず再現させることも難しい場合、システムの振る舞いがまるで「自然現象」に感じられます。((#wakateinfraの中でも、超常現象などと呼んでいました))
自動化が進んでいるからこそ、不明であることが異常に対する「恐怖」をうみます。
これは、システムに対する変更が安全かどうかを保証することは難しいためです。
その結果、振る舞いの解明に多くの時間をとられたり、わざと自動化を避けて、人間の判断をいれようとします。

実際、異常のパターンは様々です。
講演では、以下の2つの例を話しました。

- ハードウェアのキャパシティにはまだ余裕があるにもかかわらず、1台あたりの処理能力が頭打ちになり、自動スケールするが自動スケールしない別のコンポーネントが詰まるケース
- データベース((ここではMySQLとPostgreSQLを想定))のアクティブ・スタンバイ構成((ここでは、VRRPによるクラスタリングを想定))において、ネットワーク分断により、確率的にどちらかのマスターにデータが書き込まれ、データの一貫性を損失するケース

前者は、自動化していても自動で復旧できず、後者は自動化したがゆえに新たな問題が発生したケースです。
書籍「Infrastructure As Code」[[kie17]](https://www.oreilly.co.jp/books/9784873117966/)では、1.3.5節 オートメーション恐怖症にて、"オートメーションツールがどういう結果を生むかについて自信が持てないため、オートメーションツールに任せきりになるのは怖かった。"と書かれています。

## ウェブシステムの複雑性

ここまできて、なぜウェブシステムは自然現象のように感じられるか、複雑さの要因はなにかについて、体系的に整理し、分析しようと真剣に考えたことはありませんでした。
そのための最初の試みとして、自分の経験を基に以下の3点を挙げてみます。

- ソフトウェア依存関係の複雑さ
- 分散システムとしての複雑さ
- 入力パターンの複雑さ

### ソフトウェア依存関係の複雑さ

ウェブシステムは、多数のソフトウェアの重ね合わせにより構成されます。
言語処理系、OS、ドライバ、共有ライブラリ、ミドルウェア、アプリケーションライブラリ、アプリケーションなどです。
さらに、これらがネットワーク越しに接続され、さまざまなプロトコルにより通信します。

このような状況では、ソフトウェアの依存関係や組み合わせの問題が発生します。
具体的にはバージョンアップ問題やプロトコル互換問題、依存地獄問題[[yuu15]](http://gihyo.jp/dev/serial/01/perl-hackers-hub/003401)などを指します。

例えば、あるソフトウェアをバージョンアップすると、そのソフトウェアに依存したソフトウェアが動作しなくなることがあります。
データベースのバージョンアップにより、プロトコルなどの仕様変更に追従していないアプリケーションが動作しなくなるなどは典型的な例でしょう。
動作したとしても、性能が低下し障害につながるということもあります。

### 分散システムとしての複雑さ

信頼性のあるウェブシステムは、基本的に分散システムとして構成されています。
複数のノードが相互に通信するということは、単純にノードやリンクが増加すればするほど、システムとしては複雑になります。
さらに、分散システムは、ハードウェア故障、ネットワークの切断・遅延といった物理的制約がある中で、信頼性を担保しなければいけません。
部分的な故障を許容しつつ、自動でリカバリする仕組みは複雑です。
分散システムの難しさについて書かれた文献として、「本当は恐ろしい分散システムの話」[[kum17]](https://www.slideshare.net/kumagi/ss-81368169)が非常に詳しいです。

### 入力パターンとしての複雑さ

ウェブシステムの入力パターン((ワークロード))は一定でもなければ、ランダムでもないことがほとんどです。
ただし、サービスの特性により、朝はアクセスは少ないが、夜に向けてアクセスが徐々に増加するといった一定の傾向はあります。
大まかな予測はできることがあるものの、むずかしい。
人間、検索クローラ、スパマーなどの活動に応じてシステムへの入力パターンは突発的に変化します。((制御工学でいうところの外乱))
実際、この突発的な変化が障害の原因になることはよくあります。

入力パターンの突発的変化(外乱)は、人間や社会の変化によることもあるため、システム側での予測は困難です。

## システムの複雑さの度合い

複雑さを分析するのは、要因に加えて度合いの評価も必要です。
度合いについてもせいぜいサーバ台数やサービス数程度でしかみてきませんでした。

そもそも一般的に複雑さをどう定義しているかについて、複雑性科学の書籍[mel17]を参考にしました。
[mel17]には、複雑さについての一般的な定義はなく、これまでいくつかの指標が提案されたことが書かれていました。
提案された指標は、サイズ、エントロピー、アルゴリズム情報量、論理深度、熱力学深度、計算能力、統計的な複雑性、フラクタル次元、階層度がありました。
この中で、比較的ウェブシステムに当てはめやすいのは、サイズと階層度です。

前述の分散システムとしての複雑さに対して、サイズと階層度((書籍「システムの科学」[her99]の第8章 階層的システム))の概念を適応してみます。

サイズについては、例えば、はてなのシステムサイズは以下のようなものです。GoogleやAmazonであれば、おそらくこの100~1000倍の規模でしょう。

- サービス数: 100+ (内部向け含む)
- ロール数: 1000+
- ホスト数: 1000+
- プロセス/スレッド数: 10000+
- SRE数((実際の職種名はWebオペレーションエンジニア)): 10人弱

階層度を特に入れ子のレベルによって定義した場合、プログラム実行単位については10年前であれば例えば以下のようになります。

- レベル1: プロセス/スレッド
- レベル2: サーバ (複数のプロセスの集合体)
- レベル3: ロール (クラスタやロードバランサ配下のサーバ群)
- レベル4: サービス: (ロールまたはマイクロサービスの集合体)
- レベル5: プラットフォーム: (複数のサービスの集合体)
- レベル6: ウェブ

一方、現在であれば例えば以下のようになります。
ただし、サーバレスアーキテクチャを採用していれば、レベル1~3までは無視できる一方で、マイクロサービスなど層を増やす変化もあります。

- レベル1: プロセス/スレッド
- レベル2: コンテナ
- レベル3: サーバ (複数のプロセスの集合体)
- レベル4: ロール (クラスタやロードバランサ配下のサーバ群)
- レベル5: マイクロサービス
- レベル6: サービス: (ロールまたはマイクロサービスの集合体)
- レベル7: プラットフォーム: (複数のサービスの集合体)
- レベル8: ウェブ

実際には、複雑さを評価するためには、複雑さの要因ごとに複数の指標と複数の観点をもつ必要があると考えます。
ウェブシステムがどのような複雑さをもつのか、特に他分野の方に伝えるには、SREの分野では、蓄積が不足していると感じます。

# 4. ウェブシステムの自律運用へのアプローチ

ここまで、ウェブシステム運用技術の変遷とウェブシステムの複雑さについて書いてきました。
ここでは、これらを踏まえ、課題を解決するためのビジョンである観測と実験による「Experimentable Infrastructure」について述べます。

## 観測

前述の運用技術の進歩により、インフラストラクチャが抽象化され、プログマブルかつシンプルに扱えるようになってきました。
しかし、要素数を増やす方向へ技術が進んでいるため、依然としてシステム全体の挙動を人が理解することが難しいと感じます。
したがって、系全体の精緻な理解を助ける観測器が必要です。

ここでの観測とは、ウェブシステムの「過去と現在」の状況を人間またはコンピュータが自動的かつ継続的に把握することです。
20年近く前からサーバ・ネットワークを「監視」するためのツール((NagiosやZabbixなど))が開発されてきました。

従来や現在の監視ツールは、サーバに対する定期的なpingやメトリックの時系列グラフ化をサポートしています。
しかし、これだけでシステムの振る舞いを分析できるかというとそうではありません。
監視ツールを頼りにしつつも、SREはシステムのネットワークグラフ構造を調べ、ログを眺め、アプリケーションコードをgrepし、脳内でシステムに対してどのような変更があったかを思い出すといったことをやっています。

このように、まだまだ監視ツールだけではわからないことがあるのが現状です。
従来の監視はもちろん、ログやイベントデータの収集に加えて、構成要素と要素間の関係の把握などが求められます。((6. 議論 にてさらなる観測の可能性について記述))

自分が開発に関わっているサーバ監視サービスであるMackerel[[mac]](https://mackerel.io)については、[[yuu17-2]](http://blog.yuuk.io/entry/2017/the-origin-of-mackerel)に書いています。Mackerelには世の中のウェブシステムの観測結果が集約されているデータベースとしてとらえると解析対象としておもしろいんじゃないかと思います。

## 制御

システムが自律的に動作し続けるためには、システムの異常を自動で制御する必要があります。

### ナイーブな制御

例えば、クラウドの台頭によりサーバの生成と廃棄がプログラマ化されたため、メトリックの変動に応じてサーバの個数や性能を自動調整できます。
さらに、なんらかの理由により不調なプロセスやサーバをすぐ捨てて、新しいものを生成することも可能です。
現在では、このあたりがウェブシステムの現場で浸透中の制御になるかと思います。
しかし、制御のためのパラメータはエンジニアの経験を元に値を設定しており、制御がうまく動くかどうかはエンジニアの技芸に頼っていると言えます。
ナイーブな自律制御のままでは、すべての課題はクリアできません。

### 待ち行列による制御

よくあるアイデアの一つに、待ち行列理論の利用があります。情報ネットワークの分野では、よく利用されている理論です。
ウェブシステム全体と、サブシステムをそれぞれ入れ子構造の待ち行列としてモデル化できます。
待ち行列解析により、到着分布と処理分布を観測しつづけることで、必要なコンピューティングリソースを割り出し、自動的にリソースを配分し続けられます。
例えば、最も簡単なリトルの法則を応用すると、[[myu16]](http://memo.yuuk.io/entry/2016/03/27/023002)のように中期的なキャパシティプランニングに利用できます。

しかし、待ち行列理論の課題は、仮定する分布の範囲外の予測のできない突発的な外乱に対応しづらいことです。
到着分布は、前述したように入力の複雑さにより、予測することは難しいでしょう。
さらに、到着分布が予測可能であっても、ネットワークのパケット処理とは異なり、ウェブシステムでは、処理の重たい入力とそうでない入力の差が大きい((いわゆる地雷URLなど))ため、処理分布が予測できない可能性もあります。

外乱は事業機会となることがあるため、分布から外れた異常値だからといって無視はできないという事情があります。
そこで、最近はフィードバック制御に着目しています。(([[yuu17-3]](https://speakerdeck.com/yuukit/the-concept-of-hatena-system)でも紹介した))

### フィードバック制御

>フィードバック制御は、大規模で複雑なシステムを、たとえシステムが外乱に影響を受けようとも、あるいは、限られた資源を有効利用しつつ、その性能を保って動作させるための手法です。
[phi14]より引用

フィードバック制御に着目した理由は、制御対象はブラックボックスであり、中身は不明でよいという点です。
これは、SREがアプリケーションの中身を知らずに観測結果だけをみて障害対応する様子に似ていると感じました。
待ち行列理論ではできないダイナミクスを扱えるのも特徴です[[ohs13]](http://www.ieice.org/~netsci/wp-content/uploads/2013/08/NetSci201308_Ohsaki.pdf)。
現実のウェブシステムでは、解析的にモデルを導出するのは難しいため、パラメータの決定には「実験」による計測が必要です。

ウェブシステムに対して、フィードバック制御の導入イメージは例えば、以下のようなものです。
制御入力は、明示的に変更可能なパラメータです。例えばサーバの台数やサーバのキャッシュメモリ量などがこれに相当します。
制御出力は、制御対象パラメータです。例えば、応答時間やエラーの数などになります。
制御出力を監視し続け、目標値から外れたら制御入力を変更し、元に戻すような操作を、システムモデルに基づいて行います。
具体的には、制御入力に対して伝達関数を適用し、制御出力を得ます。
ただし、伝達関数の同定やチューニングは、実システムで応答をみる必要があります。

ただし、ここで述べているのは古典的な制御理論の話であり、単一入出力しか扱えません。
実際には、複数の入力と出力を扱ったり、階層的なシステムに対する制御をやりたくなるでしょう。
そちらは、現代制御理論やポスト現代制御理論と呼ばれる発展的な理論の範疇のようです。

制御理論をウェブシステムの運用に組み込む研究には、[jen16]などがあります。
[jen16]は、データベースクラスタ内のサーバのスケーリングについて、フィードバック制御、強化学習、パーセプトロン学習の3つの手法を比較しています。
さらに、フィードバック制御(PID制御)をApache Sparkのバックプレッシャー機構に組み込む実装もあります[[spapid]](https://github.com/apache/spark/blob/master/streaming/src/main/scala/org/apache/spark/streaming/scheduler/rate/PIDRateEstimator.scala)。

## 実験

待ち行列にせよ、フィードバック制御にせよ、機械学習的なアプローチにせよ、実システムの応答結果を継続的に得ることが必要です。
おそらく、統一的なモデルなどはなく、システムやサブシステムごとに異なるモデルとなると考えています。

しかし、単純に平常時のシステムを観測し続けるだけでは、良好な制御モデルが得られない可能性があるのではないかと考えています。
というのは、システムごとのモデルとなると、過去に限界値や異常値に達したデータの数が少ないため、学習データが足りない可能性があります。
((異常検知であれば平常時だけを知っておけば問題なさそうだが、その他のアプローチの場合はどうか))
特に新システムであればデータはゼロなので、本番環境の蓄積データだけでは、制御パラメータを決定できません。

ワークロードのない状態では、例えば1台あたりのサーバの限界性能というのは実際に限界まで負荷をかけないとわからないことが多いでしょう。
素朴に考えると、手動で実験してデータをとることになってしまいます。

そこで、実験の自動化を考えます。
システムには日々変更が加えられるため、継続的な実験が必要であり、手作業による実験は人手が必要で結局長続きしないためです。

分散システムの自動実験の概念としてNetflixが提唱するChaos Engineering[[cha17]](http://principlesofchaos.org/)があります。
Chaos Engineeringは、本番環境にて故意に異常を起こす逆転の発想です。
例えば、サーバダウンなどわざと異常を起こすことで、システムが異常に耐えられるのかをテストし続けます。
Chaos Engineering自体は、先に述べたように制御モデルのパラメータ推定についての言及はありませんが、ビジョンの構想に大きく影響を受けました。((書籍[cas17]では、奇しくもフィードバック制御の伝達関数の話が例としてでてくるが、予測モデルを構築することは困難なので、実験しましょうということが書かれているだけだった))

しかし、一般に言われていることは、本番環境で異常を起こしたり、限界まで負荷をかけるのは不安であるということです。
実際、書籍「Chaos Engineering」[cas17]では、監視の環境整備、異常時の挙動の仮説構築、実験環境での手動テスト、ロールバックなどの基盤を整えた上で十分自信をもった状態で望むようにと書かれています。
しかし、この段階では、実験そのものは自動化されていても、それに至るまでに人間による判断を多く必要とします。

ここで、クラウドやコンテナ技術など限りなく本番に近い環境をオンデマンドに構築する技術が発達してきていることを思い出します。
自分の考えでは、実験環境を高速に作成することで安全に実験を自動化する技術を突き詰め、効率的にデータを取得し、パラメータを決定するというアプローチを考えています。((本番環境の負荷の再現が壁になるだろうとは思います))

これら以外に手動で実験するケースについても、実験という概念に内包し扱おうしています。
動作テスト、負荷テスト、パラメータチューニング(OSやミドルウェアのパラメータ)などです。((パラメータチューニングの自動化については、おもしろい例[[mir13-2]](https://speakerdeck.com/mirakui/quan-zi-dong-parametatiyuningusan)がある))

## Experimentable Infrastructure

以上のような観測と実験の自動化アプローチには、近代科学の手法の自動化であるというメタファーが隠されています。

書籍「科学哲学への招待」[noe15]に近代科学の歴史とともに、仮説演繹法について紹介されています。

- (1) 観察に基づいた問題の発見 (観測)
- (2) 問題を解決する仮説の提起
- (3) 仮説からのテスト命題の演繹
- (4) テスト命題の実験的検証または反証 (実験)
- (5) テストの結果に基づく仮説の受容、修正または放棄

仮説演繹法のループを高速に回し、自律的に変化に適応し続けるシステムを「Experimentable Infrastructure」と呼んでいます。
コンピュータに仮説の提起のような発見的な手法を実行させるのはおそらく難しいと思います。
しかし、ウェブシステムの観測と実験により判明することは、世紀の大発見ということはなく、世の中的には既知のなにかであることがほとんどなので、仮説提起をある程度パターン化できるのではないかと考えています。

# 5. 自律運用の壁とウェブサイエンス

仮に前述のアプローチがうまくいったとしても、さらにその先には壁があります。
自律運用の壁は、「ハードウェアリソース制約」と「予想できない外乱の大きな変化」です。

前者は、予め用意したリソースプールでさばける以上の負荷には耐えられないことです。
クラウドにも上限は存在します。

後者は、サーバの増加などには必ずディレイが存在するため、外乱の大きさによっては、フィードバックが間に合わないケースもありえます。
これについては、以下のようにウェブサイエンスの研究成果である状態予測をフィードフォワード制御に利用するといったアイデアもあるかもしれません。

>
自発的に発展するサービスの特徴を捉え、例えば、Web サービスが今後発展していくのか、元気をなくしていくのか、そうした状態予測を目指し、自律的な人工システムのダイナミクスを捉える普遍的な方法論をつくり、自然科学としての人工システム現象という分野の確立を目指している。
> 
106 人 工 知 能　31 巻 1 号（2016 年 1 月）「ウェブサイエンス研究会（SIG-WebSci）」 発足

## 自律運用

ここまでの「自律」の定義は「自動修復」「自律運用」でした。
自律運用では、与えられた制約条件=信頼性 を満たすように自律動作することを目指しています。
信頼性を自律的に満たせれば、費用のうち人件費はある程度削減できます。
しかし、信頼性の条件設定、アーキテクチャの決定、ソフトウェアの効率化などは依然として人の仕事です。

## 自律開発

自律運用に対して、自律開発((おそらく一般的に使われている言葉がソフトウェア工学の世界などにあるかもしれません))という考え方があります。
これは、この記事の文脈では例えば、自律的に費用を最小化するようなシステムを指します。

自律開発には、進化・適応の概念が必要であり、分散システムアーキテクチャの設計・改善やソフトウェア効率改善の自律化などを含みます。
おそらくソフトウェア進化の研究[oom12]などで進んでいる分野だと思います。

## 運用から解放されたその先

ここまではウェブシステムの運用という工学的モチベーションの話でした。

IPSJ-ONEの記事[[yuu17]](http://blog.yuuk.io/entry/ipsjone2017)にて、以下のような宿題がありました。

>
しかし、最終的に自分のやっていることが世界にとってどういう意味があるかということを加えるとよいという話もあったのですが、ここは本番では組み込めなかった部分です。自動化されて、運用から解放されて、遊んで暮らせるようになるだけなのか？という漠然とした疑念はありました。科学の歴史をみてみると、例えば未知であった電気現象を逆に利用して、今ではコンピュータのような複雑なものを動かすことができるようになっています。そこからさらにメタなレイヤで、同じようなことが起きないかといったことを考えているのですが、これはこれからの宿題ということにします。

いまだにこの宿題に対する自分の中の答えはありませんが、ウェブサイエンス研究会発足の文章を拝読して、ぼんやりと基礎科学の貢献という道もあるのだなと思いあたりました。
人の手を介さずに動き続けるウェブシステムを探究することで、複雑な系に対する統一的な法則を発見し、基礎科学へ貢献できないかどうかといったことを考えながら、老後を過ごすのも、昔からシステムが好きな自分にとってよいのかもしれません。

>
ネットワークの技術階層を含む Webの存在そのものを新しい「自然現象」として捉え、例えば、その「生態系」としての構造を明らかにすることで、普遍的なダイナミクスやパターンを明らかにし、従来の自然科学・人文科学の考えを発展させることを目指している。
>
106 人 工 知 能　31 巻 1 号（2016 年 1 月）「ウェブサイエンス研究会（SIG-WebSci）」 発足

# 6. 議論

講演後にいただいた質問や議論から、SREの分野は、まだまだサイエンスというより、エンジニアの技芸の上に成り立っているなと感じました。

例えば、以下のようなデータ解析の内容をSREの分野で書かれた文献を今のところ僕は知りません。

- ウェブシステムの複雑さの定義と解析
- ウェブシステムの階層構造の変化の解析
- ウェブシステムの階層ごとの到着分布、処理分布の解析
- ウェブシステムの自律度合いの定義と解析
- 異常のパターン分析と体系化

これは、以下の2点が要因としてあると考えています。

- SREとデータ解析の関心やスキルセットのミスマッチ
- データ収集が困難
  - 数年前までは、自社システムを自社内で観測してデータを溜め込んでいるだけであったため、多数のウェブシステムの情報をまとめて解析することができなかった

後者については、Mackerelを持っていることは強みなので、うまく活用していきたいと思います。
このようなデータ解析の観点でみると、観測には前述した項目よりもっと先があることを想起させれます。

# 7. まとめ

ウェブシステムの運用は、ここ10年で自動化が進んでおり、物理的な世界からソフトウェアの世界になってきました。
ウェブシステムは複雑ではあるが、現代のところコンピュータだけで自律した系ではありません。
ウェブシステムという人工物を自然のように振る舞わせ、人間を運用から解放したいというのが最終的な目標です。

# 参考文献

- [Bet17]: Betsy Beyer, Chris Jones, Jennifer Petoff, Niall Richard Murphy編 澤田武男 関根達夫 細川一茂 矢吹大輔 監訳 Sky株式会社 玉川竜司 訳,「SRE サイトリライアビリティエンジニアリング ――Googleの信頼性を支えるエンジニアリングチーム」,オライリー・ジャパン,2017/08, https://www.oreilly.co.jp/books/9784873117911/
- [Oco12]: P. O'Connor and A. Kleyner, 「Practical Reliability Engineering」, 5th edition: Wiley, 2012.
- [ito08]: 伊藤直也, 勝見祐己, 田中慎司, ひろせまさあき, 安井真伸, 横川和哉 著, 「［24時間365日］サーバ/インフラを支える技術 ……スケーラビリティ，ハイパフォーマンス，省力運用」, 技術評論社, 2008/08, https://gihyo.jp/magazine/wdpress/plus/978-4-7741-3566-3
- [rx709]: [http://d.hatena.ne.jp/rx7/20091125/p1:title:bookmark]
- [coo15]: [https://aws.amazon.com/jp/solutions/case-studies/cookpad/:title:bookmark]
- [awshis]: [https://aws.amazon.com/jp/aws_history/details/:title:bookmark]
- [doc13]: [https://blog.docker.com/2013/03/opening-docker/:title]
- [imm13]: [http://chadfowler.com/2013/06/23/immutable-deployments.html:title]
- [miz13]: [http://mizzy.org/blog/2013/10/29/1/:title:bookmark]
- [mir13]: [http://blog.mirakui.com/entry/2013/11/26/231658:title:bookmark]
- [sta13]: [http://blog.stanaka.org/entry/2013/12/01/092642:title:bookmark]
- [mar16]: [https://martinfowler.com/articles/serverless.html:title:bookmark]
- [nek16]: [http://d.nekoruri.jp/entry/20161222/serverless2016:title:bookmark]
- [mer15]: [http://tech.mercari.com/entry/2015/11/18/153421:title:bookmark]
- [yuu17]: [http://blog.yuuk.io/entry/ipsjone2017:title:bookmark]
- [kie17]: Kief Morris著 宮下剛輔監訳 長尾高弘訳,「Infrastructure as Code ――クラウドにおけるサーバ管理の原則とプラクティス」, オライリー・ジャパン,2017/03, https://www.oreilly.co.jp/books/9784873117966/
- [yuu15]: [http://gihyo.jp/dev/serial/01/perl-hackers-hub/003401:title:bookmark]
- [kum17]: [https://www.slideshare.net/kumagi/ss-81368169:title:bookmark]
- [mel11]: Melanie Mitchell著 高橋洋 訳,「ガイドツアー　複雑系の世界: サンタフェ研究所講義ノートから」,紀伊國屋書店,2011/11
- [her99]: Herbert Alexander Simon著,稲葉元吉,吉原英樹 訳,「システムの科学 第3版」,パーソナルメディア,1999/6
- [mac]: [https://mackerel.io:title:bookmark]
- [yuu17-2]: [http://blog.yuuk.io/entry/2017/the-origin-of-mackerel:title:bookmark]
- [myu16]: [http://memo.yuuk.io/entry/2016/03/27/023002:title:bookmark]
- [phi14]: Philipp K. Janert 著, 野原 勉 監訳, 星義克,米元謙介 訳,「エンジニアのためのフィードバック制御入門」,オライリー・ジャパン,2014/07,https://www.oreilly.co.jp/books/9784873116846/
- [ohs13]: 大崎 博之, 大規模ネットワークの 設計・モデル化・制御, 第2回NetSci/CCS研究会 合同WS, http://www.ieice.org/~netsci/wp-content/uploads/2013/08/NetSci201308_Ohsaki.pdf
- [yuu17-3]: [https://speakerdeck.com/yuukit/the-concept-of-hatena-system:title:bookmark]
- [cha17]: [http://principlesofchaos.org/:title:bookmark]
- [cas17]: Casey Rosenthal, Lorin Hochstein, Aaron Blohowiak, Nora Jones, and Ali Basiri,「Chaos Engineering - Building Confidence in System Behavior through Experiments」, O'REILLY, 2017, http://www.oreilly.com/webops-perf/free/chaos-engineering.csp
- [mir13-2]: [https://speakerdeck.com/mirakui/quan-zi-dong-parametatiyuningusan:title:bookmark]
- [noe15]: 野家啓一著,「科学哲学への招待」,ちくま学芸文庫,2015
- [oom12]: 大森隆行, 丸山勝久, 林晋平, 沢田篤史著,「ソフトウェア進化研究の分類と動向」, コンピュータソフトウェア29巻3号, 2012
- [jen16]: Ortiz, Jennifer and Lee, Brendan and Balazinska, Magdalena, "PerfEnforce Demonstration: Data Analytics with Performance Guarantees", In Proceedings of the 2016 International Conference on Management of Data(SIGMOD'16), 2016

# 発表スライド

[https://speakerdeck.com/yuukit/experimentable-infrastructure:embed]

# あとがき

そもそも、ウェブサイエンス研究会に招待していただいたきっかけは、IPSJ-ONE 2017 [http://blog.yuuk.io/entry/ipsjone2017:title:bookmark] の登壇にてご一緒した鳴海先生に声をかけていただいたことです。
さすがに、場違いではとも思いました。というのも、僕が実際やっていることは、[時系列データベースの開発](http://blog.yuuk.io/entry/the-rebuild-of-tsdb-on-cloud)であったり、10年前から続くウェブシステムの運用効率化などであり、技芸であって科学ではない((John Allspaw、Jesse Robbins編、角 征典訳,ウェブオペレーションーーサイト運用管理の実践テクニック,オライリージャパン より引用))からです。
しかし、[はてなシステムを構想する](https://speakerdeck.com/yuukit/the-concept-of-hatena-system)にあたって、地に足がついてなくてもいいから、無理やり未来を考えるいい機会になると捉え、登壇を引き受けさせていただきました。
今回の研究会のテーマは、「自然現象としてのウェブ」ということで、本当に何を話したらよいかわからないテーマで相当苦戦しましたが、その結果、IPSJ-ONE登壇で考えたことの言語化を進められました。((発表自体は、タイムコントロールに久々に大失敗して、途中スライドスキップして残念な感じになってしまいましたが、この記事で補完できればと思います。))
途中、妄想のような話もあり、他の分野の専門家からみれば眉をひそめるような表現もあるかもしれませんが、一度考えたことを言語化しておくことでまた次のステップに進めると考えています。

普段はどうしても目の前の課題に熱中しがちで、未来のことを考えようとはなかなか思いません。
概念や思想だけではなかなかそれを取り入れようとは考えず、それを実現するソフトウェアなりハードウェアが目の前にあらわれ使える状態になってはじめて目を向けることになります。
例えば、AWSもDockerもないと仮定して、Immutable Infrastructureの考え方に触れたとしても、到達までの道筋がすぐにはみえないため、諦めて考えないようにしてしまいそうです。

発表後に、研究会の幹事である橋本先生に、技術者はどこまで先を考えているものなのか、と質問をいただきました。
少なくとも、日本のウェブの技術者界隈で、未来の技術ビジョンを設定し、それに進もうとしている様子が外からみえることはなかなかありません。
[ペパボ研究所が掲げるなめらかなシステム](https://rand.pepabo.com/) ((研究所なので技術者界隈とは呼ばないかもしれません))が僕の知る唯一の例です。
Real Worldでは、一歩前に進むだけでも本当に様々な問題が起き、とにかく目の前のことを倒すことが求められるので、とても未来どころではなくなるというのが現状かもしれません。

未来を考えるのは、研究者の場合は当たり前に求められるという印象があります。
しかし、SREの分野では、研究者のコミュニティが他と比べて未発達なようにも思います。
近い分野である情報ネットワークに関しては、日本でも様々な研究会がありますが、僕の知る限りでは、日本では直接的にSREの分野を扱う研究会は存在しないようです。((海外ではUSENIXのLISAやSREconなどがあります))

そこで、[ウェブシステムアーキテクチャ研究会](http://websystemarchitecture.hatenablog.jp/entry/2017/11/16/182041)、([#wsa研](https://twitter.com/search?f=tweets&vertical=default&q=%23wsa%E7%A0%94&src=typd))というものを立ち上げようとしています。
第1回は京都開催にもかかわらず、全員発表型で10人以上の参加者が既に集まっています。
今回の講演の準備をするにあたって、我々の分野で未来を議論するための既存の枠組みや土台があまりないことを改めて実感しました。((SRE本は本当に稀有な存在))
WSA研では、未来を考えるために、現状を体系化し、そこから新規性や有用性を追求していこうと思います。