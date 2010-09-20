// basic product page enhancements
$(function () {
  $('#product-variants input[type=radio]').click(function (event) {
    var price = $("#variant-price_"+this.value).text();
    $(".selling").text(price);
  });
  
  $("#product-variants li").hover(
    function (e) {
      $(this).addClass('hover-variant');
      
    },
    function (e) {
      $(this).removeClass('hover-variant');
    }
  );

  $('#product-variants li').qtip({
     text: false,
     show: 'mouseover',
     hide: 'mouseout'
  })
});