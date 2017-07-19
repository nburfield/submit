/*$(document).on("click", "#create_testcase", function(){
  doPoll(Math.floor(Date.now()/1000));
});

function doPoll(startTime){
  var v = $('#test_case').data("test_case");
  var timeConstraint = $('#cpu').data("test_case");
  console.log(startTime);
  console.log(timeConstraint);
  console.log(v);
  $.get('data/' + v.id)
    .done(function(data) {
      $.get('outputs/' + v.id);
    	
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
    	
    	
    });
    */
  