---
Title: サーバーレスアーキテクチャ再考
Category:
- Serverless
Date: 2019-09-11T17:37:57+09:00
URL: https://blog.yuuk.io/entry/2019/rethinking-serverless-architecture
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/26006613429983179
---

[2014年にAWS Lambdaが登場](https://aws.amazon.com/jp/blogs/aws/run-code-cloud/)し、Functionを単位としてアプリケーションを実行する基盤をFunction as a Service(以下、FaaS)と呼ぶようになった。
そして、同時にサーバーレスアーキテクチャ、またはサーバーレスコンピューティングと呼ばれる新しいコンセプトが普及するに至った。
当初、そのコンセプトが一体何を示すかが定まっていなかったために議論が巻き起こり、今現在では一定の理解に着地し、議論が落ち着いているようにみえる。
しかし、サーバーレスという名付けが悪いということで議論が着地したようにみえていることにわずかに疑問を覚えたために、2019年の今、これらの流れを振り返ってみて、サーバーレスアーキテクチャとは何かを改めて考えてみる。

## サーバーレスとの個人的関わり

サーバーレスアーキテクチャという名を僕がはじめて耳にしたのはAWS Lambdaが登場した2015年だったと思う。
当初は、ご多分に漏れず、「サーバーレス？サーバーを使わないってことはフロントエンドの話か？クライアントサイドでP2Pでもやるのかな」と思いながら、解説記事を開くと、関数だとかイベント駆動だとリアクティブだとか書かれていてなにやらよくわからないけど、とりあえずサーバーあるやん！とつっこんでしまった。
その後、僕自身はサーバーレスアーキテクチャというものにさして興味をもたずに、どうやらFaaSを利用したシステムのことをサーバーレスと呼ぶらしいという話に一旦落ち着いたようにみえた。

その後、前職で機会があり、2016年後半あたりからサーバーレスアーキテクチャに基づいて時系列データベースアプリケーションを開発したことがあった[https://blog.yuuk.io/entry/the-rebuild-of-tsdb-on-cloud:title]。
そこで、AWS LambdaやAmazon DynamoDBを使い倒し、具体的な開発や運用のノウハウを蓄積したのちに、論文にまとめることとなり、サーバーレスとは改めて何だったのかということを振り返るきっかけとなった[https://blog.yuuk.io/entry/2018/writing-the-tsdb-paper:title]。

## サーバーレスの既存の定義

まずここで第一に文献として挙げたいのが、CNCF(Cloud Native Computing Foundation)内のサーバーレスワーキンググループがまとめたサーバーレスコンピューティングのホワイトペーパーである。((Sarah Allen, et al., CNCF Serverless Whitepaper v1.0, <https://github.com/cncf/wg-serverless/tree/master/whitepapers/serverless-overview>, 2019.))
このホワイトペーパーから、サーバーレスコンピューティングの定義を引用してみよう。

>
A serverless computing platform may provide one or both of the following:
>
1. Functions-as-a-Service (FaaS), which typically provides event-driven computing. Developers run and manage application code with functions that are triggered by events or HTTP requests. Developers deploy small units of code to the FaaS, which are executed as needed as discrete actions, scaling without the need to manage servers or any other underlying infrastructure.
>
2. Backend-as-a-Service (BaaS), which are third-party API-based services that replace core subsets of functionality in an application. Because those APIs are provided as a service that auto-scales and operates transparently, this appears to the developer to be serverless.

簡単にいうと、サーバーレスコンピューティングとは、FaaSとBaaSのいずれか一方か両方を指すという定義になっている。
BaaSというのは、データベースなどのアプリケーションが必要とする機能の一部をAPIを通じて利用可能なサービスとなっているものの総称である。
BaaSの例として、データベース系統であれば、Amazon DynamoDBやGoogle BigQuery、メール系統であればSendgrid、DNS系統であればAmazon Route53、認証系であればAuth0などがある。

次に、カリフォルニア大学バークレー校からArxivにて今年公開された論文"Cloud Programming Simplified: A Berkeley View on Serverless Computing"((Eric Jonas, et al., Cloud Programming Simplified: A Berkeley View on Serverless Computing, arXiv preprint arXiv:1902.03383, 2019.))によると、次のように記述されており、ここでも、FaaS + BaaSの定義が採用されている。

> Put simply, serverless computing = FaaS + BaaS.
In our definition, for a service to be considered serverless, it must scale automatically with no need for explicit provisioning, and be billed based on usage.

さらに、[AWSのサーバーレスの製品サイト](https://aws.amazon.com/jp/serverless/)によると、サーバーレスプラットフォームと称して、コンピューティングカテゴリのAWS Lambdaだけでなく、ストレージ、データストアなどのBaaSも含まれている。

既存の定義から、サーバーレスはFaaS+BaaSということでもういいじゃんということになるのだけれども、なぜこれらが「サーバーレス」といえるのかをここではもう少し掘り下げてみよう。

## サーバーフルコンピューティング

まず、そもそも「サーバー」という用語が示す意味を考える。
サーバーは多義的な用語であり、少なくとも、ハードウェアとしてのサーバーとソフトウェアとしてのサーバーの2つの顔をもつ。
ここでは、データセンター内にある物理マシンと物理マシンを仮想化した仮想マシンを「マシンサーバー」とし、WebサーバーのようにOS上でネットワークソケット宛ての要求を処理するプロセスを「ネットワークサーバー」とする。

前者のマシンサーバーは、通常、コンピューティング機能としてCPU、RAMがあり、永続化機能としてのディスク、ネットワーク通信機能としてのNICといったモデル化されたハードウェアとして認識することが多い。
しかし、実際に抽象化の進んでいるWebアプリケーションのようなソフトウェアを開発していると、ハードウェアが隠蔽されているため、今書いているコードがどの程度メモリを消費して、どの程度のディスクIOPSになるのかといったことを知ることは難しい。
実際に動作させて計測しないとあたりもつけられないというところが実態だろう。
過去の経験では、アプリケーション開発者がコードを書き、SREがマシンサーバーのキャパシティを見積もるというような分担をしている場合に、SREはコードからではキャパシティの見積もりようがないので、ベンチマークして実験するか、すでに稼働している同じような性質のアプリケーションがあればそのアプリケーションがもたらすハードウェアリソース量を参考にしたりしていた。
加えて、高可用性やスケールアウトのために同一構成のサーバーを複数台用意したりする必要もある。
つまり、いくら抽象化されていても、ハードウェアを意識しないといけないということである。

後者のネットワークサーバーは常にプロセスが起動しており、特定のポート番号を占有して待ち受けている形態をとる。
常にプロセスが起動していれば、ソフトウェア開発者はメモリなどのリソースのリークを気にしなければならない。
また、ソケットを共有していない複数のネットワークサーバーが同一のポートを共有することはできないため、要求を処理しつづけながらネットワークサーバーのコードをデプロイするために、Graceful Restartのようなネットワークサーバー特有の仕組みが必要となる。
こちらも、ネットワークサーバーであることを意識する必要がある。

このように、サーバー上でソフトウェアを動作させることを意識して、プログラミングしたり、デプロイしたりすることを先程の"Cloud Programming Simplified"の論文ではサーバーフルコンピューティング(Serverful Computing)と読んでいる。

## サーバーレスとはなにか

書籍「Serverlessを支える技術」 ((Aki @ nekoruri, Serverlessを支える技術 第3版, BOOTH, 2019.))の表現を借りると、サーバーレスとは「サーバという単位を意識しない」ということになる。
これだけではまだちょっとよくわからないので、この考え方をマシンサーバーとネットワークサーバーのそれぞれに適用してみよう。

まず、マシンサーバーという単位を意識しないということは、マシンサーバーの個数やスペックを意識しないし、ハードウェアのリソースをどの程度消費するかということを意識しないということになる。
これは、DynamoDBやBigQueryの利用体験に近しいものがある。
DynamoDBについては、[https://blog.yuuk.io/entry/2018/dynamodb-cost-points:title]の記事で述べたように、インスタンスサイズによる課金モデルではなく、ストレージのデータ使用量とスループットを基にした課金モデルとなっている。
つまり、ハードウェアリソースの消費量ではなく、クエリの回数や保存データ量といったよりアプリケーションに近いモデルでキャパシティの見積もりが可能となる。
サーバーの個数やスペックも隠蔽されているため、自分でDynamoDB相当のデータストアを構築する場合と比べて、明らかにマシンサーバーを意識しなくてよくなっている。

次に、ネットワークサーバーを意識しないために、アプリケーションの実行単位をサーバーではなくFunctionとしたのがFaaSのアプローチである。
FaaSでは、様々なイベントをFunctionの入力として扱え、Functionプロセスがイベントを購読するモデルとなっている。
例えば、Webアプリケーションサーバー代わりに、Amazon API GatewayがHTTPリクエストを受け付けて、内部でLambda用のイベントに変換した上でLambda Functionに受け渡す。
その他、バッチサーバー代わりに、Amazon CloudWatch Eventsでイベントを発火する日にちや時刻を指定し、Lambda Functionを起動することもできる。
イベントの発火を契機にFunctionが起動するため、Function自体は通常のネットワークサーバーのように常時起動するわけではない。
Functionプロセスは一定時間起動し、連続してイベントを処理したのちに停止するため、毎回コンテナプロセスを起動するコストを低減させている。
Functionは必要なときに起動されるだけなので、事前にFunctionプロセスを何個起動するかといったキャパシティプランニングが不要である。
また、イベント駆動でのプロセス起動とイベント購読モデルであることから、イベントの流量が増加しても流量にあわせてひたすらFunctionプロセスを起動させていくだけなので、オートスケールが容易である。
これは、Functionプロセスがマシンサーバー上で動作することを意識しなくてよい点である。
ただし、現状では、Functionプロセスのメモリサイズを指定する必要があるため、マシンサーバーであることを完全に隠蔽できているわけではない。

蛇足だが、サーバーレスとはCGIであるという言説もSNS上でみたことがあるかもしれない。
CGIはWebサーバーが受け付けたHTTPリクエストを契機に任意のスクリプトを実行できるため、FaaSの特性のうち、イベントを契機にFunctionプロセスを起動するところがCGIと似ている。
ただし、CGIにはBaaSの性質は含まれないこと、扱えるイベントがHTTPのみといった当たり前のわかりやすい違いがある。
さらに、WebサーバーとCGIスクリプトは密結合であり同一ホスト上で実行されるため、CGI処理のみスケールさせるということはできない。
したがって、Webサーバーのホスト自体をスケールさせる必要があるため、マシンサーバーとして意識しなければならない。

サーバーレスにより単にサーバーを意識しないだけでなく、アプリケーション実行単位がFunctionとなった結果、Functionを糊として、各BaaSをつなぐピタゴラスイッチのような構成がとられるようになった。
例えば、BaaS上で発生するイベントをFunctionに入力し、そのFunction内で別のBaaSのAPIを叩き、さらにそのイベントを契機に別のFunctionが起動するといったものである。
そのような構成を指して、サーバーレスアーキテクチャと呼ぶこともある。
[https://blog.yuuk.io/entry/the-rebuild-of-tsdb-on-cloud:title]の構成はまさにそのようになっている。
部分的に紹介すると、DynamoDBへの書き込み時にレコード単位でTTLを設定し、TTLが0になった時点で、Functionにレコード内容をイベントとして入力し、S3にPutするといった処理の流れになっている。
サーバーレスの名称からピタゴラスイッチ構成を直接想像することは難しいが、サーバーを意識しなくなった結果、少なくともWebアプリケーションのスコープでは新しい構成がみられるようになったことは、ここ数年で一番好きな技術変遷である。
ただし現状では、クラウドベンダーが独自にFaaSとBaaSを連携させているため、OSSを使って同様の構成をとることはとてもむずかしく、特定のクラウドベンダーに非依存でピタゴラスイッチ構成を実現するにはどうしたらいいかに興味を持っている。
FaaSについては基礎的なビルディングブロックを提供する[Knative](https://knative.dev)や、まさにFaaSそのものを実現する[OpenFaaS](https://www.openfaas.com)などがあり、ベンダー非依存の環境が整ってきている。
しかし、FaaSとBaaSを連携するには、少なくとも、[CloudEvents](https://cloudevents.io)のようにイベントの表現を標準化することと、BaaS側ではOSSミドルウェアにイベントを発火できるように対応する必要があり、道のりは険しい。

## サーバーレスの制約

さて、ここまででだいたいサーバーレスがなにかということの議論は終わったが、ではあらゆるアプリケーションをサーバーレスで設計するのがよいかというとそういうわけではない。
特にネットワークサーバーの形態をとらないことは、前述のようなメリットもある一方でデメリットもある。
その一例として、次の図に示すように、FaaSにおいて、同期的に応答しなければならないリクエストが都度やってくる場合、リクエストを1個ずつFunctionで処理することになるため、各リクエストを同一プロセスで並行処理できない。
Functionの処理のうちI/Oブロッキング時間が支配的であれば、I/Oブロッキング中にCPUは他のFunctionで利用できるがメモリは確保したままになるため、メモリ使用効率が悪く、コストが高くなってしまうという課題がある。
ちなみに、非同期の応答でよければ、FaaS内のキューにイベントを溜め込み、Functionが複数のイベントを同時に取得できるため、複数のリクエストを並行処理可能である。
この課題については、[https://blog.yuuk.io/entry/2017/lambda-disadvantages-from-a-cost-viewpoint:title]の記事で具体的なアプリケーションを例にして紹介している。

[f:id:y_uuki:20190911103012p:image]

"Cloud Programming Simplified"の論文では、その他の現状のサーバーレスプラットフォームの制約を整理してまとめられている。
このように従来のサーバーフルコンピューティングではなかった制約があるため、アプリケーションの特性を見極めて、アーキテクチャを選択する必要がある。

## まとめ

このエントリでは、サーバーレスアーキテクチャが主観的にどのように見えていたかから始まり、サーバーレスの既存の定義を紹介したあとに、そもそもサーバーとはなにか、サーバーレスはサーバーという単位を意識しないという意味で捉えて、サーバーレスアーキテクチャとは何だったのかを再考した。
サーバーレスという名前付けがその意図とセットで普及しなかった結果、ミスリーディングな名前となってしまったが、一周回ってこの名前もそれほど悪くはないように思えてきた、というのがこのエントリを書いた動機となった。

このエントリの下書きをLINE OpenChatで先んじて公開したところ、[@tzkb](https://twitter.com/tzkb)さんからデータベースの文脈だとサーバーレスはどうなんでしょうねという話題になり、伝統的なデータベースでは密結合になっているバッファプールとテーブルファイルなどのデータ構造を分解して、各データ構造をBaaS上で実装してFaaSでつないで、ユーザーが書いたFunctionをフックできたり、BaaS上に任意のインデックス構造を拡張できたりするアーキテクチャにしたらおもしろいよねといって盛り上がった。
昨年論文にしたTSDBのアーキテクチャではまさにそのような分解と再構築を行っていたのだった。
[https://blog.yuuk.io/entry/2018/writing-the-tsdb-paper]
