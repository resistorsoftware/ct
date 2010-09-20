$(function () {
  $('#product-variants input[type=radio]').click(function (event) {
    var price = $("#variant-price_"+this.value).text();
    $(".selling").text(price);
  });
});