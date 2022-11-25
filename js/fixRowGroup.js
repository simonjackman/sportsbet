$.fn.fixRowGroup = function (n) {
  return $(this).each(function () {
  var $table = $(this).css('border-collapse', 'collapse'); // no way around this!
  var $rows = $table.find('tr');
    $rows.each(function () {
      if ( $(this).hasClass("dtrg-group")){
        $(this).find('td').attr("colspan",n);
      }
    });
  });
};
