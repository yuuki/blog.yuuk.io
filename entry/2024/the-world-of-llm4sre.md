---
Title: “LLM for SRE“の世界探索
Category:
- SRE
- LLM
- 研究
Date: 2024-03-20T22:57:47+09:00
URL: https://blog.yuuk.io/entry/2024/the-world-of-llm4sre
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/6801883189092352135
Draft: true
CustomPath: 2024/the-world-of-llm4sre
---

ChatGPTが登場した当初、対話や要約、翻訳、コード生成などの典型的な言語タスクができても、SREやAIOpsの研究開発にはあまり関係ないのではないかと正直思っていた。AIOpsでは典型的にはいわゆるObservabilityデータ（メトリクス、ログ、トレースなど）が入力となるため、自然言語ではなく数値のデータを解析することが求められる。自然言語のタスクを研究対象としていなかったため、AIOpsとChatGPTに強い関係性は見いだせなかった((ちょうど１年前にGPT-4が公開された際に、メトリクスの数値列をプロンプトに含めて遊んでみたときの印象はこちら <https://twitter.com/yuuk1t/status/1636758804535869442?s=20>。))。

しかし、自分で大規模言語モデル（Large Language Model: LLM）を日常的に使用したり、表題にあるようにSREのためのLLM（LLM for SRE, LLM4SRE）に関する論文を読むうちに、LLMのテキスト生成器としての性質よりもその優れた推論機械としての性質に注目するようになった。特にSREの障害診断は、人間の専門家が推論と、ツールを介したデータ取得とシステム操作を反復する試行錯誤のプロセスである。

この記事で紹介する論文のうち、RCAgentとD-Botは、実世界のデータの検索器とシステム操作のためのツールによりLLMを拡張し、反復的な推論や複数のLLMの協調を実現している。それはまさに、**熟練のエンジニアが障害に対応する際に、事前にもつ知識とその場の調査内容を基に推論を重ねて原因を特定する様を連想する**。自分の過去のエンジニアとしての経験からも、これならたしかに多くのケースで原因特定が可能だと直感する。もちろん、実世界に展開可能となるまでにはまだ時間がかかるだろう。しかし、これまで自分が暗黙に考えていた限界のようなものを超えられるかもしれない、そう感じるおもしろいものに出会ったと感じている。

この記事では、この自分が感じたおもしろさを共有するために、ITシステムの障害診断をLLMにより自動化する手法に関する最新の研究動向を俯瞰して探索していきたい。

## はじめに

SREでは、オンラインサービスのテレメトリデータ（メトリクス、ログ、トレース、イベントなど）やインシデントデータ（アラート、チケット、ポストモーテムのテキストなど）を機械学習、統計、データマイニングの技術により解析し、障害管理（Failure Management）を自動化する研究が盛んである。自分も、SREの国内カンファレンスSRE NEXT 2022で、それらの研究の一部を発表した((https://speakerdeck.com/yuukit/sre-next-2022))。これらの研究で提案されているほとんどの手法は、時系列データなどの多変量データの数値解析に基づき、障害検知、障害原因特定、障害緩和などのタスクを実行するものである。

GPTに代表されるLLMの目覚ましい進歩により、一つのモデルが様々なドメインの、様々な下流タスクを解決できるようになってきている。また、LLMの知識だけでなく、LLMがもつ世界理解と世界理解に基づく汎用的な推論能力の高さも注目されている。一方で、SREのドメインでは、LLMは、SREの一般的知識を公開文書やコードなどから事前に獲得しているものの、SREの専門家ほどの細部の知識はない。特に企業内で管理されている産業秘匿データ（テレメトリデータやインシデントデータ）を当然ながら学習していない。そのため、グローバルな学習データに基づくその汎用的な知的能力を基に、ローカルなドメイン知識も加えてLLMに学習させる必要がある。


（図１：LLMによる原因診断論文の発表タイムライン）

ソフトウェアエンジニアリングの分野においても、プログラムコードの生成を中心にLLMの活用が進んできている。ソフトウェアエンジニアリングの一分野であるSRE（Site Reliability Engineering）の分野では、LLMに基づくSREへのアプローチ、特にクラウド上に展開されるシステムに発生する障害診断をLLMにより自動化するアプローチが研究されている。図１にLLMに基づく障害診断法を提案する論文が最初に発表された時期を次の図に時系列順にプロットした。2022年11月のChatGPTのローンチ後に次々とLLM4SREの障害管理をテーマとする論文が発表されている。

SREのドメインでは、産業データを扱うため、専門性や機密性が高く、バニラLLMの事前学習データでは不足する課題がある。研究者らは、まずLLMにドメイン特化のデータを追加で学習させるファインチューニングに着目する。その後、ファインチューニングの計算コストとハルシネーションを避けるために、その後、LLMのプロンプトに学習データを例示する文脈内学習（In-Context Learning）や、LLMが外部知識や外部ツールにアクセスするアプローチに移行している。これらのアプローチでは、SRE固有の一般的なドメイン知識を検索したり、ローカルのシステムが保持するデータ（過去のインシデント、テレメトリなど）をLLMのプロンプトに注入する。

しかし、これらの研究のうちMicrosoftやAWS、Alibabaといった大手事業者の研究グループが発表した論文でさえ、英語圏も含めたSNS上でほとんど注目されていない。そこで、クラウドの障害の原因診断・復旧のためのオペレーションの自動化を提案する複数の論文を自分が調査・整理した内容を紹介する。これは、自分が知る限り英語圏も含めて、LLM4SREの研究論文に関する初の包括的な調査となる。

この記事の残りを次のように構成する。まず、LLMを使用するために必要となる基本用語を整理する。次に、LLM4SREの障害診断技術を提案する論文を複数の異なる区分で分類する。さらに、代表的な論文のそれぞれの概要と感想を述べ、最後に今後の方向性をまとめる。

## LLMの基本用語

[東京大学の松尾研究室主宰のLLM講座資料](https://weblab.t.u-tokyo.ac.jp/llm_contents/)と[Prompt Engineering Guide](https://www.promptingguide.ai/)を基に、LLMの技術用語を整理する。ここでは、後述する論文に登場する用語の紹介のみに留める。この記事で登場する用語は大きく分けて３つのカテゴリがあり、「ファインチューニング」、「プロンプティングと文脈内学習」、「拡張言語モデル」である。

### ファインチューニング（Fine-Tuning）

LLMの学習は、1) 語彙・文法・知識・推論能力などの基本的な言語能力を、言語モデルに導入する事前学習と、2) 事前学習済みモデルの性能改善や様々なタスクに対する適応を実現するファインチューニングや事後学習、の大きく２段階で構成される。

LLMの文脈におけるファインチューニングは、事前学習済みモデルの出力内容や形式を用途に応じて調整・制御したり、事前学習済みモデルの未知タスクに対する性能を改善することを目的とする。学習の方法は、指示文を入力し、それに対する理想的な出力文を正解とした教師あり学習となる。これは**Instructution Tuning**（"Finetuned Language Models Are Zero-Shot Learners", 2021）と呼ばれる。LLMがもつ膨大な数のパラメータを更新するための大き過ぎるコストを避けるために、事前学習時のパラメータを凍結し、追加的に設定したパラメータや一部のパラメータのみを訓練・更新するParameter Efficient Fine-Tuningが用いられる。

OpenAI APIには、gpt-3.5-turboやgpt-4(experimental)を対象としたInstruction Tuning機能がある [Fine-tuning - OpenAI API](https://platform.openai.com/docs/guides/fine-tuning)。しかし、GPT-4の中でも最近のモデルやその他のAPIベースのLLMは、ファインチューニングのためのAPIが必ずしも公開されているわけではないため、ファインチューニングを使用できないことがある。

### プロンプティングと文脈内学習

現在のLLMの大きな特徴の一つに、言語モデル自体のアーキテクチャの変更やパラメータの更新を必要とせずに、モデルへの入力を変えるだけで、様々なタスクに対応したり、推論性能を向上させられることがある。プロンプティング（Prompting）とは、特定の機能の発生を促進 (prompt)するように言語モデルに入力するコンテキスト文を指す。文脈内学習（In-Context Learning）とは、文脈内学習は、言語モデルのパラメータを更新せずに条件づけにより予測を修正できる。

- **Zero-Shot Prompting** : 学習時に一切見たことのないタスクに対して、事前学習済みのLLMの汎用的な知識を活用して推論を行う方法である。例えば、根本原因診断タスクでは、現在発生中の障害の説明のみをプロンプトにコンテキストとして含めて、その障害の根本原因はなにか？とLLMに質問することを指す。[Zero-Shot Prompting | Prompt Engineering Guide\<!-- --\>](https://www.promptingguide.ai/techniques/zeroshot)
- **Few-Shot Prompting**：少数の事例をプロンプトに含めることで、LLMにタスクの解き方を示唆し、性能を向上させる手法である。（“Language Models are Few-Shot Learners”, NeurIPS2020） [Few-Shot Prompting | Prompt Engineering Guide](https://www.promptingguide.ai/techniques/fewshot)
- **Chain-of-Thought Prompting（CoT、思考連鎖）**: 単に最終的な答えを出すのではなく、Few-Shotの事例の際に、途中の思考の流れを明示することで、回答の質や説得力を高める。（“Chain of Thought Prompting Elicits Reasoning in Large Language Models”, NeurIPS2022） [Chain-of-Thought Prompting | Prompt Engineering Guide\<!-- --\>](https://www.promptingguide.ai/techniques/cot)
	- Zero-Shot Chain-of-Thought：Few-Shotの事例なしで、単に"Let's think step by step."とプロンプトに指示を追加するだけでCoTを実現する手法である。（”Large Language Models are Zero-Shot Reasoners”, NeurIPS2022）[Chain-of-Thought Prompting | Prompt Engineering Guide](https://www.promptingguide.ai/techniques/cot#zero-shot-cot-prompting)
- **Self Consistency（自己無矛盾性）**: 複数のプロンプトや推論結果の整合性を評価し、最も無矛盾な結果を多数決で選択することで、LLMの出力の一貫性を高める手法である。CoTの推論能力を改善する。（“Self-Consistency Improves Chain of Thought Reasoning in Language Models”, ICLR2023）[Self-Consistency | Prompt Engineering Guide\<!-- --\>](https://www.promptingguide.ai/techniques/consistency)

### 拡張言語モデル（Augumented Language Model: ALM）

拡張言語モデルには、次の検索ベースのモデルとツールベースのモデルがある。

**Retrieval Augumented Laguage Models（検索拡張言語モデル）** は、LLMの推論時に、外部の知識源（Wikipediaや社内文書など）から関連する情報を検索し、言語モデルに提示する手法である。特に、検索した文書を元の入力に結合してコンテキストとして入力する手法を**RAG（Retrieval Augmented Generation）** と呼ぶ。（"In-Context Retrieval-Augmented Language Models", 2023） [Retrieval Augmented Generation (RAG) | Prompt Engineering Guide\<!-- --\>](https://www.promptingguide.ai/techniques/rag)

文書の検索には、外部テキストdからクエリqに類似した文書を見つけるための検索器（Retriever）を用いる。類似度の定義方法は様々あり、単語の出現頻度に基づくTF-IDFや、テキストdとクエリqの各埋め込み（Embedding）ベクトル間のコサイン類似度などがその代表である。

**Tool Augumented Langage Models（ツール拡張言語モデル）** は、LLMが知識ではなく外部ツールと連携し、生成を修正・補強する、またはエージェントを操作するなどにより、タスクを遂行する手法である。外部ツールとしては、検索、コード、API、異種モデルなどがある。ツール拡張言語モデルとしてToolFormerやReActなどが有名である。

- **ToolFormer**: どのAPIを呼び出すか、いつ呼び出すか、どの引数を渡すか、そしてその結果をどのように将来のトークン予測に反映させるかを決定するために学習するモデルである。（“ToolFormer” Language Models Can Teach Themselves to Use Tools”, 2023）
- **ReAct**: Reasoning（推論）とAction（行動）を交互に繰り返すことで、LLMに複雑なタスクを自律的に遂行させるフレームワークである。例えば、質問に答えるために必要な情報を外部ツールで検索したり、途中の計算結果を利用したりしながら、段階的に回答を構築する。（“ReAct: Synergizing Reasoning and Acting in Language Models”, ICLR2023）[ReAct Prompting | Prompt Engineering Guide\<!-- --\>](https://www.promptingguide.ai/techniques/react)
- **Reflexion**: 自己評価、自己反省、記憶のコンポーネントを導入することで、ReActフレームワークを拡張したものである。これによりLLMは過去の失敗から迅速かつ効果的に学習できる。（"Reflexion: Language Agents with Verbal Reinforcement Learning", 2023） [Reflexion | Prompt Engineering Guide\<!-- --\>](https://www.promptingguide.ai/techniques/reflexion)

検索拡張言語モデルとツール拡張言語モデルは、外部の知識やツールにより言語モデルを拡張することに着目した用語である。一方で、拡張された能力を用いて、LLMが頭脳となり外部環境と相互作用しながら自律的に試行錯誤してタスクを実行することに着目した用語が**LLMエージェント**（LLM Agents: [LLM Agents | Prompt Engineering Guide](https://www.promptingguide.ai/research/llm-agents)）である。LLMエージェントは構築方法がフレームワーク化されている。LLMとプランニングやメモリ、ツール使用などの主要モジュールを組み合わせたアーキテクチャを使用する。この際、LLMはタスクやユーザ要求を完了するために必要な操作の流れを制御するメインコントローラまたは頭脳として機能する。 ReActとReflexionはLLMエージェントの一種である。

## LLMによる障害診断法の分類

各論文の詳細を説明する前に、各論文が提案する障害診断手法を分類することにより、概観を把握するための手助けをする。

まず、障害診断手法を、各手法が採用するLLMの要素技術に基づいて、ファインチューニングベース、検索拡張言語ベース、LLMエージェントベースの3種のグループに分類する。

1) ファインチューニングベース：2022年11月にMicrosoft ResearchからLLM4SREでは初の研究[[Ahmed+,ICSE'23]](https://dl.acm.org/doi/abs/10.1109/ICSE48619.2023.00149)が公開された。 Microsoftの40,000件以上のインシデントのタイトルやサマリーなどのテキストデータを用いて、GPT-3.5をファインチューニングしている。2023年5月公開の[Oasis](https://dl.acm.org/doi/10.1145/3611643.3613891)は、個別具体的なシステムのドメイン用語を理解させるために、同じくGPT-3.5をファインチューニングすることにより、障害状況の要約文を自動で作成する。

2) 検索拡張言語ベース：[[Zhang+,2024]](https://arxiv.org/abs/2401.13810)は、現在アクティブな障害に類似する過去の障害の文書を履歴から検索し、LLMのプロンプトにFew-Shotとして例示することで、アクティブな障害の説明テキストを入力として根本原因を予測させる。PACE-LMは障害履歴を基に予測させた根本原因がどの程度信頼できるかをキャリブレーションし、信頼度スコアを付与する。過去ではなく、今何が起きているか？を示すテレメトリデータも検索するアプローチとして、[RCACopilot](https://arxiv.org/abs/2305.15778)と[Panda](https://www.amazon.science/publications/panda-performance-debugging-for-databases-using-llm-agents)がある。

3) LLMエージェントベース：より発展的なアプローチとして、[[Roy+,2024]](https://arxiv.org/abs/2403.04123)、[RCAgent](https://arxiv.org/abs/2310.16340)、[D-Bot](https://arxiv.org/abs/2312.01454)などのLLMエージェントに基づく研究がある。エージェントベースのアプローチは、検索拡張に加えてツール拡張を備え、検索とツールの実行と推論を折り重ねることで、まるで人間のエンジニアが試行錯誤するかのように、障害原因を自律的に診断する。

次に、その他の観点を含めた各論文の性質を以下の表にまとめる。各論文の「対象システム」、論文の手法が使用する「ドメイン固有データとツール」、「LLM技術」、「モデル」を整理する。

|              文献名（手法名）               |       対象システム       |           タスク           |             ドメイン固有データとツール              |                        LLM技術                         |       使用する主なモデル       |     |
| :---------------------------------: | :----------------: | :---------------------: | :------------------------------------: | :--------------------------------------------------: | :-------------------: | --- |
|          [Ahmed+,ICSE'23]          |        クラウド        |       根本原因と緩和策の予測       |         インシデントの履歴。タイトルとサマリーのみ。         |                  Instruction Tuning                  |        GPT-3.5        |     |
|        [Jin+,FSE'23] (Oasis)        |        クラウド        | 関連する複数のインシデントの要約テキストの生成 |         インシデントの履歴。手動作成の要約を含む。          |                  Instruction Tuning                  |    GPT-3 / GPT-3.5    |     |
|           [Zhang+,2024]            |        クラウド        |         根本原因の予測         |               インシデントの履歴                |                    RAG + Few-Shot                    |         GPT-4         |     |
|      [Zhang+,2023] (PACE-LM)       |        クラウド        |   予測された根本原因の信頼性スコアの計算   |               インシデントの履歴                |                    RAG + Few-Shot                    |         GPT-4         |     |
| [Samanta+,CLOUD'23] (InsightsSumm) | クラウド /<br>アプリケーション |      障害の要約テキストの生成       |   アラート、トポロジー、ログ、メトリクス（Golden Signal）   |                       Few-Shot                       | ChatGPT / Flan T5 XXL |     |
|  [Chen+,EuroSys'24] (RCACopilot)   |      メールサービス       |       根本原因カテゴリの予測       |        テレメトリ（メトリクス/ログ）、インシデント履歴        |                    RAG + Few-Shot                    |         GPT-4         |     |
|    [Komal+,CASCON2023] (ADARMA)    |      マイクロサービス      |     障害の修復のためのコード生成      |       テレメトリ（メトリクス/ログ）、公開Runbook        |             Few-Shot, Instruction Tuning             |          NA           |     |
|            [Roy+,2024]             |        クラウド        |         根本原因の予測         |        インシデント履歴と詳細、Runbook相当の文書        |                   LLMエージェント（ReAct）                   |         GPT-4         |     |
|       [Wang+,2023] (RCAgent)       |        クラウド        |         根本原因の予測         |            非構造化データ（ログ/コード）             | Zero-Shot CoT, LLMエージェント（ReActの拡張）, Self-Consistency |        Vicuna         |     |
|      [Hamadanian+,HotNets'23]      |       ネットワーク       |         緩和計画の生成         |         インシデントの情報とメタデータ（詳細不明）          |                      LLMエージェント                       |          NA           |     |
|        [Zhou+,2023] (D-Bot)         |       データベース       | 症状、根本原因、緩和策を含む診断レポートの生成 |     データベース製品文書、pg_stat_statements、     |                 LLMエージェント, マルチエージェント                 |         GPT-4         |     |
|        [Singh+,2024] (Panda)        |       データベース       | 症状、根本原因、緩和策を含む診断レポートの生成 |     Auroraのwaitイベント文書と250のDBメトリクス      |                         RAG                          |         GPT-4         |     |
|      [Jiang+,ICSE'24] (Xpert)      |        クラウド        | テレメトリデータ分析用ドメイン固有言語の生成  | インシデント履歴（メタデータ、タイトル、概要、ディスカッション）、クエリ履歴 |                    Few-Shot + RAG                    |    GPT-3.5 / GPT-4    |     |

**対象システム**: D-BotとPandaはデータベースシステムの、[Hamadanian+,HotNets'23]はネットワークシステムの障害診断を対象とする。それ以外のほとんどの論文では細部の対象指定はなく単に"クラウドシステム"と記述されており、IaaSやPaaSに限るのか、SaaSやWebアプリケーションも含むかは定かではない。

**タスク**: 提案手法の大半が対象としているタスクは、障害の根本原因予測である。他には、障害の要約やレポートの自動生成、緩和策の提案、修復のためのコード生成など、障害管理プロセスの各フェーズに対応するタスクを扱う手法も存在する。

**データ**: ほとんどの手法が、過去に発生したインシデント（障害）の履歴データを利用している。履歴データの形式は、インシデントのタイトルやサマリーのテキストデータが主流だが、詳細な説明や手動で作成された要約を含む場合もある。一方で、リアルタイムに収集されるテレメトリデータを活用する手法も登場している。障害対応の運用手順を記したRunbookなどのナレッジベースを参照する手法もある。

**モデル**: 多くの手法でGPTファミリー（GPT-3、GPT-3.5、GPT-4）を使用しているが、一部でFlan-T5-XXL、Vicunaなども用いられている。

## LLMによる障害診断論文の個別紹介

主要な障害診断論文を一つずつ取り上げ、論文の概要と論文に対する自分の主観を交えた感想を個別に紹介する。概要は論文に記載されているAbstractそのものではなく、自分なりにまとめたものである。個別の論文を詳細までは解説しきれないため、詳細を知りたい場合は本文を直接読んでみてほしい。

### [[Ahmed+,ICSE'23]: "Recommending Root-Cause and Mitigation Steps for Cloud Incidents using Large Language Models"](https://arxiv.org/abs/2301.03797)

概要：LLMをAIOpsへ適用する初の研究。Microsoftの40,000件以上のインシデントのタイトルやサマリーなどのテキストデータを用いて、インシデントの根本原因特定と緩和策の提案の２つのタスクに対して、LLMの有効性を評価した。自動メトリクスと人間へのインタビューの評価の結果、LLMのある程度の有用性と将来性が期待できることが実証された。Davinci-002（GPT-3.5）はGPT-3の全モデルに対してそれぞれ少なくとも15.38％、11.9％の性能向上を達成した。また、GPT-3.xモデルをファインチューニングすることで、ゼロショットに対して、LLMの有用性が大幅に向上することが発見された。Microsoftのブログ記事<https://www.microsoft.com/en-us/research/blog/large-language-models-for-automatic-cloud-incident-management/>でも本論文が解説されている。

感想：MSならではの大規模なデータセットで最速でLLMを評価していることは非常に興味深い。LLMではない既存の機械学習によるデータ解析手法と比較してどの程度よいのかの比較と、実インシデントにLLMを用いて対応する事例はまだないため、あくまでLLMの将来性を確認する研究であると位置づけられる。GPT-4が登場する以前に公開された論文なので、GPT-4で評価されていないが、GPT-4で性能が向上するかに注目したい。さらに、インシデントのタイトルとサマリー以外に、チャット上でのエンジニアの対応ログや、システム構成データ、ソースコード、各種ソフトウェアのドキュメントやチケットデータなどのテキストデータを学習することで、性能が向上する可能性がある。

### [[Jin+,ESEC/FSE'23 (Oasis)]: "Assess and Summarize: Improve Outage Understanding with Large Language Models"](https://dl.acm.org/doi/10.1145/3611643.3613891)

概要：Microsoftのクラウド（おそらくAzure）では1度の障害で複数のインシデントが発生することがあり、それらの影響範囲を手動で評価し、要約することは困難である。Microsoftの過去3年間の18のクラウドシステムからのインシデントデータを用いて、障害の悪影響とエンジニアの対処法を実証調査した。その結果、エンジニアによる手動評価時間の中央値は1時間であった。さらに、ルールベース、インシデント履歴、深層学習による3つのインシデントリンク法の組み合わせにより障害の影響範囲を自動で特定する手法を提案し、そのリンク構造から、障害の要約をGPT-3.5の事前のファインチューニングとプロンプティングにより実現する。評価の結果、GPT-3モデル（DaVinci）を用いたOasisが語彙評価指標で最高となり、人間による評価でも54名中32名のエンジニアが、Oasis-DaVinciの要約を最も優れていると評価した。

感想：MSのおそらくAzureを対象とするため、1個の障害に対して、複数のインシデントが紐づけられる、かなり大規模な問題設定となっている。本論文では、第一コンポーネントである影響範囲法自体の定量的評価は行われていないが、Microsoftで3年以上にわたって広く使用されていると記述されている。したがって、この論文の主な貢献は、MSの大規模なインシデントの実証調査報告部分とLLMという流行の技術を用いた要約生成部分になる。要約生成のロジック自体は単純であり、ファインチューニングによる貢献が大きいものと思われる。また、要約作成までの時間が中央値１時間とあるが、その内訳は書かれておらず、インシデントのリンク付けのほうが時間を要している可能性もある。その場合、要約生成は手動でも自動でもあまり総合的な時間はかわらない可能性もある。GPT-4など上位のモデルはファインチューニングの方法を提供していないため、プロンプティングや拡張言語モデルにより同等の要約性能を達成できないだろうか。

### [[Zhang+,2024]: "Automated Root Causing of Cloud Incidents using In-Context Learning with GPT-4"](https://arxiv.org/abs/2401.13810)

概要：Microsoft Researchからの、GPT-4を用いてクラウドのインシデントの履歴データから根本原因分析を自動化するシステムの提案論文。履歴データをすべて個別にGPT-3.5で要約・埋め込みベクトル化し、発生中のインシデントの記述と関連するインシデントを検索しプロンプトに含める文脈内学習を行う。約10万件のインシデントデータを用いた実験の結果、GPT-4ベースの提案法は、GPT-3ファインチューニングよりも24.77%高い精度となったが、GPT-3.5ベースの提案法はまだ及ばない結果であった。人間による評価では、提案法が正しさの点で43.5%高いスコアを獲得した。その他、プロンプトに含める過去インシデント例の個数や質、順序を変化させたり、GPTファミリーごとの性能差についても定量的に比較されている。

感想：ドメイン特化のファインチューニングモデルに対して、単純なチャンク分割ではないインシデントデータに特化したRAG手法が性能で凌駕したと解釈した。提案法は単純だが、Few Shotの例の数や質、順序によりどのように性能が変化するかを細かく定量的に比較していることが貢献である。RCACopilotやRCAgentはまさにこの論文で提示されている今後の課題に取り組んだようなアプローチがなぜ本論文で取り上げられていないのかは不明である。また、提案法はファインチューニング済みGPT-4相当のモデルと比較しないとフェアな比較とは言えない。

### [[Zhang+,2023 (PACE-LM)]: "PACE-LM: Prompting and Augmentation for Calibrated Confidence Estimation with GPT-4 in Cloud Incident Root Cause Analysis"](https://arxiv.org/abs/2309.05833)

概要：Microsoft Researchからの、LLMによる根本原因の予測結果を過去のインシデント履歴を用いてキャリブレーションされた信頼度を推定する手法PACE-LMの提案論文。推定のプロセスは2段階あり、まず、現在のインシデントの根本原因について推論するのに十分な証拠を過去のインシデント履歴が持っているかどうかの二値をLLMに分析させる。次に、その分析のための会話ログをプロンプトに含めて、生成された根本原因をスコアリングするようにLLMに依頼する。GPTのパラメータTemperatureを1にして、サンプリングした経験平均をスコアとする。最後に、各段階のそれぞれのスコアを結合し、最適な信頼度区間に割り当てるための最適化を行う。

感想：本論文は、[Zhang+,2024]のRAGベースの根本原因予測に対して、信頼度スコアを追加で算出することを提案するような格好である。分析とスコアリングでステップを分けるとなぜうまくいくのかは疑問ではあるが、推論の手順を指示することはChain-of-Thoughtに近い。一旦「過去データは現在のインシデント分析の役に立つかを分析させて」その結果をスコアリングで再評価するというのはおもしろい。 $I_a$と$I_s$のプロンプト文次第で、結果が左右されるはずなので、プロンプト文が示されていないのは再現性に影響する。

### [[Chen+,EuroSys'24 (RCACopilot)]  "Automatic Root Cause Analysis via Large Language Models for Cloud Incidents"](https://arxiv.org/abs/2305.15778)

概要：Microsoftにおけるクラウドのインシデントの根本原因カテゴリをLLMで自動で推論するシステムRCACopilotの提案論文。インシデント対応時にエンジニアが複数のデータソースから手動でデータを精査することが難しいことに対して、1)アラート種別ごとに、ルールベースのプログラムを組み合わせた決定木ライクなハンドラを構築し、これにより診断情報を収集し、2)LLMを用いて一旦診断情報を要約した上で、さらに過去の類似インシデントのFew Shot学習により根本原因カテゴリとその説明を提供する。Microsoftのメールサービスシステムの653件のインシデントデータを用いた実験ではXGBoost、FastText、Fine-tuned LLM、素のGPT-4、GPT-4 embeddingに対して、予測精度が大幅に向上し、平均15秒以内に応答できている。

感想：アドホックな動機や設計が気になるが、現場寄りの高度なオンコールシステムの設計が提案されていることはおもしろい。 根本原因のカテゴリ予測のみにタスクを限定しているが、なぜ限定するかについては納得の行く説明は含まれていなかった。診断情報収集ステージのハンドラはルールベースのプログラムの集合であり、フローやアクションのフックとなるスクリプトをアラートタイプごとに事前に整備しておかなければならない。これはエンジニアに大きな作業コストを要求する可能性がある。具体的には、ハンドラ内で、複数のデータソースから必要なデータを取得するためのクエリパラメータをどのようにして決定するのか？、どの基準でスコープを切り替えるのか？といった細部の疑問を解消していかなければならない。Pandaと同様、文脈内学習の範疇で高い精度を達成していることは、社会実装する際の重要な示唆である。

### [[Roy+,2024]: "Exploring LLM-based Agents for Root Cause Analysis"](https://arxiv.org/abs/2403.04123)

概要：Microsoftから、クラウドのインシデントの根本原因特定の自動化を、データを収集できる外部環境とのインタラクションをもつLLMのエージェントを用いた手法を実装・評価する論文。評価のための手法は既存のReActを基に実装される。ReActは段階的な推論とツールの使用によりLLMを拡張する。ツールでアクセス可能なデータは要約前のインシデントの詳細と過去のインシデント履歴である。ゼロショットにて、ReActはRAGやCoTのようなベースラインと競合する性能を持ち、かつハルシネーションの割合が大幅に低くなることを示した。MS社内のRunbookやトラブルシューティングガイドに相当するKBAと呼ばれる文書にアクセス可能とし、かつ、コンソールへのログインなど人間への介入したときの可能性があることを明らかにした。

感想：本研究で初めて提案されたとされるエージェントベースのRCAには、AlibabaからのRCAgentが存在するがなぜこの論文が参照されていないかは不明である。エージェントの文脈で、KBAと表記されるいわゆるRunbookやトラブルシューティングガイド（TSGs）の、ポストモーテムにはない診断プロセスの重要性が強調されていることは興味深い。 最後の研究の方向性については、まさに自分が考えるInteractive AIOpsに近い話である。

### [[Wang+,2023 (RCAgent)]: "RCAgent: Cloud Root Cause Analysis by Autonomous Agents with Tool-Augmented Large Language Models"](https://arxiv.org/abs/2310.16340)

概要：Alibabaにおけるクラウドインシデントの根本原因をLLMを用いて自動で推論するシステムの提案論文。LLMによる障害診断の既存手法は、ファインチューニングやRAGベースのものがあるが、すべてGPTファミリーとMicrosoft内のシナリオに基づいていることから、データプライバシーの懸念がある。そこで、プライバシーの懸念と手動ワークフロー設計の問題に対処する、ツール拡張型の自律エージェントRCAgentを提案している。RCAgentは、プライバシー懸念を解消するローカルのオープンLLM（Vicuna）、ワークフローの手動設計を必要としない行動軌跡レベルのゼロショット、および、コンテキスト長を短縮するための、多様な非構造化データ型を集約するためのプロンプトフレームワーク、ノイズの多いデータの修正、自己一貫性による行動軌跡の集約機構などを備える。実験では、ツール拡張型自律エージェントの代表であるReActに対して、全ての側面でRCAgentが凌駕しており、特にエビデンスの予測において従来の手法を改善している。

感想：過去のインシデントデータをおそらくは用いずにRCAシステムを組み上げている例として興味深い。Self-Consistency Aggregationの機構は理解することがかなり困難であった。おそらく、ReActについての理解がないとなぜ集約する必要があるのかの動機からしてわからない。LLMとして、Vicunaを用いているが、2024年2月現在公開されているより性能の高いLLMであれば、どの程度システムを簡易化できるのだろうか。

### [[Zhou+,2023, (D-Bot)]: "D-Bot: Database Diagnosis System using Large Language Models"](https://arxiv.org/abs/2312.01454)

概要：中国の清華大学のDB研究グループによる、LLMを用いたDBの異常診断システムD-Botを提案する論文。D-Botのソースコードは、<https://github.com/TsinghuaDatabaseGroup/DB-GPT>に公開されている。既存の半自動診断ツールは、1)診断シナリオが限られている、2)DBバージョンに応じた診断ルールの更新が手間である、3)反復的な推論能力を持たないなどの課題がある。GPT-4でもDBドメイン固有の診断知識を直接学習できない(精度50%以下)。そこでD-Botは、ドキュメントから知識とツールを抽出し、現在の異常の内容をもとに、関連する知識とツールを検索しプロンプトに含め、診断の過程では、複数回のLLMの投票をもとに最も有望なものを選択するようLLMを誘導するツリーベースの探索戦略を導入し、プロンプトが異なる複数のLLMエキスパートが非同期で協調して診断する。PostgreSQLを用いた評価の結果、ベースラインに対して顕著な改善(8%~54%)を達成し、人間の専門知識とさえ拮抗し、一部は上回っている。

感想：RCAgentのように、LLMをエージェントとして振る舞わせ、段階的な推論過程を踏みながら診断を行っていく様は非常に興味深い。今後は、原因診断にLLMを適用する場合は、LLMを推論機械とみなし、いかに必要なドメイン知識をプロンプトに注入するか、いかに複数の推論ステップを踏ませ、いかに複数の推論指向を用意できるように推論過程を設計するか。LLM自体の推論能力が高まった場合にどうなるのか。推論過程を人間からみえる分、結果の説明性が高いかもしれない。

### [[Singh+,CIDR'24, (Panda)]: "Panda: Performance Debugging for Databases using LLM Agents"](https://www.amazon.science/publications/panda-performance-debugging-for-databases-using-llm-agents)

概要：AWSのAI研究グループによるデータベースのデバッギングにLLMを応用するシステムの提案論文。DBのデバッギングはそのDBの文脈を踏まえる必要があるが、GPT-4の応答は一般的なベストプラクティスしか出力しない。RAGを用いるにも、非構造化テキストであるマルチモーダルデータに対してどのようにRAGを応用するかは自明ではない。提案するLLM駆動の自律型DBデバッグエージェントは、文脈を補完するためのGrounding、引用を生成するためのVerification、高リスクのアクションを強調するAffordance、改善のためのフィードバックを収集可能なFeedbackの4つの特性をもつ。合計6.25MトークンのAurora PostgreSQLとMySQLのwaitイベントドキュメントと、1分間の粒度で7日間かけて収集された合計250のDBメトリクスを用いて、GPT-3.5を基にした提案システムとGPT-4を比較した結果、人間による応答のスコア評価では、Pandaは信頼度、理解度、有用度においてGPT-4を凌駕した。Amazon Scienceのブログ記事<https://www.amazon.science/publications/panda-performance-debugging-for-databases-using-llm-agents>でも本論文が解説されている。

感想：DBのデバッギングに関して、人間のエンジニアが検索して取得するデータを集めてきて、GPTにそのデータ片をヒントに推論させれば望む回答が得られるのは直感的にもうまくいくように思う。文中では等に強調されていないが、膨大のメトリクスから絞り込むのではなく、関連文書内に含まれるメトリクス名からtop-kの類似度をもつメトリクスを取得する方法は即興的で簡便だが確かにうまく動作する可能性がある。メトリクスの時系列データをどのようにテキスト化しているかは文中の説明だけではわからなかった。おそらく、時系列データのベクトルそのものを直接テキストにするのではなく、変化点時刻やトレンド、p95などのスカラー値のみをテキストとして含めているのではないか。

## その他の関連論文と関連製品

ここでは、LLM4SREに関連する論文を簡単に列挙する。自分がAbstract程度しか読めていないものがほとんどであるため、詳しくは紹介できない。障害診断に関する論文、テキストログ解析、より汎用的な基盤モデルに関する論文がある。

### 障害に関連するその他の論文

前節で紹介した以外に、障害診断に関連する論文は次のようなものがある。Xpertは障害発生時にテレメトリデータに問い合わせるためのMicrosoft独自のDSLを自動生成する。Nissistは、エンジニアが記述したトラブルシューティングガイドのテキストと過去の緩和策を基に、障害の緩和策を提示する。InsightsSummは、故障に関する異種洞察/文脈データ(例:異常やその詳細、トポロジー情報、証拠を含むアラート)が与えられたとき、障害の要約を生成する。ADARMAは障害の緩和策をAnsible Playbookとして生成する。[Hamadanian+, HotNets2023]は、ネットワークシステムにおいてLLMを用いた新しい障害管理方法を提示する構想論文である。[Lian+,2023] (Ciri)は、LLMを基にした、ミドルウェアなどの設定を自動で検証するフレームワークである。

- [Xpert: Empowering Incident Management with Query Recommendations via Large Language Models](https://arxiv.org/abs/2312.11988)
- [Nissist: An Incident Mitigation Copilot based on Troubleshooting Guides](https://arxiv.org/abs/2402.17531)
- [InsightsSumm: Summarization of ITOps Incidents through In-Context Prompt Engineering](https://research.ibm.com/publications/insightssumm-summarization-of-itops-incidents-through-in-context-prompt-engineering)
- [ADARMA: Auto-Detection and Auto-Remediation of Microservice Anomalies by Leveraging Large Language Models](https://dl.acm.org/doi/10.5555/3615924.3615949)
- [Hamadanian+, HotNets2023]: [A Holistic View of AI-driven Network Incident Management](https://dl.acm.org/doi/abs/10.1145/3626111.3628176)
- [Lian+,2023 (Ciri)]: [Configuration Validation with Large Language Models](https://arxiv.org/abs/2310.09690)

### テキストログ解析

テキストログ解析、またはロギングのための計装にLLMを用いる論文もいくつか発表されている。

- [UniLog: Automatic Logging via LLM and In-Context Learning](https://dl.acm.org/doi/abs/10.1145/3597503.3623326)
- [LLMParser - A LLM-based Log Parsing Framework](https://conf.researchr.org/details/icse-2024/icse-2024-research-track/150/LLMParser-An-Exploratory-Study-on-Using-Large-Language-Models-for-Log-Parsing)
- [LogPrompt: Prompt Engineering Towards Zero-Shot and Interpretable Log Analysis](https://ieeexplore.ieee.org/abstract/document/10191948)
- [Prompting for Automatic Log Template Extraction](https://arxiv.org/abs/2307.09950)
- [Learning Representations on Logs for AIOps](https://arxiv.org/abs/2308.11526)
- [Exploring the Effectiveness of LLMs in Automated Logging Generation: An Empirical Study](https://arxiv.org/abs/2307.05950)

### 基盤モデル

基盤モデルとは、大量かつ多様なデータで訓練され、多様な下流タスクに適応（ファインチューニングなど）できるモデル((https://blog.recruit.co.jp/data/articles/foundation_models/))を指す。LLMを含む生成AIと呼ばれるAIモデルは基盤モデルの一種である。

次の３つの論文は、自分が知る限り、LLM4SREをテーマとする論文の中で最もLLMの基礎技術に近いものである。 [[Qiu+,NeurIPS'23]](https://research.ibm.com/publications/on-the-promise-and-challenges-of-foundation-models-for-learning-based-cloud-systems-management)は、AIOpsに特化した基盤モデルの構築に向けた構想論文である。 [Owl](https://arxiv.org/abs/2309.09298)は、ITオペレーションに特化したデータセットで学習させたLLMを提案している。Owlのコードとデータセットは<https://github.com/HC-Guo/Owl>に公開されている。[OpsEval](https://arxiv.org/abs/2310.07637)はバニラGPT-4に対するITオペレーションに特化したベンチマークである。CoTとSelf Consistencyの有効性や英語のほうが中国語より性能が高い、 4ビットの量子化では性能をほぼ維持できるが3ビットでは大きく低下するといった発見が報告されている。その他には、次のような論文がある。

- [Exploring Large Language Models for Low-Resource IT Information Extraction](https://research.ibm.com/publications/exploring-large-language-models-for-low-resource-it-information-extraction)
- [Proactive Continuous Operations using Large Language Models (LLMs) and AIOps](https://dl.acm.org/doi/10.5555/3615924.3615948)

### 関連製品

製品レベルでのLLM応用については自分はそれほど詳しくないが、自分が確認しているだけで次のようなものがある。

インシデント（障害）対応向けのSaaSで、LLMを用いている製品はいくつかある。自分の副業で関わらせてもらっている[Waroom](https://waroom.com/)では、発生中のインシデントの状況のサマリーをSlackのメッセージログを基に生成((https://docs.waroom.com/07a817e519394b15a5c63377bba5cfac))したり、対応後にポストモーテムを自動生成する((https://docs.waroom.com/e7824359da2240ae9c9dd8f5838ecb9c#block-34339fa259a24b03a25a6e4f8659badf))。[Pagerduty](https://www.pagerduty.com/)では、PagerDuty Copilotと呼ばれる生成AIによる自動化機能のセットがある。PagerDuty Copilotは、Slack botを介して各種PagerDutyの機能を自然言語から呼び出せたり、ステータスページの自動更新、ポストモーテムのドラフトの生成などが可能である((https://www.pagerduty.com/platform/generative-ai))。

その他、Honeycombには、テレメトリデータに対するクエリ文の生成機能がある((https://www.honeycomb.io/blog/introducing-query-assistant))。これはXpertと同じカテゴリのものである。

## 今後の展望

ここまでみてきた研究動向を踏まえて、LLMによる障害診断技術の今後を展望する。

### スナップショットとダイジェスト化

RCACopilot、RCAgent、D-Bot、および、Pandaなどは、障害発生時にローカルのシステムのテレメトリデータをLLMのプロンプトに取り込んでいる。これを障害スナップショットとここでは呼ぶことにする。RCACopilotの論文で指摘されているように、余分な情報がプロンプトに含まれるとノイズとなり、精度が低下する。そのため、LLMのコンテキストウィンドウの上限が増加しているとはいえ、現在発生中の障害に無関係の情報を削減しダイジェスト化できるかが重要となってくる。

障害スナップショットについて、既存論文は、テレメトリデータに対するクエリを自動生成することと、テレメトリデータのフィルタリングなどのテクニックを採用している。
Xpertはテレメトリデータに対するクエリのDSL（Domain Specific Language）をLLMにより生成する。Pandaはメトリクスの時系列データに対して、変化点検知により変化点のなかったメトリクスを除去し、障害に関連するデータを絞り込んでいる。

ダイジェスト化については、RCACopilotはログメッセージを含む不要な診断用情報を削減するために、診断用情報を約120〜140語以下に一旦要約している。RCAgentは、コンテキストウィンドウの使用量を低減するために、テレメトリデータの頭部のみを表示し、ハッシュIDを残す。その後、必要に応じて長文テキストを直接パラメータとして扱うのではなく、ハッシュIDからデータ本体を参照するようにLLMに指示する。ツールのAPIは、エンティティIDのような単純なパラメータしか受け付けないようにする。

Observabilityのコミュニティでは、テレメトリの計装と保存については[OpenTelemetry](https://opentelemetry.io/)により標準化が進んでいる。その一方で、テレメトリの障害スナップショットとダイジェスト化技術は、標準的な手法や実装が未だ確立されていない。そのため、今後の研究、あるいは、実装の課題となる。

### プロセスデータの管理

RCACopilotと[Roy+,2024]は共通してトラブルシューティングのプロセスに着目している。RCACopilotはエンジニアがアラート種別ごとにルールベースの自動対応プロセスを事前に設計している。[Roy+,2024]は診断の計画（プロセス）を手動で記述したRunbookを用いてReActが高レベルの診断計画を構築する。インシデントレポート（ポストモーテム）には、通常、診断ステップを実行するためのオペレーション知識ではなく、診断ステップの結果のみが含まれている。

このように、LLMエージェントは、人間のエンジニアのヒントなしに、高レベルの診断プロセスを導くことは困難であるため、手動による診断プロセスをいかに管理するが重要となってくるだろう。

### LLMの診断結果の説明性

機械学習一般に、モデルの予測に対する説明性または解釈性（Explainability）が重要であるとされている。モデルの予測が何をもって説明性をもつとするかは多岐に渡る。

LLMを用いないAIOpsでは、モデルの予測結果を人間への説明性を高めるために自然言語で説明するというアプローチを取りにくかった。しかし、LLMエージェントを採用した障害診断法では、反復の過程の履歴が残るため、その履歴を要約して人間に提示することにより、説明性は高くなりやすい。PACE-LMは原因の診断結果がどの程度信頼できるかのスコア付けを行っている。今後もなぜLLMがそのような診断をしたのかを根拠を提示する研究や製品UIが必要となるはずだ。

### 人間との協働

[Roy+,2024]に書かれているように、人間のSREsからのフィードバックにより精度を向上させていくアプローチと、危険な操作や人間にとって容易な操作を人間のSREsをエージェントのワークフローに介入させるアプローチが今後重要になってくるだろう。

このアプローチの良い例として、つい先日、ソフトウェア開発のための自律エージェントである、初のAIソフトウェアエンジニア[Devin](https://www.cognition-labs.com/blog)がある。このDevinでは認証が必要な操作は人間のソフトウェアエンジニアに介入させるようになっている。ワークフローを一貫してLLMエージェントに任せようとすると、どこか一つのステップで意図しない動作が発生すると、そのエージェントは使いものにならなくなってしまうが、人間を介入させることによりエージェントが全てをこなせなくとも有用となるように設計されている。

また、LLMの診断結果に対してその良し悪しを人間がフィードバックし、次回から改善されるサイクルも重要である。Pandaは単純なフィードバック機構を搭載しており、Few Shotで事例を列挙する際の事例を選択するときにフィードバック結果を反映している。このように、より良いモデルを効率的に学習するために人間を活用することはHuman in the Loopと呼ばれる。

### 従来のAIOpsモデルとの相補性

従来のAIOpsのモデルは、LLMのような汎用性はなく、ドメインとタスクに特化させてきた。従来モデルがLLMに取って代わるかというと必ずしもそうではなく、AIOpsのタスクによってはLLMが不向きであることもある。例えば「障害検知」は時系列データの多変量解析に依存するため、LLMにとっては困難なタスクであろう。障害診断のようにLLMに向いたタスクであっても、LLMが頭脳となり、ツールとして従来モデルを呼び出す手法が今後登場するだろう。

例えば、自分の研究成果である[MetricSifter](https://github.com/ai4sre/metricsifter)は、軽量な教師なし機械学習を用いて、障害と関連のないメトリクスをフィルタリングできる。MetricSifterを用いることにより、前述の障害スナップショットを取得しやすくなる。

### LLMの推論能力の制限と発展

この記事で紹介した論文のほとんどがGPTシリーズを用いている。その一方で、プライバシーなどの理由から、[オープンなLLM](https://github.com/Hannibal046/Awesome-LLM?tab=readme-ov-file#open-llm)を使いたい動機がある。

RCAgentはオープンなLLMを用いる数少ない手法である。しかし、GPT-4と比較して、 論文内では、スコアリングさせたときに、モデルは1と9しか提供できず、評価に多様性がないことや、ドキュメントの調整をしないと、エージェントは存在しない関数を呼び出すか、関数呼び出しのパラメータ化を誤る危険性があること、が指摘されている。

このような制限に対して、例えば、OwlのようなSRE特化データによるファインチューニングで補えるのか？それともやはりドメインに依存しない推論能力を向上する必要があるのか？といった問いが生まれる。

あるいは今後、記事執筆現在噂されているGPT-5などに代表される、GPT-4やClaude 3以上のLLMが開発される可能性がある。そのときに、この記事で紹介した論文の手法は依然として役に立つのか、あるいは不要になるのかは未知数である。

## むすび

この記事では、LLMによるシステム障害診断法に関する最新の研究動向を紹介した。SREの障害診断にLLMを応用する際に考慮すべきは、産業データとしての秘匿性（ローカルシステムの固有データ）とグローバルなドメイン知識の必要性（製品ドキュメントなど）、これらの2種類の外部知識の更新の必要性、オペレーションのための外部ツールの操作性、推論・観測・操作などを繰り返す反復性、といった性質である。これらのSRE全般、あるいはソフトウェアエンジニアリング全般に共通する性質でもあるため、この記事の内容は、隣接分野のLLM応用の世界を探索する際の参考になるかもしれない。

この記事により、LLM4SREの世界が今どうなっているのかをソフトウェアエンジニアリングのコミュニティに届けられ、興味を持ってもらえれば幸いである。LLMを含む生成AIに関する技術は急速に発展しているため、今日紹介した技術の課題を解決する技術が今後もすぐに登場する可能性はある。しかし、この記事を土台にしてもらえれば、それらの技術がなぜ優れているのかを比較的容易に理解できるかもしれない。

これを機にSRE論文を読もうと思われた人は、以前に自分が書いた、SRE論文の探し方と読み方をまとめた記事も読んでみてほしい。[エンジニアのためのSRE論文への招待 - SRE NEXT 2023 - ゆううきブログ](https://blog.yuuk.io/entry/2023/srenext2023)
