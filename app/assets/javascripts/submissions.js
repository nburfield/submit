$(document).on("click", "#run_submission", function(){
  deleteOutputs();
  doPoll(Math.floor(Date.now()/1000));
});

function deleteOutputs(){
  var v = $('#submission').data("submission");
  console.log("id",v.id);
  $.get('delete/' + v.id);
}

function doPoll(startTime){
  var v = $('#submission').data("submission");
  var timeConstraint = $('#cpu').data("submission");
  console.log(startTime);
  console.log(timeConstraint);
  console.log(v);
 
  $.get('data/' + v.id)
    .done(function(data) {
      $.get('outputs/' + v.id);
    	if(parseInt(data.trc) != parseInt(data.total)) {
    		var currentTime = Math.floor(Date.now()/1000);
    		if(currentTime - startTime > (timeConstraint*data.total)+30)
    		{
    			$.get('outputs/' + v.id);
    		}
    		else
    		{
          $.get('outputs/' + v.id);
    			setTimeout(doPoll, 500, startTime);
    		}
    	}
    	else {
    		$.get('outputs/' + v.id);
    	}
    });


  //   function doPoll(startTime){
  // var v = $('#submission').data("submission");
  // var timeConstraint = $('#cpu').data("submission");
  // console.log(startTime);
  // console.log(timeConstraint);
  // console.log(v);
  // $.get('data/' + v.id)
  //   .done(function(data) {
  //     if(parseInt(data.trc) != parseInt(data.total)) {
  //       var currentTime = Math.floor(Date.now()/1000);
  //       if(currentTime - startTime > (timeConstraint*data.total)+30)
  //       {
  //         $.get('outputs/' + v.id)  
  //       }
  //       else
  //       {
  //         setTimeout(doPoll, 500, startTime);
  //       }
  //     }
  //     else {
  //       $.get('outputs/' + v.id)
  //     }
  //   });
 

}

