---
Title: "Gitのリビジョン番号(SHA-1のアレ)の正体をソースコードを読んで調べてみた "
Category:
- Git
Date: 2012-06-18T19:20:00+09:00
URL: http://blog.yuuk.io/entry/2012/06/18/Git%E3%81%AE%E3%83%AA%E3%83%93%E3%82%B8%E3%83%A7%E3%83%B3%E7%95%AA%E5%8F%B7%28SHA-1%E3%81%AE%E3%82%A2%E3%83%AC%29%E3%81%AE%E6%AD%A3%E4%BD%93%E3%82%92%E3%82%BD%E3%83%BC%E3%82%B9%E3%82%B3%E3%83%BC%E3%83%89
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/12704591929890985445
---

> [Git Advent Calendar/Jun.](http://qiita.com/advent-calendar/git)6/18担当分の転載です．


今回はGitのリビジョン番号であるSHA-1のハッシュ値は何を元に生成されているのかを調べてみました．

Gitではリビジョン番号としてSubversionのような連番ではなく，SHA-1のハッシュ値を使用しています．

こんなやつですね．

```
commit 9bea2b5896701cf952f75c8f6756656cd3c40af0
```

Gitでは各開発者がローカルにリポジトリを持っているため，連番で管理すると，共有リポジトリにpushした時にコミットの一意性が保証されません．
そこで，Gitでは「何か」をKeyにしてSHA-1によるハッシュ値を計算し，各コミットに一意性のある番号を割り振っています．「何か」は各コミットにおいて一意である必要があります．

プロジェクトファイルの内容を全部SHA-1に突っ込んでたら計算時間が結構かかりそうだし，なんか工夫してそうだったので，の「何か」を調べるためにGitのソースを読んでみました．（https://github.com/git/git）

結論から言うと，Keyは(各ファイルに対するハッシュ値を統合したハッシュ値) + (当該コミットのAuthorやコミットメッセージを合わせたもの)になっているようです． 
前者の統合されたハッシュ値はインデックス作成時に計算され，後者の情報はコミット時に取得されます．
どうやらコミットの度にファイルを全部なめてるわけではないようです．
今回は後者について調べたところで力尽きました．前者についてはまた機会があれば調べたいと思います．

##調査手順

本当はトップダウンにソースを見ていきたかったんですが，途中でどの関数がSHA-1計算してそうかがわからなくなってしまったので，ボトムアップに探っていきました．
具体的には．```git grep SHA1```とかやって，怪しいところを見つけました．

commit.c内の```commit_tree_extended()```にて，commitツリーを拡張しています（つまりcommitの追加）．
ここで，```buffer```に対して```strbuf_addf()```で"tree"や"parent"などのヘッダ情報を連結していき，最後に，```write_sha1_file()```に```buffer```を渡してハッシュ値を計算させてる感じになっています．
```buffer```に連結する情報を以下に列挙してみます．

- ```buffer```のサイズは最大8192バイト
- "tree <treeオブジェクトのハッシュ値（16進数）>"を追加 (treeオブジェクトが何のことかは参考文献を参照)
- "parent <親コミットのハッシュ値>\nparent <親コミットのハッシュ値>\n…"を追加．
- "author <author文字列>"を追加
- encodingがutf-8でない場合，"encoding <エンコーディングの種別>"を追加
- ```extra```とかいうのを追加．extraがよくわからない．
- 改行追加
- コミットメッセージを追加


```c
int commit_tree_extended(const struct strbuf *msg, unsigned char *tree,
			 struct commit_list *parents, unsigned char *ret,
			 const char *author, const char *sign_commit,
			 struct commit_extra_header *extra)
{
	int result;
	int encoding_is_utf8;
	struct strbuf buffer;

	assert_sha1_type(tree, OBJ_TREE);

	if (memchr(msg->buf, '\0', msg->len))
		return error("a NUL byte in commit log message not allowed.");

	/* Not having i18n.commitencoding is the same as having utf-8 */
	encoding_is_utf8 = is_encoding_utf8(git_commit_encoding);

	strbuf_init(&buffer, 8192); /* should avoid reallocs for the headers */
	strbuf_addf(&buffer, "tree %s\n", sha1_to_hex(tree));

	/*
	 * NOTE! This ordering means that the same exact tree merged with a
	 * different order of parents will be a _different_ changeset even
	 * if everything else stays the same.
	 */
	while (parents) {
		struct commit_list *next = parents->next;
		struct commit *parent = parents->item;

		strbuf_addf(&buffer, "parent %s\n",
			    sha1_to_hex(parent->object.sha1));
		free(parents);
		parents = next;
	}

	/* Person/date information */
	if (!author)
		author = git_author_info(IDENT_STRICT);
	strbuf_addf(&buffer, "author %s\n", author);
	strbuf_addf(&buffer, "committer %s\n", git_committer_info(IDENT_STRICT));
	if (!encoding_is_utf8)
		strbuf_addf(&buffer, "encoding %s\n", git_commit_encoding);

	while (extra) {
		add_extra_header(&buffer, extra);
		extra = extra->next;
	}
	strbuf_addch(&buffer, '\n');

	/* And add the comment */
	strbuf_addbuf(&buffer, msg);

	/* And check the encoding */
	if (encoding_is_utf8 && !is_utf8(buffer.buf))
		fprintf(stderr, commit_utf8_warn);

	if (sign_commit && do_sign_commit(&buffer, sign_commit))
		return -1;

	result = write_sha1_file(buffer.buf, buffer.len, commit_type, ret);
	strbuf_release(&buffer);
	return result;
}
```
 
以上で，何をKeyとしてSHA-1を計算しているかはわかりましたが，一応，write_sha1_fileをたどっていきます．
ここでは，commit_typeには"commit"が代入されています．

```c
const char *commit_type = "commit";
```

```write_sha1_file_prepare()```で```sha1```バッファに計算したハッシュ値を```returnsha1```に入れて返しています．

```c
int write_sha1_file(const void *buf, unsigned long len, const char *type, unsigned char *returnsha1)
{
	unsigned char sha1[20];
	char hdr[32];
	int hdrlen;

	/* Normally if we have it in the pack then we do not bother writing
	 * it out into .git/objects/??/?{38} file.
	 */
	write_sha1_file_prepare(buf, len, type, sha1, hdr, &hdrlen);
	if (returnsha1)
		hashcpy(returnsha1, sha1);
	if (has_sha1_file(sha1))
		return 0;
	return write_loose_object(sha1, hdr, hdrlen, buf, len, 0);
}
```

さらに，```write_sha1_file_prepare()```を辿ってみると，```hdr```と```buf```を合わせてSHA-1計算してます．
```hdr```の中身は，```"commit <bufの長さ>"```になるはずです．（```type```には"commit"が入ってる）

```c:sha1_file.c
static void write_sha1_file_prepare(const void *buf, unsigned long len,
                                    const char *type, unsigned char *sha1,
                                    char *hdr, int *hdrlen)
{
	git_SHA_CTX c;

	/* Generate the header */
	*hdrlen = sprintf(hdr, "%s %lu", type, len)+1;

	/* Sha1.. */
	git_SHA1_Init(&c);
	git_SHA1_Update(&c, hdr, *hdrlen);
	git_SHA1_Update(&c, buf, len);
	git_SHA1_Final(sha1, &c);
}
```

以上で，SHA-1のkeyが何かだいたいわかりました．
最初，全然違うところを見てて疲れました．

##まとめ

- Gitのコードは関数の行数が高々30行程度以下に抑えてあって多分結構読みやすいです．

- リボジョン番号のハッシュ値は```hdr``` + ```buf```をKeyとして計算しています．

```
hdr = "commit <bufの長さ>"
buf = "tree <treeオブジェクトのハッシュ値(16進数)> parent <親コミットのハッシュ値>\nparent <親コミットのハッシュ値>\n… author <author文字列> encoding <エンコーディングの種別> <extra> \n <コミットメッセージ>"
```

- treeオブジェクトのハッシュ値を真面目に見てませんが，おそらく各ファイルの内容を反映した値になってるはずです．機会があればそっちもくわしく見ていきたいと思います．

##参考文献

- [9.2 Gitの内側-Gitオブジェクト](http://git-scm.herokuapp.com/book/ja/Git%E3%81%AE%E5%86%85%E5%81%B4-Git%E3%82%AA%E3%83%96%E3%82%B8%E3%82%A7%E3%82%AF%E3%83%88)
ユーザが意識しないようなローレベルの話が書いてあります．tree オブジェクトとかの詳細はここが参考になります．
