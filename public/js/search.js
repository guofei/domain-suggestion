document.charset="UTF-8";

var timer_get_result = null;

var get_domain_result = function(url, only_show_vailable){
    console.log(url);
    $.getJSON(url, function(data) {
                  var items = [];
                  var i = 0;
                  $.each(data, function(key, val) {
                             if(key === "isfinished?"){
                                 if(val != 1)
                                     timer_get_result = setTimeout(function(){get_domain_result(url, only_show_vailable);},5000);
                             }
                             else if(key === "percent?"){
                                 var p = 1;
                                 if(val > p) p = val;
                                 $("#search_result").empty();
                                 $('<div/>',{
                                       html: 'Loading ' + p + '% ' + '<div class="progress progress-striped active"><div class="bar" style="width: ' + p + '%;"></div></div>'
                                   }).appendTo('#search_result');

                                 var checked = "";
                                 if(only_show_vailable)
                                     checked = "checked";
                                 $('<div/>',{
                                        html: '<input type="checkbox" id="onlyshowvaliable" '+ checked +'> Only show available'
                                   }).appendTo('#search_result');

                                 $("#onlyshowvaliable").click(function(){
                                                                  if(timer_get_result != null){
                                                                      clearTimeout(timer_get_result);
                                                                      timer_get_result = null;
                                                                  }
                                                                  if(this.checked)
                                                                      get_domain_result(url, true);
                                                                  else
                                                                      get_domain_result(url, false);
                                                              });
                             }
                             else{
                                 var value = "<i class=\"icon-search icon-ban-circle\"></i>  Not Available";
                                 if (val == 0)
                                     value = "<i class=\"icon-search icon-ok\"></i>  Available!";
                                 if (val == -1)
                                     value = "<i class=\"icon-question-sign\"></i>  Unknown";
                                 if (val == null)
                                     value = "<img src='/img/l.gif'>";

                                 if(only_show_vailable){
                                     if(val == 0 || val == null)
                                         items.push('<tr><td> ' + (++i) + ' </td><td>' + key + '</td><td>' + value + '</td></tr>');
                                 }
                                 else
                                     items.push('<tr><td> ' + (++i) + ' </td><td>' + key + '</td><td>' + value + '</td></tr>');
                             }
                         });

                  $('<table/>', {
                        'class': 'table table-hover',
                        html: '<thead><tr><th>#</th><th>Domain Name</th><th>Status</th></tr></thead><tbody>' + items.join('') + '</tbody>'
                    }).appendTo('#search_result');
              });
};

var submit_search = function(){
    var domain = $("#domain").attr("value");
    var tdl = $("#tdl").attr("value");
    var dic = $("#dic").attr("value");
    console.log(dic);
    var place = '0';
    if($('#optionsRadios2').is(':checked'))
        place = '1';

    if(timer_get_result != null){
        clearTimeout(timer_get_result);
        timer_get_result = null;
    }

    $.getJSON("/api/getallasync/" + domain + "/" + tdl + "?place=" + place + "&dic=" + dic, function(data) {});

    is_only_show_vailable = false;

    var p = 1;
    $("#search_result").empty();
    $('<div/>',{
          html: 'Loading ' + p + '% ' + '<div class="progress progress-striped active"><div class="bar" style="width: ' + p + '%;"></div></div>'
      }).appendTo('#search_result');

    get_domain_result("/api/result/" + domain + "/" + tdl + "?place=" + place + "&dic=" + dic, false);
};

$(document).ready(function() {
                      $("#search").click(function() {
                                             submit_search();
                                             return false;
                                         });
                      $("#search_domain_form").submit(function(){
                                                          submit_search();
                                                          return false;
                                                      });
                  });

