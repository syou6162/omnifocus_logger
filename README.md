# Usage
コマンドラインでomnifocusを様々な形式に整形できるofexport2をダウンロードして、パスの通った場所に置きます。

- [psidnell/ofexport2: Export your OmniFocus data to multiple file formats.](https://github.com/psidnell/ofexport2)

このコマンドを使って、jsonで出力し、rubyで加工、elasticsearchに投下します。

```bash
/path/to/ofexport2/bin/of2 -p -f json | ruby omnifocus_logger.rb | curl -XPOST localhost:9200/_bulk --data-binary @-
```
