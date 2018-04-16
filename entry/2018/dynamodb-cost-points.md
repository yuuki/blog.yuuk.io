---
Title: DynamoDBのインフラコスト構造と削減策
Category:
- Database
- DynamoDB
Date: 2018-04-16T23:56:19+09:00
URL: http://blog.yuuk.io/entry/2018/dynamodb-cost-points
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/17391345971635750655
CustomPath: 2018/dynamodb-cost-points
---

[Amazon DynamoDB](https://aws.amazon.com/jp/dynamodb/)は、RDSのようなインスタンスサイズによる課金モデルではなく、ストレージのデータ使用量とスループットを基にした課金モデルになっている。
インスタンスサイズによる課金モデルでないデータストア系サービスとして、他にはS3、Kinesisなどがある。
これらは、AWSの中でも、フルマネージドサービスと呼ばれる位置づけとなるサービスだ。
フルマネージドサービスは、ElastiCacheのようなそうでないものと比較し、AWSに最適化されていて、サービスとしてよくできていると感じている。

Mackerelの時系列データベースのスタックの一つとして、DynamoDBを採用している。[http://blog.yuuk.io/entry/the-rebuild-of-tsdb-on-cloud:title:bookmark]
時系列データベースの開発は、コストとの戦いだったために、それなりにコスト知見が蓄積してきた。

(※ 以下は、2018年4月16日時点での情報を基にしている。)

# DynamoDBのコスト構造

冒頭に書いたように、「ストレージのデータ使用量」と「スループット」を基にするため、インスタンスサイズモデルと比較して、よりアプリケーションコードがダイレクトに反映されるコスト構造になっている。

正確なコスト定義は、[公式ドキュメント](https://aws.amazon.com/jp/dynamodb/pricing/)を参照してほしいが、これを初見で理解するのはなかなか難しい。データ使用量のコストモデルはGB単価なため把握しやすい。しかし、スループットに関するキャパシティユニットの概念が難しい。
以下では、各要素について、メンタルモデルを説明する。
[AWS Calculator](https://calculator.s3.amazonaws.com/index.html)に適当な値をいれてみながらコストを見てみるとだいたいの感覚をつかめると思う。

## ストレージのデータ使用量

ストレージのGB単価は、$0.25/GBであり、S3のStandardストレージクラスと比較して、およそ10倍程度となる。
こう聞くと割高に聞こえるが、画像やブログのテキストデータなどを格納しなければ((そもそも、DynamoDBはアイテムサイズが現在のところ400KBまでという制限がある <https://docs.aws.amazon.com/ja_jp/amazondynamodb/latest/developerguide/Limits.html#limits-items>))、それほど高いというわけではない。
実際、1TBのデータ使用に対して、$300/月程度のコストとなる。

DynamoDBはSSD上に構築されている((<https://aws.amazon.com/jp/dynamodb/>))ようなので、安定して低レイテンシという性能特性があるため、大容量データをひたすら保持するというよりは、エンドユーザに同期的に応答するようなユースケースに向いている。

## スループット

スループットによるコストには、「秒間のread数/write数」と「対象のアイテムサイズ」が要素として含まれる。
S3のように月のAPIコール数の合計により課金されるわけではなく、予めどの程度のスループットとなるかを予測し、事前にキャパシティとして確保しておく必要がある。
したがって、見込んでいる最大のスループットにあわせてキャパシティ設定することになり、正味のリソース消費量よりも余分にコストがかかることに注意する。
ただし、後述するAuto Scalingにより、余分なコストを抑えられる可能性がある。

スループットによるコストは、大雑把には以下の特性をもつ。

- 「秒間read数/write数」に比例してコストが大きくなる
- アイテムサイズを1KBに固定したときの「秒間write数」の単価は「秒間read数」の約5~6倍程度となる。読み取り整合性を[結果整合性のある読み込み](https://docs.aws.amazon.com/ja_jp/amazondynamodb/latest/developerguide/HowItWorks.ReadConsistency.html)にすると、秒間read数のコストは1/2となる
- readまたはwriteしたアイテムのサイズに比例してコストが大きくなる
- 「アイテムサイズ」のコスト単位はreadとwriteで異なる。readは4KB単位で比例し、writeは1KB単位で比例する。
- [グローバルセカンダリインデックス](https://docs.aws.amazon.com/ja_jp/amazondynamodb/latest/developerguide/GSI.html)および[ローカルセカンダリインデックス](https://docs.aws.amazon.com/ja_jp/amazondynamodb/latest/developerguide/LSI.html)を利用する場合、writeする度に、内部的にインデックスの更新作業が走るため、writeコストが大きくなる。((プライマリキー単体と比較して、プライマリキー+ソートキーの複合キーの作成により、追加のwriteコストが発生することはないと認識しているが、ドキュメントを見つけられなかった。))

2番目、4番目、5番目の特性がwriteスループットの大きいユースケースでDynamoDB利用が割高と言われる所以である。
同条件でのread(strong consitency)とwriteの差は、アイテムサイズが最小単位の場合では5~6倍程度となる。
さらに、アイテムサイズがより大きい場合では、readとwriteの差はより大きくなる。

### 複数アイテム操作

DynamoDBは、同時に複数のアイテムを操作するAPI(BatchGetItem、BatchWriteItem)があり、これらを用いてアプリケーションの性能を改善することができる。
しかし、基本的には、キャパシティユニットの消費を抑えられるわけではないため、これらのAPIを用いてコストが下がるわけではない。
ただし、Queryについては、単一の読み取りオペレーションとして扱われる((内部的にはソートキーでソートされたSSTableのような構造になっていて、Queryは、OSのファイルシステム上で連続領域に対するreadになり、1回か少ないI/Oで読み出せるためではないかと推測している))。これについては最近まで見落としていた。
キャパシティーユニットの消費の詳細については、 <https://docs.aws.amazon.com/ja_jp/amazondynamodb/latest/developerguide/CapacityUnitCalculations.html> に書かれている。

### フィルタ式

[フィルタ式](https://docs.aws.amazon.com/ja_jp/amazondynamodb/latest/developerguide/Query.html#Query.CapacityUnits)を用いると、クライアントとDynamoDB間のネットワーク通信料を削減できる。
しかし、DynamoDB内部の読み取りオペレーションの数が減るわけではないため、キャパシティユニットの消費を抑えることはできない

### コスト試算表

以下の表では、いくつかのケースで、スループットコストを試算している。実際には、readとwriteのワークロードは両方発生するため、readとwriteのコストの合計値となる。コストはap-northeast-1のもの。

|アイテムサイズ(KB) | read or write | 秒間オペレーション数 | 読み取り整合性 | コスト(USD) |
|---------------:|:-------------:|----------------:|:------------:|-----------:|
|   1             | read          | 1000             | strong       | [100](https://calculator.s3.amazonaws.com/index.html#r=NRT&s=DynamoDB&key=calc-46219349-6EEC-4CF2-8A5D-D2F5C5B496E0) |
|   1             | read          | 5000             | strong       | [540](https://calculator.s3.amazonaws.com/index.html#r=NRT&s=DynamoDB&key=calc-31A058FB-EB8A-4A5B-AE94-F6F788B31AF7) |
|   4             | read          | 5000             | strong       | [540](https://calculator.s3.amazonaws.com/index.html#r=NRT&s=DynamoDB&key=calc-391B9C4B-48B9-4F16-A709-87F44A504B6B) |
|   40            | read          | 5000             | strong       | [5400](https://calculator.s3.amazonaws.com/index.html#r=NRT&s=DynamoDB&key=calc-C2B94E1F-14E6-4236-AE39-5DB1E46686CC) |
|   40            | read          | 5000             | eventually   | [2700](https://calculator.s3.amazonaws.com/index.html#r=NRT&s=DynamoDB&key=calc-4A75F327-E28C-43AC-B04C-B41C45FB9A7B) |
|   1             | write         | 1000             | -            | [500](https://calculator.s3.amazonaws.com/index.html#r=NRT&s=DynamoDB&key=calc-89CE36E2-6111-429B-A99A-DE63C230B544) |
|   4             | write         | 1000             | -            | [2000](https://calculator.s3.amazonaws.com/index.html#r=NRT&s=DynamoDB&key=calc-5E5BE9FE-443D-4719-A7EF-0BCD288E9C65) |
|   4             | write         | 5000             | -            | [10800](https://calculator.s3.amazonaws.com/index.html#r=NRT&s=DynamoDB&key=calc-7CA75F88-46F0-480A-B57A-967BF741A9E8) |

表をみるとわかるように、writeのコストが大きくなりやすい。

## ネットワーク

同一リージョンの他のAWSサービスとの間で転送されたデータは無料となる。S3と基本的に同じ。

ただし、プライベートサブネットにあるクライアントからDynamoDBへ転送されたデータには、[VPC NAT Gateway](https://docs.aws.amazon.com/ja_jp/AmazonVPC/latest/UserGuide/vpc-nat-gateway.html) での転送処理コストが発生する。
<https://aws.amazon.com/jp/vpc/pricing/>によると、TokyoリージョンではGB単価が$0.062であり、[AZ間通信の$0.010/GB](https://aws.amazon.com/jp/ec2/pricing/on-demand/)の6倍あるため、あなどれないコストになる。

# コスト削減策

知る限りのDynamoDBのコスト削減策を書いてみる。ここにある方法以外の策がほしい場合は、そもそもDynamoDBに向いてないユースケースか、アーキテクチャレベルで再設計する必要があるかもしれない。

## リザーブドキャパシティ

DynamoDBには、EC2のリザーブドインスタンスのように前払いにより、コストを下げるリザーブドキャパシティがある。
<https://aws.amazon.com/jp/dynamodb/pricing/>によると、前払いした分のキャパシティ消費が$0になるわけではなく、別途時間料金が設定されており難しい。
最大効率では、1年間前払いで、約50%程度の割引になり、3年間前払いでは、約75%程度の割引になるはず。

## Auto Scaling

前述したように、[DynamoDB Auto Scaling](https://docs.aws.amazon.com/ja_jp/amazondynamodb/latest/developerguide/AutoScaling.html)により、固定的なキャパシティ割り当てから、実際に消費したキャパシティユニットにより近づけることで、コスト削減できる。
ただし、一日のキャパシティ削減回数には限りがあるため、インターバルの小さいキャパシティ増減には対応できない。

## メモリキャッシュ & DAX

DynamoDBのシャーディング機構は、プライマリキーを内部ハッシュ関数への入力とし、内部的なノード配置を決定する。
したがって、特定プライマリキーにreadまたはwriteが集中すると、テーブルのキャパシティを増やしても、1つのノードの性能限界にあたってしまう。

readについては、前段にmemcachedのようなキャッシュを挟むことで対応できる。
もしくは、DynamoDBのインメモリキャッシュである[DynamoDB Accelerator](https://aws.amazon.com/jp/dynamodb/dax/)を使う。
DAXはDynamoDBのwrite throughキャッシュとして動作し、DynamoDBのストレージまで到達してから、DAX上のアイテムに書き込み、レスポンスを返す。
一方で、読み込みは、インメモリキャッシュのレスポンスを返すため、readが支配的なワークロードで効果を発揮する。
DAXの動作モデルについては、<https://docs.aws.amazon.com/ja_jp/amazondynamodb/latest/developerguide/DAX.consistency.html>が詳しい。
DAXは自分で使ったことがないので、DAXそのもののコストについては理解が浅いが、インスタンスタイプベースのコストモデルになっている。

## テーブルデータ構造

前述したようにDynamoDBは、writeが支配的なワークロードで、コストが大きくなりやすい。
しかし、メインDBとなるMySQLやPostgreSQLはwriteスケールアウトしづらいため、DynamoDBを使いたいケースにはwriteが支配的であることは多いように思う。
スループットコストの特性からみて、基本的には、writeの回数を減らすか、アイテムサイズを小さくすることで対処する。

writeの回数を減らすには、一つのアイテムに詰め込んで書き込むことになる。
しかし、単純に詰め込んでも、アイテムサイズに比例して、一回あたりの書き込みコストが増加してしまう。
そこで、例えば、1KBが最小単位なため、1KB未満のデータを書き込んでいる場合は、1KBぎりぎりのサイズになるように、データを詰め込んで書き込む。

アイテムサイズを小さくするには、なんらかの手段で圧縮し、バイナリとして書き込むという手段がある。
バイナリとして書き込む場合は、アイテムの追記が難しい。追記するには、一旦アイテムのデータを読み出してから、データを連結して書き込む必要があり、読み出しコストが余分にかかる。リスト型やマップ型の要素としてバイナリ型を使って意味があるケースであれば、素直に追記できる。

数値はおおよそのサイズが「（属性名の長さ）+（有効桁数 2 あたり 1 バイト）+（1 バイト）」と書かれており、桁数ベースなので、バイナリとして扱うほうがサイズ効率はよい。
<https://docs.aws.amazon.com/ja_jp/amazondynamodb/latest/developerguide/CapacityUnitCalculations.html>

あとは、属性名の長さがアイテムサイズに含まれるので、長い属性名を付けている場合は、短くするとよい。

## ネットワーク転送

NAT Gatewayのコストは、[DynamoDB VPCエンドポイント](https://docs.aws.amazon.com/ja_jp/amazondynamodb/latest/developerguide/vpc-endpoints-dynamodb.html)により回避できる。
S3とDynamoDBのVPCエンドポイントは、[ゲートウェイVPCエンドポイント](https://docs.aws.amazon.com/ja_jp/AmazonVPC/latest/UserGuide/vpce-gateway.html)と呼ばれるタイプのエンドポイントで、プライベートなDNSエンドポイントが払い出されるわけではなく、VPCのルーティングテーブルを変更し、L3でルーティングする。
想像したものと違ったので、面食らったが、NAT Gatewayのコストは問題なく削減できる。

# まとめ

DynamoDBのコスト構造と、自分が知るコスト削減手段を紹介した。
DynamoDBは、データモデルとコストモデルのための公式ドキュメントがもちろん揃っているのだが、計算式はそれなりに複雑になので、妥当な感覚を掴むまでに時間がかかった。
コスト見積もりし、サービスインしたのちに、実際の使用量を確認し、改善策を打つことで、徐々に理解が進んできた。
CPU、メモリなどのハードウェアベースのキャパシティプランニングとは異なり、アプリケーションロジックフレンドリーな計算モデルなため、アプリケーション開発者がコスト見積もりやスケーリング対応をしやすいサービスになっている。

ちなみにAWS Lambdaのコスト構造については、次のエントリ内で紹介している。[http://blog.yuuk.io/entry/2017/lambda-disadvantages-from-a-cost-viewpoint:title]
