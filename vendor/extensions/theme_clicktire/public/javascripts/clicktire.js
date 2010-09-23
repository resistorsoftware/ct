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

/*
bxCarousel v1.0
Plugin developed by: Steven Wanderski
http://bxcarousel.com
http://stevenwanderski.com

Released under the GPL license:
http://www.gnu.org/licenses/gpl.html
*/

(function($){$.fn.bxCarousel=function(options){var defaults={move:4,display_num:4,speed:500,margin:0,auto:false,auto_interval:2000,auto_dir:'next',auto_hover:false,next_text:'next',next_image:'',prev_text:'prev',prev_image:'',controls:true};var options=$.extend(defaults,options);return this.each(function(){var $this=$(this);var li=$this.find('li');var first=0;var fe=0;var last=options.display_num-1;var le=options.display_num-1;var is_working=false;var j='';var clicked=false;li.css({'float':'left','listStyle':'none','marginRight':options.margin});var ow=li.outerWidth(true);wrap_width=(ow*options.display_num)-options.margin;var seg=ow*options.move;$this.wrap('<div class="bx_container"></div>').width(999999);if(options.controls){if(options.next_image!=''||options.prev_image!=''){var controls='<a href="" class="prev"><img src="'+options.prev_image+'"/></a><a href="" class="next"><img src="'+options.next_image+'"/></a>';}
else{var controls='<a href="" class="prev">'+options.prev_text+'</a><a href="" class="next">'+options.next_text+'</a>';}}
$this.parent('.bx_container').wrap('<div class="bx_wrap"></div>').css({'position':'relative','width':wrap_width,'overflow':'hidden'}).before(controls);var w=li.slice(0,options.display_num).clone();var last_appended=(options.display_num+options.move)-1;$this.empty().append(w);get_p();get_a();$this.css({'position':'relative','left':-(seg)});$this.parent().siblings('.next').click(function(){slide_next();clearInterval(j);clicked=true;return false;});$this.parent().siblings('.prev').click(function(){slide_prev();clearInterval(j);clicked=true;return false;});if(options.auto){start_slide();if(options.auto_hover&&clicked!=true){$this.find('li').live('mouseenter',function(){if(!clicked){clearInterval(j);}});$this.find('li').live('mouseleave',function(){if(!clicked){start_slide();}});}}
function start_slide(){if(options.auto_dir=='next'){j=setInterval(function(){slide_next()},options.auto_interval);}else{j=setInterval(function(){slide_prev()},options.auto_interval);}}
function slide_next(){if(!is_working){is_working=true;set_pos('next');$this.animate({left:'-='+seg},options.speed,function(){$this.find('li').slice(0,options.move).remove();$this.css('left',-(seg));get_a();is_working=false;});}}
function slide_prev(){if(!is_working){is_working=true;set_pos('prev');$this.animate({left:'+='+seg},options.speed,function(){$this.find('li').slice(-options.move).remove();$this.css('left',-(seg));get_p();is_working=false;});}}
function get_a(){var str=new Array();var lix=li.clone();le=last;for(i=0;i<options.move;i++){le++
if(lix[le]!=undefined){str[i]=$(lix[le]);}else{le=0;str[i]=$(lix[le]);}}
$.each(str,function(index){$this.append(str[index][0]);});}
function get_p(){var str=new Array();var lix=li.clone();fe=first;for(i=0;i<options.move;i++){fe--
if(lix[fe]!=undefined){str[i]=$(lix[fe]);}else{fe=li.length-1;str[i]=$(lix[fe]);}}
$.each(str,function(index){$this.prepend(str[index][0]);});}
function set_pos(dir){if(dir=='next'){first+=options.move;if(first>=li.length){first=first%li.length;}
last+=options.move;if(last>=li.length){last=last%li.length;}}else if(dir=='prev'){first-=options.move;if(first<0){first=li.length+first;}
last-=options.move;if(last<0){last=li.length+last;}}}});}})(jQuery);

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
  
  $.clearFilterBoxResults = function () {
    if(typeof $(".psg-wheel")[0] != "undefined") {
      $(".psg-wheel").html("");
    }
    if(typeof $(".oem-sizes")[0] != "undefined") {
      $(".oem-sizes").html("");
    }
    if(typeof $(".plus-sizes")[0] != "undefined") {
      $(".plus-sizes").html("");
    }
  };
  
  // user changed a drop down on the filter box, we should clean things up... depending on which dd changed
  $.resetFilterBox = function(type) {
     $.clearFilterBoxResults();
     $.cookie('psg_wheel', null, {expires: 7, path: '/'});
     $.cookie('psg_tires', null, {expires: 7, path: '/'});
      
    if(type === 'year') {
      $.cookie('psg_makes', null, {expires: 7, path: '/'});
      $.cookie('psg_models', null, {expires: 7, path: '/'});
      $('#selectModel').clearOptions();
      $('#selectMake').clearOptions();
      $(".vehicle-model").html("");
      $(".vehicle-make").html("");
    } else if(type === 'make') {
      $.clearFilterBoxResults();
      $.cookie('psg_models', null, {expires: 7, path: '/'});
      $('#selectModel').clearOptions();
      $(".vehicle-model").html("");
    }
  };
  
  $.setYearCookie = function () {
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
  };
  
  $.setMakeCookie = function () {
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
  };
  
  $.setModelCookie = function () {
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
  };
  
})(jQuery);

$(function () {
  
  // if the filter box is in the DOM, we need to deal with it, like the one on the front page...
  if($("#filter-box").length) {
    
    var yearCookie = $.cookie("psg_years");
    if(yearCookie) {
      var data = JSON.parse(yearCookie);
      var yearData = {
        selected: data.selectedYear,
        years: data.years
      }
    }
    
    var makeCookie = $.cookie("psg_makes");
    if(makeCookie) {
      var data = JSON.parse(makeCookie);
      var makeData = {
        selected: data.selectedMake,
        makes: data.makes
      }
    }
    
    var modelCookie = $.cookie("psg_models");
    if(modelCookie) {
      var data = JSON.parse(modelCookie);
      var modelData = {
        selected: data.selectedModel,
        models: data.models
      }
    }
    
    // if we found prevous setting, we can instantiate the controls as appropriate
    if (yearData instanceof Object) {
      ClickTire.utils.setYears(yearData.years);
      $('#selectYear').addOptions({
        text: '',
        data: ClickTire.utils.getYears(),
        selected: yearData.selected
      });
      if(yearData.selected != 0) {
        $(".vehicle-year").text(yearData.selected);
      }
      
      if(makeData instanceof Object) {
        ClickTire.utils.setMakes(makeData.makes);
        $('#selectMake').addOptions({
          text: (parseInt(makeData.selected,10))? '' : 'select make...',
          data: ClickTire.utils.getMakes(),
          selected: makeData.selected
        });
        if(makeData.selected !=0) {
          $(".vehicle-make").text(makeData.selected);
        }
      }
       
      if(modelData instanceof Object) {
        ClickTire.utils.setModels(modelData.models);
        var x = {
          text: (parseInt(modelData.selected,10))? '' : 'select model...',
          data: ClickTire.utils.getModels(),
          selected: modelData.selected
        }
        $('#selectModel').addOptions(x);
        if(modelData.selected != 0) {
          $(".vehicle-model").text(modelData.selected);
        }
        
        // now update the results... 
        // containers are oem-sizes, plus-sizes, and psg-wheel
        var wheel = JSON.parse($.cookie("psg_wheel"));
        if($(".psg-wheel").length && typeof wheel != 'undefined') {
          $(".psg-wheel").html(tmpl("wheelTemplate",wheel));
        }
        var tires = JSON.parse($.cookie("psg_tires"));
        // show off the OE tires for this vehicle
        if(tires && typeof $(".oem-sizes")[0] != 'undefined') {
          var oeTire = ""
          if(tires.oe && tires.oe.length) {
            for(var i = 0, len = tires.oe.length; i < len; i++) {
              oeTire += tmpl("tireTemplate", tires.oe[i]);
            }
            $(".oem-sizes").html(oeTire);
          }
        }
        
        // show off the Plus Size tires for this vehicle
        if(tires && typeof $(".plus-sizes")[0] != 'undefined') {
          var plusTire = ""
          if(typeof tires.ps != 'undefined' && tires.ps.length) {
            for(var i = 0, len = tires.ps.length; i < len; i++) {
              plusTire += tmpl("tireTemplate", tires.ps[i]);
            }
            $(".plus-sizes").html(plusTire);
          }
        }
        $('.psg-tire').hover(function () {$(this).addClass('psg-tire-on')}, function () {$(this).removeClass('psg-tire-on')});
        $('.psg-tire').click(function () {
          $.feedback("success","Search for "+$(this).text()+" tires");
          $.ajax({
             type: 'get',
             url: "/collections",
             dataType: "script",
             data: {t: 'Tires', option: 'size', criteria: $(this).text()},
             success: function(res) {
               console.log(res);
             }
           })
        });
      }
    } else {
      //ask for some years via an ajax call
      $.ajax({
        url: "/plussizeguide",
        dataType: "json",
        success: function(res) {
           ClickTire.utils.setYears(res.year);
           $('#selectYear').addOptions({text: '', data: ClickTire.utils.getYears(), selected: null});
           $('#selectModel').clearOptions();
           $('#selectMake').clearOptions();
           $.setYearCookie();
        }  
      });   
    }
    
    
  } 
  
  
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
      }
    } else {
      //ask for some years via an ajax call
      $.ajax({
        url: "/plussizeguide",
        dataType: "json",
        success: function(res) {
           ClickTire.utils.setYears(res.year);
           $('#selectYear').addOptions({text: '', data: ClickTire.utils.getYears(), selected: null});
           $('#selectModel').clearOptions();
           $('#selectMake').clearOptions();
           $.setYearCookie();
        }  
      });   
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
            $.resetFilterBox('year');
            ClickTire.utils.setMakes(res.make);
            $('#selectMake').clearOptions().addOptions({text: 'select make...', data: ClickTire.utils.getMakes(), selected: 'select make...'});
            $('#selectModel').clearOptions();
            if(typeof $(".vehicle-make")[0] != 'undefined') {
              $(".vehicle-year").text(year);
            }
            $.feedback('success', 'Loaded all Makes for the year '+year);
            $.setYearCookie();
            $.setMakeCookie();
         }  
       });
    });
    
    $("#selectMake").change(function () {
       var make = $(this).val();
       var year = $('#selectYear').val();
       $.resetFilterBox('make');
       // send this along to the PSG service to get new values for Make drop downs
       $.ajax({
         url: "/plussizeguide",
         dataType: "json",
         data: {selectYear: year, selectMake: make},
         success: function(res) {
            ClickTire.utils.setModels(res.model);
            $('#selectModel').clearOptions().addOptions({text: 'select model...', data: ClickTire.utils.getModels(), selected: 'select model...'});
            if(typeof $(".vehicle-make")[0] != 'undefined') {
              $(".vehicle-make").text(make);
            }
            $.setMakeCookie();
            $.setModelCookie();
            $.feedback('success', 'Loaded all Models for ' + make + ' from ' + year);
         }  
       });
    });
    
    $("#selectModel").change(function () {
       var make = $("#selectMake").val();
       var year = $('#selectYear').val();
       var model = $(this).val();
       $.resetFilterBox('model');
       // send this along to the PSG service to get new values for Make drop downs
       $.ajax({
         url: "/plussizeguide",
         dataType: "json",
         data: {selectYear: year, selectMake: make, selectModel: model},
         success: function(res) {
          
           if(typeof $(".vehicle-make")[0] != 'undefined') {
             $(".vehicle-model").text(model);
           }
           if(res.wheel) {
             $.cookie("psg_wheel", JSON.stringify(res.wheel), {expires: 7, path: '/'});
             $.cookie("psg_tires", JSON.stringify(res.tires), {expires: 7, path: '/'}); 
           }
           $.setModelCookie();
           $.feedback('success', 'Received Tires and Wheels for ' + year + ' ' + make + ' ' + model);
           
           // now update the results... 
           // containers are oem-sizes, plus-sizes, and psg-wheel
           if(typeof $(".psg-wheel")[0] != 'undefined') {
             $(".psg-wheel").html(tmpl("wheelTemplate",res.wheel));
           }
           // show off the OE tires for this vehicle
           if(typeof $(".oem-sizes")[0] != 'undefined') {
             var oeTire = ""
             if(res.tires.oe.length) {
               for(var i = 0, len = res.tires.oe.length; i < len; i++) {
                 oeTire += tmpl("tireTemplate", res.tires.oe[i]);
               }
               $(".oem-sizes").html(oeTire);
             }
           }

           // show off the Plus Size tires for this vehicle
           if(typeof $(".plus-sizes")[0] != 'undefined') {
             var plusTire = ""
             if(res.tires.ps.length) {
               for(var i = 0, len = res.tires.ps.length; i < len; i++) {
                 plusTire += tmpl("tireTemplate", res.tires.ps[i]);
               }
               $(".plus-sizes").html(plusTire);
             }
           }
           $('.psg-tire').hover(function () {$(this).addClass('psg-tire-on')}, function () {$(this).removeClass('psg-tire-on')});
           $('.psg-tire').click(function () {
             $.feedback("success","Search for "+$(this).text()+" tires");
             $.ajax({
               type: 'get',
               url: "/collections",
               dataType: "html",
               data: {t: 'tires', option: 'size', criteria: $(this).text()},
               success: function(res) {
                 $("#content").html(res);
               }
             })
           });
         }  
       });
    });
    
    // save the year, make and model values to their respective cookies.
    $(".psg-search").click(function () {
      if ($(this).hasClass('wheel')) {
        var href = '/t/wheels';
      } else {
        var href = '/t/tires';
      }
      document.location.href = href;
    });
    
    $('ul.product-image').bxCarousel({
      display_num: 1,       // number of elements to be visible
      move: 1,              // number of elements to the shift the slides
      speed: 500,           // number in milliseconds it takes to finish slide animation
      margin: 10,             // right margin to be applied to each <li> element (in pixels, although do not include "px")
      auto: false,          // automatically play slides without a user click
      auto_interval: 2000,  // the amount of time in milliseconds between each auto animation
      auto_dir: 'next',     // direction of auto slideshow (options: 'next', 'prev')
      auto_hover: false,    // determines if the slideshow will stop when user hovers over slideshow
      next_text: 'next',    // text to be used for the 'next' control
      next_image: '/images/icon_arrow_right.png',       // image to be used for the 'next' control
      prev_text: 'prev',    // text to be used for the 'prev' control
      prev_image: '/images/icon_arrow_left.png',       // image to be used for the 'prev' control
      controls: true        // determines if controls will be displayed 
    }); 
                         
    $(".pagination.ajax a").live('click',function (e) {
      e.preventDefault();
      console.log("You clicked an ajax pagination link, so let's fire off an ajax request to the controller ", this);
    }); 
    
});
