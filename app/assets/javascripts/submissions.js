$(document).on("click", "#run_submission", function(){
	doPoll();
});

$(document).on("click", "#delete_outputs", function(){
	doTestPoll();
});


function doPoll(){
	var v = $('#submission').data("submission")
	console.log("Running the Poll")
	console.log(v)

	$.get('data/1')
}

function doTestPoll(){
	console.log("Running Test Poll")
	$.get('compile/1')
}

