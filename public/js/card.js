// console.log('loading:ok');
$(function() {
    //カードをめくる
    $('.turncard').on('click', function() {
        $(this).parent().prev('.card-style').toggleClass('is-surface').toggleClass('is-reverse');
    });
    $('.turn-btn.trash').on('click', function() {
        $(this).next('.micro-message').show();
    });

});
