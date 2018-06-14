// console.log('loading:ok');
$(function() {
    // カードをめくる
    $('.turncard').click( function() {
        $(this).parent().prev('.card-style').toggleClass('is-surface').toggleClass('is-reverse');
    });
    // 削除ボタン
    $('.turn-btn.trash').click( function() {
        $('.micro-message').fadeOut(80);
        $(this).next('.micro-message').fadeIn(100);
    });
    // 削除ボタンのキャンセル
    $('.micro-message .cancel').click( function() {
        $(this).closest('.micro-message').fadeOut(80)
    });
});
