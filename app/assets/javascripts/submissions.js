$(document).on("click", "#run_submission", function(){
  doPoll();
});

function doPoll(){
  var v = $('#submission').data("submission")

  $.get('data/' + v.id)
    .done(function(data) {
    	if(parseInt(data.trc) != parseInt(data.total)) {
    		setTimeout(doPoll, 500);
    	}
    	else {
    		$.get('outputs/' + v.id)
    	}
    });
}
