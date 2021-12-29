---
Title: Linux eBPFトレーシング技術の概論とツール実装
Category:
- eBPF
- Tracing
Date: 2021-12-28T16:50:58+09:00
URL: https://blog.yuuk.io/entry/2021/ebpf-tracing
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/13574176438046968896
---

eBPF（extended Berkley Packet Filter）という用語を著者が初めてみかけたのは、2015年ごろだった。最初は、eBPFをその字面のとおり、パケットキャプチャやパケットフィルタリングを担うだけの、Linuxの新しいサブシステムであろうと認識していた。しかし、実際にはそうではなかった。

システム性能の分析のための方法論をまとめた書籍Systems Performance <sup id="a1">[1](#f1)</sup> の著者で有名なBrendan Greggが、Linuxのネットワークサブシステムとは特に関係ない文脈で、古典的なシステム性能計測ツールでは計測できないことを計測するツールを作っていた。その計測ツールがeBPFという技術によって実装されていることを知ったときに、eBPFに興味をもったのだった。また、eBPFは、システム性能を調べる用途以外にXDP（eXpress Data Path）と呼ばれるプログラマブルなパケット処理機構を備えている。10年近く前に、Linuxカーネルのパケット処理機構を扱っていたことがあった (([超高速なパケットI/Oフレームワーク netmap について - ゆううきブログ](https://blog.yuuk.io/entry/2013/08/03/162715)、[GPUを用いたSSLリバースプロキシの実装について - ゆううきブログ](https://blog.yuuk.io/entry/2013/04/17/171230)、[Linuxでロードバランサやキャッシュサーバをマルチコアスケールさせるためのカーネルチューニング - ゆううきブログ](https://blog.yuuk.io/entry/linux-networkstack-tuning-rfs)))ことから、より興味を引き立てられた。

このように、6年以上前からeBPFに興味はあったものの、当時扱っていたシステムのLinuxカーネルバージョンは、eBPFをサポートしていなかったため、本格的にeBPFを学習しようとはしてこなかった。

その後、仕事の内容が研究開発に移り、特定の現場に依存する仕事がなくなった。偶然ではあるが、以前から進めていた研究のプロトタイピングで、eBPFによるカーネル内のネットワーク通信をトレースすることにより、依存関係マップを構築するための基礎技術を研究することになった。そのため、eBPFをいちから学ぶ必要があったのだが、eBPFは機能が豊富かつ開発も活発なため、まずeBPFの各機能の位置付けや歴史を知ることが難しく、さらに実際にeBPFの最新の機能を用いてアプリケーションを開発するとなると、参考文献や参考コードが少なく、それなりの困難を伴った。

[https://blog.yuuk.io/entry/2021/wsa08:embed]

その経験を踏まえて、この記事では、今年の4月にゲスト出演したポッドキャスト[e34.fm ep2](https://e34.fm/2/)のエピソードをもとに、eBPFを用いたLinuxカーネルのトレーシング技術の概要とトレーシングアプリケーションの実装プロセスを整理する。この記事がeBPF登場の動機からeBPFの基本要素とツールの実装に至るまでのガイドラインとなれば幸いである。

（extended BPFの正式略称はBPFであるため、以降では書き分ける必要がない限りBPFと表記する。）

[:contents]


## BPFとはなにか

Brendan Gregg著 "BPF Performance Tools"<sup id="a2">[2](#f2)</sup>(("BPF Performance Tools"自体については、id:go_vargoさんにより熱量のある感想が書かれている。 [BPF Performance Toolsを読んだ感想 - go_vargoのブログ](https://go-vargo.hatenablog.com/entry/2020/03/29/210304)))によると、BPFとはカーネルのプログラマビリティを高めるための汎用実行エンジンを指す。 BPFは、多種多様なカーネルやアプリケーションのイベントに対して、ミニプログラムを実行する方法を提供する。この実行方法は、ウェブブラウザ上で発火するイベントを契機にJavaScriptのコードが呼ばれる方式と類似している。[ebpf.io](https://ebpf.io/what-is-ebpf#hook-overview)では、カーネルやアプリケーションが事前定義されたフックポイント（システムコール、関数の入出力、カーネルのtracepoints、ネットワークイベント、その他）を通過したときに、BPFプログラムが実行されると説明されている。

BPFは、カーネル内にBPF独自の命令セットを解釈する仮想マシン、カーネル内の複数のミニプログラム間、あるいは、カーネル空間とユーザ空間間でデータを共有するためのストレージオブジェクト、ヘルパー関数から構成されている。BPF命令により記述されたミニプログラムをシステムコール（bpf(2)）経由でユーザ空間からカーネルへ送り込んだのちに、ミニプログラムに指定されたイベントが発火すると、ミニプログラムが実行される。この機構により、ファイルを開く、CPUが任意の命令を実行する、ネットワークパケットを受信する、といった各種イベントが発生したタイミングで、そのイベントがもつデータをもとに制約の範囲内で任意のプログラムを実行できる。

このような機構をもつBPFの主要なユースケースは、"BPF Performance Tools"<sup id="a2">[2](#f2)</sup>によるとNetworking、Observability、Securityの3点である。ebpf.io<sup id="a4">[4](#f4)</sup>でもほぼ同様に、Networking、Security、Observability & Tracingの3点が挙げられている。この記事では、Observability & Tracingの観点で、BPFをとりあげる。

## トレーシングにおけるBPFの位置付け

著者の関心対象である、クラウド上のソフトウェアを運用するオペレーターの観点で、トレーシングにおけるBPFを位置づける。

マイクロサービスアーキテクチャやコンテナオーケストレーションの普及などの要因により、クラウド上に展開されたアプリケーションの複雑化が加速している。そのため、システムのオペレーターは、システムの内部状態を把握することが難しくなっている。内部状態を知るために、システムの上位層ではAPM（Application Performance Management）や分散トレーシングといった、アプリケーションの知識を用いたトレーシング技術が発展している。その一方で、システムの下位層、コンテナやミドルウェアのようにOSカーネルの機能を直接呼び出すシステムの下位層の内部状態も把握する必要がある。

システムの下位層の状態を知るには、従来より、Linuxカーネルが標準で提供するprocfsやsysfsからファイル読み込み操作によりメトリックを取得することが一般的である。シェルの対話環境でデータを閲覧するのであれば、[Linuxサーバにログインしたらいつもやっているオペレーション - ゆううきブログ](https://blog.yuuk.io/entry/linux-server-operations)や[Linux Performance Analysis in 60,000 Milliseconds | by Netflix Technology Blog | Netflix TechBlog](https://netflixtechblog.com/linux-performance-analysis-in-60-000-milliseconds-accc10403c55)のように、古典的なコマンドを駆使する。データを蓄積するのであれば、データ収集用の常駐プロセスが中央のストレージへデータを送信する。サーバ監視サービス[Mackerel](https://mackerel.io)の場合、[mackerel-agent](https://github.com/mackerelio/mackerel-agent)と呼ばれる常駐プロセスがprocfsから直接値を読み込むか、コマンド出力を読み込んでいる。[GitHub - mackerelio/go-osstat: OS system statistics library for Go](https://github.com/mackerelio/go-osstat/)

これらのメトリックが示すものは、ハードウェアリソースの合計の使用量など限定的なものである。例えば、通信先のIPアドレスごとのネットワーク使用帯域を取得することはできない。また、数値データとしてのメトリックの取得以外に、カーネル内のスタックトレースなどプロファイリングのための出力を得ることもできない。そのため、Linuxではカーネルの内部状態をトレースするための技術（perf、ftrace、SystemTap、kprobe、uprobe、DTrace、straceなど）が古くから存在している。Linuxのトレーシング技術は、[Linuxカーネルのドキュメント](https://www.kernel.org/doc/html/latest/trace/index.html)にまとめられている。その他、[Julia Evansによるブログポスト](https://jvns.ca/blog/2017/07/05/linux-tracing-systems/)、[Jake EdgeによるLWNのポスト](https://jvns.ca/blog/2017/07/05/linux-tracing-systems/)日本語では[mm_iさんによる記事](https://mmi.hatenablog.com/entry/2018/03/04/052249)で各種トレーシング技術が視覚的に整理されている。歴史的な事情もあり、Linuxのトレーシングの各要素技術間の関係性は複雑なものとなっている。

これらのトレーシングツールは、機能が制限されているため、カーネル内の任意の複雑な構造を参照できず、カスタムのロジックを書くことが難しい。また、カーネル内でイベントが発生すると、カーネル内のバッファ経由で全てのイベントのレコードがユーザ空間のツールに送られ、ツールがレコードを解析する。そのためイベントの流量が大きい場合、カーネルからユーザ空間への転送負荷が課題となる。

従来のカーネル拡張機構である**カーネルモジュール**はカーネルのイベントソースやAPIにアクセスできるため、カーネルモジュールにより、カーネル内でイベントをフィルタリング・集約することにより、ユーザ空間へのイベントの転送負荷を抑えることも可能である。モニタリングツールの[draios/sysdig](https://github.com/draios/sysdig)は現在ではBPFで実装されているが、以前はカーネルモジュールが使用されていた。しかし、カーネルモジュールはバグ（カーネルパニック）やセキュリティの脆弱性を防ぐ機構をもたないため、安全性に課題がある。また、カーネルに含まれる不安定なABIを呼び出すこともできるため、カーネルバージョン間の移植性にも課題がある<sup id="a2">[2](#f2)</sup>。Sysdig社のブログ記事での同様の指摘がある。[Sysdig and Falco now powered by eBPF. – Sysdig](https://sysdig.com/blog/sysdig-and-falco-now-powered-by-ebpf/)

BPFは専用の仮想マシン用の命令で記述されたコードを専用の検査器が検査した上で、仮想マシンがコードを解釈するアーキテクチャをとる。これにより、カーネル内で安全なサンドボックス化された、ユーザーのカスタムプログラムを実行できる。仮想マシン用の命令セットや仮想マシンから呼び出し可能なカーネル機能へのインターフェイスはカーネル開発者により安定して維持されるため、移植性が高い。BPFにおいても、カーネル内でイベントをフィルタリング・集約したのちにユーザ空間へ転送させることができる。筆者の研究にて、カーネル内のデータの集約により、CPU負荷が低減されることを一例として確認している。[分散アプリケーションの依存発見に向いたTCP/UDPソケットに基づく低負荷トレーシング - ゆううきブログ](https://blog.yuuk.io/entry/2021/wsa08)

次の図に、BPFトレーシングの構成を示しておく。

[f:id:y_uuki:20211228160112p:plain:w480]

## BPFトレーシングの技術要素

BPFの位置付けを整理したところで、次はBPFトレーシングを理解するための各要素を説明する。

### BPFのアーキテクチャ

BPFは狭義にはLinuxカーネルに含まれる**BPF仮想マシン**を指す。BPF仮想マシンは、[BPF用の独自の命令セット](https://github.com/iovisor/bpf-docs/blob/master/eBPF.md)で表現されたコード（**BPFバイトコード**）を解釈し、カーネルが動作するプロセッサに適したネイティブ命令に変換し、カーネルにロードする。ロードされたBPFプログラムは、指定されたイベントが発生するたびに実行される。

既存のソフトウェアをユーザーが拡張できるようにするために仮想マシンを組み込み、ユーザー定義のコードを解釈するような機構は他でもみられる。例えば、RedisはLuaの仮想マシンを組み込んでおり、ユーザーがLuaで独自のコマンドを定義できる。さらに、今日のより先進的な技術にWeb Assemblyがある。

BPFバイトコードは、一般に、制約付きのC言語で記述されたBPFプログラムからLLVM/Clangコンパイラにより生成される。BPFバイトコードは、ユーザー空間から[bpf(2)](https://man7.org/linux/man-pages/man2/bpf.2.html)システムコールにより、カーネルに渡される。カーネルはBPFの検証器（**BPF Verifier**）を使用して、BPFバイトコードがカーネルをクラッシュさせずに安全に実行可能かを検証する。検査結果に問題がなければ、BPFバイトコードは**JIT（Just in Time）コンパイラ**によりネイティブ命令によるマシンコードに変換される。このアーキテクチャによる恩恵は、BPFプログラムをロードするためにカーネルを再起動する必要がないことだ。

BPF Verifierの検証内容は多岐にわたる。例えば、カーネル内でのブロックを防ぐをために、終了が保証されないループを含むプログラムは棄却される。その他、変数の初期化や境界外のメモリへアクセスしないことを保証する。BPF Verifierのさらなる詳細は、eBPFの開発者であるStarovoitovによるeBPF Summit 2021の[Safe Programs, the Foundation of BPF](https://www.youtube.com/watch?v=AV8xY318rtc)の動画で解説されている。

カーネルはBPFプログラムを実行するにあたって、そのプログラムがどのフックポイントにアタッチされるかを知る必要がある。フックポイントは**BPFプログラムタイプ**に応じて定義されている。BPFプログラムタイプは、[bcc/kernel-versions.md](https://github.com/iovisor/bcc/blob/master/docs/kernel-versions.md#program-types)には、執筆時点で22個((この表にないBPF_PROG_TYPE_TRACINGもあるため、全てのプログラムタイプが記載されているわけではないかもしれない))のプログラムタイプが記載されている。トレーシングに使用されるプログラムタイプは次のようなものである。

- Kprobeプログラム（後述）
- Tracepointプログラム（後述）
- Perf Eventプログラム
- Raw Tracepointプログラム

その他、ネットワーキングに使用されるタイプとして、NIC（Network Interface Card）からカーネルに到着したパケットに対して処理をフックするためのXDP（eXpress Data Path）がある。

**BPFマップ**はカーネルとユーザスペースの間でデータを共有するためのストレージである。配列やハッシュマップ、キュー、スタック、リングバッファなどの様々な種類のデータ構造が用意されている。BPFマップのリストは[bcc/kernel-versions.md](https://github.com/iovisor/bcc/blob/master/docs/kernel-versions.md#tables-aka-maps)に網羅されている。

BPFプログラムは、カーネルバージョンの互換性のために、カーネルが提供する安定したAPIである**ヘルパー関数**を呼び出せる。任意のカーネル関数を呼び出すことはできない。ヘルパー関数には、BPFマップにアクセスするための関数や自身のスレッドID、uid/gidなどを取得する関数などが含まれる。ヘルパー関数のリストは[bpf-docs/bpf_helpers.rst](https://github.com/iovisor/bpf-docs/blob/master/bpf_helpers.rst)にある。

### イベントソース

LinuxカーネルはBPFのフックポイントとして様々なイベントソースを提供している。イベントソースは次のような計装により利用可能となっている。

動的計装（動的トレーシングとも呼ばれる）は実行中のソフトウェアに計測ポイントを挿入する機能である。ソフトウェアが変更されずに実行されるため、計測を有効にしなければ、計測オーバヘッドはゼロになる利点がある。

Linuxカーネルの関数向けの動的計装は2004年に開発された **[Kprobe（Kernel probe）](https://www.kernel.org/doc/html/latest/trace/kprobes.html)** である。Linuxのユーザレベルの関数の動的計装は2012年に**Uprobe（User probe）** として開発された。BPFは両者をサポートしている。

動的計装の欠点は、ソフトウェアのバージョン変更によって、対象の名前やパラメータが変更されたり、対象が削除される可能性があることだ。これを回避するには、ソフトウェアのバージョンごとにトレーシングコードを書くことになる。

このようなインターフェイスの安定性の問題を解決する方法は、関数や変数名をそのままトレースするのではなく、イベント名をコード化し、開発者がそれを維持することである。このような計装方法は静的計装と呼ばれる。Linuxカーネルはカーネルレベルの静的計装用の **[tracepoint](https://www.kernel.org/doc/html/latest/trace/tracepoints.html)** とユーザーレベルの **USDT（User Statically-Defined Tracing）** をサポートする。USDTを利用するには、トレース対象のソフトウェアが個々にUSDTをサポートする必要があり、なおかつ、USDTを有効にした状態でビルドされていなければならない。

その他のイベントソースとしては、プロセッサのイベントカウンタであるPMCs（Performance Monitoring Counters）や[perf_events](https://perf.wiki.kernel.org/index.php/Main_Page)などがある。

### BCC (BPF Compiler Collection)

[BCC](https://iovisor.github.io/bcc/)はBPFアプリケーションを構築するためのコンパイラフレームワークとライブラリを含むツールキットである。[bccリポジトリには、70個以上の性能分析ツールが含まれている](https://github.com/iovisor/bcc/tree/master/tools)。

BPFを用いたトレーシングツールは、次の2つのプログラムで構成される。この2つのプログラムをあわせて、この記事では、BPFアプリケーションと表記する。

- BPFプログラム：カーネル内で実行されるプログラム。BPF命令セットへコンパイルされたコードはBPFバイトコード。
- フロントエンドプログラム：ユーザ空間で実行されるフロントエンドのプログラム。実行時に、BPFプログラムをユーザ空間からカーネルへロードする。トレーシングでは、カーネルからBPFマップ経由でトレースの結果を受け取る。

BCCでは、フロントエンドプログラムをPython、Lua、および、C++で書ける。

ディスクI/Oのサイズのカウントと分散を表示する[bitesize](https://github.com/iovisor/bcc/blob/master/tools/bitesize.py)はシンプルで理解しやすいBCCで書かれた書かれた性能分析ツールの例だ。BPFプログラムをPythonの文字列として記述して、BPFクラスの引数にその文字列を渡してオブジェクトを生成し、オブジェクト経由でヒストグラムが格納されるBPFマップにアクセスする。bitesizeはブロックデバイス層でI/Oを発行する際に通過するblock_rq_issueというtracepointをフックすることにより実現されている。

### bpftrace

bpftraceは、トレーシングのための専用のスクリプト言語を解釈・実行するためのフロントエンドツールである。bpftraceでは、制約はあるものの、フロントエンドプログラムとBPFプログラムを書き分ける必要がなく、ワンライナーでもトレーシングできる。そのため、アドホックな性能分析には最適なツールである。

bpftraceコミッタであるmm_iさんによる昨年の記事は、bpftraceの最近の動向をチェックするのにとてもよい。[bpftrace 2020 - 睡分不足](https://mmi.hatenablog.com/entry/2020/12/02/031534)

### CO-RE (Compile Once - Run Everywhere)

カーネルトレーシング用のBPFプログラムは、トレース対象のカーネルの構造体や関数の定義を参照するため、コンパイル時にそれらの宣言を含むカーネルヘッダが必要となる。しかし、コンパイルを実行するホストのカーネルと、BPFアプリケーションの配布先のホストのカーネルのバージョンが異なる場合、宣言と実際の定義が矛盾する。強引にBPFプログラムを実行すると、構造体のフィールド変数のオフセットがカーネルバージョン間で異なれば、BPFプログラムは見当違いの値を読み出すことになる。

BCCを含むこれまでのBPFアプリケーションは、同一ホスト上でBPFプログラムをコンパイルしたのちに実行している。(([Andrii Nakryikoのスライド]((http://vger.kernel.org/bpfconf2019_talks/bpf-core.pdf)では、この性質を'"On the fly" compilation'と呼んでいる。))そのため、BPFアプリケーションの配布先にコンパイルに必要なパッケージ（clang+LLVM、Linuxカーネルヘッダ）をインストールするか、または、BPFアプリケーションの配布物にこれらのコンパイル用パッケージを同梱する必要がある。これが配布物のサイズの肥大化を招く。また、ホスト上でBPFアプリケーションを起動するときに、コンパイルによる一時的なCPU・メモリ負荷が発生する。多数のホストに対して、常駐でトレーシングする場合、これらのオーバヘッドを無視できなくなることがある。

このような移植性の課題を解決するためには、一度コンパイルされたBPFバイトコードを、再コンパイルすることなく様々な配布先ホストに複製して配置するのみで動作させる必要がある。

CO-REは、コンパイル時に決定される構造体フィールド変数のオフセットなどの参照情報を、BPFプログラムの実行時にカーネルから正しい情報を照合・書き換える機構（再配置：relocation）である。CO-REの構成要素として、コンパイラ、BTF（BPF Type Format）、BPFローダー、カーネルの4つがある。コンパイラ（Clang）は、BPFバイトコードを含むELFオブジェクトファイルの再配置セクションに参照情報を記録する。カーネルは、C言語の構造体、関数、グローバル変数などの定義情報を軽量に表現可能なフォーマットBTF（BPF  Type Format）を用いて再配置情報を提供する。フロントエンドプログラムのビルド時に組み込まれるBPFローダー（libbpf）は、フロントエンドプログラムの実行時に、オブジェクトファイルの参照情報を取り出し、実行中のカーネルから提供されるBTF情報と照合し、オフセットやその他の再配置可能な情報を更新する。これらの要素技術の組み合わせにより、実行中のカーネルに適合するように調整されたBPFプログラムを得ることができる。

CO-REをサポートしたアプリケーションを動作させるには、BTFをビルトインでサポートしたカーネル、または、パッケージのインストールとカーネルの設定変更と再ビルドが必要となる。BTFがビルトインされたカーネルは、Ubuntuであれば、Ubuntu 20.10以降でサポートされる。執筆時点の最新のLTSバージョンは、そのままではBTFをサポートしないため注意する必要がある。[libbpfのREADME](https://github.com/libbpf/libbpf#bpf-co-re-compile-once--run-everywhere)により詳細な情報が記載されている。

CO-REのより深い技術詳細を知るには、Nakryikoによる次の記事をすすめる。
[BPF CO-RE (Compile Once – Run Everywhere)](https://nakryiko.com/posts/bpf-portability-and-co-re/)
また、実際にオフセットが書き換えられている要素が、nttlabs [@brewaddict](https://twitter.com/brewaddict)さんの次の記事に書かれている。 [純粋なRustへの愛を貫くため、libbpfを捨て、RustだけでeBPFを動かしたい。 | nttlabs](https://medium.com/nttlabs/bpf-co-re-618a765a110c)

## BPFトレーシングの歴史

BPFの位置付けを整理したところで、次にObservabilityの文脈におけるBPFの歴史、およびLinuxトレーシングを支える要素技術を簡単に紹介する。BPFはここ数年普及した技術であると認知されているが、その起源は1992年にまで遡る。

### 1992 cBPF (classic BPF)

BPFの最初のアイデアは、バークレー研究所のSteven McCannによる1993年の論文<sup id="a5">[5](#f5)</sup>にて提案された。パケットフィルタを効率よく実行するためには、カーネルからユーザ空間への全てのパケットを転送するのではなく、カーネル内でフィルタリングしたのちに、ユーザ空間へ転送する必要がある。スタックベースのオリジナルのUNIXのフィルタ評価器に代えて、レジスタベースのフィルタ評価器であるBPFが提案された。eBPF登場以後は、この評価器はclassic BPF（cBPF）と呼ばれている。

論文<sup id="a5">[5](#f5)</sup>の4節に、"BPF is now about two years old and has been put to work in several applications."と記載されていることから、BPFが実装されたのは1990年ごろだと推察される。

### 1997 Linux Socket Filter (LSF)

[メーリングリストの履歴](https://lists.archive.carbon60.com/linux/kernel/4376?page=last)によると、Jay SchulistがLinuxにBPFをLinux Socket Filterという名称で追加したのは、バージョン 2.1.8xであると記載されている。[Linuxカーネルバージョンの歴史](https://en.wikipedia.org/wiki/Linux_kernel_version_history)によると、2.1.8xの開発は1997年ごろである。

### 2013 eBPFの提案

2013年にAlexei StarovoitovはcBPFを拡張するためにcBPFの大幅な書き換えを提案した。[LKML: Alexei Starovoitov: [PATCH net-next] extended BPF](https://lkml.org/lkml/2013/9/30/627) そして、翌年の2014年にLinuxカーネルに搭載された。

書籍<sup id="a2">[2](#f2)</sup>の序文にて、2014年にStarovoitovはBPFを高度なネットワーキングやその他のプログラムを実行できる汎用の仮想マシンにしようと取り組んでいたと記述されている。同書の2.3節に、SDN（Software Defined Networking）の新しい方法を調査していたPLUMgrid社に勤務していたStarovoitovにより、eBPFが作られたとある。また、同書の序文で、その取り組みを聞いた著者であるGreggはBPFの上に性能分析ツールを開発することに興味を持ったと述懐している。eBPFのパッチの提案には、具体的なユースケースは述べられていなかったが、開発当時からパケットフィルタに留まらない汎用実行エンジンを目指していたことが伺える。

### 2015 BCCの開発

2015年にBrenden Blancoにより、BPFアプリケーションを構築するためのコンパイラフレームワークとライブラリを含むツールキット[BPF Compiler Collection（BCC）](https://iovisor.github.io/bcc/)が開発された。

### 2016 BPF Superpowers

2016年に開催された、Facebook主催のPerformance @ScaleにてBrendan Greggによる[Linux BPF Superpowers](https://www.brendangregg.com/blog/2016-03-05/linux-bpf-superpowers.html)と題したプレゼンテーションが披露された。タイトルが示すように、Obserbabilityの文脈でBPFの秘めた可能性が日本国内でも知られるようになったきっかけとなった。

### 2017 bpftrace

2017年にAlastair Robertsonによりbpftraceが開発された。

### 2019 CO-RE

[Linux Kernel Developers' bpfconf 2019](http://vger.kernel.org/bpfconf2019.html)にて、FacebookのAndrii Nakryikoが、BPFプログラムの移植性を向上させるための[BPF CO-REのプロジェクトを発表した](http://vger.kernel.org/bpfconf2019_talks/bpf-core.pdf)。

### 2020 BCC Pythonの性能ツールが廃止予定に

[https://brendangregg.com/blog/2020-11-04/bpf-co-re-btf-libbpf.html:embed]

BCCリポジトリにおけるPythonでの性能分析ツールのコーディングはlibbpf Cに移行するため廃止予定（deprecated）となった。BCC自体が廃止されるわけではない。移植されたBCCに含まれる性能分析ツールは、[iovisor/bccリポジトリのlibbpf-toolsディレクトリ](https://github.com/iovisor/bcc/tree/master/libbpf-tools)にある。

### 2020 クラウドネイティブにおける注目技術

クラウドネイティブ技術を推進する財団であるCNCFが主催するKubeCon NA 2020にて、CNCF TOC chairのLiz Riceにより、2021年に注目すべき5つのテクノロジーの一つとして、Web AssemblyとeBPFが挙げられていた。

[https://twitter.com/CloudNativeFdn/status/1329863326428499971:embed]

### 2021 BPF on Windows

[https://cloudblogs.microsoft.com/opensource/2021/05/10/making-ebpf-work-on-windows/:embed]

Microsoftの公式ブログで、WindowsでBPFを動作させるプロジェクトが発表された。 Windows 10 and Windows Server 2016以降でBPFがサポートされることになった。

## BPFトレーシングのプログラミング

BPFトレーシングを学ぶためのプロセスが、Greggの次の記事で述べられている。

[https://www.brendangregg.com/blog/2019-01-01/learn-ebpf-tracing.html:embed]

記事によると、初心者、中級者、上級者に分けて、次のようなステップで学んでいくとよいとある。

- 初心者：bccの性能分析ツールを動かす。
- 中級者：bpftraceのツール(スクリプト)を開発する。
- 上級者：bccのツールを開発する、bccやbpftraceに貢献する。

[eBPF Summit 2020](https://ebpf.io/summit-2020/)でLiz Riceにより発表されたビギナーズガイドには、BCCの簡単なツール開発に至るまでの最短の道案内が示されている。

[https://github.com/lizrice/ebpf-beginners:embed]

今後は、CO-REをサポートすることが推奨されていくことを踏まえると、BCC以外にCO-REに対応したツール開発が必要となるだろう。そこで、著者のBPFアプリケーションの実装経験を踏まえて、CO-REに対応したトレーシングツール開発を目指した、BPFプログラミングのプロセスを紹介する。

### 0. 何のツールをつくるかを決める

まずは、どのようなトレーシングツールをつくるかを決めるところから始まる。既存のツールと重複しないものが望ましいが、最初から新規性かつ有用性を兼ね備えるようなツールの着想に至るのは難しいだろう。

書籍<sup id="a2">[2](#f2)</sup>のPart Ⅱ: Using BPF toolsの各章末にトレーシングに関する練習問題が挙げられており、一部の問題は指示されたツールの開発である。この問題に取り組んでみるのもいいかもしれない。例えば、8.5 "Optional Exercises"のリストの3-7番目はツール開発の問題である。そのうちの4番目がおもしろそうなので、以下に引用しておく。

> 4. Develop a tool to show the ratio of logical file system I/O (via VFS or the file system interface) vs physical I/O (via block tracepoints).

### 1. トレーシング対象の発見

カーネルから何かしらの内部状態を取得したいと考えたときに、カーネルのどの関数やどの変数からトレースすればよいかは自明ではない。

まずは、kprobesとtracepointsでカーネル内のフックポイントのリストを出力し、トレース可能な対象を概観する。kprobesでアタッチ可能な関数のリストは、`/sys/kernel/debug/tracing/available_filter_functions`から読み出せる。

```shell-session
# cat /sys/kernel/debug/tracing/available_filter_functions | grep -e '^tcp_v4' | head
tcp_v4_init_seq
tcp_v4_init_ts_off
tcp_v4_reqsk_destructor
tcp_v4_restore_cb
tcp_v4_fill_cb
tcp_v4_md5_hash_headers
tcp_v4_md5_hash_skb
tcp_v4_route_req
tcp_v4_init_req
tcp_v4_init_sock
```

tracepointsのリストはbcc toolsに含まれる[tplist(8)](https://github.com/iovisor/bcc/blob/master/tools/tplist.py)の出力から得られる。システムコールはtracepointsに含まれる。
```shell-session
# tplist | grep tcp:
tcp:tcp_retransmit_skb
tcp:tcp_send_reset
tcp:tcp_receive_reset
tcp:tcp_destroy_sock
tcp:tcp_rcv_space_adjust
tcp:tcp_retransmit_synack
tcp:tcp_probe
```

実際に概観してみると、大量のフックポイントがあることがわかる。ここから望むものを発見することは難しい。しかし、なんらかの負荷想定をもっていれば、その想定からフックポイントのを絞り込める。

実際にカーネルに負荷を発生させながら、その負荷に関連するイベントソースを調べる方法がある。bcc toolsの[profile(8)](https://manpages.debian.org/experimental/bpfcc-tools/profile-bpfcc.8.en.html) では、-pオプションでPIDを指定することにより、動作中のプロセスに紐づくスタックトレースを取得できる。スタックトレースからフックポイントとして使えそうなものを発見できるかもしれない。その他のスタックトレースや関数の呼び出し回数を出力するツールは、[funccount(2)]((https://manpages.debian.org/unstable/bpfcc-tools/funccount-bpfcc.8.en.html) メモリであれば[memleak(8)](https://manpages.debian.org/unstable/bpfcc-tools/memleak-bpfcc.8.en.html)、ファイルシステムであれば[xfsdist(8)]()、[ext4dist(8)]()、ディスクI/Oであれば、[biostacks(8)]()、ネットワークの上位層のソケット層では、[sockstat(8)]()がある。bcc tools以外では、ネットワークの下位層のパケットに対しては、[@YutaroHayakawa](https://twitter.com/YutaroHayakawa)さん作の[ipftrace2](https://github.com/YutaroHayakawa/ipftrace2)も有用である。ipftrace2はカーネル内のパケットのフローを関数単位で追跡できる。

フックポイントに見当をつけたのちに、そのフックポイントの詳細を調べる。まず、tplist(8)により、フックポイントの引数の名前と型を確認する。
```shell-session
# tplist -v syscalls:sys_enter_read
syscalls:sys_enter_read
int __syscall_nr;
unsigned int fd;
char * buf;
size_t count;
```
次に、[argdist(8)]()により引数の値と返り値の分散を確認できる。フックポイントの通過頻度が小さければ、[trace(8)]()で個々のイベントを出力することもできる。最後に、bpftraceを使用してフックポイントに対して簡単に処理を書いてみることもできる。[bpftraceのリファレンスガイド](https://github.com/iovisor/bpftrace/blob/master/docs/reference_guide.md)にあるように、さまざまなユーティリティ関数が揃っている。

### 2. BCCによるプロトタイピング

bccリポジトリ内の性能分析ツールが非推奨になったとはいえ、BCCはプロトタイピングに有用だ。BCCであれば、BPFプログラムとフロントエンドプログラムの両方を1枚のスクリプト内に収められるため、試行錯誤を速められる。例えば、BPFプログラムはPythonの文字列として記述されるため、フロントエンドへの入力に応じて、文字列処理で簡単にBPFプログラムを動的生成できる。mapへのアクセスも、libbpfを直接使うより簡単に書ける。 BCCの機能は、[BCCのリファレンスガイド](https://github.com/iovisor/bcc/blob/master/docs/reference_guide.md)に整理されている。

id:chikuwait:detail さんの[「おいしくてつよくなる」eBPFのはじめかた](https://speakerdeck.com/chikuwait/learn-ebpf)の中盤から終盤にかけて、Hello World、TCPコネクションのトレース、コンテナ判定を題材として、BCCによるプログラミングのステップが図解されている。

著者はいきなり最終ステップであるlibbpf + CO-REから書き始めたが、一旦BCCでプロトタイプを作成したのちに、libbpf + CO-REで実装すればよかったと後悔した。

### 3. libbpf + CO-RE

Nakryikoによる[Building BPF applications with libbpf-bootstrap](https://nakryiko.com/posts/libbpf-bootstrap/)の記事にlibbpfベースのBPFアプリケーションの構築方法がまとめられている。同時に、[libbpf + Cに移植されたbcc toolsのソースコード](https://github.com/iovisor/bcc/tree/master/libbpf-tools)が具体例として参考になる。これらのリソースがなければ、著者は実装がおぼつかなかっただろう。ただし、Nakryikoの記事は古いバージョンのlibbpfを基に書かれているため、[libbpf 1.0](https://github.com/libbpf/libbpf/wiki/Libbpf%3A-the-road-to-v1.0)以降では一部のAPIの仕様が変更されていることに留意しなければならない。

BPFは開発が活発なため、カーネルの細かなバージョンごとに利用可能な機能に差異がある。[BPFの機能とカーネルバージョンとの対応表](https://github.com/iovisor/bcc/blob/master/docs/kernel-versions.md)があるため、サポートするカーネルバージョンを決めてからどの機能を利用するかを見当するとよい。

余談だが、CO-REの機構を使わずに、異なるカーネルバージョンに対応する方法もなくはない。[weaveworks/tcptracer-bpf](https://github.com/weaveworks/tcptracer-bpf)では、既知のパラメータ（既知のIPアドレスやポートなど）で一連のTCP接続を作成し、それらのパラメータがカーネルのstruct sock構造体のフィールドオフセットを検出している。[datadog-agent](https://github.com/DataDog/datadog-agent)でも

### Go言語によるBPFプログラミング

Prometheusに代表されるように、Goで書かれたObservabilityツールは多数存在する。GoでBPFのフロントエンドを書きたいというニーズもあるだろう。

GoでBPFのフロントエンドを書くには、以下のライブラリのいずれかを使うことになる。フロントエンドのBPFライブラリに最低限必要な処理は、(1)BPFバイトコードとmapのカーネルへのロードと、(2)mapの操作である。

- [iovisor/gobpf](https://github.com/iovisor/gobpf): BCCのGoラッパー
- [dropbox/goebpf](https://github.com/dropbox/goebpf): libbpfを使わず自前でbpfシステムコールを呼ぶ
- [cilium/ebpf](https://github.com/cilium/ebpf): Pure Go
- [DataDog/ebpf](https://github.com/DataDog/ebpf): cilium/ebpfからforkされ、BPFオブジェクトのライフサイクル管理マネージャーが追加されている。
- [aquasecurity/libbpfgo](https://github.com/aquasecurity/libbpfgo): 元はセキュリティランタイムの[Tracee](https://aquasecurity.github.io/tracee/latest)用のlibbpfのGoラッパー。
- libbpf + cgo bindings

カーネルが提供するBPFの最新の機能を使いたければ、カーネルのアップストリームでメンテされているlibbpfを使う。Goからはcgoを使用してlibbpfのAPIを呼び出す。libbpfをGoのバイナリに含めるには、libbpfを静的リンクさせる。具体的には、[libbpfの静的ライブラリファイル（.a）をCGO_LDFLAGSで指定してビルド](https://github.com/yuuki/go-conntracer-bpf/blob/e36514323db7b9b84abdced2ba0710ac5468f8d0/Makefile#L89-L94)する。libbpfはlibelfとlibzに依存するため、これらのパッケージがインストールされていない環境を想定するなら、libelfとlibzも自前でビルドしてバイナリに含める。

libbpf APIを自前で呼び出すのが手間であれば、aquasecurity/libbpfgoを使う。ただし、libbpfの全てのAPIがラッピングされているわけではないため、使いたいAPIがサポートされているかを確認しなければならない。

Pure Goのライブラリが使いたければ、cilium/ebpfかDataDog/ebpfを使う。ただし、執筆時点では、[CO-REに対応しきれていないなどの課題](https://github.com/cilium/ebpf/issues/114)がある。

Go + BPFについては、次の記事にも整理されている。
[Getting Started with eBPF and Go | networkop](https://networkop.co.uk/post/2021-03-ebpf-intro/)

また、XDPにフォーカスしたときのGoライブラリの選択については、[@takemioIO](https://twitter.com/takemioIO)さんによる次の記事が参考になるだろう。[Go+XDPな開発を始めるときに参考になる記事/janog LT フォローアップ - お腹.ヘッタ。](https://takeio.hatenablog.com/entry/2021/01/26/180129)

### Rust言語によるBPFプログラミング

システムソフトウェア用のプログラミング言語としてRustが人気である。RustでBPFプログラミングをしたいという人は多いだろう。著者はRustのプログラミング経験はほとんどないため、既存のリソースを簡単に紹介するにとどめておく。

[libbpf/libbpf-rs](https://github.com/libbpf/libbpf-rs)はlibbpfのRustラッパーである。libbpfには依存するが、libbpfの最新の機能が使いやすい。

[aya-rs/aya](https://github.com/aya-rs/aya)はRustでフロントエンドプログラムを書くための最近のBPFライブラリだ。ayaにより、libbpfにもbccにも依存せずに、libcのみの依存で、CO-REに対応したバイナリを生成できる。

[foniod/redbpf](https://github.com/foniod/redbpf)は、フロントエンドではなく、BPFプログラムをRustで書くためのツールとライブラリである。

その他、RustによるBPFトレーシングについて、id:udzura:detail さんの次のスライドが参考になる。[Rustで作るLinuxトレーサ / libbpf-core-with-rust - Speaker Deck](https://speakerdeck.com/udzura/libbpf-core-with-rust)

### BPFプログラミングの留意事項

著者が気づいた範囲でのBPFプログラミングの留意事項を紹介する。

**カーネル・ユーザ間並行性** すでに述べたように、BPFアプリケーションはカーネルとユーザ空間の2種類のプログラムがmapやring bufferなどのカーネル内のデータ構造を経由して、一方向または双方向にデータを共有する。そのため、カーネルとユーザのそれぞれのプログラムで並行して処理が行われる。トレーシングでは、カーネルはMAPにデータを更新し、ユーザがMAPの読み終わったデータを削除することもあるため、書き込み競合が発生する可能性がある。[BPF_LOOKUP_AND_DELETE_BATCHなどのアトミックなAPIを使用して回避できる](https://github.com/iovisor/bcc/blob/629d40a34dd766ed1e962a6aff713a9c4e7e61bd/libbpf-tools/syscount.c#L199-L200)。

**カーネルスレッド間並行性** カーネルでは複数のスレッドが協調して動作しており、スレッド間で並行処理が行われる。kprobeとtracepointでアタッチされたBPFプログラムが、異なるスレッドから同時に呼び出されることを考慮する必要がある。mapの構造体のフィールド変数のインクリメント操作などは、アトミックに更新する必要がある。アトミックな更新には、[__atomic_add_fetch()](https://github.com/iovisor/bcc/blob/3e8eb8b62f6e92aef332b2eab48305220705dfae/libbpf-tools/tcpconnect.bpf.c#L98)を使用できる。

## まとめ

この記事では、BPFの定義から始まり、トレーシングの文脈でのBPFの位置付け、BPFトレーシングを構成する技術要素、BPFとBPFトレーシングの歴史、BPFトレーシングツールのプログラミングまでを概観した。BPFでツールをつくってみたいと思い立ったときに、実装の細部の試行錯誤以外では、迷いがないように体系的な知識として整理されるように心がけた。

来春のUbuntu 22.04 LTSのリリースをきっかけに、今後は、デフォルトでCO-REをサポートする環境が増えていくはずだ。それに伴い、BPFトレーシングツールのデプロイが容易になるため、BPFトレーシングは一層普及していくだろう。

## あとがき

冒頭で述べたように、研究開発向けに着想した手法を実装するために、BPFを学習する必要があった。OSに近しい低レイヤのプログラミングは好きではあるものの、得意というほどでもないため、それなりの学習コストがあった。C言語は8年ぶりぐらいに書いたように思う。BPFのC言語は制約が強く、コードに明らかな欠陥があればBPF Verifierが検出してくれるため、C言語自体にはそれほど苦労しなかった。カーネルのコードのどの箇所をフックするか、どの変数から必要なデータを読み出すかといったコードの理解により苦労した。

今年の前半にBPFの話を仲間内でしていたら、[@deeeet](https://twitter.com/deeeet)と[@rrreeeyyy](https://twitter.com/rrreeeyyy)がホストするe34.fmに出演させてもらった。このときに、BPFの基本と応用例をそれなりに調査していたので、そのうち、テキストにまとめようと思ったものの、そのままになっていた内容を今年のうちにまとめることができてよかった。e34.fmでは触れらなかったBPFトレーシングの実装に踏み込んだ話も整理できた。

今年の春頃から、前職の同僚たちによるBPF Performance Tools<sup id="a2">[2](#f2)</sup>の輪読会に参加させてもらっている。この本の後半は、CPU・メモリ・ファイルシステム・ディスク・ネットワークについて、BCCの性能分析ツールがひたすらに紹介されている。ひとつずつ読んでいくのが苦行に感じてはいるものの、BPFトレーシングでどういうことができるのか、トレーシング結果の表示形式、トレーシングのオーバヘッド、kprobeとtracepointのそれぞれにアタッチしたときの利点と欠点の肌感をおかげで掴めつつある。（Thanks to id:masayoshi:detail, id:dekokun:detail, id:hokkai7go:detail, id:hayajo_77:detail）

この輪読会のなかで、6年以上前の時系列データベースのディスクI/O関連のトラブルシューティングに、BPFが使えていればなあと何度も吐露していた[Mackerelにおける時系列データベースの性能改善 / Performance Improvement of TSDB in Mackerel - Speaker Deck](https://speakerdeck.com/yuukit/performance-improvement-of-tsdb-in-mackerel)。とはいえ、kprobeやtracepointはそれ以前から存在していたので、perfやSystemTapを使いこなせていれば効率よくトラブルシュートできていたかもしれない。

今後はBPFを活用していきたい一方で、2010年代後半のBPFが普及した時期と同時期に、クラウドの分野では、OSよりも上位層のソフトウェアを抽象化してサービス化するマネージドサービスが普及していることは見逃せない。多くのマネージドサービスは、利用者がLinuxカーネルがアクセスことを制限しているため、BPFを使おうと思っても使えないか、使う必要すらないこともある。マネージドサービスは極めて便利で、実務上は使わない手はないのだけど、システムソフトウェアの領域で、自分のアイデアでなにかをつくれるような余地が徐々に狭まっているように感じる自分もいる。実務上の利便性を無視することは難しいが、BPFやWASMのようなユーザーが拡張可能な技術の上に、システムソフトウェアに関心のある研究者や技術者が自分のアイデアを創造できるような世界であってほしいと願う。

## 参考文献

- <b id="f1">[1]</b>: Brendan Gregg, "Systems Performance", Pearson, ed. 1st, 2013. [↩](#a1)
- <b id="f2">[2]</b>: Brendan Gregg, "BPF Performance Tools", Addison-Wesley Professional, 2019. [↩](#a2)
- <b id="f3">[3]</b>: David Calavera, and Fontana Lorenzo, "Linux Observability with BPF: Advanced Programming for Performance Analysis and Networking", O'Reilly Media, 2019. [↩](#a3)
- <b id="f4">[4]</b>: The Linux Foundation, eBPF - Introduction, Tutorials & Community Resources, <https://ebpf.io/>, 2021. [↩](#a4)
- <b id="f5">[5]</b>: Steven McCanne, and Van Jacobson, "The BSD Packet Filter: A New Architecture for User-level Packet Capture." USENIX winter. Vol. 46. 1993. [↩](#a5)
