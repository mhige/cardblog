// console.log('preview loading:ok');

$(function () {
    //画像ファイルプレビュー表示のイベント追加 fileを選択時に発火するイベントを登録
    $('form').on('change', 'input[type="file"]', function (e) {
        var file = e.target.files[0],
            reader = new FileReader(),
            $preview = $(".preview");
        t = this;
        // 画像ファイル以外の場合は何もしない
        if (file.type.indexOf("image") < 0) {
            return false;
        }
        // ファイル読み込みが完了した際のイベント登録
        reader.onload = (function (file) {
            return function (e) {
                //既存のプレビューを削除
                $preview.empty();
                // .prevewの領域の中にロードした画像を表示するimageタグを追加
                $preview.append($('<img>').attr({
                    src: e.target.result,
                    width: "150px",
                    class: "preview",
                    title: file.name
                }));
            };
        })(file);
        reader.readAsDataURL(file);
    });
});

$(function () {
    //新規作成ボタンを押したときの動き
    $('button.new-post').click(function () {
        $('.modal-title .edit-post').hide();
    });
    //編集ボタンを押したときの動き
    $('button.edit').click(function () {
        $('.modal-title .new-post').hide();

        var $cardWrap  = $(this).closest('article'), //最も近い article を取得
            $postID    = $(this).closest('article').attr('id'), //最も近い article の id の中身（記事ID）を取得
            $ttlLabel  = $('label:contains("タイトル")'),
            $title     = $cardWrap.find('.post-title').text(),
            $content   = $cardWrap.find('.content-body p').text(),
            $image     = $cardWrap.find('.th-image').attr('src'),
            $imageName = $image.replace("\/img\/", "");
        alert($title);

        //ID・画像ファイル名（非表示）
        $ttlLabel.before('<input type="text" value="' + $postID + '" name="id" class="d-none">');
        $ttlLabel.before('<input type="text" value="' + $imageName + '" name="updatefile" class="d-none">');

        //入力フォームに値を入れる
        $('input[name="title"]').val($title);
        $('textarea[name="body"]').text($content);

        // input type="file"は
        // JSでフォームをコントロールできないので
        // 一回inputタグを消してもう一度作成しリセット
        var $imageInput = $('input[name="file"]');
        $imageInput.remove();
        $('label:contains("メイン画像")').after($imageInput);

        // 現在指定している画像のプレビュー
        var $preview =  $('.preview');
        $preview.empty(); //既存のプレビューを削除
        $preview.append($('<img>').attr({
            src: $image,
            width: "150px",
            class: "preview",
            title: $imageName
        }));

    });
    //キャンセルボタンを押したときの動き
    $('button.cancel').click(function () {
        //タイトルを全て表示（"新規投稿編集"）
        $('.modal-title .new-post').show();
        $('.modal-title .edit-post').show();
    });
});
