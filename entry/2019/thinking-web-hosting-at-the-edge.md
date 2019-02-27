---
Title: エッジコンピューティング環境でのウェブアプリケーションホスティング考
Category:
- Edge Computing
- Data Intensive
CustomPath: 2019/thinking-web-hosting-at-the-edge
---

[さくらインターネット研究所](https://research.sakura.ad.jp/about/)では、[超個体型データセンター](https://research.sakura.ad.jp/2019/02/22/concept-vision-2019/)というコンセプトに則り、あらゆるデバイスと場所がデータセンターとなり、各データセンターが有機的に結合した集中と分散のハイブリッド構造をもつコンピューティングを目指している。
超個体型データセンターにとって、重要な先行コンセプトに、エッジコンピューティングがある。
この記事では、エッジコンピューティング環境において、ウェブアプリケーションをホスティングするためのアーキテクチャを考察する。

# エッジコンピューティング

Kashifらのサーベイ論文[^1]によると、エッジコンピューティング技術を必要とする背景は、次のようなものになる。
スマートデバイス、ウェアラブルガジェット、センサーの発展により、スマートシティ、pervasive healthcare、AR、インタラクティブなマルチメディア、IoE(Internet of Everything)などのビジョンが現実化しつつあり、レイテンシに敏感で高速なレスポンスを必要とする。
従来のクラウドコンピューティングでは、エンドユーザーや端末とデータセンターとの間のネットワークレイテンシが大きいという課題がある。
そこで、この課題を解決するために、エッジコンピューティングでは、ネットワークのエッジやエンドユーザーとクラウドデータセンターの間の中間層を設けることにより、レイテンシの最小化とネットワークの中枢の下りと上りのトラフィックの最小化を目指す。 ([https://memo.yuuk.io/entry/2019/learning-edge-computing01:title])

エッジコンピューティングは、ある一つの形態があるのではなく、複数のコンピューティング形態を内包する。
先のサーベイ論文は、エッジコンピューティング技術としてFogコンピューティング[^2]、Cloudlets[^3]、Mobile Edge Computing(MEC)[^4]、Micro Data Centers[^5]の4つが紹介されている。
エッジと呼ぶものの実態は、ルーターやアクセスポイントであったり、基地局に付随する小さなクラウド環境であったり、単独の小さなデータセンターであったりする。
エッジコンピューティングの典型構成は、端末 - エッジ - クラウドの3-tier構造であり、P2Pのような強い分散構造ではなく、端末とエッジの分散構造とクラウドの集中構造を併せ持つ。
エッジコンピューティングを利用したアプリケーションでは、エッジでは端末から収集した情報をフィルタリングしつつクラウドへ転送したり、アクチュエーターの制御のために端末の情報をもとに別の端末へ制御命令を送るといった処理フローが想定されている。

<!-- ここでのリアルタイムアプリケーションの想定応答時間は25-50msであり、クラウドには到達できない。 -->

エッジコンピューティングでは、[https://memo.yuuk.io/entry/2019/learning-edge-computing02:title]で紹介したように、インタラクティブな動画コンテンツ、ウェアラブルコンピューティング、クラウドゲーミング、スマートリビング、スマートグリッド、医療モニタリング、5Gなど、現場にあるものをリアルタイムに制御する必要があるアプリケーションが想定されている。
これらのアプリケーションの端末までの想定応答時間は25-50ms程度であり、クラウドへ到達できないほどのシビアな要求となる。
これらのアプリケーションは、現場にある大量のデータを収集し、それらの情報をもとに分析をしたり、なんらかの制御を実行したりするデータインテンシブなアプリケーションといえる。

エッジコンピューティングは、このようなリアルタイムアプリケーションをメインターゲットとする一方で、これまでクラウド上でホスティングされてきた伝統的なウェブアプリケーションの応答速度を高める可能性がある。
クラウド環境が前提となるウェブアプリケーションは豊富なハードウェアリソースを必要とするため、CloudletsやMicro Data Centers (以降、MDCsとする)のような小規模データセンター環境で動作させることを目標とするのが妥当である。
エッジコンピューティングの目的であるエンドユーザーとのレイテンシの削減を達成するためには、ユーザーがどこにいても、近傍にデータセンターが存在しなくてはならないため、MDCsが地理的に遍在している状況を仮定する。
そこで、クラウドとMDCsを併用する環境を利用し、WordPressのようにデータをRDBMSに格納する伝統的なウェブアプリケーションの応答速度を向上させる手法を考察する。

# エッジ環境におけるウェブアプリケーションホスティングの課題

## ウェブアプリケーションの構成パターン

伝統的なウェブアプリケーションは、ウェブサーバ、アプリケーションサーバ、データベースサーバの3-tier構造により構成される。
この3-tier構造をエッジコンピューティング環境で構成するパターンは次の3つである。

- (a): 3-tier構造をすべてMDCsに配置。
- (b): ウェブサーバとアプリケーションサーバをMDCsに配置し、データベースサーバをクラウドに配置。
- (c): ウェブサーバをMDCsに配置し、アプリケーションサーバとデータベースサーバをクラウドに配置。

パターン(a)については、エッジ環境にてtier要素をすべて配置することにより、応答時間を短縮できる。
しかし、データベースサーバを分散することになり、各データベースサーバの一貫性を維持するためのプロトコルが必要となる。
具体的に一貫性を維持する状況として、各アプリケーションサーバがローカルのデータベースに書き込むときに、他のMDCのデータベースとの間で書き込み競合がある。
または、書き込み競合を避けるために、各MDC上のアプリケーションサーバがクラウド上のデータベースサーバのみに書き込み、ローカルのデータベースから読み出すように構成し、読み込みクエリのみを高速化かつスケールする手法もある。
つまり、クラウド上のデータベースサーバを単一のリーダー(マスター)として、MDC上のデータベースサーバをフォロワー(スレーブ)とし、フォロワーには読み込みクエリのみを向ける。
しかし、この手法も、Read-after-write consistency[^7]、Monotonic reads[^8]などのレプリケーション遅延により引き起こされる異常がある。

エッジコンピューティングのように、クラウド内通信と比較し通信レイテンシの大きい環境では、書き込みが全ノードに伝搬する前に別のノードが次の書き込みを処理する可能性が高くなるため、一貫性を維持することがより難しくなるはずである。
一般にこのような一貫性の問題に対して、データベースミドルウェアのみで解決することは難しく、アプリケーション仕様やコードにて一貫性のための考慮が必要となる。

パターン(b)については、アプリケーションサーバとデータベースサーバ間のレイテンシが大きいという性質がある。
アプリケーションサーバが動的コンテンツを生成したり、API処理をするには、1回以上データベースに問い合わせすることになる。
したがって、ユーザーとウェブサーバ間でHTTPのリクエストとレスポンスを1往復する処理の間に、アプリケーションサーバからデータベースサーバへのクエリと結果取得の往復が少なくとも1回以上あるため、クラウドのみのパターンと比較し、却って応答が遅くなる可能性がある。

パターン(c)については、ウェブサーバとアプリケーションサーバ間のレイテンシが大きいという性質がある。
HTTPリダイレクトや静的コンテンツの配信など、ウェブサーバのみで完結する処理については、ユーザーの近傍で処理が完結するため、パターン(c)は高速となる（ただし、パターン(b)も同様）。
また、ウェブサーバとアプリケーションサーバ間の接続を永続化することにより、TCPの3-wayハンドシェイクのためのラウンドトリップ時間を抑えられる。
ウェブサーバとアプリケーションサーバ間はHTTPの往復は1回となるため、パターン(b)のように却って応答が遅くなることはない。
しかし、アプリケーションサーバがウェブアプリケーションとしての処理の大部分を実行するという前提を置くと、エッジコンピューティングの利点をあまり生かせない構成といえる。

[f:id:y_uuki:20190226163356p:image:w400]
(図1: エッジ環境におけるウェブアプリケーションホスティング構成)

## ウェブアプリケーションの分類

### アクセスパターン

ウェブアプリケーションをアクセスパターンにより分類すると、ブログシステムのような読み込み処理主体のRead Heavyアプリケーションと、ソーシャルゲームのような書き込み処理主体のWrite Heavyアプリケーションがある。
Read Heavyアプリケーション

- 地域による参照局所性

# アーキテクチャ

エッジコンピューティングがもつエンドユーザーとのレイテンシ最小化の利点を活かすには、Read Heavyアプリケーションに対して、構成パターン(a)または(b)を適用することになる。
データの複製、クエリの結果のキャッシュ、バッファプールを各MDC間で協調して同期することにより、それぞれの構成の課題を解決する。

## 分散クエリキャッシュ

分散クエリキャッシュの先行手法として,
Ferdinand[^9]がある。
Ferdinandは、各アプリケーションサーバがキャッシュをローカルに持ち Publish/Subscribeにより、アプリケーションサーバ群が協調してキャッシュを同期する。これにより、中央のデータベースサーバの負荷を削減し、スループットを向上させている。

エッジ環境では、エッジ数の個数の増加とエッジ間やエッジ・クラウド間のネットワークがレイテンシが大きいかつ不安定になることが想定される。
キャッシュもっともレイテンシ

- プロキシ型
- コネクションプーリング https://blog.yuuk.io/entry/architecture-of-database-connection
- キャッシュストア B-treeArray 
https://github.com/sysown/proxysql/blob/89e31bf972110edf68ebd1f3950ceb25056452cc/include/query_cache.hpp#L35
- キャッシュインとアウトの同期
  - LAN Gossip & WAN Gossip https://www.consul.io/docs/internals/architecture.html

## 分散バッファプール

分散クエリキャッシュは、RDBMSのテーブル単位でキャッシュを失効させるために、行単位と比較し、キャッシュヒット率が低いという課題がある。
しかし、〜があり、より小さな粒度でキャッシュを失効させることは難しい。
そこで、RDBMSを構成する部品のうち、バッファプールをエッジに配置し、ストレージエンジンをクラウドに配置する構成をとることにより、バッファプール内のデータを前段のエッジで返却できるようにする。
さらに、エッジに分散された各ノードのバッファプールデータの一貫性を保つために、Pub/Subにより同期する。

- 分散バッファプール
- Buffer pool の一貫性


- キャッシュ同期 一貫性 アプリケーション変更しないように
- リアクティブ性: キャッシュがないうちは、クラウドへ接続 クラウド上でキャッシュを作成し、クラウドからエッジへキャッシュ同期しリアクティブ
  - 端末近傍のエッジを覚えておくシステムがいる


# まとめと今後の展望

エッジコンピューティングは、レイテンシの大きな地理分散環境を前提とする。
したがって、データセンター内の分散システムと比較し、分散システムの各透過性の要件を満たすことが難しい。

- 実装と評価を進める
- エンドユーザーやエンドデバイスが、近傍のエッジを発見するサービスディスカバリのためのアーキテクチャが必要となる。
  - DNS anycast

# 参考文献

[^1]: Bilal Kashif, Khalid Osman, Erbad Aiman, Khan Samee U, "Potentials, Trends, and Prospects in Edge Technologies: Fog, Cloudlet, Mobile edge, and Micro data centers.", Computer Networks, vol. 130, pp.94-120, 2018.
[^2]: Flavio Bonomi, Rodolfo Milito, Jiang Zhu, and Sateesh Addepalli, "Fog Computing and Its Role in the Internet of Things.", first edition of the MCC workshop on Mobile cloud computing, pp.13-16, 2012.
[^3]: Mahadev Satyanarayanan, Paramvir Bahl, Ram'on Caceres, and Nigel Davies, "The Case for VM-based Cloudlets in Mobile Computing.", IEEE Pervasive Computing, vol. 4, pp.14-23, 2009.
[^4]: Michael Till Beck, Martin Werner, and Sebastian Schimper Feld, Mobile edge computing: A Taxonomy, Sixth International Conference on Advances in Future Internet (AFIN), pp.48-55, 2014.
[^5]: V. Avelar, Practical Options for Deploying Small Server Rooms and Micro Data Centers, Revision 1, White Paper [online] Available: <http://www.datacenterresearch.com/whitepaper/practical-options-for-deploying-small-server-rooms-and-micro-9014.html>, 2016.
[^6]: Sharad Agarwal, Matthai Philipose, and Paramvir Bahl, "Vision: the case for cellular small cells for cloudlets", Fifth International Workshop on Mobile Cloud Computing & Services, pp.1-5, 2014.
[^7]: Douglas B. Terry, Alan J. Demers, Karin Petersen, et al., “Session Guarantees for Weakly Consistent Replicated Data”, 3rd International Conference on Parallel and Distributed Information Systems (PDIS), 1994.
[^8]: Douglas B. Terry, “Replicated Data Consistency Explained Through Baseball,” Microsoft Research, Technical Report MSR-TR-2011-137, 2011.
[^9]: Charles Garrod, Amit Manjhi, Anastasia Ailamaki, Bruce Maggs, Todd Mowry, Christopher Olston, and Anthony Tomasic, “Scalable Query Result Caching for Web Applications”, VLDB Endowment, vol. 1, no. 1, pp.550-561, 2008.

<!-- [^7]: Shubham Agarwal, Sarvesh SS Rawat and V Sumathi, "A Drawing Robotic Hand Based on Inverse Kinematics", 
International Conference on Information Communication and Embedded Systems (ICICES), pp. 1-5, 2014 -->

<!-- [^5]: Mohammad Aazam and Eui-Nam Huh, "Dynamic Resource Provisioning through Fog Micro Datacenter", IEEE International Conference on Pervasive Computing and Communication Workshops (PerCom workshops), pp.105-110, -->
 
