/**
 * console.log fix for machines not running firebug.
 *
 */
if (typeof(console) === 'undefined') {
    var console = {
        log: function () {},
        info: function () {},
        warn: function () {},
        error: function () {},
        time: function () {}
    };
}
else if (typeof(console.log) === 'undefined') {
    console.log = function () {};
}

if(typeof ClickTire == 'undefined') {
  var ClickTire = {};
}

ClickTire.utils = function () {
  
  var years = [];
  var makes = [];
  var models = [];
  
  return {
    
    getYears : function () {
      if (years.length) {
        return years;
      } else {
        return null;
      }
    },
    
    setYears : function (data) {
      years = data;
    },
    
    getMakes : function () {
      if (makes.length) {
        return makes;
      } else {
        return null;
      }
    },
    
    setMakes : function (data) {
      makes = data;
    },
    
    getModels : function () {
      if (models.length) {
        return models;
      } else {
        return null;
      }
    },
    
    setModels : function (data) {
      models = data;
    }
                 
    
  };
}();

// Simple JavaScript Templating
// John Resig - http://ejohn.org/ - MIT Licensed
(function() {
    var cache = {};

    this.tmpl = function tmpl(str, data) {
        // Figure out if we're getting a template, or if we need to
        // load the template - and be sure to cache the result.
        var fn = !/\W/.test(str) ?
      cache[str] = cache[str] ||
        tmpl(document.getElementById(str).innerHTML) :

        // Generate a reusable function that will serve as a template
        // generator (and which will be cached).
      new Function("obj",
        "var p=[],print=function(){p.push.apply(p,arguments);};" +

        // Introduce the data as local variables using with(){}
        "with(obj){p.push('" +

        // Convert the template into pure JavaScript
str.replace(/[\r\t\n]/g, " ")
   .replace(/'(?=[^%]*%>)/g,"\t")
   .split("'").join("\\'")
   .split("\t").join("'")
   .replace(/<%=(.+?)%>/g, "',$1,'")
   .split("<%").join("');")
   .split("%>").join("p.push('")
   + "');}return p.join('');");
        // Provide some basic currying to the user
        return data ? fn(data) : fn;
    };
})();


(function ($) {
  $.fn.addOptions = function (obj) {
    options = [];
    if(obj.text.length) {
      options.push("<option value='" + 0 + "'>" + obj.text + "</option>");
    }
    $.each(obj.data, function(i, val) {
      if(obj.selected == val) {
        options.push('<option value="' + val + '" selected="selected">' + val + '</option>');
      } else {
        options.push("<option value='" + val + "'>" + val + "</option>");
      }
    })
     
    $(this).append(options.join(''));
    return this;
  } 
  
  $.fn.clearOptions = function () {
    $(this).children().remove();
    return this;
  }
  
  // feedback uses gritter to style things for us.
  $.feedback = function(type, msg) {
    feedback_title = {
      sticky: "Notification",
      notice: "Please note",
      error:  "Error",
      success: "Success"
    };

    $.gritter.add({
      image: '/images/gritter_icons/'+type+'.png',
      text: msg,
      title: feedback_title[type],
      sticky: type === 'sticky',
      time: (type === 'error')? 5000 : 3000
    });
  };
  
})(jQuery);

$(function () {
  if($('#tire_filter').length) {
    // Years can either come from Ajax or a cookie
    var yearCookie = $.cookie("psg_years");
    var makeCookie = $.cookie("psg_makes");
    var modelCookie = $.cookie("psg_models");
    
    if(yearCookie) {
      var data = JSON.parse(yearCookie);
      var yearData = {
        selected: data.selectedYear,
        years: data.years
      }
    }
    
    if(makeCookie) {
      var data = JSON.parse(makeCookie);
      var makeData = {
        selected: data.selectedMake,
        makes: data.makes
      }
    }
    
    if(modelCookie) {
      var data = JSON.parse(modelCookie);
      var modelData = {
        selected: data.selectedModel,
        models: data.models
      }
    }
    
    if (yearData instanceof Object) {
      ClickTire.utils.setYears(yearData.years);
      $('#selectYear').addOptions({
        text: '',
        data: ClickTire.utils.getYears(),
        selected: yearData.selected
      });
      
      // keep on trucking and try makes now too
      if(makeData instanceof Object) {
        ClickTire.utils.setMakes(makeData.makes);
        $('#selectMake').addOptions({
          text: (parseInt(makeData.selected,10))? '' : 'select make...',
          data: ClickTire.utils.getMakes(),
          selected: makeData.selected
        });
      } 
      // finish with any models
      if(modelData instanceof Object) {
        ClickTire.utils.setModels(modelData.models);
        var x = {
          text: (parseInt(modelData.selected,10))? '' : 'select model...',
          data: ClickTire.utils.getModels(),
          selected: modelData.selected
        }
        $('#selectModel').addOptions(x);
//        var ct = document.getElementById("wheel-results");
//        ct.innerHTML = tmpl("wheelTemplate",JSON.parse($.cookie("psg-wheel")));
//        var ct = document.getElementById("tire-results");
//        var tireData = "";
//        tires = JSON.parse($.cookie("psg-tires"));
//        for (var i = 0, len = tires.length; i < len; i++) {
//          tireData += tmpl("tireTemplate",tires[i]);
//        }
//        ct.innerHTML = tireData;
//        $('.tire-data').hover(function () {$(this).addClass('tire-data-on')}, function () {$(this).removeClass('tire-data-on')});
//        $('.tire-data').click(function () {
//          $.feedback("success","Search for "+$(this).find('.tiresize').text()+" tires");
//        });
      }
    } else {
      // ask for some years via an ajax call
      // $.ajax({
      //        url: "/plussizeguide",
      //        dataType: "json",
      //        success: function(res) {
      //           ClickTire.utils.setYears(res.year);
      //           $('#selectYear').addOptions({text: '', data: ClickTire.utils.getYears(), selected: null});
      //           $('#selectModel').clearOptions();
      //           $('#selectMake').clearOptions();
      //        }  
      //      }); 
    }
}    
    // setup some listeners for the drop downs.
    $("#selectYear").change(function () {
       var year = $(this).val();
       // send this along to the PSG service to get new values for Make drop downs
       $.ajax({
         type: 'get',
         url: "/plussizeguide",
         dataType: "json",
         data: {selectYear: year},
         success: function(res) {
            ClickTire.utils.setMakes(res.make);
            $('#selectMake').clearOptions().addOptions({text: 'select make...', data: ClickTire.utils.getMakes(), selected: 'select make...'});
            $('#selectModel').clearOptions();
            $.feedback('success', 'Loaded all Makes for the year '+year);
         }  
       });
    });
    
    $("#selectMake").change(function () {
       var make = $(this).val();
       var year = $('#selectYear').val();
       // send this along to the PSG service to get new values for Make drop downs
       $.ajax({
         url: "/plussizeguide",
         dataType: "json",
         data: {selectYear: year, selectMake: make},
         success: function(res) {
            ClickTire.utils.setModels(res.model);
            $('#selectModel').clearOptions().addOptions({text: 'select model...', data: ClickTire.utils.getModels(), selected: 'select model...'});
            $.feedback('success', 'Loaded all Models for ' + make + ' from ' + year);
         }  
       });
    });
    
    $("#selectModel").change(function () {
       var make = $("#selectMake").val();
       var year = $('#selectYear').val();
       var model = $(this).val();
       // send this along to the PSG service to get new values for Make drop downs
       $.ajax({
         url: "/plussizeguide",
         dataType: "json",
         data: {selectYear: year, selectMake: make, selectModel: model},
         success: function(res) {
           if(res.wheel) {
             // save these structures as a cookie as well as rendering them 
//             var ct = document.getElementById("wheel-results");
//             ct.innerHTML = tmpl("wheelTemplate",res.wheel);
//             $.cookie("psg-wheel", JSON.stringify(res.wheel), {expires: 7, path: '/'});
//             var ct = document.getElementById("tire-results");
//             var tireData = "";
//             for (var i = 0, len = res.tires.length; i < len; i++) {
//               tireData += tmpl("tireTemplate",res.tires[i]);
//             }
//             ct.innerHTML = tireData;
             $.cookie("psg-tires", JSON.stringify(res.tires), {expires: 7, path: '/'}); 
           }
           $.feedback('success', 'Received Tires and Wheels for ' + year + ' ' + make + ' ' + model);
//           $('.tire-data').hover(function () {
//               $(this).addClass('tire-data-on')},
//             function () {$(this).removeClass('tire-data-on')}
//           ).click(function () {
//                $.feedback("success","Search for "+$(this).find('.tiresize').text()+" tires");
//                $.ajax({
//                  type: 'get',
//                  url: "/collections",
//                  dataType: "html",
//                  data: {taxon: 'Tires', option: "size", criteria: $(this).find('.tiresize').text()},
//                  success: function(res) {
//                    $("#content").html(res);
//                  }
//                })
//              });
//           $('.wheel-data').hover(function () {$(this).addClass('wheel-data-on')}, function () {$(this).removeClass('wheel-data-on')}).click(function () {
//             $.feedback("success","Search for "+$(this).find('.bolt-pattern').text()+" wheels");
//           });
         }  
       });
    });
    
    // save the year, make and model values to their respective cookies.
    $(".psg-search").click(function () {
      // first the years
      var years = $("#selectYear").find('option');
      if(years.length > 1) {
        var y = [];
        years.each(function(idx, val) {
          if(idx > 0) {
            y.push($(this).text());
          }
        })
        var data = {
          selectedYear: $("#selectYear").val(),
          years: y
        }
        $.cookie("psg_years", JSON.stringify(data), {expires: 7, path: '/'});
      }
      // now the makes
      var makes = $("#selectMake").find('option');
      if(makes.length > 1) {
        var m = [];
        makes.each(function(idx, val) {
          if(idx > 0) {
            m.push($(this).text());
          }
        })
        var data = {
          selectedMake: $("#selectMake").val(),
          makes: m
        }
        $.cookie("psg_makes", JSON.stringify(data), {expires: 7, path: '/'});
      }
      // finally, the models
      var models = $("#selectModel").find('option');
      if(models.length > 1) {
        var m = [];
        models.each(function(idx, val) {
          if(idx > 0) {
            m.push($(this).text());
          }
        })
        var data = {
          selectedModel: $("#selectModel").val(),
          models: m
        }
        $.cookie("psg_models", JSON.stringify(data), {expires: 7, path: '/'});
      }
      if ($(this).hasClass('wheel')) {
        var href = '/t/wheels';
      } else {
        var href = '/t/tires';
      }
      document.location.href = href;
    });
    
    $(".psg-clear").click(function () {
      $.cookie('psg_years', null, {expires: 7, path: '/'});
      $.cookie('psg_makes', null, {expires: 7, path: '/'});
      $.cookie('psg_models', null, {expires: 7, path: '/'});
      $.cookie('psg_wheel', null, {expires: 7, path: '/'});
      $.cookie('psg_tires', null, {expires: 7, path: '/'});
      // reset the drop-down back to the basics...
      $('#selectModel').clearOptions();
      $('#selectMake').clearOptions();
      $('#selectYear').val(0);
      $("#tire-results").html('');
      $("#wheel-results").html('');
      $.feedback("success","Reset the Search settings") 
    });
    
});
