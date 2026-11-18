# Dockerで試す AWS Emulator と Amazon S3

猫の画像を1枚保存して、同じ画像を取り出すハンズオンです。AWS CLIとAWS Emulatorの両方が1つのコンテナ内で動きます。必要なのはDockerとDocker Compose（`up --wait` 対応版）です。AWSアカウントの作成や、PCへのAWS CLIのインストールは不要です。

## まず動かす

このリポジトリをダウンロードして、`compose.yaml` のあるフォルダーで実行します。Docker Desktopを使う場合は先に起動してください。初回ビルド時にインターネットから公式AWS CLIイメージとエミュレーターのRPMを取得します。

```sh
docker compose up -d --build --wait
docker compose exec lab sh /opt/lab/demo.sh
```

デモは接続先のアカウントIDを確認し、バケットを作り、同梱の猫の画像をアップロードします。一覧を2通り表示してから画像をダウンロードし、元画像とSHA-256が一致すると `OK: photos/cat.jpg matches the original.` と表示します。デモは繰り返し実行できます。

## 同じ操作を自分で試す

**1. 接続先を確認する。** `Account` が `000000000000` ならエミュレーターです。コマンド先頭の `docker compose exec lab` は「このコンテナの中で実行する」という意味です。

```sh
docker compose exec lab aws sts get-caller-identity
```

**2. 入れ物に名前を付ける。** S3の入れ物が「バケット」です。次の例では `my-study-bucket` という名前で作ります。自動デモを先に実行した場合は作成済みなので、一覧表示から進めます。

```sh
docker compose exec lab aws s3 mb s3://my-study-bucket
docker compose exec lab aws s3 ls
```

**3. 猫の画像を保存する。** 保存先のバケット名は `my-study-bucket`、中のデータを識別する名前（キー）は `photos/cat.jpg` です。次の1行で保存できます。

```sh
docker compose exec lab aws s3 cp /opt/lab/cat.jpg s3://my-study-bucket/photos/cat.jpg
```

**4. 同じデータの見え方を比べる。** 1行目はキー全体の `photos/cat.jpg` を表示します。2行目では区切り文字に `/` を指定し、共通の先頭部分（プレフィックス）の `photos/` を表示します。一般用途バケットのS3コンソールがフォルダーのように見せる仕組みです。保存前に `photos` ディレクトリを作る操作はありません。

```sh
docker compose exec lab aws s3api list-objects-v2 --bucket my-study-bucket --query "Contents[].Key" --output text
docker compose exec lab aws s3api list-objects-v2 --bucket my-study-bucket --delimiter / --query "CommonPrefixes[].Prefix" --output text
```

**5. 画像を取り出す。** 取得にもキー全体を指定します。PCで画像を見たいときは、2行目でカレントフォルダーへコピーします。

```sh
docker compose exec lab aws s3 cp s3://my-study-bucket/photos/cat.jpg /tmp/downloaded-cat.jpg
docker compose cp lab:/tmp/downloaded-cat.jpg ./downloaded-cat.jpg
```

## 終了・やり直し

```sh
docker compose down
```

バケットと保存したデータはメモリ上にあり、エミュレーターの停止で消えます。次回は再び `docker compose up -d --wait` から始められます。

## 接続とトラブルシューティング

- CLIの接続先はコンテナ内の `https://127.0.0.1:9297`。起動ごとにエミュレーターが生成した認証情報と証明書を使います。ホストのAWS設定のマウント、ポートの公開、実行時の外部通信はいずれも不要です。操作はターミナルで行います。
- 起動が完了しないときは `docker compose ps -a` と `docker compose logs lab` を確認してください。DockerがLinuxコンテナを実行できること、ビルド時にPublic ECRとdownloads.aws.comへ接続できることを確認します。
- イメージはCLI 2.34.20と、ビルド時点の公式LTSパッケージを使用します。エミュレーターの版は `docker compose exec lab rpm -q aws-emulator` で確認できます。エミュレーターのIAM判定や対応APIには実AWSとの違いがあります。

AWS公式資料：[Dockerでの導入](https://docs.aws.amazon.com/emulator/latest/userguide/getting-started-docker.html) · [CLIの接続設定](https://docs.aws.amazon.com/emulator/latest/userguide/point-sdk-to-emulator.html) · [S3のオブジェクトキー](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-keys.html)

## 動作確認

2026年11月18日、Apple Silicon Mac、Docker Compose v5.6.1、AWS Emulator 1.0.500-1（aarch64）、AWS CLI 2.34.20で、自動デモを2回実行しました。キー一覧は `photos/cat.jpg`、区切りを指定した一覧は `photos/` となり、取得した画像の内容は元画像と一致しました。Dockerfileはlinux/amd64用パッケージも選択できますが、実行確認はlinux/arm64のみです。
