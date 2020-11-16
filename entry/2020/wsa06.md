---
Title: "分散アプリケーションの異常の因果関係を即時に追跡するための手法の構想"
Category:
- SRE
- Monitoring
Date: 2020-02-14T15:18:15+09:00
URL: https://blog.yuuk.io/entry/2020/wsa06
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/26006613511915114
Draft: true
---

- 英文タイトル: A Concept of Scalable and On-time Causal Tracing for System Failures from Dependency Graphs and Monitored Metrics in Distributed Applications.
- 著者: 坪内佑樹(\*1)
- 所属: (\*1) さくらインターネット株式会社 さくらインターネット研究所
- 研究会: [第6回Webシステムアーキテクチャ研究会](https://websystemarchitecture.hatenablog.jp/entry/2019/12/11/165624)

<hr/>

<!-- 社会の背景  -->
Webサービスの普及に伴い、分散アプリケーションを構成するコンポーネント間の依存関係が複雑化している。システム管理者がシステム障害を検知するために、障害を自動で監視するシステム（監視システム）を利用する[^1]。システムに問題があれば、監視システムはメールやチャットツールなどを介してシステム管理者にアラートを通知する。

<!-- 問題意識 -->
システム管理者は、各コンポーネント内の時系列の各メトリックに対して、ツールを利用してアラート条件を設定することが一般的である。コンポーネントの個数と種類が増加すると、システム管理者はアラート条件の設定に手間を要することになる。また、実際に障害が発生すると、複数のコンポーネントがそれぞれアラート条件を満たすことがある。そのとき、システム管理者は、異なる複数のコンポーネントから同時にアラート通知を受信することになる。結果として、 システム管理者は、どのコンポーネントが障害の要因となっているかを特定することが難しくなる。
<!-- 機械学習による異常検知システムにおいても、サブシステムからアラートが通知されるのは同様である。 -->

<!-- 先行研究と課題 -->
個々のメトリックに対してアラート条件を設定せずに、各時系列メトリックを相関分析することにより、突発的変化が発生したメトリックを探索できる。よって、影響のあったコンポーネントを絞り込むことが可能となる。しかし、対象のメトリック数が増加するほど、相関分析のための処理負荷が大きくなる。また、相関分析を監視間隔ごとに実行し続けなければならないため、相関分析のための処理負荷は継続的に発生する。

<!-- 提案手法 -->
そこで、本稿では、メトリック数の増加に対するスケーラビリティと、原因分析処理の即時性をもつ因果追跡のための手法を提案する。提案する手法は、サービス全体の信頼性指標に対してのみアラート条件を設定した上で、アラートが生成されたのちに、外部からのリクエストを直接受け付ける構成要素（フロントシステム）から依存関係がある他の構成要素の信頼性指標に相関する振る舞いがないかを探索する。サービス全体および、各構成要素における信頼性指標として、リクエストのスループット、レイテンシ、エラーを計測するRED（Rate, Errors, and Duration）手法[^3]を採用する。

異常の探索手順は次のようになる。

1. あらかじめ設定したサービス全体のRED指標に対するアラートが通知される。
1. サービスの最前段のコンポーネント（起点コンポーネント）から直接依存するコンポーネントを依存関係追跡システム[^6]から取得する。
1. 起点コンポーネントと依存コンポーネントのREDメトリックに対して、相関のある振る舞いをするメトリック同士をクラスタ化する。
1. 相関のあるコンポーネント群のそれぞれを次の起点コンポーネントとして、2.~4.を依存関係ツリーの末端まで実行する。
1. 末端のコンポーネントが公開するすべてのメトリックをクラスタ化し、異常の原因を示すメトリック候補を選出する。

本手法により、サービス全体から依存関係のある構成要素へ、相関分析対象を絞り込むことから、探索が必要なメトリック数を低減させられる。結果的に、サービスの障害をより高速に復旧できる。また本手法では、アラート条件を設定するのはサービス全体のRED指標のみとなるため、システム管理者がアラート条件を設定する手間と受信するアラート通知数を低減できる。

## 関連研究

Sieve[^2]は、システム管理者が大量のメトリックから、根本原因分析などの目的に対して、有用な洞察を自動で得るためのプラットフォームである。
Sieveは、分散アプリケーションに対して、負荷テストを事前に実施し、各コンポーネントの呼び出しグラフとメトリックを記録する。
次に、メトリックの次元削減のために、コンポーネントごとに代表となるメトリックを予め選択する。
最後に、代表となるメトリック同士の依存関係を調べ、コンポーネント間の依存関係グラフを構築する。
Sieveでは、依存関係の変更前後のグラフを比較して、変更の影響度の大きいコンポーネントとメトリックのリストを抽出することにより、根本原因分析に役立てる。

しかし、Sieveは分散アプリケーションのグラフ構造の変化や公開メトリックの増減に対して、解析処理を最初からやり直す必要がある。
また、アプリケーションに対応した負荷生成のためのシステムを用意する必要がある。

## 参考文献

[^1]: Giuseppe Aceto, Alessio Botta, Walter De Donato, Antonio Pescap'e, Cloud Monitoring: A Survey, Computer Networks, vol.57, no.9, pp.2093-2115, 2013.
[^2]: Jorg Thalheim, Antonio Rodrigues, Istemi Akkus, and others, Sieve: Actionable Insights from Monitored Metrics in Distributed Systems, 18th ACM/IFIP/USENIX Middleware Conference, pp.14-27 2017.
[^3]: Tom Wilkie, The RED Method: key metrics for microservices architecture, 2017 <https://www.weave.works/blog/the-red-method-key-metrics-for-microservices-architecture/>.
[^4]: Betsy Beyer, Chris Jones, Jennifer Petoff, and others, Site Reliability Engineering: How Google Runs Production Systems, O'Reilly Media, Inc 2016.
[^5]: Brendan Gregg, Systems Performance: Enterprise and the Cloud, Pearson Education 2013.
[^6]: 坪内佑樹, 古川雅大, 松本亮介, “Transtracer: 分散システムにおけるTCP/UDP通信の終端点の監視によるプロセス間依存関係の自動追跡”, インターネットと運用技術シンポジウム論文集, 2019, 64-71 (2019-11-28), 2019年12月.

<!-- C. W. S. Emmons, and B. Gregg. A Microscope on Microservices. http://techblog.netflix.com/2015/02/a-microscope-on-microservices.html, 2015. Last accessed: September, 2017. -->
<!-- E. Haddad. Service-Oriented Architecture: Scaling the uber Engineering Codebase As We Grow. https://eng.uber.com/soa/, 2015. Last accessed: September, 2017. -->
