//console.log('loading:ok');
$(function() {
    $('.turncard').on('click', function() {
        $(this).prev('.card-style').toggleClass('is-surface').toggleClass('is-reverse');
    });
});
