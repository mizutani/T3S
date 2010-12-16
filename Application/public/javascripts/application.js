$(document).ready(function() { 
    $("table") 
    .tablesorter({widthFixed: true, widgets: ['zebra']}) 
    .tablesorterPager({container: $("#pager")}); 
}); 
$(function(){
    $('form[data-remote]').bind('ajax:success', function(data, status, xhr){
        console.log("*** ajax:success ***");
        console.dir(data);
        console.dir(status);
        console.log("*** END: ajax:success ***");
    });
    
    $('form[data-remote]').bind('ajax:failure', function(xhr, status, error){
        console.log("+++ ajax:failure +++");
        console.dir(xhr);
        console.dir(status);
        console.dir(error);
        console.log("+++ END: ajax:failure +++");
    });
});
