---
Title: "C++11でstaticな関数群を抽象化するための設計メモ "
Category:
- C++
Date: 2012-06-02T15:50:53+09:00
URL: http://blog.yuuk.io/entry/C%2B%2B11%E3%81%A7static%E3%81%AA%E9%96%A2%E6%95%B0%E7%BE%A4%E3%82%92%E6%8A%BD%E8%B1%A1%E5%8C%96%E3%81%99%E3%82%8B%E3%81%9F%E3%82%81%E3%81%AE%E8%A8%AD%E8%A8%88%E3%83%A1%E3%83%A2_
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/12704591929884338734
---

C++を始めて3週間くらいになります．gccのエラーを読むのがしんどいです．そろそろTBBを使いたい．


前回(http://qiita.com/items/16532cbb20ce15e622ed) のSorterクラスの設計を少しまともにしてみた．


http://github.com/y-uuki/cpp-sorter



*やったこと
- Template展開によりint型以外のデータ型に対応した．

- std::greater<>()などのプレディケートを指定できるようにした．

- 関数テンプレートのデフォルト引数（C++11）により，デフォルトのプレディケートのstd::less<>()にした．

- ソートに状態とかいらないし，抽象クラスによる抽象化をやめて代わりに，名前空間 namespace mysorter内にstatic関数をおくだけにした．

- privateにしたい関数をまとめておくための名前空間 namespace _implをつくり，擬似的にカプセル化した．（[twitter:@Linda_pp] に教わった）

- クイックソートとヒープソートを追加した．


***呼び出し側コード

>|cpp|
int main() {
    std::vector<int> a = {30, 40, 10, 70, 20, 90, 50, 60, 80};
    std::cout << "original:\n";
    print(a);

    std::cout << "heap_sort:\n";
    auto g(a);
    mysorter::heap_sort(g.begin(), g.end(), std::greater<>);
    print(g);

    return 0;
}
||<

***実装側コード

>|cpp|

/////////// Heap Sort ///////////
namespace _impl_hsort {

    template <
        class RandomAccessIterator,
        class Predicate = std::less< typename std::iterator_traits<RandomAccessIterator>::value_type >
    >
    static void heapify(RandomAccessIterator first, RandomAccessIterator last, const RandomAccessIterator idx, const Predicate pred)
    {
        auto const left = first + 2 * std::distance(first, idx) + 1;
        auto const right = first + 2 * std::distance(first, idx) + 2;
        auto largest = idx; // largest or smallest

        if (left < last and pred(*idx, *left)) {
            largest = left;
        }

        if (right < last and pred(*largest, *right)) {
            largest = right;
        }

        if (largest != idx) {
            std::iter_swap(idx, largest);
            heapify(first, last, largest, pred);
        }
    }

    template <
        class RandomAccessIterator,
        class Predicate = std::less< typename std::iterator_traits<RandomAccessIterator>::value_type >
    >
    static void build_heap(RandomAccessIterator first, RandomAccessIterator last, const Predicate pred)
    {
        const size_t n = std::distance(first, last);
        for (auto it = std::next(first, n/2 - 1); it >= first; --it) {
            heapify(first, last, it, pred);
        }
    }

}

template <
    class RandomAccessIterator,
    class Predicate = std::less< typename std::iterator_traits<RandomAccessIterator>::value_type >
>
static void heap_sort(RandomAccessIterator first, RandomAccessIterator last,
        const Predicate pred = std::less< typename std::iterator_traits<RandomAccessIterator>::value_type >())
{
    _impl_hsort::build_heap<RandomAccessIterator, Predicate>(first, last, pred);
    for (auto it = last - 1; it > first; --it) {
        std::iter_swap(first, it); // move largest value to a part of sorted array
        _impl_hsort::heapify<RandomAccessIterator, Predicate>(first, it, first, pred); // first becomes largest
    }
}

```
||<

*課題

現状の実装だと，テストコードを書くときに各ソートアルゴリズムごとに同一入力のテストを書かなければならないし冗長になる，
そこで，(http://www.slideshare.net/krustf/c11-11577820:title:bookmark) に書かれているTag Dispatchで抽象化したい．

traitで型を取得するためのイディオムが長いし，もう少しなんとかならないものか．
typename std::iterator_traits<RandomAccessIterator>::value_type
